import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
// PivoProPlayer v6.0 — WebView-based Player (DASH / Iframe / HTML)
// ════════════════════════════════════════════════════════════════════════════
//
// Critical fix: setMediaPlaybackRequiresUserGesture(false) on Android
// so the WebView page can autoplay without a user gesture, solving the
// "loads then immediately pauses" bug.
//

class PivoProPlayer extends StatefulWidget {
  final String url;
  final String channelName;
  final VoidCallback? onRefresh;
  final VoidCallback? onAllServersFailed;
  final int currentServer;
  final int totalServers;

  const PivoProPlayer({
    super.key,
    required this.url,
    required this.channelName,
    this.onRefresh,
    this.onAllServersFailed,
    this.currentServer = 1,
    this.totalServers = 1,
  });

  @override
  State<PivoProPlayer> createState() => _PivoProPlayerState();
}

class _PivoProPlayerState extends State<PivoProPlayer>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late final WebViewController _wvc;
  late final UnifiedVideoController _unified;
  final VideoState _videoState = VideoState();

  bool _isFullscreen = false;
  AspectRatioType _arType = AspectRatioType.ratio16_9;
  bool _disposed = false;
  bool _videoStarted = false;
  int _iframeRetries = 0;

  Timer? _stateMonitor;
  Timer? _loadingFailsafe;
  Timer? _iframeTimeout;
  StreamSubscription? _stateSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🌐 PivoProPlayer v6.0 — ${widget.channelName}');
    debugPrint('   URL: ${widget.url}');
    _initWebView();
    _startStateMonitor();
    _startLoadingFailsafe();
    _startIframeTimeout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _js('window.pause()');
    } else if (state == AppLifecycleState.resumed) {
      _js('window.play()');
    }
  }

  // ── WebView Init ─────────────────────────────────────────────────────────

  void _initWebView() {
    _wvc = WebViewController();

    // ╔══════════════════════════════════════════════════════════════╗
    // ║ CRITICAL FIX: Allow autoplay without user gesture           ║
    // ║ This is the root cause of "loads then pauses" on Android    ║
    // ╚══════════════════════════════════════════════════════════════╝
    final platform = _wvc.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    _wvc
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
        onWebResourceError: _onWebResourceError,
      ))
      ..addJavaScriptChannel('FlutterChannel',
          onMessageReceived: _onMessageFromHtml)
      ..loadRequest(Uri.parse(widget.url));

    _unified = UnifiedVideoController.fromWeb(_wvc, _videoState);
    _stateSub = _videoState.stateChanges.listen(_onStateChange);
  }

  // ── Page events ──────────────────────────────────────────────────────────

  void _onPageStarted(String url) {
    debugPrint('📄 Page started: $url');
    if (!_disposed && mounted) {
      setState(() => _videoState.update(loading: true, error: false));
    }
  }

  void _onPageFinished(String url) {
    debugPrint('✅ Page finished: $url');
    // Trigger play after page is fully loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_disposed && mounted) {
        _js('window.play()');
      }
    });
    _startIframeTimeout();
  }

  void _onWebResourceError(WebResourceError err) {
    final isCritical = err.errorType == WebResourceErrorType.hostLookup ||
        err.errorType == WebResourceErrorType.timeout ||
        err.errorType == WebResourceErrorType.connect;
    if (!isCritical) {
      return;
    }

    debugPrint('❌ WebView error: ${err.description}');
    _iframeRetries++;

    if (_iframeRetries > PlayerConfig.maxIframeRetries) {
      if (!_disposed && mounted) {
        setState(() => _videoState.update(
            loading: false,
            error: true,
            errorMsg: 'Error de conexión: ${err.description}'));
        widget.onAllServersFailed?.call();
      }
    } else {
      debugPrint(
          '🔄 WebView retry $_iframeRetries/${PlayerConfig.maxIframeRetries}');
      Future.delayed(
        const Duration(milliseconds: PlayerConfig.quickRetryDelayMs),
        () {
          if (!_disposed && mounted) _wvc.reload();
        },
      );
    }
  }

  // ── HTML → Flutter messages ──────────────────────────────────────────────

  void _onMessageFromHtml(JavaScriptMessage msg) {
    if (_disposed || !mounted) return;
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (data['state'] != null) {
        _syncState(data['state'] as Map<String, dynamic>);
      }

      switch (type) {
        case 'playerReady':
          debugPrint('✅ HTML player ready');
          break;
        case 'playingStarted':
          _onPlayingStarted(data);
          break;
        case 'loadingStart':
          _onLoadingStart();
          break;
        case 'stateUpdate':
          if (data['state'] != null) {
            _syncState(data['state'] as Map<String, dynamic>);
          }
          break;
        case 'buffering':
          setState(() => _videoState.update(
                buffering: data['state'] == 'waiting',
              ));
          break;
        case 'audioEnabled':
          setState(() => _videoState.update(muted: false));
          break;
        case 'audioDisabled':
          setState(() => _videoState.update(muted: true));
          break;
        case 'streamStalled':
          _onStreamStalled();
          break;
        case 'serverChange':
          _onServerChange(data);
          break;
        case 'error':
          _onHtmlError(data);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ HTML msg parse: $e');
    }
  }

  void _syncState(Map<String, dynamic> s) {
    _videoState.update(
      playing: s['isPlaying'] as bool?,
      buffering: s['isBuffering'] as bool?,
      muted: s['isMuted'] as bool?,
      loading: s['isLoading'] as bool?,
      bufHealth: s['bufferHealth'] as int?,
      stalled: s['stallDetected'] as bool?,
      servIndex: s['serverIndex'] as int?,
      totalServ: s['totalServers'] as int?,
    );
  }

  void _onLoadingStart() {
    _loadingFailsafe?.cancel();
    _startLoadingFailsafe();
    if (mounted) {
      setState(() => _videoState.update(loading: true, error: false));
    }
  }

  void _onPlayingStarted(Map<String, dynamic> data) {
    _loadingFailsafe?.cancel();
    _iframeTimeout?.cancel();
    _videoStarted = true;
    _iframeRetries = 0;

    final muted = data['muted'] as bool? ?? false;
    if (mounted) {
      setState(() => _videoState.update(
            loading: false,
            playing: true,
            buffering: false,
            muted: muted,
            error: false,
          ));
    }
    debugPrint('▶️ Playing — muted: $muted');
  }

  void _onStreamStalled() {
    debugPrint('⚠️ Stream stalled');
    if (mounted) setState(() => _videoState.update(stalled: true));
    Future.delayed(const Duration(seconds: 4), () {
      if (!_disposed && mounted && _videoState.stallDetected) {
        _js('window.nextServer()');
      }
    });
  }

  void _onServerChange(Map<String, dynamic> data) {
    final idx = data['serverIndex'] as int? ?? 1;
    final total = data['totalServers'] as int?;
    if (mounted) {
      setState(() => _videoState.update(
            loading: true,
            servIndex: idx - 1,
            totalServ: total,
          ));
    }
  }

  void _onHtmlError(Map<String, dynamic> data) {
    debugPrint('❌ HTML error: ${data['code']} — ${data['message']}');
    _iframeRetries++;
    if (_iframeRetries > PlayerConfig.maxIframeRetries) {
      if (mounted) {
        setState(() => _videoState.update(
              loading: false,
              error: true,
              errorMsg: data['message'] as String? ?? 'Error desconocido',
            ));
      }
      widget.onAllServersFailed?.call();
    } else {
      if (mounted) {
        setState(() => _videoState.update(loading: true, error: false));
      }
      Future.delayed(
        const Duration(milliseconds: PlayerConfig.quickRetryDelayMs),
        () {
          if (!_disposed && mounted) _wvc.reload();
        },
      );
    }
  }

  // ── Monitoring ────────────────────────────────────────────────────────────

  void _startStateMonitor() {
    _stateMonitor?.cancel();
    _stateMonitor = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || !mounted) return;
      _js('if(window.FlutterBridge)window.FlutterBridge.sendStateUpdate()');
    });
  }

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(PlayerConfig.loadingFailsafeTimeout, () {
      if (!_disposed && mounted && _videoState.isLoading) {
        debugPrint('⏱ Loading failsafe');
        setState(() => _videoState.update(loading: false));
      }
    });
  }

  void _startIframeTimeout() {
    _iframeTimeout?.cancel();
    _iframeTimeout = Timer(PlayerConfig.iframeLoadTimeout, () {
      if (_disposed || !mounted || _videoStarted) return;
      debugPrint('⏱ Iframe timeout');
      _iframeRetries++;
      if (_iframeRetries > PlayerConfig.maxIframeRetries) {
        setState(() => _videoState.update(
              loading: false,
              error: true,
              errorMsg: 'El servidor no respondió a tiempo',
            ));
        widget.onAllServersFailed?.call();
      } else {
        setState(() => _videoState.update(loading: true, error: false));
        _wvc.reload();
        _startIframeTimeout();
      }
    });
  }

  void _onStateChange(VideoStateChange change) {
    if (_disposed || !mounted) return;
    if (change.hasChanged('isLoading') ||
        change.hasChanged('hasError') ||
        change.hasChanged('isPlaying')) {
      setState(() {});
    }
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  Future<void> _toggleMute() => _js('window.toggleMute()');
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
    setState(() {
      _videoState.reset();
      _iframeRetries = 0;
      _videoStarted = false;
    });
    _loadingFailsafe?.cancel();
    _iframeTimeout?.cancel();
    _startLoadingFailsafe();
    _startIframeTimeout();
    await _wvc.reload();
    widget.onRefresh?.call();
  }

  Future<void> _js(String script) async {
    if (_disposed) return;
    try {
      await _wvc.runJavaScript('(function(){try{$script}catch(e){}})()');
    } catch (_) {}
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: WebViewWidget(controller: _wvc),
            ),
          ),
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unified,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: _isFullscreen,
              aspectRatioLabel: _arType.label,
              onAspectRatioChange: _changeAspectRatio,
              onMuteToggle: _toggleMute,
              isMuted: _videoState.isMuted,
              currentServer: _videoState.serverIndex + 1,
              totalServers: _videoState.totalServers,
              onServerSelect: (idx) => _js('window.switchToServer($idx)'),
            ),
          ),
          // Loading overlay only during initial load (not mid-stream buffering)
          if (_videoState.isLoading && !_videoState.isBuffering)
            VideoLoadingWidget(
              message: 'Conectando...',
              isBuffering: false,
              serverInfo: _videoState.totalServers > 1
                  ? '${_videoState.serverIndex + 1}/${_videoState.totalServers}'
                  : null,
            ),

          // Minimal buffering indicator (no full-screen blur overlay)
          if (_videoState.isBuffering && !_videoState.isLoading)
            const Center(
              child: PivoteLoader(
                size: 36,
                strokeWidth: 3,
                color: Colors.white70,
              ),
            ),

          // Stall detection: show reconnecting overlay
          if (_videoState.stallDetected && !_videoState.isLoading)
            VideoLoadingWidget(
              message: 'Reconectando...',
              isBuffering: true,
              serverInfo: _videoState.totalServers > 1
                  ? '${_videoState.serverIndex + 1}/${_videoState.totalServers}'
                  : null,
            ),
          if (_videoState.hasError && !_videoState.isLoading) _buildError(),
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
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _videoState.errorMessage ?? 'Error desconocido',
                style: GoogleFonts.dmSans(
                    color: Colors.white54, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (_videoState.totalServers > 1) ...[
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
                    'Servidor ${_videoState.serverIndex + 1}/${_videoState.totalServers}',
                    style: GoogleFonts.dmSans(
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
                          style: GoogleFonts.dmSans(
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

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stateMonitor?.cancel();
    _loadingFailsafe?.cancel();
    _iframeTimeout?.cancel();
    _stateSub?.cancel();
    _unified.dispose();
    _videoState.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _wvc.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }
}
