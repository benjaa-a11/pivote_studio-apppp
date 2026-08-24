import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Ascenso2026Screen extends StatefulWidget {
  const Ascenso2026Screen({super.key});

  @override
  State<Ascenso2026Screen> createState() => _Ascenso2026ScreenState();
}

class _Ascenso2026ScreenState extends State<Ascenso2026Screen> {
  static const String _pageUrl =
      'https://copafacil.com/-ndrde5sdllc0nexjb9u@9szj';
  static const String _allowedHost = 'copafacil.com';
  static const Duration _autoRefreshInterval = Duration(minutes: 5);

  late final WebViewController _controller;
  Timer? _refreshTimer;
  Timer? _progressTimer;

  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  bool _hasError = false;
  bool _refreshInProgress = false;
  int _progress = 0;
  int _lastRenderedProgress = -1;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _loadInitialPage();

    // La página ya contiene datos dinámicos. Evitamos recargas frecuentes que
    // disparan de nuevo HTML, JS, imágenes y scripts completos.
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (!mounted || !_hasLoadedOnce || _isLoading || _refreshInProgress) {
        return;
      }
      _silentRefresh();
    });
  }

  WebViewController _createController() {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _onProgress,
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
          onNavigationRequest: _onNavigationRequest,
        ),
      );

    return controller;
  }

  void _onProgress(int progress) {
    _progress = progress.clamp(0, 100);

    // Android WebView puede emitir muchos callbacks de progreso. No hagamos
    // rebuild del árbol Flutter por cada uno: actualizamos como máximo ~10 FPS.
    if (_progressTimer != null || !mounted) return;

    _progressTimer = Timer(const Duration(milliseconds: 100), () {
      _progressTimer = null;
      if (!mounted || _progress == _lastRenderedProgress) return;
      _lastRenderedProgress = _progress;
      setState(() {});
    });
  }

  void _onPageStarted(String url) {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
      _lastRenderedProgress = 0;
      _currentUrl = url;
    });
  }

  Future<void> _onPageFinished(String url) async {
    await _applyAppPresentation();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _refreshInProgress = false;
      _hasLoadedOnce = true;
      _hasError = false;
      _progress = 100;
      _lastRenderedProgress = 100;
      _currentUrl = url;
    });
  }

  void _onWebResourceError(WebResourceError error) {
    if (!mounted) return;
    if (error.isForMainFrame ?? true) {
      setState(() {
        _isLoading = false;
        _refreshInProgress = false;
        _hasError = true;
      });
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final host = uri.host.toLowerCase();
    final isAllowed =
        host == _allowedHost || host.endsWith('.$_allowedHost');

    // Nunca dejamos que un enlace externo saque al usuario de Pivote.
    return isAllowed
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  Future<void> _loadInitialPage() async {
    // Da tiempo a que el primer frame nativo de Pivote aparezca antes de
    // iniciar el trabajo pesado del WebView.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    await _controller.loadRequest(Uri.parse(_pageUrl));
  }

  Future<void> _silentRefresh() async {
    _refreshInProgress = true;
    try {
      await _controller.reload();
    } catch (_) {
      _refreshInProgress = false;
    }
  }

  Future<void> _refresh() async {
    if (_isLoading || _refreshInProgress) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _refreshInProgress = true;
      _progress = 0;
      _lastRenderedProgress = 0;
    });

    try {
      await _controller.reload();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _refreshInProgress = false;
        _hasError = true;
      });
    }
  }

  Future<void> _applyAppPresentation() async {
    // Idempotente: no vuelve a registrar listeners cada vez que Copa Fácil
    // navega entre vistas internas.
    const script = r'''
      (() => {
        try {
          if (window.__PIVOTE_ASCENSO_OPTIMIZED__) return;
          window.__PIVOTE_ASCENSO_OPTIMIZED__ = true;

          const head = document.head || document.getElementsByTagName('head')[0];
          if (!head) return;

          let viewport = document.querySelector('meta[name="viewport"]');
          if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            head.appendChild(viewport);
          }
          viewport.content =
            'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';

          let style = document.getElementById('pivote-webview-style');
          if (!style) {
            style = document.createElement('style');
            style.id = 'pivote-webview-style';
            head.appendChild(style);
          }

          style.textContent = `
            html, body {
              width: 100% !important;
              max-width: 100% !important;
              min-width: 0 !important;
              overflow-x: hidden !important;
              -webkit-text-size-adjust: 100% !important;
              overscroll-behavior-x: none !important;
              margin: 0 !important;
              padding: 0 !important;
            }
            body {
              padding-bottom: 12px !important;
            }
            img, video, iframe, canvas, table {
              max-width: 100% !important;
            }
            * {
              -webkit-tap-highlight-color: transparent !important;
            }
          `;

          document.addEventListener('click', (event) => {
            const anchor = event.target && event.target.closest
              ? event.target.closest('a')
              : null;
            if (!anchor) return;

            const href = anchor.href || '';
            try {
              const url = new URL(href, location.href);
              const sameHost =
                url.hostname === 'copafacil.com' ||
                url.hostname.endsWith('.copafacil.com');
              if (!sameHost) event.preventDefault();
            } catch (_) {
              event.preventDefault();
            }
          }, true);

          document.addEventListener('gesturestart',
            (event) => event.preventDefault(),
            {passive: false});

          document.addEventListener('dblclick',
            (event) => event.preventDefault(),
            {passive: false});
        } catch (_) {}
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // El contenido sigue funcionando aunque la capa de presentación falle.
    }
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PivoteAppBar(
          title: 'Ascenso 2026',
          actions: [
            IconButton(
              tooltip: 'Actualizar resultados',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        // Sin tarjetas, sombras, padding ni overlays persistentes: el WebView
        // ocupa toda el área disponible debajo del header nativo.
        body: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading && !_hasLoadedOnce)
              _InitialLoadingOverlay(progress: _progress),
            if (_hasError)
              _WebViewErrorOverlay(onRetry: _refresh),
          ],
        ),
      ),
    );
  }
}

class _InitialLoadingOverlay extends StatelessWidget {
  final int progress;

  const _InitialLoadingOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: SizedBox(
            width: 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: progress <= 0 || progress >= 100
                        ? null
                        : progress / 100,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Cargando Ascenso 2026',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  progress > 0 && progress < 100
                      ? '$progress%'
                      : 'Preparando datos…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebViewErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const _WebViewErrorOverlay({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'No se pudo cargar Copa Fácil',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Revisá tu conexión e intentá nuevamente.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
