import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PivoProPlayer extends StatefulWidget {
  final String channelId;
  final String playerHtmlUrl;

  const PivoProPlayer({
    super.key,
    required this.channelId,
    required this.playerHtmlUrl,
  });

  @override
  State<PivoProPlayer> createState() => _PivoProPlayerState();
}

class _PivoProPlayerState extends State<PivoProPlayer> {
  late final WebViewController _controller;

  // Estados del player
  bool isLoading = true;
  bool isMuted = true; // Inicia muteado
  bool isPlaying = false;
  bool isFullscreen = false;
  bool audioActivado = false; // Track si ya se activó el audio
  String? errorMessage;

  // Info del canal
  int currentServer = 1;
  int totalServers = 0;
  String? currentChannel;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Parámetros de plataforma específicos
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      // Android
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    // Configuración Android específica
    if (_controller.platform is AndroidWebViewController) {
      // Habilitar debugging solo si es necesario, dejarlo en false para prod por seguridad
      // AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Ignorar errores comunes de carga de recursos no críticos
            // Opcional: Loggear
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _handleMessageFromHtml,
      )
      ..loadRequest(
        Uri.parse('${widget.playerHtmlUrl}?id=${widget.channelId}'),
      );
  }

  // ========================================
  // MANEJO DE MENSAJES HTML → FLUTTER
  // ========================================
  void _handleMessageFromHtml(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final data = jsonDecode(message.message);
      final eventType = data['type'] as String;

      // debugPrint('📨 Evento HTML: $eventType');

      switch (eventType) {
        case 'playerReady':
          _getPlayerState();
          break;

        case 'loadingStart':
          setState(() {
            isLoading = true;
            currentChannel = data['channel'];
            currentServer = data['serverIndex'] ?? 1;
            totalServers = data['totalServers'] ?? 0;
          });
          break;

        case 'playingMuted':
          // ¡CRÍTICO! El video está reproduciendo MUTEADO
          setState(() {
            isLoading = false;
            isPlaying = true;
            isMuted = true;
            audioActivado = false;
            currentServer = data['serverIndex'] ?? 1;
          });
          // debugPrint('🔇 Video reproduciendo MUTEADO - esperando tap de usuario');
          break;

        case 'iframeLoaded':
          setState(() {
            isLoading = false;
            currentServer = data['serverIndex'] ?? 1;
          });
          break;

        case 'audioEnabled':
          setState(() {
            isMuted = false;
            audioActivado = true;
          });
          break;

        case 'audioDisabled':
          setState(() {
            isMuted = true;
          });
          break;

        case 'playbackStarted':
          setState(() {
            isPlaying = true;
          });
          break;

        case 'playbackPaused':
          setState(() {
            isPlaying = false;
          });
          break;

        case 'serverChange':
          setState(() {
            currentServer = data['serverIndex'] ?? 1;
            totalServers = data['totalServers'] ?? 0;
            isLoading = true;
          });
          break;

        case 'buffering':
          // Opcional: manejar buffering visual extra
          break;

        case 'error':
          setState(() {
            errorMessage = data['message'] ?? 'Error desconocido';
            isLoading = false;
          });
          break;

        case 'backPressed':
          if (mounted) Navigator.of(context).pop();
          break;
      }
    } catch (e) {
      debugPrint('❌ Error procesando mensaje: $e');
    }
  }

  // ========================================
  // LLAMADAS FLUTTER → HTML
  // ========================================

  Future<void> unmute() async {
    await _controller.runJavaScript('window.unmute()');
    if (mounted) {
      setState(() {
        isMuted = false;
        audioActivado = true;
      });
    }
  }

  Future<void> mute() async {
    await _controller.runJavaScript('window.mute()');
    if (mounted) {
      setState(() {
        isMuted = true;
      });
    }
  }

  Future<void> toggleMute() async {
    if (isMuted) {
      await unmute();
    } else {
      await mute();
    }
  }

  Future<void> play() async {
    await _controller.runJavaScript('window.play()');
    if (mounted) setState(() => isPlaying = true);
  }

  Future<void> pause() async {
    await _controller.runJavaScript('window.pause()');
    if (mounted) setState(() => isPlaying = false);
  }

  Future<void> togglePlayPause() async {
    await _controller.runJavaScript('window.togglePlayPause()');
    if (mounted) setState(() => isPlaying = !isPlaying);
  }

  Future<void> toggleFullscreen() async {
    await _controller.runJavaScript('window.toggleFullscreen()');
    if (mounted) setState(() => isFullscreen = !isFullscreen);

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

  Future<void> nextServer() async {
    await _controller.runJavaScript('window.nextServer()');
  }

  Future<void> reloadCurrentServer() async {
    await _controller.runJavaScript('window.reloadCurrentServer()');
  }

  Future<void> _getPlayerState() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
          'JSON.stringify(window.getPlayerState())');

      if (result is String) {
        // En Android, runJavaScriptReturningResult devuelve un JSON string quoteado
        // Ej: "\"{\\\"field\\\":...}\""
        // Necesitamos parsearlo correctamente
        String jsonString = result;
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          jsonString = jsonDecode(jsonString);
        }

        final state = jsonDecode(jsonString);
        if (mounted) {
          setState(() {
            isPlaying = state['isPlaying'] ?? false;
            isMuted = state['isMuted'] ?? true;
            audioActivado = state['audioActivado'] ?? false;
            currentChannel = state['currentChannel'];
            currentServer = state['serverIndex'] ?? 1;
            totalServers = state['totalServers'] ?? 0;
            isFullscreen = state['isFullscreen'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error parseando estado: $e');
    }
  }

  // ========================================
  // MANEJO DEL PRIMER TAP (CRÍTICO)
  // ========================================
  void _handleFirstTap() {
    // Si el video está reproduciendo pero aún muteado,
    // activar el audio con el primer tap
    if (isPlaying && !audioActivado) {
      unmute();
    }
  }

  // ========================================
  // UI
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView con detector de gestos
          GestureDetector(
            onTap: _handleFirstTap, // CRÍTICO
            child: WebViewWidget(controller: _controller),
          ),

          // Indicador de carga
          if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando servidor $currentServer/$totalServers',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Mensaje de error
          if (errorMessage != null && !isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: reloadCurrentServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                      ),
                      child: const Text('Reintentar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // CONTROLES NATIVOS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [ 
            Colors.black.withValues(alpha: 0.9),
            Colors.transparent.withValues(alpha: 0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Play/Pause
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                _handleFirstTap();
                togglePlayPause();
              },
            ),

            // Mute/Unmute
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: audioActivado ? Colors.white : Colors.grey,
                size: 32,
              ),
              onPressed: () {
                _handleFirstTap();
                toggleMute();
              },
            ),

            // Fullscreen
            IconButton(
              icon: Icon(
                isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
                size: 32,
              ),
              onPressed: toggleFullscreen,
            ),

            // Cambiar servidor
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
              onPressed: nextServer,
            ),

            // Info servidor
            Text(
              '$currentServer / $totalServers',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
