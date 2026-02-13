import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Professional HTML-based video player widget using WebView + Shaka Player
///
/// Supports:
/// - MPD (DASH) streams with DRM ClearKey
/// - M3U8 (HLS) streams
/// - Iframe embeds
///
/// Features:
/// - Low memory footprint (~50MB vs ~150MB with media_kit)
/// - Universal compatibility
/// - Flutter-native controls overlay
class HtmlPlayerWidget extends StatefulWidget {
  final String url;
  final String? k1; // DRM Key ID (hex)
  final String? k2; // DRM Key (hex)
  final VoidCallback? onReady;
  final Function(String)? onError;
  final Function(bool)? onPlayingChanged;
  final VoidCallback? onFailover;

  const HtmlPlayerWidget({
    super.key,
    required this.url,
    this.k1,
    this.k2,
    this.onReady,
    this.onError,
    this.onPlayingChanged,
    this.onFailover,
  });

  @override
  State<HtmlPlayerWidget> createState() => _HtmlPlayerWidgetState();
}

class _HtmlPlayerWidgetState extends State<HtmlPlayerWidget> {
  late WebViewController _controller;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  bool _isMuted = false;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.runJavaScript('destroy()');
    super.dispose();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePlayerEvent(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint('📄 HTML Player page loaded');
            _loadStream();
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView error: ${error.description}');
            setState(() {
              _error = 'Error al cargar el reproductor';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadFlutterAsset('assets/html/player.html');
  }

  void _loadStream() {
    final type = _detectStreamType(widget.url);
    final config = {
      'url': widget.url,
      'k1': widget.k1,
      'k2': widget.k2,
      'type': type,
    };

    debugPrint('🎬 Loading stream:');
    debugPrint('   Type: $type');
    debugPrint(
        '   URL: ${widget.url.substring(0, widget.url.length > 60 ? 60 : widget.url.length)}...');
    if (widget.k1 != null && widget.k2 != null) {
      debugPrint('   DRM: ClearKey enabled');
    }

    _controller.runJavaScript(
      'loadStream(${jsonEncode(config)})',
    );
  }

  String _detectStreamType(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.mpd')) return 'mpd';
    if (urlLower.contains('.m3u8') || urlLower.contains('m3u')) return 'm3u8';
    return 'iframe';
  }

  void _handlePlayerEvent(String message) {
    try {
      final data = jsonDecode(message);
      final event = data['event'];

      // debugPrint('📡 Player event: $event');

      switch (event) {
        case 'loaded':
          setState(() {
            _isLoading = false;
            _error = null;
          });
          widget.onReady?.call();
          break;

        case 'playing':
          setState(() {
            _isPlaying = true;
            _isLoading = false;
          });
          widget.onPlayingChanged?.call(true);
          _startControlsTimer();
          break;

        case 'paused':
          setState(() => _isPlaying = false);
          widget.onPlayingChanged?.call(false);
          break;

        case 'buffering':
          setState(() => _isLoading = true);
          break;

        case 'error':
          final errorMessage = data['message'] ?? 'Error desconocido';
          final shouldFailover = data['fileserver'] == true;

          debugPrint(
              '❌ Player error: $errorMessage (Failover: $shouldFailover)');

          if (mounted) {
            setState(() {
              _error = errorMessage;
              _isLoading = false;
            });
          }

          if (shouldFailover) {
            widget.onFailover?.call();
          } else {
            widget.onError?.call(errorMessage);
          }
          break;

        case 'progress':
          // Handle progress updates if needed
          break;

        case 'ended':
          setState(() => _isPlaying = false);
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing player event: $e');
    }
  }

  // Player controls
  void play() => _controller.runJavaScript('play()');
  void pause() => _controller.runJavaScript('pause()');
  void setVolume(double volume) =>
      _controller.runJavaScript('setVolume($volume)');

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // WebView Player
          WebViewWidget(controller: _controller),

          // Controls Overlay
          if (_showControls && !_isLoading && _error == null)
            _buildControlsOverlay(),

          // Loading indicator
          if (_isLoading && _error == null)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),

          // Error display
          if (_error != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        children: [
          // Center Play/Pause
          Center(
            child: IconButton(
              iconSize: 64,
              color: Colors.white,
              icon: Icon(_isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded),
              onPressed: () {
                if (_isPlaying) {
                  pause();
                } else {
                  play();
                }
                _startControlsTimer();
              },
            ),
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        pause();
                      } else {
                        play();
                      }
                      _startControlsTimer();
                    },
                  ),
                  const SizedBox(width: 8),
                  // LIVE Indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _toggleMute();
                      _startControlsTimer();
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Toggle fullscreen (handled by parent usually, but we can trigger callback if needed)
                      // For now, just hide system UI
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersiveSticky,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
