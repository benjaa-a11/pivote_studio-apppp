import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/pivo_pro_player.dart';

/// Professional video player widget with support for:
/// - MPD (DASH) streams with DRM ClearKey via WebView + Shaka Player
/// - M3U8 (HLS) streams via WebView + Shaka Player
/// - Iframe embeds via WebView
/// - Automatic server failover
/// - Intelligent error recovery
/// - Stream health monitoring
///
/// @version 3.0 (WebView + HTML Player)
enum AspectRatioType {
  auto,
  ratio16_9,
  ratio4_3,
  stretch,
}

class VideoPlayerWidget extends StatefulWidget {
  final Channel channel;

  const VideoPlayerWidget({
    super.key,
    required this.channel,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ═══════════════════════════════════════
  // Controllers
  VideoPlayerController? _videoPlayerController;
  WebViewController? _webViewController;
  UnifiedVideoController? _unifiedController;
  final VideoState _webVideoState = VideoState();

  // ═══════════════════════════════════════
  // State
  // ═══════════════════════════════════════
  StreamSource? _currentStream;

  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;
  AspectRatioType _aspectRatioType = AspectRatioType.ratio16_9;
  int _currentServerIndex = 0;

  bool _isMuted = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  int _retryCount = 0;
  int _serverAttempt = 0;
  int _stuckCounter = 0;
  bool _useHtmlPlayer = false; // Use HTML player for all streams

  static const int _maxRetries = 2;
  static const int _watchdogThreshold = 3; // 15 seconds (3 * 5s checks)

  // ═══════════════════════════════════════
  // Timers
  // ═══════════════════════════════════════
  Timer? _serverTimeoutTimer;
  Timer? _errorRecoveryTimer;
  Timer? _stateCheckTimer;
  Timer? _orientationCheckTimer;

  // ═══════════════════════════════════════
  // Animation
  // ═══════════════════════════════════════
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    debugPrint('═══════════════════════════════════════');
    debugPrint('🎬 VideoPlayerWidget v3.1 (Unified Hybrid)');
    debugPrint('📺 Canal: ${widget.channel.name}');
    debugPrint('🔢 Servidores: ${widget.channel.streamUrl.length}');
    debugPrint('═══════════════════════════════════════');

    _initializePlayer();
    _startWatchdog();
    _startOrientationMonitor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('⏸️ App en background - pausando');
      _unifiedController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ App en foreground - resumiendo');
      _unifiedController?.play();
    }
  }

  // ═══════════════════════════════════════
  // Orientation Monitor - Fix fullscreen bugs
  // ═══════════════════════════════════════

  void _startOrientationMonitor() {
    _orientationCheckTimer?.cancel();
    _orientationCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      _checkOrientation();
    });
  }

  void _checkOrientation() {
    if (!mounted) return;

    final currentOrientation = MediaQuery.of(context).orientation;
    final isLandscape = currentOrientation == Orientation.landscape;

    // Si la orientación cambió a portrait pero el estado dice fullscreen
    if (!isLandscape && _isFullScreen) {
      debugPrint('🔄 Detectado cambio a portrait - saliendo de fullscreen');
      _safeSetState(() {
        _isFullScreen = false;
      });
    }
    // Si la orientación cambió a landscape pero el estado dice no fullscreen
    else if (isLandscape && !_isFullScreen) {
      debugPrint('🔄 Detectado cambio a landscape - entrando a fullscreen');
      _safeSetState(() {
        _isFullScreen = true;
      });
    }
  }

  // ═══════════════════════════════════════
  // Watchdog - Stream Health Monitoring
  // ═══════════════════════════════════════

  void _startWatchdog() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      _checkStreamHealth();
    });
  }

  void _checkStreamHealth() {
    // Check Unified Controller buffering state
    if (_unifiedController != null) {
      if (_unifiedController!.isBuffering) {
        _stuckCounter++;
        debugPrint('⚠️ Watchdog: Buffering (${_stuckCounter * 5}s)');

        if (_stuckCounter >= _watchdogThreshold) {
          debugPrint('🔄 Watchdog: Stream stalled, switching server');
          _stuckCounter = 0;
          _handleServerFailure();
        }
      } else if (_unifiedController!.isPlaying) {
        _stuckCounter = 0;
      }
    }
  }

  // ═══════════════════════════════════════
  // Player Initialization
  // ═══════════════════════════════════════

  Future<void> _initializePlayer() async {
    if (_isInitializing || _isDisposed) return;

    _safeSetState(() {
      _isInitializing = true;
      _isLoading = true;
      _error = null;
      _retryCount = 0;
      _serverAttempt = 0;
      _stuckCounter = 0;
    });

    try {
      await _tryCurrentServer();
    } catch (e, st) {
      debugPrint('❌ Error en initializePlayer: $e\n$st');
      _safeSetState(() {
        _isLoading = false;
        _error = 'Error al cargar el canal';
        _isInitializing = false;
      });
    }
  }

  Future<void> _tryCurrentServer() async {
    if (_isDisposed) return;

    _serverTimeoutTimer?.cancel();

    if (_currentServerIndex >= widget.channel.streamUrl.length) {
      throw Exception('No hay más servidores disponibles');
    }

    _currentStream = widget.channel.streamUrl[_currentServerIndex];
    String url = _currentStream!.url.trim();

    debugPrint('───────────────────────────────────────');
    debugPrint(
        '🔄 Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}');
    debugPrint('🔗 URL: ${url.substring(0, min(60, url.length))}...');
    debugPrint('───────────────────────────────────────');

    // Resolve URLs with tokens or redirects
    try {
      final resolvedUrl = await _resolveStreamUrl(url);
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        url = resolvedUrl;
        debugPrint('✅ URL resuelta: ${url.substring(0, min(80, url.length))}');
      }
    } catch (e) {
      debugPrint('⚠️ Error resolviendo URL: $e');
    }

    if (url.isEmpty) {
      throw Exception('URL vacía');
    }

    // Server timeout (10 seconds)
    _serverTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted &&
          !_isDisposed &&
          _isLoading &&
          _currentServerIndex < widget.channel.streamUrl.length - 1) {
        debugPrint(
            '⏱️ Timeout servidor ${_currentServerIndex + 1}, siguiente...');
        _currentServerIndex++;
        _tryCurrentServer();
      }
    });

    // Hybrid Player Strategy:
    // - HLS (.m3u8): Use Native VideoPlayer (Better stability for unstable connections)
    // - DASH (.mpd) / Iframe / Web: Use WebView with Unified Controls

    final isHls = url.toLowerCase().contains('.m3u8') ||
        url.toLowerCase().contains('m3u');

    if (isHls) {
      debugPrint('📱 Mode: Native HLS Player');
      setState(() {
        _useHtmlPlayer = false;
      });
      await _initializeVideoPlayer(url);
    } else {
      debugPrint('🌐 Mode: Web Player (External/DASH)');
      setState(() {
        _useHtmlPlayer = true;
      });
      await _initializeWebPlayer(url);
    }
  }

  /// Enhanced URL resolver - handles tokens, redirects, and dynamic URLs
  Future<String?> _resolveStreamUrl(String url) async {
    debugPrint('🔍 Resolviendo URL...');

    // If it already ends with .m3u8, no need to resolve
    if (url.toLowerCase().endsWith('.m3u8')) {
      debugPrint('✓ URL ya es .m3u8');
      return url;
    }

    HttpClient? httpClient;
    try {
      final uri = Uri.parse(url);
      httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..badCertificateCallback = (cert, host, port) => true;

      debugPrint('📡 Siguiendo redirects para: ${uri.host}');

      final request = await httpClient.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
      );
      request.headers.set('Accept', '*/*');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close();

      // Follow redirects
      if (response.redirects.isNotEmpty) {
        final finalUrl = response.redirects.last.location.toString();
        debugPrint(
            '🔀 Redirect encontrado: ${finalUrl.substring(0, min(80, finalUrl.length))}');

        // If the final URL is an m3u8, return it
        if (finalUrl.toLowerCase().endsWith('.m3u8')) {
          return finalUrl;
        }

        // Otherwise, check if we can extract m3u8 from response
        final body = await response.transform(const Utf8Decoder()).join();
        if (body.contains('.m3u8')) {
          // Try to extract m3u8 URL from response body
          final m3u8Match =
              RegExp(r'https?://[^\s<>"]+\.m3u8').firstMatch(body);
          if (m3u8Match != null) {
            final extractedUrl = m3u8Match.group(0)!;
            debugPrint('📎 URL .m3u8 extraída del body');
            return extractedUrl;
          }
        }

        return finalUrl;
      }

      // Check response headers for Location or m3u8
      final location = response.headers.value('location');
      if (location != null) {
        debugPrint('📍 Location header encontrado');
        return location;
      }

      // If status is 200, read body to check for m3u8
      if (response.statusCode == 200) {
        final contentType = response.headers.contentType;

        // If content type suggests it's an m3u8
        if (contentType?.mimeType == 'application/vnd.apple.mpegurl' ||
            contentType?.mimeType == 'application/x-mpegURL') {
          debugPrint('✓ Content-Type indica m3u8');
          return url;
        }

        // Try reading body for m3u8 URL
        final body = await response.transform(const Utf8Decoder()).join();
        if (body.contains('.m3u8')) {
          final m3u8Match =
              RegExp(r'https?://[^\s<>"]+\.m3u8').firstMatch(body);
          if (m3u8Match != null) {
            final extractedUrl = m3u8Match.group(0)!;
            debugPrint('📎 URL .m3u8 extraída del body');
            return extractedUrl;
          }
        }
      }

      debugPrint('⚠️ No se encontró .m3u8, usando URL original');
      return url;
    } catch (e) {
      debugPrint('❌ Error resolviendo URL: $e');
      return url;
    } finally {
      httpClient?.close(force: true);
    }
  }

  // ═══════════════════════════════════════
  // VideoPlayer (HLS)
  // ═══════════════════════════════════════

  Future<void> _initializeVideoPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 Inicializando VideoPlayer (HLS)');

      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
      };

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: headers,
      );

      _videoPlayerController!.addListener(_videoListener);

      await _videoPlayerController!.initialize();

      if (_isDisposed || !mounted) return;

      _unifiedController =
          UnifiedVideoController.fromVideoPlayer(_videoPlayerController!);

      _serverTimeoutTimer?.cancel();

      await _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _videoPlayerController!.play();

      _fadeController.forward();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
        _stuckCounter = 0;
      });

      debugPrint('✅ VideoPlayer listo');
    } catch (e, st) {
      debugPrint('❌ Error VideoPlayer: $e\n$st');
      await _handleServerFailure();
    }
  }

  void _videoListener() {
    if (_isDisposed || !mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;

    if (value.isInitialized && value.isPlaying && !value.hasError) {
      _stuckCounter = 0;
    }

    if (value.hasError && !_isLoading && !_isInitializing) {
      final errorDesc = value.errorDescription ?? 'Error desconocido';
      debugPrint('⚠️ Error VideoPlayer: $errorDesc');

      if (_errorRecoveryTimer?.isActive ?? false) return;

      _errorRecoveryTimer = Timer(const Duration(milliseconds: 800), () async {
        if (_isDisposed || !mounted) return;
        _retryCount++;
        debugPrint('🔄 Recuperación $_retryCount/$_maxRetries');

        if (_retryCount <= _maxRetries) {
          await _initializeVideoPlayer(_currentStream!.url);
        } else {
          await _handleServerFailure();
        }
      });
    }

    _safeSetState(() {});
  }

  // ═══════════════════════════════════════
  // Web Player (External)
  // ═══════════════════════════════════════

  Future<void> _initializeWebPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();
      debugPrint('🎬 Inicializando WebView Player');

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              debugPrint('📄 Web Page Loaded');
              _injectControlScript();
              _safeSetState(() {
                _isLoading = false;
                _isInitializing = false;
              });
              _fadeController.forward();
            },
            onWebResourceError: (error) {
              debugPrint('❌ WebView Resource Error: ${error.description}');
              // Only failover on main frame errors if needed, but resource errors are common
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            _handleWebMessage(message.message);
          },
        )
        ..loadRequest(Uri.parse(url));

      _unifiedController =
          UnifiedVideoController.fromWeb(_webViewController!, _webVideoState);

      // Auto-play attempt
      _serverTimeoutTimer?.cancel();
    } catch (e) {
      debugPrint('❌ Error WebPlayer: $e');
      await _handleServerFailure();
    }
  }

  void _injectControlScript() {
    const script = '''
      (function() {
        console.log("💉 Injecting Video Control Script");
        
        function findVideo() {
          return document.querySelector('video') || document.querySelector('iframe')?.contentDocument?.querySelector('video');
        }

        function notify(video) {
          if (!video) return;
          try {
            window.FlutterChannel.postMessage(JSON.stringify({
              playing: !video.paused,
              position: video.currentTime,
              duration: video.duration,
              buffering: video.readyState < 3
            }));
          } catch(e) {}
        }
        
        var checkInterval = setInterval(function() {
          var video = findVideo();
          if (video) {
             clearInterval(checkInterval);
             console.log("✅ Video element found");
             
             // Initial state
             notify(video);
             
             // Listeners
             video.addEventListener('play', function() { notify(video); });
             video.addEventListener('pause', function() { notify(video); });
             video.addEventListener('timeupdate', function() { notify(video); });
             video.addEventListener('waiting', function() { notify(video); });
             video.addEventListener('playing', function() { notify(video); });
             
             // Force play
             video.play().catch(e => console.log("Autoplay blocked: " + e));
          }
        }, 500);
      })();
    ''';
    _webViewController?.runJavaScript(script);
  }

  void _handleWebMessage(String message) {
    try {
      final data = jsonDecode(message);
      _webVideoState.update(
        playing: data['playing'],
        buffering: data['buffering'],
        pos: (data['position'] as num?)?.toDouble(),
        dur: (data['duration'] as num?)?.toDouble(),
      );
      _safeSetState(() {});
    } catch (e) {
      // debugPrint('Error parsing web message: $e');
    }
  }

  // ═══════════════════════════════════════
  // Error Handling & Server Failover
  // ═══════════════════════════════════════

  Future<void> _disposeExistingControllers() async {
    // VideoPlayer
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoListener);
      try {
        await _videoPlayerController!.pause();
        await _videoPlayerController!.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing VideoPlayer: $e');
      }
      _videoPlayerController = null;
    }

    // WebPlayer
    if (_webViewController != null) {
      try {
        _webViewController!.loadRequest(Uri.parse('about:blank'));
        _webViewController!.runJavaScript('document.body.innerHTML = "";');
      } catch (e) {
        debugPrint('⚠️ Error cleaning up WebView: $e');
      }
      _webViewController = null;
    }

    _unifiedController = null;
  }

  Future<void> _handleServerFailure() async {
    if (_isDisposed) return;

    debugPrint('⚠️ Servidor ${_currentServerIndex + 1} falló');

    if (_currentServerIndex < widget.channel.streamUrl.length - 1) {
      _currentServerIndex++;
      debugPrint(
          '🔄 Intentando servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}');

      await Future.delayed(_backoffDurationForAttempt(_serverAttempt));
      _serverAttempt++;

      await _tryCurrentServer();
    } else {
      debugPrint('❌ No quedan más servidores');
      if (mounted && !_isDisposed) {
        _safeSetState(() {
          _isLoading = false;
          _error = 'No se pudo conectar a ningún servidor.\nIntenta más tarde.';
          _isInitializing = false;
        });
      }
    }
  }

  Duration _backoffDurationForAttempt(int attempt) {
    final ms = min(6000, (500 * pow(2, attempt)).toInt());
    return Duration(milliseconds: ms);
  }

  // ═══════════════════════════════════════
  // UI Controls
  // ═══════════════════════════════════════

  void _toggleFullScreen() {
    if (_isDisposed) return;

    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
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
    if (_isDisposed) return;

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
        return 'Auto';
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
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized) {
          return _videoPlayerController!.value.aspectRatio;
        }
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

  void _toggleMute() {
    if (_isDisposed) return;

    setState(() {
      _isMuted = !_isMuted;
    });

    _videoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  // ═══════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════

  @override
  void dispose() {
    debugPrint('🗑️ Disposing VideoPlayerWidget');
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _serverTimeoutTimer?.cancel();
    _errorRecoveryTimer?.cancel();
    _stateCheckTimer?.cancel();
    _orientationCheckTimer?.cancel();
    _fadeController.dispose();

    _disposeExistingControllers();

    // Reset system UI state strictly
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    WakelockPlus.disable();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Build
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // The player must always be in dark mode
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.25,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Video Layer
            Center(
              child: AspectRatio(
                aspectRatio: _getAspectRatio(),
                child: _useHtmlPlayer
                    ? PivoProPlayer(
                        // Uses the exact URL from the active stream
                        url: _currentStream!.url,
                        channelName: widget.channel.name,
                        onRefresh: _handleServerFailure,
                      )
                    : (_videoPlayerController != null &&
                            _videoPlayerController!.value.isInitialized)
                        ? VideoPlayer(_videoPlayerController!)
                        : Container(color: Colors.black),
              ),
            ),

            // 2. Controls Layer (Only for Native Player)
            if (!_useHtmlPlayer && _unifiedController != null)
              Positioned.fill(
                child: CustomVideoControls(
                  controller: _unifiedController!,
                  channelName: widget.channel.name,
                  onFullScreenToggle: _toggleFullScreen,
                  isFullScreen: _isFullScreen,
                  aspectRatioLabel: _getAspectRatioLabel(),
                  onAspectRatioChange: _changeAspectRatio,
                  onMuteToggle: _toggleMute,
                  isMuted: _isMuted,
                  currentServer: _currentServerIndex + 1,
                  totalServers: widget.channel.streamUrl.length,
                ),
              ),

            // 3. Loading Indicator (Only for Native Player)
            // PivoProPlayer handles its own loading state
            if (!_useHtmlPlayer &&
                (_isLoading ||
                    (_unifiedController != null &&
                        _unifiedController!.isBuffering)))
              _buildLoadingWidget(),

            // 4. Error Message (Only for Native Player)
            if (!_useHtmlPlayer && _error != null && !_isLoading)
              _buildErrorWidget(_error!),

            // 5. Fade Animation (Optional, mostly for native)
            if (!_useHtmlPlayer)
              IgnorePointer(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0)
                      .animate(_fadeAnimation),
                  child: Container(color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Conectando...',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
              ),
            ),
            if (_retryCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Reintentando $_retryCount/$_maxRetries...',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
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
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
