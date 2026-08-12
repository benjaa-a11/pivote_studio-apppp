import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/iptv_engine.dart';
import 'package:pivote/features/video/presentation/widgets/stream_url_resolver.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:pivote/features/video/presentation/widgets/pivo_pro_player.dart';
import 'package:pivote/features/video/presentation/widgets/pivo_shaka_player.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
// Pivote VideoPlayerWidget v7.0 — Universal PHP→M3U8 Edition
// ════════════════════════════════════════════════════════════════════════════
//
//  Native paths:
//    M3U8 / MP4 / HTTP(S) streams  → IPTVEngine (libmpv)
//    DASH / Iframe / HTML          → PivoProPlayer (WebView)
//    PHP / JS-obfuscated pages     → StreamUrlResolver → IPTVEngine
//
//  Features:
//    • Universal PHP→M3U8 resolver (6 strategies + LRU cache)
//    • GB-array + atob() JS obfuscation decoder
//    • Referer passthrough to libmpv for stream auth
//    • Mutex-protected initialization (no race conditions)
//    • Per-server retry with exponential backoff
//    • Adaptive server timeout (base + 2 s per attempt)
//    • IPTVEngine state polling + ChangeNotifier listener
//    • Orientation monitor for seamless fullscreen
//

class VideoPlayerWidget extends StatefulWidget {
  final Channel channel;
  final Widget Function(
    BuildContext context,
    UnifiedVideoController controller,
    bool isFullScreen,
    VoidCallback toggleFullScreen,
  )? controlsBuilder;

  const VideoPlayerWidget({
    super.key,
    required this.channel,
    this.controlsBuilder,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ── Engine / Controllers ─────────────────────────────────────────────────
  IPTVEngine? _engine;
  UnifiedVideoController? _unified;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── State ─────────────────────────────────────────────────────────────────
  PlayerState _playerState = PlayerState.idle;
  StreamSource? _currentStream;
  bool _isFullScreen = false;
  AspectRatioType _aspectRatio = AspectRatioType.ratio16_9;
  int _serverIndex = 0;
  bool _isMuted = false;
  bool _disposed = false;
  bool _useWebPlayer = false;
  bool _useShakaPlayer = false;
  int _retryCount = 0;
  int _serverAttempt = 0;

  /// Referer URL when stream was resolved from a PHP/web page
  String? _resolvedReferer;

  Completer<void>? _initLock;

  // ── Timers ─────────────────────────────────────────────────────────────────
  Timer? _serverTimeout;
  Timer? _loadingFailsafe;
  Timer? _orientationTimer;
  Timer? _enginePollTimer;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _disposed = false;

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addObserver(this);

    debugPrint('🎬 VideoPlayerWidget v6.0 — ${widget.channel.name}');

    _initPlayer();
    _startOrientationMonitor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || _useWebPlayer || _useShakaPlayer) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _engine?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _engine?.play();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _serverTimeout?.cancel();
    _loadingFailsafe?.cancel();
    _orientationTimer?.cancel();
    _enginePollTimer?.cancel();
    _engine?.removeListener(_onEngineState);
    _engine?.dispose();
    _unified?.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Orientation Monitor ───────────────────────────────────────────────────

  void _startOrientationMonitor() {
    _orientationTimer?.cancel();
    _orientationTimer =
        Timer.periodic(PlayerConfig.orientationCheckInterval, (_) {
      if (_disposed || !mounted) return;
      final landscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      if (landscape && !_isFullScreen) {
        _safeSetState(() => _isFullScreen = true);
      }
      if (!landscape && _isFullScreen) {
        _safeSetState(() => _isFullScreen = false);
      }
    });
  }

  // ── Player Initialization ─────────────────────────────────────────────────

  Future<void> _initPlayer() async {
    if (_initLock != null && !_initLock!.isCompleted) return;
    if (_disposed) return;

    _initLock = Completer();
    _setPlayerState(PlayerState.connecting);
    _retryCount = 0;
    _serverAttempt = 0;
    _serverIndex = 0;

    try {
      await _tryServer();
    } catch (e) {
      debugPrint('❌ _initPlayer: $e');
      _setPlayerState(PlayerState.error);
    } finally {
      _initLock?.complete();
    }
  }

  Future<void> _tryServer() async {
    if (_disposed) return;

    _serverTimeout?.cancel();
    _loadingFailsafe?.cancel();

    if (_serverIndex >= widget.channel.streamUrl.length) {
      _setPlayerState(PlayerState.error);
      return;
    }

    _currentStream = widget.channel.streamUrl[_serverIndex];
    String url = _currentStream!.url.trim();
    _resolvedReferer = null;

    debugPrint(
        '── Server ${_serverIndex + 1}/${widget.channel.streamUrl.length}');
    debugPrint('   URL: ${url.substring(0, min(80, url.length))}');

    // Detect stream type — skip URL resolution for MPD/DRM
    final isMpd = _currentStream != null &&
        (_currentStream!.isDash || _currentStream!.hasDrm);
    final isWeb = !isMpd && _isWebStream(url);

    // ── Universal URL resolution (PHP/web → M3U8) ─────────────────────
    // Runs for any URL that isn't a direct CDN/M3U8 or WebView/MPD path.
    if (!isMpd && !isWeb) {
      _setPlayerState(PlayerState.resolvingUrl);
      try {
        final result = await StreamUrlResolver.resolve(url);
        if (result.url.isNotEmpty) {
          url = result.url;
          _resolvedReferer = result.referer;
          if (result.wasResolved) {
            debugPrint(
                '🔗 Resolver [${result.strategy}] → ${url.substring(0, min(80, url.length))}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Resolver failed: $e');
      }
    }

    if (url.isEmpty) {
      await _nextServer();
      return;
    }

    // Re-check if the resolved URL is now a WebView/MPD type
    final resolvedIsWeb = !isMpd && _isWebStream(url);
    final resolvedIsMpd = !isMpd && url.toLowerCase().contains('.mpd');

    // Server timeout
    final timeoutSec = PlayerConfig.baseServerTimeout.inSeconds +
        (_serverAttempt * 2).clamp(0, PlayerConfig.maxTimeoutExtensionSeconds);

    _serverTimeout = Timer(Duration(seconds: timeoutSec), () {
      if (_disposed || !mounted) return;
      if (_playerState.isLoading &&
          _serverIndex < widget.channel.streamUrl.length - 1) {
        debugPrint('⏱ Server $_serverIndex timeout');
        _nextServer();
      }
    });

    // Loading failsafe — always show UI after 25 s (tuned for aggressive buffer)
    _loadingFailsafe = Timer(const Duration(seconds: 25), () {
      if (!_disposed && mounted && _playerState.isLoading) {
        debugPrint('⏱ Failsafe triggered');
        _setPlayerState(PlayerState.playing);
      }
    });

    if (resolvedIsWeb || isWeb) {
      debugPrint('🌐 Mode: WebView');
      _safeSetState(() {
        _useWebPlayer = true;
        _useShakaPlayer = false;
      });
      _setPlayerState(PlayerState.playing);
      _serverTimeout?.cancel();
      _loadingFailsafe?.cancel();
    } else if (resolvedIsMpd || isMpd) {
      debugPrint('🌐 Mode: Shaka WebView (MPD/DRM)');
      _safeSetState(() {
        _useWebPlayer = false;
        _useShakaPlayer = true;
      });
      _setPlayerState(PlayerState.playing);
      _serverTimeout?.cancel();
      _loadingFailsafe?.cancel();
    } else {
      debugPrint('📱 Mode: libmpv (IPTVEngine)');
      _safeSetState(() {
        _useWebPlayer = false;
        _useShakaPlayer = false;
      });
      _setPlayerState(PlayerState.initializing);
      await _loadIPTV(url);
    }
  }

  bool _isWebStream(String url) {
    final u = url.toLowerCase();
    return u.contains('iframe') ||
        u.contains('embed') ||
        u.contains('pivo-pro') ||
        u.contains('pivopro') ||
        u.contains('vercel.app') ||
        (u.contains('.html') && !u.endsWith('.php'));
  }

  // ── IPTVEngine Load ───────────────────────────────────────────────────────

  Future<void> _loadIPTV(String url) async {
    if (_disposed) return;

    // Destroy old engine cleanly
    _enginePollTimer?.cancel();
    _engine?.removeListener(_onEngineState);
    await _engine?.stop();
    _engine?.dispose();
    _unified?.dispose();

    // Fresh engine
    _engine = IPTVEngine();
    _unified = UnifiedVideoController.fromIPTV(_engine!);
    _engine!.addListener(_onEngineState);

    // Start polling fallback for non-notified states
    _enginePollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_disposed || !mounted) return;
      _safeSetState(() {});
    });

    await _engine!.load(
      url,
      k1: _currentStream?.k1,
      k2: _currentStream?.k2,
      // Pass the PHP page URL as Referer so CDN auth works correctly
      referer: _resolvedReferer,
    );
  }

  void _onEngineState() {
    if (_disposed || _engine == null) return;
    final s = _engine!.state;

    switch (s.status) {
      case IPTVStatus.playing:
        _serverTimeout?.cancel();
        _loadingFailsafe?.cancel();
        _retryCount = 0;
        if (_playerState != PlayerState.playing) {
          _setPlayerState(PlayerState.playing);
          _fadeCtrl.forward();
        }
        break;
      case IPTVStatus.buffering:
        if (_playerState == PlayerState.playing) {
          _setPlayerState(PlayerState.buffering);
        }
        break;
      case IPTVStatus.error:
        debugPrint('❌ Engine error: ${s.errorMessage}');
        _nextServer();
        break;
      case IPTVStatus.reconnecting:
        _setPlayerState(PlayerState.retrying);
        break;
      default:
        break;
    }

    _safeSetState(() {});
  }

  // ── Server failover ───────────────────────────────────────────────────────

  Future<void> _nextServer() async {
    if (_disposed) return;
    if (_serverIndex < widget.channel.streamUrl.length - 1) {
      _serverIndex++;
      _retryCount = 0;
      _serverAttempt++;
      _setPlayerState(PlayerState.connecting);

      final delay = _backoff(_serverAttempt);
      await Future.delayed(Duration(milliseconds: delay));
      if (!_disposed) await _tryServer();
    } else {
      debugPrint('❌ All servers exhausted');
      _loadingFailsafe?.cancel();
      _setPlayerState(PlayerState.error);
    }
  }

  int _backoff(int attempt) =>
      (PlayerConfig.backoffBaseMs * pow(2, attempt).toInt())
          .clamp(PlayerConfig.backoffBaseMs, PlayerConfig.backoffMaxMs);

  // ── URL Resolution ────────────────────────────────────────────────────────
  // Delegated entirely to StreamUrlResolver (see stream_url_resolver.dart).
  // The resolver handles: direct M3U8, PHP pages, JS-obfuscated arrays,
  // JWPlayer/Clappr configs, HTML5 video tags, and redirect chains.
  // Results are cached for 5 minutes to avoid repeated HTTP requests.

  // ── UI Helpers ────────────────────────────────────────────────────────────

  void _setPlayerState(PlayerState s) {
    if (_disposed || !mounted || _playerState == s) return;
    debugPrint('📊 State: ${_playerState.name} → ${s.name}');
    _safeSetState(() => _playerState = s);
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) setState(fn);
  }

  void _toggleFullScreen() {
    if (_disposed) return;
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _changeAspectRatio() => setState(() => _aspectRatio = _aspectRatio.next);

  double _getAspectRatio() {
    switch (_aspectRatio) {
      case AspectRatioType.auto:
      case AspectRatioType.ratio16_9:
        return 16 / 9;
      case AspectRatioType.stretch:
        final s = MediaQuery.of(context).size;
        return s.width / s.height;
    }
  }

  void _toggleMute() {
    if (_disposed) return;
    setState(() => _isMuted = !_isMuted);
    _engine?.setMuted(_isMuted);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── 1. Video Layer ──────────────────────────────────────────
            _buildVideoLayer(),

            // ── 2. Native Controls (only libmpv path) ──────────────────
            if (!_useWebPlayer && !_useShakaPlayer && _unified != null)
              Positioned.fill(
                child: widget.controlsBuilder != null
                    ? widget.controlsBuilder!(
                        context,
                        _unified!,
                        _isFullScreen,
                        _toggleFullScreen,
                      )
                    : CustomVideoControls(
                        controller: _unified!,
                        channelName: widget.channel.name,
                        onFullScreenToggle: _toggleFullScreen,
                        isFullScreen: _isFullScreen,
                        aspectRatioLabel: _aspectRatio.label,
                        onAspectRatioChange: _changeAspectRatio,
                        onMuteToggle: _toggleMute,
                        isMuted: _isMuted,
                        currentServer: _serverIndex + 1,
                        totalServers: widget.channel.streamUrl.length,
                        onServerSelect: (idx) {
                          _serverIndex = idx;
                          _retryCount = 0;
                          _serverAttempt = 0;
                          _setPlayerState(PlayerState.connecting);
                          _tryServer();
                        },
                      ),
              ),

            // ── 3. Fade-in animation ────────────────────────────────────
            if (!_useWebPlayer && !_useShakaPlayer)
              IgnorePointer(
                child: FadeTransition(
                  opacity: Tween(begin: 1.0, end: 0.0).animate(_fadeAnim),
                  child: Container(color: Colors.black),
                ),
              ),

            // ── 4. Loading overlay ──────────────────────────────────────
            if (!_useWebPlayer && !_useShakaPlayer && _shouldShowLoading())
              _buildLoading(),

            // ── 5. Error overlay ────────────────────────────────────────
            if (!_useWebPlayer &&
                !_useShakaPlayer &&
                _playerState == PlayerState.error)
              _buildError(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_useWebPlayer && _currentStream != null) {
      return Center(
        child: PivoProPlayer(
          url: _currentStream!.url,
          channelName: widget.channel.name,
          currentServer: _serverIndex + 1,
          totalServers: widget.channel.streamUrl.length,
          onRefresh: () => _nextServer(),
          onAllServersFailed: () {
            debugPrint('🔄 WebView exhausted → next server');
            _nextServer();
          },
        ),
      );
    }

    if (_useShakaPlayer && _currentStream != null) {
      return Center(
        child: PivoShakaPlayer(
          url: _currentStream!.url,
          k1: _currentStream!.k1,
          k2: _currentStream!.k2,
          clearkeys: _currentStream!.clearkeys,
          channelName: widget.channel.name,
          currentServer: _serverIndex + 1,
          totalServers: widget.channel.streamUrl.length,
          onRefresh: () => _nextServer(),
          onAllServersFailed: () {
            debugPrint('🔄 Shaka exhausted → next server');
            _nextServer();
          },
        ),
      );
    }

    if (_engine != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _getAspectRatio(),
          child: Video(
            controller: _engine!.videoController,
            controls: NoVideoControls,
            fill: Colors.black,
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }

  bool _shouldShowLoading() {
    if (_playerState.isLoading) return true;
    if (_engine?.state.status == IPTVStatus.buffering) return true;
    if (_engine?.state.status == IPTVStatus.reconnecting) return true;
    return false;
  }

  Widget _buildLoading() {
    final isReconnecting = _engine?.state.status == IPTVStatus.reconnecting;
    final isBuffering = _playerState == PlayerState.buffering ||
        _engine?.state.status == IPTVStatus.buffering;

    String msg;
    if (isReconnecting) {
      msg =
          'Reconectando... (${_engine?.state.reconnectAttempt}/${IPTVConfig.maxReconnectAttempts})';
    } else if (isBuffering) {
      msg = 'Cargando...';
    } else {
      msg = _playerState.displayMessage;
    }

    return VideoLoadingWidget(
      isBuffering: isBuffering,
      message: msg,
      serverInfo: widget.channel.streamUrl.length > 1
          ? '${_serverIndex + 1}/${widget.channel.streamUrl.length}'
          : null,
      subMessage: _playerState == PlayerState.retrying
          ? 'Intento $_retryCount/${PlayerConfig.maxRetriesPerServer}'
          : null,
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withAlpha(20),
                  border:
                      Border.all(color: Colors.red.withAlpha(60), width: 1.5),
                ),
                child: const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No se pudo conectar',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verifica tu conexión e intentá nuevamente.',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (widget.channel.streamUrl.length > 1) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withAlpha(20), width: 0.5),
                  ),
                  child: Text(
                    'Servidor ${_serverIndex + 1}/${widget.channel.streamUrl.length}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _serverIndex = 0;
                  _serverAttempt = 0;
                  _initPlayer();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).colorScheme.primary.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Reintentar',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
