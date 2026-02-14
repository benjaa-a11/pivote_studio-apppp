import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

enum AspectRatioType {
  auto,
  ratio16_9,
  ratio4_3,
  stretch,
}

class PivoProPlayer extends StatefulWidget {
  final String url;
  final String channelName;
  final VoidCallback? onRefresh;
  final int currentServer;
  final int totalServers;

  const PivoProPlayer({
    super.key,
    required this.url,
    required this.channelName,
    this.onRefresh,
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
  StreamSubscription? _stateSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    debugPrint('═══════════════════════════════════════');
    debugPrint('🌐 PivoProPlayer v4.0 Iniciando');
    debugPrint('📺 Canal: ${widget.channelName}');
    debugPrint('🔗 URL: ${widget.url}');
    debugPrint('═══════════════════════════════════════');

    _initializeWebView();
    _startStateMonitoring();
    _startLoadingFailsafe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('⏸️ App en background');
        _executeJS('window.pause()');
        break;
      case AppLifecycleState.resumed:
        debugPrint('▶️ App en foreground');
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
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params);

    // Android Optimizations
    if (_webViewController.platform is AndroidWebViewController) {
      final androidController =
          _webViewController.platform as AndroidWebViewController;

      androidController.setMediaPlaybackRequiresUserGesture(false);

      // Enable hardware acceleration
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(
            allow: false,
            retain: false,
          );
        },
      );
    }

    _webViewController.setUserAgent(
      'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
    );

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
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

    // Listen to state changes
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
    // Don't remove loading here - wait for player events
  }

  void _onWebResourceError(WebResourceError error) {
    // Only handle critical errors
    final isCritical = error.errorType == WebResourceErrorType.hostLookup ||
        error.errorType == WebResourceErrorType.timeout ||
        error.errorType == WebResourceErrorType.connect;

    if (isCritical) {
      debugPrint('❌ Critical WebView Error: ${error.description}');
      if (!_isDisposed && mounted) {
        setState(() {
          _videoState.update(
            loading: false,
            error: true,
            errorMsg: 'Error de conexión: ${error.description}',
          );
        });
      }
    }
  }

  // ═══════════════════════════════════════
  // Message Handling (Enhanced)
  // ═══════════════════════════════════════

  void _handleMessageFromHtml(JavaScriptMessage message) {
    if (_isDisposed || !mounted) return;

    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      debugPrint('📨 HTML Event: $eventType');

      // Update state from HTML player state
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
      debugPrint('❌ Error procesando mensaje HTML: $e\n$st');
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
    debugPrint('✅ Player Ready');
    debugPrint('Version: ${data['version']}');
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

    debugPrint('✅ Reproduciendo - Muted: $isMuted');
  }

  void _onStateUpdate(Map<String, dynamic> data) {
    // Full state sync from HTML
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

    debugPrint('🔄 Servidor $serverIndex/$totalServers (Intento $attempt)');

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

    // Auto retry after stall
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed && mounted && _videoState.stallDetected) {
        debugPrint('🔄 Auto-retry después de stall');
        _executeJS('window.nextServer()');
      }
    });
  }

  void _onError(Map<String, dynamic> data) {
    final code = data['code'] as String?;
    final message = data['message'] as String?;

    debugPrint('❌ Error: $code - $message');

    if (mounted) {
      setState(() {
        _videoState.update(
          loading: false,
          error: true,
          errorMsg: message ?? 'Error desconocido',
        );
      });
    }
  }

  // ═══════════════════════════════════════
  // State Monitoring
  // ═══════════════════════════════════════

  void _startStateMonitoring() {
    _stateMonitor?.cancel();
    _stateMonitor = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      // Request state update from HTML
      _executeJS('window.FlutterBridge.sendStateUpdate()');
    });
  }

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(const Duration(seconds: 12), () {
      if (!_isDisposed && mounted && _videoState.isLoading) {
        debugPrint('⏱️ Loading failsafe triggered');
        setState(() {
          _videoState.update(loading: false);
        });
      }
    });
  }

  void _onStateChange(VideoStateChange change) {
    if (_isDisposed || !mounted) return;

    // Log significant changes
    if (change.hasChanged('isPlaying')) {
      debugPrint('▶️ isPlaying: ${change.getValue('isPlaying')}');
    }
    if (change.hasChanged('isBuffering')) {
      debugPrint('⏳ isBuffering: ${change.getValue('isBuffering')}');
    }
    if (change.hasChanged('hasError')) {
      debugPrint('❌ hasError: ${change.getValue('hasError')}');
    }

    // Force rebuild on important changes
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
      switch (_aspectRatioType) {
        case AspectRatioType.auto:
          _aspectRatioType = AspectRatioType.ratio16_9;
          break;
        case AspectRatioType.ratio16_9:
          _aspectRatioType = AspectRatioType.ratio4_3;
          break;
        case AspectRatioType.ratio4_3:
          _aspectRatioType = AspectRatioType.stretch;
          break;
        case AspectRatioType.stretch:
          _aspectRatioType = AspectRatioType.auto;
          break;
      }
    });
  }

  String _getAspectRatioLabel() {
    switch (_aspectRatioType) {
      case AspectRatioType.auto:
        return 'Original';
      case AspectRatioType.ratio16_9:
        return '16:9';
      case AspectRatioType.ratio4_3:
        return '4:3';
      case AspectRatioType.stretch:
        return 'Estirar';
    }
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
      debugPrint('❌ Error ejecutando JS: $e');
    }
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 Refresh solicitado');

    setState(() {
      _videoState.reset();
    });

    _loadingFailsafe?.cancel();
    _startLoadingFailsafe();

    await _webViewController.reload();
    widget.onRefresh?.call();
  }

  // ═══════════════════════════════════════
  // Build
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. WebView con AspectRatio
          Center(
            child: AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: WebViewWidget(controller: _webViewController),
            ),
          ),

          // 2. Controles Nativos
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unifiedController,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: _isFullscreen,
              aspectRatioLabel: _getAspectRatioLabel(),
              onAspectRatioChange: _changeAspectRatio,
              onMuteToggle: _toggleMute,
              isMuted: _videoState.isMuted,
              currentServer: _videoState.serverIndex + 1,
              totalServers: _videoState.totalServers,
            ),
          ),

          // 3. Loading Indicator
          if (_videoState.isLoading) _buildLoadingWidget(),

          // 4. Buffering Indicator
          if (!_videoState.isLoading && _videoState.isBuffering)
            _buildBufferingWidget(),

          // 5. Error Message
          if (_videoState.hasError && !_videoState.isLoading)
            _buildErrorWidget(),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return VideoLoadingWidget(
      message: 'Conectando...',
      serverInfo: '${_videoState.serverIndex + 1}/${_videoState.totalServers}',
    );
  }

  Widget _buildBufferingWidget() {
    return VideoLoadingWidget(
      message: _videoState.stallDetected ? 'Reconectando...' : 'Cargando...',
      isBuffering: true,
      serverInfo: '${_videoState.serverIndex + 1}/${_videoState.totalServers}',
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _videoState.errorMessage ?? 'Error desconocido',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
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
    debugPrint('🗑️ Disposing PivoProPlayer');
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _stateMonitor?.cancel();
    _loadingFailsafe?.cancel();
    _stateSubscription?.cancel();
    _unifiedController.dispose();
    _videoState.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }
}
