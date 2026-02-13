import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';

class PivoProPlayer extends StatefulWidget {
  final String url;
  final String channelName;
  final VoidCallback? onRefresh;

  const PivoProPlayer({
    super.key,
    required this.url,
    required this.channelName,
    this.onRefresh,
  });

  @override
  State<PivoProPlayer> createState() => _PivoProPlayerState();
}

class _PivoProPlayerState extends State<PivoProPlayer> {
  late final WebViewController _webViewController;
  late final UnifiedVideoController _unifiedController;
  final VideoState _videoState = VideoState();

  // Estados locales
  bool isLoading = true;
  bool isFullscreen = false;
  bool audioActivado = false;
  String? errorMessage;
  int currentServer = 1;
  int totalServers = 1;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Parámetros de plataforma
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

    if (_webViewController.platform is AndroidWebViewController) {
      // CRÍTICO: Permitir autoplay
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
          onWebResourceError: (error) {
            // debugPrint('WebResourceError: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _handleMessageFromHtml,
      )
      ..loadRequest(Uri.parse(widget.url));

    // Inicializar UnifiedController para usar CustomVideoControls
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
          _getPlayerState();
          break;

        case 'loadingStart':
          if (mounted) {
            setState(() {
              isLoading = true;
              currentServer = data['serverIndex'] ?? 1;
              totalServers = data['totalServers'] ?? 1;
            });
          }
          break;

        case 'playingMuted':
          // Video reproduciendo MUTEADO. Actualizamos estado pero esperamos tap.
          _videoState.update(playing: true, buffering: false);
          if (mounted) {
            setState(() {
              isLoading = false;
              audioActivado = false;
              // isMuted (en videoState) debería ser true, pero UnifiedController no expone isMuted directo en interface?
              // CustomVideoControls usa isMuted como prop externa.
            });
          }
          break;

        case 'iframeLoaded':
          _videoState.update(playing: true, buffering: false);
          if (mounted) setState(() => isLoading = false);
          break;

        case 'audioEnabled':
          if (mounted) setState(() => audioActivado = true);
          break;

        case 'audioDisabled':
          // Audio desactivado
          break;

        case 'playbackStarted':
          _videoState.update(playing: true, buffering: false);
          break;

        case 'playbackPaused':
          _videoState.update(playing: false);
          break;

        case 'serverChange':
          if (mounted) {
            setState(() {
              isLoading = true;
              currentServer = data['serverIndex'] ?? 1;
              totalServers = data['totalServers'] ?? 1;
            });
          }
          break;

        case 'buffering':
          _videoState.update(buffering: true);
          break;

        case 'error':
          if (mounted) {
            setState(() {
              errorMessage = data['message'] ?? 'Error desconocido';
              isLoading = false;
            });
          }
          break;
      }

      // Actualizar UI si hubo cambios en VideoState que requieran rebuild de controles
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error msg HTML: $e');
    }
  }

  // ========================================
  // CONTROLES
  // ========================================

  Future<void> _unmute() async {
    await _webViewController.runJavaScript('window.unmute()');
    if (mounted) setState(() => audioActivado = true);
  }

  Future<void> _toggleMute() async {
    // Si aún no se activó el audio (está muteado por autoplay), intentar desmutear
    if (!audioActivado) {
      await _unmute();
    } else {
      await _webViewController.runJavaScript('window.toggleMute()');
      // El estado de mute real debería venir del callback de JS,
      // pero por latencia podemos asumir toggle en UI localmente o esperar evento
    }
  }

  Future<void> _toggleFullscreen() async {
    await _webViewController.runJavaScript('window.toggleFullscreen()');
    if (mounted) {
      setState(() => isFullscreen = !isFullscreen);
    }

    if (isFullscreen) {
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

  // ========================================
  // TAP HANDLER (CRÍTICO)
  // ========================================
  void _handleFirstTap() {
    if (_unifiedController.isPlaying && !audioActivado) {
      _unmute();
    }
  }

  Future<void> _getPlayerState() async {
    // Implementación opcional para sincronizar estado inicial
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. WebView
          GestureDetector(
            onTap: _handleFirstTap, // Detectar tap en área de video
            child: WebViewWidget(controller: _webViewController),
          ),

          // 2. Controles Nativos (CustomVideoControls)
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unifiedController,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: isFullscreen,
              aspectRatioLabel: 'Original', // Web maneja su ratio
              onAspectRatioChange: () {}, // No soportado en web por ahora
              // CustomVideoControls espera 'onMuteToggle' y 'isMuted'
              onMuteToggle: () {
                _handleFirstTap();
                _toggleMute();
              },
              isMuted:
                  !audioActivado, // Simplificación: si no activado, asumo muteado
              currentServer: currentServer,
              totalServers: totalServers,
            ),
          ),

          // 3. Loading
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 4. Error
          if (errorMessage != null && !isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(errorMessage!,
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  if (widget.onRefresh != null)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                          isLoading = true;
                        });
                        _webViewController.reload();
                        widget.onRefresh!();
                      },
                      child: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
}
