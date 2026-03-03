import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:google_fonts/google_fonts.dart';

// Android Platform Import for advanced configuration
/// PivoProPlayer v5.0 — WebView-based Player
/// ═══════════════════════════════════════════════════════════════
///
/// Handles DASH, Iframe, and external HTML-based streams via WebView.
/// Uses the same shared enums and unified loading/error UI as the
/// native M3U8 player for visual consistency.
///

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
  // ═══════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════
  late final WebViewController _webViewController;
  late final UnifiedVideoController _unifiedController;
  final VideoState _videoState = VideoState();

  // ═══════════════════════════════════════
  // States
  // ═══════════════════════════════════════
  bool _isFullscreen = false;
  AspectRatioType _aspectRatioType = AspectRatioType.ratio16_9;
  bool _isDisposed = false;

  // ═══════════════════════════════════════
  // Timers & Monitoring
  // ═══════════════════════════════════════
  Timer? _stateMonitor;
  Timer? _loadingFailsafe;
  Timer? _iframeLoadTimeout;
  StreamSubscription? _stateSubscription;
  int _iframeRetryCount = 0;
  bool _videoStartedPlaying = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    debugPrint('═══════════════════════════════════════');
    debugPrint('🌐 PivoProPlayer v5.0 Starting');
    debugPrint('📺 Channel: ${widget.channelName}');
    debugPrint('🔗 URL: ${widget.url}');
    debugPrint('═══════════════════════════════════════');

    _initializeWebView();
    _startStateMonitoring();
    _startLoadingFailsafe();
    _startIframeLoadTimeout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('⏸️ App background');
        _executeJS('window.pause()');
        break;
      case AppLifecycleState.resumed:
        debugPrint('▶️ App foreground');
        _executeJS('window.play()');
        break;
      default:
        break;
    }
  }

  // ═══════════════════════════════════════
  // WebView Initialization
  // ═══════════════════════════════════════

  void _initializeWebView() {
    _webViewController = WebViewController();

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      // Permitir reproducción automática de media sin gesto del usuario
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _handleMessageFromHtml,
      )
      ..loadRequest(Uri.parse(widget.url));

    _unifiedController =
        UnifiedVideoController.fromWeb(_webViewController, _videoState);

    _stateSubscription = _videoState.stateChanges.listen(_onStateChange);
  }

  // ═══════════════════════════════════════
  // Navigation Callbacks
  // ═══════════════════════════════════════

  void _onPageStarted(String url) {
    debugPrint('📄 Page Started: $url');
    if (!_isDisposed && mounted) {
      setState(() {
        _videoState.update(loading: true, error: false, errorMsg: null);
      });
    }
  }

  void _onPageFinished(String url) {
    debugPrint('✅ Page Finished: $url');
    // Lanzar intento de autoplay dentro del iframe
    _executeJS('window.play()');
    // Start a check: if video doesn't play within timeout, retry
    _startIframeLoadTimeout();
  }

  void _onWebResourceError(WebResourceError error) {
    final isCritical = error.errorType == WebResourceErrorType.hostLookup ||
        error.errorType == WebResourceErrorType.timeout ||
        error.errorType == WebResourceErrorType.connect;

    if (isCritical) {
      debugPrint('❌ Critical WebView Error: ${error.description}');
      _iframeRetryCount++;

      if (_iframeRetryCount > PlayerConfig.maxIframeRetries) {
        debugPrint('❌ Iframe max retries exceeded — signaling parent');
        if (!_isDisposed && mounted) {
          setState(() {
            _videoState.update(
              loading: false,
              error: true,
              errorMsg: 'Error de conexión: ${error.description}',
            );
          });
          // Signal parent to try next server
          widget.onAllServersFailed?.call();
        }
      } else {
        debugPrint(
            '🔄 Iframe retry $_iframeRetryCount/${PlayerConfig.maxIframeRetries}');
        if (!_isDisposed && mounted) {
          setState(() {
            _videoState.update(loading: true, error: false);
          });
          // Quick retry
          Future.delayed(
            const Duration(milliseconds: PlayerConfig.quickRetryDelayMs),
            () {
              if (!_isDisposed && mounted) {
                _webViewController.reload();
              }
            },
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════
  // Message Handling
  // ═══════════════════════════════════════

  void _handleMessageFromHtml(JavaScriptMessage message) {
    if (_isDisposed || !mounted) return;

    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      debugPrint('📨 HTML Event: $eventType');

      if (data.containsKey('state')) {
        _syncStateFromHtml(data['state'] as Map<String, dynamic>);
      }

      switch (eventType) {
        case 'playerReady':
          _onPlayerReady(data);
          break;
        case 'loadingStart':
          _onLoadingStart(data);
          break;
        case 'playingStarted':
          _onPlayingStarted(data);
          break;
        case 'stateUpdate':
          _onStateUpdate(data);
          break;
        case 'buffering':
          _onBuffering(data);
          break;
        case 'audioEnabled':
        case 'audioDisabled':
          _onAudioChange(data);
          break;
        case 'serverChange':
          _onServerChange(data);
          break;
        case 'streamStalled':
          _onStreamStalled(data);
          break;
        case 'error':
          _onError(data);
          break;
        default:
          debugPrint('⚠️ Unknown event: $eventType');
      }
    } catch (e, st) {
      debugPrint('❌ Error processing HTML message: $e\n$st');
    }
  }

  void _syncStateFromHtml(Map<String, dynamic> htmlState) {
    _videoState.update(
      playing: htmlState['isPlaying'] as bool?,
      buffering: htmlState['isBuffering'] as bool?,
      muted: htmlState['isMuted'] as bool?,
      loading: htmlState['isLoading'] as bool?,
      bufHealth: htmlState['bufferHealth'] as int?,
      stalled: htmlState['stallDetected'] as bool?,
      servIndex: htmlState['serverIndex'] as int?,
      totalServ: htmlState['totalServers'] as int?,
      chanId: htmlState['channelId'] as String?,
    );
  }

  void _onPlayerReady(Map<String, dynamic> data) {
    debugPrint('✅ Player Ready — Version: ${data['version']}');
  }

  void _onLoadingStart(Map<String, dynamic> data) {
    _loadingFailsafe?.cancel();
    _startLoadingFailsafe();

    if (mounted) {
      setState(() {
        _videoState.update(loading: true, error: false);
      });
    }
  }

  void _onPlayingStarted(Map<String, dynamic> data) {
    _loadingFailsafe?.cancel();
    _iframeLoadTimeout?.cancel();
    _videoStartedPlaying = true;
    _iframeRetryCount = 0; // Reset retries on success

    final isMuted = data['muted'] as bool? ?? false;

    if (mounted) {
      setState(() {
        _videoState.update(
          loading: false,
          playing: true,
          buffering: false,
          muted: isMuted,
          error: false,
        );
      });
    }

    debugPrint('✅ Playing — Muted: $isMuted');
  }

  void _onStateUpdate(Map<String, dynamic> data) {
    if (data.containsKey('state')) {
      _syncStateFromHtml(data['state'] as Map<String, dynamic>);
    }
  }

  void _onBuffering(Map<String, dynamic> data) {
    final state = data['state'] as String?;

    if (mounted) {
      setState(() {
        if (state == 'waiting') {
          _videoState.update(buffering: true);
        } else if (state == 'ready') {
          _videoState.update(buffering: false);
        }
      });
    }
  }

  void _onAudioChange(Map<String, dynamic> data) {
    final isMuted = data['type'] == 'audioDisabled';

    if (mounted) {
      setState(() {
        _videoState.update(muted: isMuted);
      });
    }
  }

  void _onServerChange(Map<String, dynamic> data) {
    final serverIndex = data['serverIndex'] as int?;
    final totalServers = data['totalServers'] as int?;
    final attempt = data['attempt'] as int?;

    debugPrint('🔄 Server $serverIndex/$totalServers (Attempt $attempt)');

    if (mounted) {
      setState(() {
        _videoState.update(
          loading: true,
          servIndex: (serverIndex ?? 1) - 1,
          totalServ: totalServers,
        );
      });
    }
  }

  void _onStreamStalled(Map<String, dynamic> data) {
    debugPrint('⚠️ Stream Stalled');

    if (mounted) {
      setState(() {
        _videoState.update(stalled: true);
      });
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (!_isDisposed && mounted && _videoState.stallDetected) {
        debugPrint('🔄 Auto-retry after stall timeout');
        _executeJS('window.nextServer()');
      }
    });
  }

  void _onError(Map<String, dynamic> data) {
    final code = data['code'] as String?;
    final message = data['message'] as String?;

    debugPrint('❌ Error: $code — $message');
    _iframeRetryCount++;

    if (_iframeRetryCount > PlayerConfig.maxIframeRetries) {
      debugPrint(
          '❌ Iframe max retries exceeded after error — signaling parent');
      if (mounted) {
        setState(() {
          _videoState.update(
            loading: false,
            error: true,
            errorMsg: message ?? 'Error desconocido',
          );
        });
      }
      // Signal parent to try next m3u8 server
      widget.onAllServersFailed?.call();
    } else {
      debugPrint(
          '🔄 Iframe retry $_iframeRetryCount/${PlayerConfig.maxIframeRetries} after error');
      if (mounted) {
        setState(() {
          _videoState.update(loading: true, error: false);
        });
      }
      Future.delayed(
        const Duration(milliseconds: PlayerConfig.quickRetryDelayMs),
        () {
          if (!_isDisposed && mounted) {
            _webViewController.reload();
          }
        },
      );
    }
  }

  // ═══════════════════════════════════════
  // State Monitoring
  // ═══════════════════════════════════════

  void _startStateMonitoring() {
    _stateMonitor?.cancel();
    _stateMonitor = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      _executeJS('window.FlutterBridge.sendStateUpdate()');
    });
  }

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(PlayerConfig.loadingFailsafeTimeout, () {
      if (!_isDisposed && mounted && _videoState.isLoading) {
        debugPrint('⏱️ Loading failsafe triggered');
        setState(() {
          _videoState.update(loading: false);
        });
      }
    });
  }

  /// Iframe-specific timeout: if video doesn't start playing within timeout, take action
  void _startIframeLoadTimeout() {
    _iframeLoadTimeout?.cancel();
    _iframeLoadTimeout = Timer(PlayerConfig.iframeLoadTimeout, () {
      if (_isDisposed || !mounted) return;
      if (_videoStartedPlaying) return; // Already playing, no issue

      debugPrint('⏱️ Iframe load timeout — video never started');
      _iframeRetryCount++;

      if (_iframeRetryCount > PlayerConfig.maxIframeRetries) {
        debugPrint(
            '❌ Iframe max retries exceeded — signaling parent for next server');
        setState(() {
          _videoState.update(
            loading: false,
            error: true,
            errorMsg: 'El servidor no respondió a tiempo',
          );
        });
        widget.onAllServersFailed?.call();
      } else {
        debugPrint(
            '🔄 Iframe timeout retry $_iframeRetryCount/${PlayerConfig.maxIframeRetries}');
        setState(() {
          _videoState.update(loading: true, error: false);
        });
        _webViewController.reload();
        _startIframeLoadTimeout(); // Restart timeout for retry
      }
    });
  }

  void _onStateChange(VideoStateChange change) {
    if (_isDisposed || !mounted) return;

    if (change.hasChanged('isPlaying')) {
      debugPrint('▶️ isPlaying: ${change.getValue('isPlaying')}');
    }
    if (change.hasChanged('isBuffering')) {
      debugPrint('⏳ isBuffering: ${change.getValue('isBuffering')}');
    }
    if (change.hasChanged('hasError')) {
      debugPrint('❌ hasError: ${change.getValue('hasError')}');
    }

    if (change.hasChanged('isLoading') ||
        change.hasChanged('hasError') ||
        change.hasChanged('isPlaying')) {
      setState(() {});
    }
  }

  // ═══════════════════════════════════════
  // Controls
  // ═══════════════════════════════════════

  Future<void> _toggleMute() async {
    await _executeJS('window.toggleMute()');
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

  void _changeAspectRatio() {
    setState(() {
      _aspectRatioType = _aspectRatioType.next;
    });
  }

  double _getAspectRatio() {
    switch (_aspectRatioType) {
      case AspectRatioType.auto:
        return 16 / 9;
      case AspectRatioType.ratio16_9:
        return 16 / 9;
      case AspectRatioType.ratio4_3:
        return 4 / 3;
      case AspectRatioType.stretch:
        final size = MediaQuery.of(context).size;
        return size.width / size.height;
    }
  }

  Future<void> _executeJS(String script) async {
    if (_isDisposed) return;

    try {
      await _webViewController.runJavaScript('''
        (function() {
          try {
            $script;
          } catch(e) {
            console.error('JS Error:', e);
          }
        })();
      ''');
    } catch (e) {
      debugPrint('❌ JS execution error: $e');
    }
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 Refresh requested');

    setState(() {
      _videoState.reset();
      _iframeRetryCount = 0;
      _videoStartedPlaying = false;
    });

    _loadingFailsafe?.cancel();
    _iframeLoadTimeout?.cancel();
    _startLoadingFailsafe();
    _startIframeLoadTimeout();

    await _webViewController.reload();
    widget.onRefresh?.call();
  }

  // ═══════════════════════════════════════
  // Build
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. WebView
          Center(
            child: AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: WebViewWidget(controller: _webViewController),
            ),
          ),

          // 2. Native Controls
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unifiedController,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: _isFullscreen,
              aspectRatioLabel: _aspectRatioType.label,
              onAspectRatioChange: _changeAspectRatio,
              onMuteToggle: _toggleMute,
              isMuted: _videoState.isMuted,
              currentServer: _videoState.serverIndex + 1,
              totalServers: _videoState.totalServers,
              onServerSelect: (idx) {
                _executeJS('window.switchToServer($idx)');
              },
            ),
          ),

          // 3. Loading/Buffering Indicator (Simplified)
          if (_videoState.isLoading || _videoState.isBuffering)
            VideoLoadingWidget(
              message: _videoState.isBuffering
                  ? (_videoState.stallDetected
                      ? 'Reconectando...'
                      : 'Cargando...')
                  : 'Conectando...',
              isBuffering: _videoState.isBuffering,
              serverInfo: _videoState.totalServers > 1
                  ? '${_videoState.serverIndex + 1}/${_videoState.totalServers}'
                  : null,
            ),

          // 5. Error Widget — Unified style with M3U8 player
          if (_videoState.hasError && !_videoState.isLoading)
            _buildErrorWidget(),
        ],
      ),
    );
  }

  /// Unified error widget matching the M3U8 player style
  Widget _buildErrorWidget() {
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
                  border: Border.all(
                    color: Colors.red.withAlpha(60),
                    width: 1.5,
                  ),
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
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _videoState.errorMessage ?? 'Error desconocido',
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                    width: 0.5,
                  ),
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
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _handleRefresh();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
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
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reintentar',
                        style: GoogleFonts.dmSans(
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

  // ═══════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stateMonitor?.cancel();
    _loadingFailsafe?.cancel();
    _iframeLoadTimeout?.cancel();
    _stateSubscription?.cancel();
    _unifiedController.dispose();
    _videoState.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _webViewController.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }
}
