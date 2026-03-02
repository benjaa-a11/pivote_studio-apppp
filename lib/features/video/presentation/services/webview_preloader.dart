import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';

/// Un singleton que instancia el motor de Chromium/WebKit en segundo plano
/// al abrir la app. Evita el "enganche" (stutter/lag) que ocurre al
/// crear un WebView por primera vez en Android/iOS.
class WebViewPreloader {
  WebViewPreloader._internal();
  static final WebViewPreloader _instance = WebViewPreloader._internal();
  static WebViewPreloader get instance => _instance;

  WebViewController? _controller;
  bool _isPreloading = false;
  bool _isClaimed = false;

  /// Inicializa el WebViewController en segundo plano.
  /// Debe ser llamado asincrónicamente durante el AppDelegate / main().
  Future<void> init() async {
    if (_controller != null || _isPreloading) return;
    _isPreloading = true;

    debugPrint('🌐 WebViewPreloader: Inicializando motor en background...');

    try {
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        final androidController =
            controller.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      controller.setUserAgent(PlayerConfig.userAgent);

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.black);

      // Carga una URL base (ligera) para despertar el motor y compilar JIT de V8.
      // Usaremos un about:blank o la raiz del reproductor para calentar caché.
      await controller.loadRequest(Uri.parse('https://pivo-pro.vercel.app/'));

      _controller = controller;
      debugPrint('✅ WebViewPreloader: Motor WebKit/Chromium calentado.');
    } catch (e) {
      debugPrint('❌ WebViewPreloader: Error pre-cargando motor: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Retorna el controlador calentado si no está en uso, de lo contrario crea uno nuevo.
  WebViewController claimController() {
    if (_controller != null && !_isClaimed) {
      _isClaimed = true;
      debugPrint('🌐 WebViewPreloader: Entregando instancia calentada.');
      return _controller!;
    }

    debugPrint(
        '🌐 WebViewPreloader: Instancia en uso o no lista. Creando nueva.');
    // Si se necesitan múltiples a la vez o no se pre-cargó, instanciamos aquí.
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final newController = WebViewController.fromPlatformCreationParams(params);
    if (newController.platform is AndroidWebViewController) {
      final androidController =
          newController.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
    newController.setUserAgent(PlayerConfig.userAgent);
    newController.setJavaScriptMode(JavaScriptMode.unrestricted);
    newController.setBackgroundColor(Colors.black);

    return newController;
  }

  /// Suelta el controlador para poder ser reutilizado, limpiando cualquier estado.
  Future<void> releaseController(WebViewController controller) async {
    if (controller == _controller) {
      _isClaimed = false;
      // Navegar a about:blank silencia cualquier audio y destruye ramas DOM pesadas
      // manteniendo el motor WebKit/V8 pre-calentado en RAM.
      await _controller?.loadRequest(Uri.parse('about:blank'));
      debugPrint('♻️ WebViewPreloader: Instancia soltada y limpiada.');
    }
  }
}
