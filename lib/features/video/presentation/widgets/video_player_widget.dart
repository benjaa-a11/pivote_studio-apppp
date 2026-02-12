import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Professional video player widget with support for:
/// - HLS (M3U8) streams via VideoPlayer
/// - Automatic server failover
/// - Intelligent error recovery
/// - Stream health monitoring
/// - Token-based URL resolution
///
/// @version 2.2 (HLS Only - Enhanced)
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
  // ═══════════════════════════════════════
  VideoPlayerController? _videoPlayerController;
  Player? _mpdPlayer;
  VideoController? _mpdController;

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
    debugPrint('🎬 VideoPlayerWidget v2.2 (HLS Enhanced)');
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
      _videoPlayerController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ App en foreground - resumiendo');
      _videoPlayerController?.play();
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
    // Check VideoPlayer
    if (_videoPlayerController != null) {
      if (_videoPlayerController!.value.isBuffering) {
        _stuckCounter++;
        debugPrint(
            '⚠️ Watchdog: VideoPlayer buffering (${_stuckCounter * 5}s)');

        if (_stuckCounter >= _watchdogThreshold) {
          debugPrint('🔄 Watchdog: Stream stalled, switching server');
          _stuckCounter = 0;
          _handleServerFailure();
        }
      } else if (_videoPlayerController!.value.isPlaying) {
        _stuckCounter = 0;
      }
    }

    // Check MediaKit (DASH)
    if (_mpdPlayer != null) {
      final state = _mpdPlayer!.state;

      // Check if stream is completely stuck (possible DRM error)
      if (!state.playing && !state.buffering && state.position.inSeconds == 0) {
        _stuckCounter++;
        debugPrint(
            '⚠️ Watchdog: DASH not starting (${_stuckCounter * 5}s) - possible DRM error');

        if (_stuckCounter >= 2) {
          // 10 seconds
          debugPrint('🔄 Watchdog: DASH failed to start, switching server');
          _stuckCounter = 0;
          _handleServerFailure();
        }
      } else if (state.buffering) {
        _stuckCounter++;
        debugPrint('⚠️ Watchdog: MediaKit buffering (${_stuckCounter * 5}s)');

        if (_stuckCounter >= _watchdogThreshold) {
          debugPrint('🔄 Watchdog: DASH stream stalled, switching server');
          _stuckCounter = 0;
          _handleServerFailure();
        }
      } else if (state.playing) {
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

    // Detect stream type inline
    final isDash = url.toLowerCase().contains('.mpd');
    final isHls = url.toLowerCase().contains('.m3u8') ||
        url.toLowerCase().contains('m3u');

    debugPrint('───────────────────────────────────────');
    debugPrint(
        '🔄 Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}');
    debugPrint('📡 Tipo: ${isDash ? "DASH" : isHls ? "HLS" : "UNKNOWN"}');
    debugPrint('🔐 DRM Required: ${_currentStream!.hasDrm}');
    if (_currentStream!.hasDrm) {
      debugPrint('   Valid DRM: ${_currentStream!.hasValidDrm}');
    }
    debugPrint('📋 Custom Headers: ${_currentStream!.headers != null}');
    if (_currentStream!.headers != null) {
      debugPrint('   Headers: ${_currentStream!.headers!.keys.join(", ")}');
    }
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

    // Detect DASH (.mpd)
    if (url.toLowerCase().endsWith('.mpd')) {
      await _initializeDashPlayer(url);
      return;
    }

    // Always use VideoPlayer for HLS
    await _initializeVideoPlayer(url);
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
  // MediaKit (DASH + DRM)
  // ═══════════════════════════════════════

  Future<void> _initializeDashPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 Inicializando DASH Player');

      // Build HTTP headers
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      // Add custom headers if present
      if (_currentStream!.headers != null) {
        headers.addAll(_currentStream!.headers!);
        debugPrint('📋 Custom Headers Added:');
        _currentStream!.headers!.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      }

      _mpdPlayer = Player();
      _mpdController = VideoController(_mpdPlayer!);

      // Build extras dynamically
      final extras = <String, String>{
        'demuxer-lavf-format': 'dash',
      };

      // Add DRM configuration if valid
      if (_currentStream!.hasDrm) {
        if (_currentStream!.hasValidDrm) {
          final clearKeyConfig = _currentStream!.clearKeyConfig!;
          extras['clearkey-key'] = clearKeyConfig;
          debugPrint('🔐 DRM ClearKey Applied');
          debugPrint('   KeyID: ${_currentStream!.k1}');
          debugPrint('   Key: ${_currentStream!.k2!.substring(0, 8)}...');
        } else {
          // Has DRM keys but they're invalid
          debugPrint('❌ DRM keys are invalid (must be hexadecimal)');
          throw Exception(
              'DRM keys are invalid. Keys must be in hexadecimal format.');
        }
      } else {
        debugPrint('ℹ️ No DRM required for this stream');
      }

      // Open media with configuration
      await _mpdPlayer!.open(
        Media(
          url,
          httpHeaders: headers,
          extras: extras,
        ),
      );

      // Listen for errors
      _mpdPlayer!.stream.error.listen((error) {
        if (!_isDisposed && mounted) {
          debugPrint('❌ MediaKit Error: $error');
          _handleDashError(error);
        }
      });

      _serverTimeoutTimer?.cancel();
      _fadeController.forward();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
        _stuckCounter = 0;
      });

      debugPrint('✅ DASH Player Ready');
    } catch (e, st) {
      debugPrint('❌ DASH Error: $e\n$st');

      // Check if it's a DRM validation error
      if (e.toString().contains('DRM keys are invalid')) {
        _safeSetState(() {
          _isLoading = false;
          _error =
              'Error de DRM: Las claves de desencriptación son inválidas.\n\nVerifica que k1 y k2 estén en formato hexadecimal.';
          _isInitializing = false;
        });
      } else {
        await _handleServerFailure();
      }
    }
  }

  /// Handle DASH-specific errors with user-friendly messages
  void _handleDashError(String error) {
    final errorLower = error.toLowerCase();

    String userMessage;

    if (errorLower.contains('drm') ||
        errorLower.contains('decrypt') ||
        errorLower.contains('clearkey')) {
      userMessage =
          'Error de DRM: Las claves de desencriptación son incorrectas.\n\nVerifica que k1 y k2 sean correctos.';
    } else if (errorLower.contains('403') || errorLower.contains('forbidden')) {
      userMessage =
          'Acceso bloqueado (403): El servidor rechazó la conexión.\n\nVerifica que los headers (Referer/Origin) sean correctos.';
    } else if (errorLower.contains('404')) {
      userMessage =
          'Stream no encontrado (404).\n\nLa URL puede estar incorrecta o el contenido no existe.';
    } else if (errorLower.contains('timeout') ||
        errorLower.contains('timed out')) {
      userMessage =
          'Timeout: El servidor no responde.\n\nIntenta nuevamente más tarde.';
    } else if (errorLower.contains('network') ||
        errorLower.contains('connection')) {
      userMessage =
          'Error de conexión: No se pudo conectar al servidor.\n\nVerifica tu conexión a internet.';
    } else {
      userMessage = 'Error de reproducción DASH.\n\n$error';
    }

    _safeSetState(() {
      _isLoading = false;
      _error = userMessage;
      _isInitializing = false;
    });
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

    // MediaKit
    if (_mpdPlayer != null) {
      try {
        await _mpdPlayer!.pause();
        await _mpdPlayer!.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing MediaKit: $e');
      }
      _mpdPlayer = null;
      _mpdController = null;
    }
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
    _mpdPlayer?.setVolume(_isMuted ? 0.0 : 100.0);
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
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.15,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    return _buildNativePlayer();
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
            const SizedBox(height: 6),
            Text(
              widget.channel.name,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.25,
              ),
            ),
            if (_currentServerIndex > 0 || _retryCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _retryCount > 0
                      ? 'Reintentando $_retryCount/$_maxRetries...'
                      : 'Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Problemas de conexión',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _currentServerIndex = 0;
                      _retryCount = 0;
                      _serverAttempt = 0;
                      _initializePlayer();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Reintentar',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Volver',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativePlayer() {
    Widget playerWidget;

    if (_mpdController != null) {
      playerWidget = Video(controller: _mpdController!);
    } else if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      playerWidget = AspectRatio(
        aspectRatio: _getAspectRatio(),
        child: VideoPlayer(_videoPlayerController!),
      );
    } else {
      playerWidget = Container(color: Colors.black);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(child: playerWidget),
          ),
          CustomVideoControls(
            controller: _createUnifiedController(),
            onFullScreenToggle: _toggleFullScreen,
            onAspectRatioChange: _changeAspectRatio,
            aspectRatioLabel: _getAspectRatioLabel(),
            isFullScreen: _isFullScreen,
            onMuteToggle: _toggleMute,
            isMuted: _isMuted,
            channelName: widget.channel.name,
            currentServer: _currentServerIndex + 1,
            totalServers: widget.channel.streamUrl.length,
          ),
        ],
      ),
    );
  }

  UnifiedVideoController _createUnifiedController() {
    if (_mpdPlayer != null) {
      return UnifiedVideoController.fromMediaKit(_mpdPlayer!);
    }
    return UnifiedVideoController.fromVideoPlayer(_videoPlayerController!);
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }
}
