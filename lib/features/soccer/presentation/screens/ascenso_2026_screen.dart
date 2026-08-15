import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
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

  late final WebViewController _controller;
  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  bool _hasError = false;
  int _progress = 0;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _preload();

    // Mantiene los resultados recientes sin recargar de forma agresiva.
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted && _hasLoadedOnce && !_isLoading) {
        _controller.reload();
      }
    });
  }

  WebViewController _createController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
              _progress = 0;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) async {
            await _applyAppPresentation();
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasLoadedOnce = true;
              _hasError = false;
              _progress = 100;
              _currentUrl = url;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            final host = uri.host.toLowerCase();
            final isAllowed =
                host == _allowedHost || host.endsWith('.$_allowedHost');

            // Todo queda dentro de la experiencia de Pivote.
            if (!isAllowed) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _preload() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    await _controller.loadRequest(Uri.parse(_pageUrl));
  }

  Future<void> _applyAppPresentation() async {
    const script = r'''
      (() => {
        try {
          const head = document.head || document.getElementsByTagName('head')[0];
          if (!head) return;

          let viewport = document.querySelector('meta[name="viewport"]');
          if (!viewport) {
            viewport = document.createElement('meta');
            viewport.setAttribute('name', 'viewport');
            head.appendChild(viewport);
          }
          viewport.setAttribute(
            'content',
            'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'
          );

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
              overflow-x: hidden !important;
              -webkit-text-size-adjust: 100% !important;
              overscroll-behavior-x: none !important;
            }
            body {
              margin: 0 !important;
              padding-bottom: 24px !important;
            }
            img, video, iframe, table {
              max-width: 100% !important;
            }
            * {
              -webkit-tap-highlight-color: transparent !important;
            }
          `;

          // Bloquea cualquier intento de salir de Copa Fácil.
          document.addEventListener('click', (event) => {
            const target = event.target && event.target.closest
              ? event.target.closest('a')
              : null;
            if (!target) return;

            const href = target.href || '';
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

          // Evita comportamientos típicos de navegador móvil que degradan la UI.
          document.addEventListener(
            'gesturestart',
            (event) => event.preventDefault(),
            {passive: false}
          );
          document.addEventListener(
            'dblclick',
            (event) => event.preventDefault(),
            {passive: false}
          );
        } catch (_) {}
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // La página sigue siendo usable aunque falle una mejora visual.
    }
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
    });

    await _controller.reload();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PivoteAppBar(
          title: 'Ascenso 2026',
          actions: [
            IconButton(
              tooltip: 'Actualizar resultados',
              onPressed: _refresh,
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _TopStatusBar(
              theme: theme,
              progress: _progress,
              isLoading: _isLoading,
              currentUrl: _currentUrl,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 6, 10, 10 + bottom),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.04,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: WebViewWidget(controller: _controller),
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: _WebViewLoadingOverlay(
                            theme: theme,
                            progress: _progress,
                            isFirstLoad: !_hasLoadedOnce,
                          ),
                        ),
                      if (_hasError)
                        Positioned.fill(
                          child: _WebViewErrorOverlay(
                            theme: theme,
                            onRetry: _refresh,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  final ThemeData theme;
  final int progress;
  final bool isLoading;
  final String? currentUrl;

  const _TopStatusBar({
    required this.theme,
    required this.progress,
    required this.isLoading,
    required this.currentUrl,
  });

  @override
  Widget build(BuildContext context) {
    final loaded = !isLoading && currentUrl != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 2),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: .28),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isLoading
                ? 'Cargando datos en tiempo real · $progress%'
                : loaded
                    ? 'Copa Fácil · datos actualizados'
                    : 'Copa Fácil',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: theme.hintColor,
            ),
          ),
          const Spacer(),
          if (isLoading)
            SizedBox(
              width: 34,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress == 0 ? null : progress / 100,
                  minHeight: 3,
                  backgroundColor: theme.dividerColor.withValues(alpha: .08),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WebViewLoadingOverlay extends StatelessWidget {
  final ThemeData theme;
  final int progress;
  final bool isFirstLoad;

  const _WebViewLoadingOverlay({
    required this.theme,
    required this.progress,
    required this.isFirstLoad,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isFirstLoad ? 1 : .82,
        duration: const Duration(milliseconds: 180),
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Preparando Ascenso 2026',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Cargando resultados, tablas y estadísticas…',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress == 0 ? null : progress / 100,
                        minHeight: 4,
                        backgroundColor:
                            theme.dividerColor.withValues(alpha: .08),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebViewErrorOverlay extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onRetry;

  const _WebViewErrorOverlay({required this.theme, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar Copa Fácil',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revisá tu conexión e intentá nuevamente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                color: theme.hintColor,
                height: 1.4,
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
    );
  }
}
