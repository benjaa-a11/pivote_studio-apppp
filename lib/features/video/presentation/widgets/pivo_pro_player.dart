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

class _PivoProPlayerState extends State<PivoProPlayer> {
  late final WebViewController _webViewController;
  late final UnifiedVideoController _unifiedController;
  final VideoState _videoState = VideoState();

  // Estados
  bool _isLoading = true;
  bool _isFullscreen = false;
  bool _isMuted = false;
  // bool _audioActivado = false; // Removed unused field
  String? _errorMessage;
  AspectRatioType _aspectRatioType = AspectRatioType.ratio16_9;

  // Timers
  Timer? _loadingTimer;
  Timer? _bufferingDebounce;
  bool _isReallyBuffering = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    // Safety timeout - si no carga en 10s, quitar loading
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

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

    // CONFIGURACIÓN ANDROID ULTRA-OPTIMIZADA
    if (_webViewController.platform is AndroidWebViewController) {
      final androidController =
          _webViewController.platform as AndroidWebViewController;

      // CRÍTICO: Permitir autoplay
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    // Optimizaciones de rendimiento (User Agent en el controlador general)
    _webViewController.setUserAgent(
      'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
    );

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (_) {
            // NO quitar loading aquí - esperar evento del HTML
            debugPrint('📄 WebView Page Finished');
          },
          onWebResourceError: (error) {
            // Solo errores críticos
            if (error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.timeout) {
              debugPrint('❌ Critical WebView Error: ${error.description}');
              if (mounted && _isLoading) {
                setState(() {
                  _errorMessage = 'Error de conexión';
                  _isLoading = false;
                });
              }
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _handleMessageFromHtml,
      )
      ..loadRequest(Uri.parse(widget.url));

    _unifiedController =
        UnifiedVideoController.fromWeb(_webViewController, _videoState);
  }

  void _handleMessageFromHtml(JavaScriptMessage message) {
    if (!mounted) return;

    try {
      final data = jsonDecode(message.message);
      final eventType = data['type'] as String?;

      switch (eventType) {
        case 'playerReady':
          debugPrint('✅ Player listo');
          break;

        case 'loadingStart':
          // Nuevo servidor cargando
          if (mounted) {
            setState(() => _isLoading = true);
          }
          break;

        case 'playingStarted':
        case 'iframeLoaded':
          // Video empezó a reproducir - QUITAR LOADING
          _loadingTimer?.cancel();
          _videoState.update(playing: true, buffering: false);

          final isMuted = data['muted'] as bool? ?? false;

          if (mounted) {
            setState(() {
              _isLoading = false;
              _isMuted = isMuted;
              _isReallyBuffering = false;
            });
          }
          debugPrint('✅ Reproduciendo - Loading OFF');
          break;

        case 'canPlay':
          // Puede reproducir pero aún no comenzó
          // NO quitar loading hasta que realmente reproduzca
          break;

        case 'buffering':
          final state = data['state'] as String?;

          // Debounce buffering events para evitar flickers
          _bufferingDebounce?.cancel();

          if (state == 'waiting') {
            // Solo mostrar buffering después de 500ms
            _bufferingDebounce = Timer(const Duration(milliseconds: 500), () {
              if (mounted && !_isLoading) {
                setState(() => _isReallyBuffering = true);
                _videoState.update(buffering: true);
              }
            });
          } else if (state == 'ready') {
            // Inmediatamente quitar buffering
            if (mounted) {
              setState(() => _isReallyBuffering = false);
              _videoState.update(buffering: false);
            }
          }
          break;

        case 'audioEnabled':
          if (mounted) {
            setState(() {
              _isMuted = false;
            });
          }
          break;

        case 'audioDisabled':
          if (mounted) {
            setState(() => _isMuted = true);
          }
          break;

        case 'playbackStarted':
          _videoState.update(playing: true);
          break;

        case 'playbackPaused':
          _videoState.update(playing: false);
          break;

        case 'serverChange':
          // Cambiando servidor
          if (mounted) {
            setState(() => _isLoading = true);
          }
          break;

        case 'error':
          if (mounted) {
            setState(() {
              _errorMessage = data['message'] ?? 'Error desconocido';
              _isLoading = false;
            });
          }
          break;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error procesando mensaje HTML: $e');
    }
  }

  // ========================================
  // CONTROLES
  // ========================================

  Future<void> _toggleMute() async {
    await _webViewController.runJavaScript('window.toggleMute()');
    // El estado se actualiza con el callback
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);

    if (_isFullscreen) {
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
        return 16 / 9; // Default para web
      case AspectRatioType.ratio16_9:
        return 16 / 9;
      case AspectRatioType.ratio4_3:
        return 4 / 3;
      case AspectRatioType.stretch:
        final size = MediaQuery.of(context).size;
        return size.width / size.height;
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // 2. Controles Nativos (siempre visibles)
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unifiedController,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: _isFullscreen,
              aspectRatioLabel: _getAspectRatioLabel(),
              onAspectRatioChange: _changeAspectRatio,
              onMuteToggle: _toggleMute,
              isMuted: _isMuted,
              currentServer: widget.currentServer,
              totalServers: widget.totalServers,
            ),
          ),

          // 3. Loading Indicator (UNIFICADO - igual al de VideoPlayer)
          if (_isLoading) _buildLoadingWidget(),

          // 4. Buffering Indicator (solo si NO está cargando)
          if (!_isLoading && _isReallyBuffering) _buildBufferingWidget(),

          // 5. Error Message
          if (_errorMessage != null && !_isLoading) _buildErrorWidget(),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const VideoLoadingWidget(
      message: 'Conectando...',
    );
  }

  Widget _buildBufferingWidget() {
    return const VideoLoadingWidget(
      message: 'Cargando...',
      isBuffering: true,
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
                _errorMessage!,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (widget.onRefresh != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    _webViewController.reload();
                    widget.onRefresh!();
                  },
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

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _bufferingDebounce?.cancel();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }
}
