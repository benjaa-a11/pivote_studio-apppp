import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/exo_player_widget.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
// PIVO SHAKA PLAYER v7.0 — Native ExoPlayer for MPD/DASH + ClearKey DRM
// ════════════════════════════════════════════════════════════════════════════
//
// Uses native Android ExoPlayer (Media3) via PlatformView instead of WebView.
// Drop-in replacement — same API and controls as the previous WebView version.
//
// Architecture:
//   Flutter Widget → AndroidView (PlatformView) → ExoPlayer native
//   Communication: MethodChannel (commands) + EventChannel (state)
//
// Features:
//   • Native ExoPlayer with DASH/MPD + ClearKey DRM
//   • CustomVideoControls integration (fullscreen, mute, aspect ratio)
//   • Loading/buffering/error UI
//   • Lifecycle management (pause/resume)
//   • Retry system with server failover
//   • Lightweight (~20MB RAM vs ~100MB WebView)
//
// ════════════════════════════════════════════════════════════════════════════

class PivoShakaPlayer extends StatefulWidget {
  final String url;
  final String? k1;
  final String? k2;
  final Map<String, String>? clearkeys; // Multi-key ClearKey DRM
  final String channelName;
  final int currentServer;
  final int totalServers;
  final VoidCallback onRefresh;
  final VoidCallback? onAllServersFailed;

  const PivoShakaPlayer({
    super.key,
    required this.url,
    this.k1,
    this.k2,
    this.clearkeys,
    required this.channelName,
    required this.currentServer,
    required this.totalServers,
    required this.onRefresh,
    this.onAllServersFailed,
  });

  @override
  State<PivoShakaPlayer> createState() => _PivoShakaPlayerState();
}

class _PivoShakaPlayerState extends State<PivoShakaPlayer>
    with WidgetsBindingObserver {
  late ExoPlayerController _exoController;
  late _ExoUnifiedAdapter _unified;

  bool _isFullscreen = false;
  AspectRatioType _arType = AspectRatioType.ratio16_9;
  bool _disposed = false;
  bool _videoStarted = false;
  int _retries = 0;

  // MPD streams need faster failure detection for high-demand events
  static const int _maxMpdRetries = 1;
  static const Duration _mpdLoadTimeout = Duration(seconds: 6);

  // State
  bool _isLoading = true;
  bool _isBuffering = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _hasError = false;
  String? _errorMessage;

  Timer? _loadingFailsafe;
  Timer? _loadTimeout;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🎬 PivoShakaPlayer v7.0 (Native ExoPlayer)');
    debugPrint(
        '   MPD: ${widget.url.substring(0, widget.url.length.clamp(0, 80))}');
    if (widget.clearkeys != null && widget.clearkeys!.isNotEmpty) {
      debugPrint('   DRM: ClearKey enabled (${widget.clearkeys!.length} keys)');
    } else if (widget.k1 != null) {
      debugPrint('   DRM: ClearKey enabled (legacy single-key)');
    }

    _exoController = ExoPlayerController();
    _unified = _ExoUnifiedAdapter(_exoController, this);

    _exoController.addListener(_onExoEvent);
    _startLoadingFailsafe();
    _startLoadTimeout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _exoController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _exoController.play();
    }
  }

  @override
  void didUpdateWidget(PivoShakaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.k1 != widget.k1 ||
        oldWidget.clearkeys != widget.clearkeys) {
      _resetAndReload();
    }
  }

  void _resetAndReload() {
    _videoStarted = false;
    _retries = 0;
    _isLoading = true;
    _isBuffering = false;
    _isPlaying = false;
    _hasError = false;
    _errorMessage = null;

    _exoController.dispose();
    _exoController = ExoPlayerController();
    _unified = _ExoUnifiedAdapter(_exoController, this);
    _exoController.addListener(_onExoEvent);

    _loadingFailsafe?.cancel();
    _loadTimeout?.cancel();
    _startLoadingFailsafe();
    _startLoadTimeout();

    setState(() {});
  }

  // ── ExoPlayer Events ─────────────────────────────────────────────────────

  void _onExoEvent(ExoPlayerEvent event) {
    if (_disposed || !mounted) return;

    switch (event.type) {
      case 'initializing':
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
        break;

      case 'buffering':
        setState(() {
          _isBuffering = true;
          _isLoading = false;
          _hasError = false;
        });
        break;

      case 'ready':
        _loadingFailsafe?.cancel();
        _loadTimeout?.cancel();
        setState(() {
          _isLoading = false;
          _isBuffering = false;
          _hasError = false;
        });
        break;

      case 'playing':
        _loadingFailsafe?.cancel();
        _loadTimeout?.cancel();
        _videoStarted = true;
        _retries = 0;
        setState(() {
          _isLoading = false;
          _isBuffering = false;
          _isPlaying = true;
          _hasError = false;
        });
        debugPrint('▶️ ExoPlayer playing');
        break;

      case 'paused':
        setState(() => _isPlaying = false);
        break;

      case 'error':
        debugPrint(
            '❌ ExoPlayer error: ${event.errorCode} — ${event.errorMessage}');
        _retries++;
        // Fast escalation: only 1 internal retry, then let parent try next server
        if (_retries > _maxMpdRetries) {
          debugPrint(
              '🔄 MPD failed after $_retries attempts → escalating to parent');
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = event.errorMessage ?? 'Error de reproducción';
          });
          widget.onAllServersFailed?.call();
        } else {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
          Future.delayed(
            const Duration(milliseconds: PlayerConfig.quickRetryDelayMs),
            () {
              if (!_disposed && mounted) _resetAndReload();
            },
          );
        }
        break;

      case 'ended':
        setState(() => _isPlaying = false);
        break;
    }
  }

  // ── Monitoring ────────────────────────────────────────────────────────────

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(PlayerConfig.loadingFailsafeTimeout, () {
      if (!_disposed && mounted && _isLoading) {
        debugPrint('⏱ ExoPlayer loading failsafe');
        setState(() => _isLoading = false);
      }
    });
  }

  void _startLoadTimeout() {
    _loadTimeout?.cancel();
    // Use faster MPD-specific timeout for quicker failover
    _loadTimeout = Timer(_mpdLoadTimeout, () {
      if (_disposed || !mounted || _videoStarted) return;
      debugPrint('⏱ ExoPlayer load timeout → escalating to parent');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'El servidor no respondió a tiempo';
      });
      // Skip internal retries on timeout — let parent try next server immediately
      widget.onAllServersFailed?.call();
    });
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _exoController.setMuted(_isMuted);
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _changeAspectRatio() => setState(() => _arType = _arType.next);

  double _getAspectRatio() {
    switch (_arType) {
      case AspectRatioType.stretch:
        final s = MediaQuery.of(context).size;
        return s.width / s.height;
      default:
        return 16 / 9;
    }
  }

  Future<void> _handleRefresh() async {
    _resetAndReload();
    widget.onRefresh.call();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. Native ExoPlayer ─────────────────────────────────
          Center(
            child: AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: ExoPlayerWidget(
                key: ValueKey('${widget.url}_${widget.k1}_${widget.clearkeys?.length ?? 0}'),
                url: widget.url,
                k1: widget.k1,
                k2: widget.k2,
                clearkeys: widget.clearkeys,
                controller: _exoController,
              ),
            ),
          ),

          // ── 2. Controls ─────────────────────────────────────────
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unified,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: _isFullscreen,
              aspectRatioLabel: _arType.label,
              onAspectRatioChange: _changeAspectRatio,
              onMuteToggle: _toggleMute,
              isMuted: _isMuted,
              currentServer: widget.currentServer,
              totalServers: widget.totalServers,
            ),
          ),

          // ── 3. Loading (only during initial load, not mid-stream buffering)
          if (_isLoading)
            VideoLoadingWidget(
              message: 'Cargando...',
              isBuffering: false,
              serverInfo: widget.totalServers > 1
                  ? '${widget.currentServer}/${widget.totalServers}'
                  : null,
            ),

          // ── 3b. Minimal buffering indicator (no blur overlay)
          if (_isBuffering && !_isLoading && _isPlaying)
            const Center(
              child: PivoteLoader(
                size: 36,
                strokeWidth: 3,
                color: Colors.white70,
              ),
            ),

          // ── 4. Error ────────────────────────────────────────────
          if (_hasError && !_isLoading) _buildError(),
        ],
      ),
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
                _errorMessage ?? 'Error de reproducción',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (widget.totalServers > 1) ...[
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
                    'Servidor ${widget.currentServer}/${widget.totalServers}',
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
                  _handleRefresh();
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
                      Text('Reintentar',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
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

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _loadingFailsafe?.cancel();
    _loadTimeout?.cancel();
    _exoController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// UnifiedVideoController adapter for ExoPlayerController
// ════════════════════════════════════════════════════════════════════════════
//
// Bridges ExoPlayerController to the UnifiedVideoController interface
// so CustomVideoControls can work identically with the native player.
//

class _ExoUnifiedAdapter implements UnifiedVideoController {
  final ExoPlayerController _exo;
  final _PivoShakaPlayerState _state;

  _ExoUnifiedAdapter(this._exo, this._state);

  @override
  bool get isPlaying => _state._isPlaying;
  @override
  bool get isBuffering => _state._isBuffering;
  @override
  bool get isInitialized => !_state._isLoading;
  @override
  bool get isMuted => _state._isMuted;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => Duration.zero;
  @override
  double get volume => _exo.volume;
  @override
  int get bufferHealth => 100;
  @override
  bool get hasError => _state._hasError;
  @override
  String? get errorMessage => _state._errorMessage;

  @override
  Future<void> play() => _exo.play();
  @override
  Future<void> pause() => _exo.pause();
  @override
  Future<void> setVolume(double v) => _exo.setVolume(v);
  @override
  Future<void> setMuted(bool muted) => _exo.setMuted(muted);
  @override
  Future<void> retry() async => _state._handleRefresh();
  @override
  Future<void> seek(Duration position) => _exo.seekTo(position);

  @override
  void addListener(void Function() l) {} // State managed by widget setState
  @override
  void removeListener(void Function() l) {}
  @override
  void dispose() {}
}
