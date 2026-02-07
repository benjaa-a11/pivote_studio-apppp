import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/channel.dart';
import 'custom_video_controls.dart';
import 'unified_video_controller.dart';

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
  // HLS Player (VideoPlayer for M3U8)
  VideoPlayerController? _videoPlayerController;

  // DASH Player (BetterPlayer for MPD with DRM)
  BetterPlayerController? _betterPlayerController;

  // Current stream info
  StreamSource? _currentStream;
  StreamType? _streamType;

  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;
  AspectRatioType _aspectRatioType = AspectRatioType.ratio16_9;
  int _currentServerIndex = 0;

  Timer? _serverTimeoutTimer;
  Timer? _errorRecoveryTimer;
  Timer? _bufferDebounceTimer;
  Timer? _watchdogTimer;

  bool _isMuted = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  // Buffering and recovery
  int _bufferingCount = 0;
  bool _isRecoveringFromBuffer = false;
  DateTime? _lastSuccessfulPlayTime;
  bool _listenerAttached = false;
  bool _internalPause = false;
  int _serverAttempt = 0;

  // Smooth transition animation
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
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        _videoPlayerController?.pause();
        _betterPlayerController?.pause();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      if (!_internalPause) {
        try {
          _videoPlayerController?.play();
          _betterPlayerController?.play();
        } catch (_) {}
      }
    }
  }

  Future<void> _initializePlayer() async {
    if (_isInitializing || _isDisposed) return;

    _safeSetState(() {
      _isInitializing = true;
      _isLoading = true;
      _error = null;
      _retryCount = 0;
      _bufferingCount = 0;
      _serverAttempt = 0;
    });

    try {
      await _tryCurrentServer();
    } catch (e, st) {
      debugPrint('❌ Error en initializePlayer: $e\n$st');
      _safeSetState(() {
        _isLoading = false;
        _error = 'Error al cargar: ${e.toString()}';
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

    // Detect stream type
    _streamType = widget.channel.getStreamType(url);
    debugPrint('🎬 Stream type detected: $_streamType for URL: $url');

    // Resolve dynamic URLs for M3U8
    if (url.contains('phpcode/lista01.php') && url.contains('token=')) {
      try {
        final resolvedUrl = await _resolveDynamicM3u8Url(url);
        if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
          url = resolvedUrl;
        }
      } catch (e) {
        debugPrint('❌ Error resolviendo URL dinámica: $e');
      }
    }

    if (url.isEmpty) {
      debugPrint('⚠️ URL vacía');
      throw Exception('URL vacía');
    }

    // Ultra-short timeout (5s) for faster server switching
    _serverTimeoutTimer = Timer(const Duration(seconds: 5), () {
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

    // Initialize player based on stream type
    if (_streamType == StreamType.dash) {
      await _initializeBetterPlayer(url);
    } else if (_streamType == StreamType.m3u8) {
      await _initializeVideoPlayer(url);
    } else {
      // For direct streams without extension, use BetterPlayer
      await _initializeBetterPlayerForDirectStream(url);
    }
  }

  Future<String?> _resolveDynamicM3u8Url(String url) async {
    debugPrint('🔍 Resolviendo URL: $url');

    HttpClient? httpClient;
    try {
      final uri = Uri.parse(url);
      httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 5);

      final request = await httpClient.headUrl(uri);

      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      );
      request.headers.set('Accept', '*/*');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close();

      if (response.redirects.isNotEmpty) {
        final redirected = response.redirects.last.location.toString();
        debugPrint('✅ URL resuelta: $redirected');
        return redirected;
      }

      final location = response.headers.value('location');
      if (location != null && location.isNotEmpty) {
        debugPrint('✅ URL (header): $location');
        return location;
      }

      return url;
    } catch (e) {
      debugPrint('❌ Error resolviendo: $e');
      return url;
    } finally {
      try {
        httpClient?.close(force: true);
      } catch (_) {}
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    if (_isDisposed) return;

    try {
      // Dispose existing controllers
      await _disposeExistingControllers();

      debugPrint('🎬 HLS Servidor ${_currentServerIndex + 1}: $url');

      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      if (url.contains('.mp4')) {
        headers['Range'] = 'bytes=0-';
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: headers,
      );

      if (!_listenerAttached) {
        _videoPlayerController!.addListener(_videoListener);
        _listenerAttached = true;
      }

      await _videoPlayerController!.initialize();

      if (_isDisposed || !mounted) return;

      _serverTimeoutTimer?.cancel();

      if (_videoPlayerController!.value.hasError) {
        throw Exception(
            'Error controller: ${_videoPlayerController!.value.errorDescription}');
      }

      // Initial buffer wait
      debugPrint('📦 Esperando buffer inicial...');
      final startWait = DateTime.now();
      const maxWait = Duration(milliseconds: 1500);
      bool gotBuffer = false;

      while (DateTime.now().difference(startWait) < maxWait &&
          !_isDisposed &&
          mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        final value = _videoPlayerController!.value;
        if (value.isInitialized &&
            !value.isBuffering &&
            value.position > Duration.zero) {
          gotBuffer = true;
          break;
        }
      }

      if (!gotBuffer) {
        debugPrint('⚠️ Buffer inicial lento, continuando...');
      }

      await _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _videoPlayerController!.setPlaybackSpeed(1.0);

      // Aggressive auto-play
      await _aggressivePlayStart(_videoPlayerController!);

      _startWatchdog();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
      });

      debugPrint('✅ HLS Servidor ${_currentServerIndex + 1} OK');
    } catch (e, st) {
      debugPrint('❌ Error HLS servidor ${_currentServerIndex + 1}: $e\n$st');
      await _handleServerFailure();
    }
  }

  Future<void> _initializeBetterPlayerForDirectStream(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 Stream Directo Servidor ${_currentServerIndex + 1}: $url');

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        videoFormat: BetterPlayerVideoFormat.other,
        headers: {
          'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
      );

      final configuration = BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        fit: BoxFit.contain,
        aspectRatio: _getAspectRatio(),
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        eventListener: _betterPlayerEventListener,
      );

      _betterPlayerController = BetterPlayerController(configuration);
      await _betterPlayerController!.setupDataSource(dataSource);

      if (_isDisposed || !mounted) return;

      _serverTimeoutTimer?.cancel();

      await _betterPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);

      // Wait for initialization
      await _waitForBetterPlayerInit();

      _fadeController.forward();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
      });

      debugPrint('✅ Stream Directo Servidor ${_currentServerIndex + 1} OK');
    } catch (e, st) {
      debugPrint(
          '❌ Error Stream Directo servidor ${_currentServerIndex + 1}: $e\n$st');
      await _handleServerFailure();
    }
  }

  Future<void> _initializeBetterPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 DASH Servidor ${_currentServerIndex + 1}: $url');
      debugPrint('🔐 DRM Keys - K1: ${_currentStream?.k1}, K2: ${_currentStream?.k2}');

      // Configure DRM if keys are provided
      BetterPlayerDrmConfiguration? drmConfiguration;
      if (_currentStream?.hasDrm == true) {
        debugPrint('🔐 Configurando DRM ClearKey');
        drmConfiguration = BetterPlayerDrmConfiguration(
          drmType: BetterPlayerDrmType.clearKey,
          clearKey: BetterPlayerClearKeyUtils.generateKey({
            _currentStream!.k1!: _currentStream!.k2!,
          }),
        );
      } else {
        debugPrint('ℹ️ Stream DASH sin DRM');
      }

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        videoFormat: BetterPlayerVideoFormat.dash,
        drmConfiguration: drmConfiguration,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
      );

      final configuration = BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        fit: BoxFit.contain,
        aspectRatio: _getAspectRatio(),
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        eventListener: _betterPlayerEventListener,
      );

      _betterPlayerController = BetterPlayerController(configuration);
      await _betterPlayerController!.setupDataSource(dataSource);

      if (_isDisposed || !mounted) return;

      _serverTimeoutTimer?.cancel();

      await _betterPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);

      await _waitForBetterPlayerInit();

      _fadeController.forward();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
      });

      debugPrint('✅ DASH Servidor ${_currentServerIndex + 1} OK');
    } catch (e, st) {
      debugPrint('❌ Error DASH servidor ${_currentServerIndex + 1}: $e\n$st');
      await _handleServerFailure();
    }
  }

  void _betterPlayerEventListener(BetterPlayerEvent event) {
    if (_isDisposed) return;

    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      debugPrint('✅ Better Player initialized');
      _lastSuccessfulPlayTime = DateTime.now();
    } else if (event.betterPlayerEventType == BetterPlayerEventType.play) {
      _lastSuccessfulPlayTime = DateTime.now();
    } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      debugPrint('❌ Better Player exception');
    }

    _safeSetState(() {});
  }

  Future<void> _waitForBetterPlayerInit() async {
    debugPrint('📦 Esperando inicialización BetterPlayer...');
    final startWait = DateTime.now();
    const maxWait = Duration(seconds: 5);
    bool initialized = false;

    while (DateTime.now().difference(startWait) < maxWait &&
        !_isDisposed &&
        mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_betterPlayerController!.isVideoInitialized() ?? false) {
        initialized = true;
        break;
      }
    }

    if (!initialized) {
      debugPrint('⚠️ Inicialización BetterPlayer lenta, continuando...');
    }
  }

  Future<void> _aggressivePlayStart(VideoPlayerController controller) async {
    debugPrint('▶️ Iniciando reproducción agresiva...');
    bool playbackStarted = false;
    int playAttempts = 0;
    const maxAttempts = 5;

    while (!playbackStarted &&
        playAttempts < maxAttempts &&
        !_isDisposed &&
        mounted) {
      playAttempts++;
      try {
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 150));

        if (controller.value.isPlaying) {
          playbackStarted = true;
          _lastSuccessfulPlayTime = DateTime.now();
          debugPrint('✅ Play OK intento #$playAttempts');
          _fadeController.forward();
        } else {
          final delay = Duration(milliseconds: 100 * playAttempts);
          await Future.delayed(delay);
        }
      } catch (e) {
        debugPrint('❌ Error play #$playAttempts: $e');
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    if (!playbackStarted) {
      debugPrint('🔴 Intento final de play...');
      try {
        await controller.play();
      } catch (e) {
        debugPrint('❌ Intento final falló: $e');
      }
    }
  }

  Future<void> _disposeExistingControllers() async {
    if (_betterPlayerController != null) {
      try {
        await _betterPlayerController!.pause();
      } catch (_) {}
      try {
        _betterPlayerController!.dispose();
      } catch (_) {}
      _betterPlayerController = null;
    }

    if (_videoPlayerController != null) {
      if (_listenerAttached) {
        _videoPlayerController!.removeListener(_videoListener);
        _listenerAttached = false;
      }
      try {
        await _videoPlayerController!.pause();
      } catch (_) {}
      try {
        await _videoPlayerController!.dispose();
      } catch (_) {}
      _videoPlayerController = null;
    }
  }

  Future<void> _handleServerFailure() async {
    if (_isDisposed) return;

    if (_currentServerIndex < widget.channel.streamUrl.length - 1) {
      _currentServerIndex++;
      await Future.delayed(_backoffDurationForAttempt(_serverAttempt));
      _serverAttempt++;
      await _tryCurrentServer();
    } else {
      if (mounted && !_isDisposed) {
        _safeSetState(() {
          _isLoading = false;
          _error = 'No se pudo conectar a ningún servidor';
          _isInitializing = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_isDisposed || !mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;
    final now = DateTime.now();

    if (value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError) {
      _lastSuccessfulPlayTime = now;
    }

    if (value.hasError && !_isLoading && !_isInitializing) {
      final errorDesc = value.errorDescription ?? 'Error desconocido';
      debugPrint('⚠️ Error: $errorDesc');

      if (_errorRecoveryTimer?.isActive ?? false) return;

      _errorRecoveryTimer = Timer(const Duration(milliseconds: 600), () async {
        if (_isDisposed || !mounted) return;
        _retryCount++;
        debugPrint('🔄 Recuperación $_retryCount/$_maxRetries');

        if (_retryCount <= _maxRetries) {
          await Future.delayed(Duration(milliseconds: 250 * _retryCount));
          await _initializeVideoPlayer(
              widget.channel.streamUrl[_currentServerIndex].url);
        } else {
          await _handleServerFailure();
        }
      });
    }

    _bufferDebounceTimer?.cancel();
    _bufferDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_isDisposed || _videoPlayerController == null) return;

      final v = _videoPlayerController!.value;

      if (v.isBuffering) {
        _bufferingCount++;
        debugPrint('📊 Buffering (contador: $_bufferingCount)');

        if (_bufferingCount >= 1 && !_isRecoveringFromBuffer) {
          await _recoverFromBuffering();
        }
      } else {
        if (_bufferingCount > 0) _bufferingCount = max(0, _bufferingCount - 1);

        if (!v.isBuffering &&
            !v.hasError &&
            !v.isPlaying &&
            !_isRecoveringFromBuffer &&
            !_internalPause) {
          if (_lastSuccessfulPlayTime != null &&
              DateTime.now().difference(_lastSuccessfulPlayTime!).inSeconds >
                  2) {
            debugPrint('🔴 Forzando play (listener)');
            try {
              await _videoPlayerController!.play();
              _lastSuccessfulPlayTime = DateTime.now();
            } catch (e) {
              debugPrint('⚠️ Error forzando: $e');
            }
          }
        }
      }

      _safeSetState(() {});
    });

    _safeSetState(() {});
  }

  Future<void> _recoverFromBuffering() async {
    _isRecoveringFromBuffer = true;
    debugPrint('🔄 RECUPERACIÓN AUTO (buffers: $_bufferingCount)');

    _internalPause = true;
    try {
      await _videoPlayerController?.pause();
    } catch (_) {}

    final recoveryTime = _bufferingCount >= 5
        ? const Duration(milliseconds: 2000)
        : const Duration(milliseconds: 1000);

    debugPrint('⏱️ Esperando ${recoveryTime.inMilliseconds}ms...');
    await Future.delayed(recoveryTime);

    if (_isDisposed || _videoPlayerController == null) return;

    bool resumed = false;
    int attempts = 0;
    const attemptsMax = 8;

    while (!resumed && attempts < attemptsMax && !_isDisposed) {
      attempts++;
      debugPrint('▶️ Intento recovery #$attempts/$attemptsMax');
      try {
        await _videoPlayerController!.play();
        await Future.delayed(const Duration(milliseconds: 200));

        if (_videoPlayerController!.value.isPlaying) {
          resumed = true;
          debugPrint('✅ RECUPERADO OK');
          _lastSuccessfulPlayTime = DateTime.now();
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint('❌ Error intento #$attempts: $e');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (!resumed) {
      debugPrint('🔴 No recuperado tras $attemptsMax intentos');
      try {
        await _videoPlayerController?.play();
      } catch (e) {
        debugPrint('❌ Intento final: $e');
      }
    }

    _bufferingCount = 0;
    _isRecoveringFromBuffer = false;
    _internalPause = false;
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDisposed || _videoPlayerController == null || !mounted) {
        timer.cancel();
        return;
      }

      final value = _videoPlayerController!.value;
      if (value.isInitialized &&
          !value.isBuffering &&
          !value.hasError &&
          !value.isPlaying &&
          !_isLoading &&
          !_isInitializing &&
          !_isRecoveringFromBuffer &&
          !_internalPause) {
        debugPrint('🚨 WATCHDOG: Forzando play');
        try {
          await _videoPlayerController!.play();
          _lastSuccessfulPlayTime = DateTime.now();
        } catch (e) {
          debugPrint('❌ WATCHDOG error: $e');
        }
      }
    });
  }

  Duration _backoffDurationForAttempt(int attempt) {
    final ms = min(6000, (400 * pow(2, attempt)).toInt());
    return Duration(milliseconds: ms);
  }

  void _toggleFullScreen() {
    if (_isDisposed) return;

    final newFullScreenState = !_isFullScreen;

    setState(() {
      _isFullScreen = newFullScreenState;
    });

    debugPrint('📺 ${newFullScreenState ? "Fullscreen" : "Normal"}');

    if (newFullScreenState) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky,
          overlays: []);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isDisposed && mounted) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      });
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isDisposed && mounted) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
              overlays: SystemUiOverlay.values);
        }
      });
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

    if (_betterPlayerController != null) {
      _betterPlayerController!.setOverriddenAspectRatio(_getAspectRatio());
    }
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
    try {
      _videoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
      _betterPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (e) {
      debugPrint('⚠️ Error toggleMute: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing VideoPlayerWidget');
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _serverTimeoutTimer?.cancel();
    _errorRecoveryTimer?.cancel();
    _bufferDebounceTimer?.cancel();
    _watchdogTimer?.cancel();
    _fadeController.dispose();

    if (_videoPlayerController != null) {
      if (_listenerAttached) {
        _videoPlayerController!.removeListener(_videoListener);
        _listenerAttached = false;
      }
      try {
        _videoPlayerController!.pause();
      } catch (_) {}
      try {
        _videoPlayerController!.dispose();
      } catch (_) {}
      _videoPlayerController = null;
    }

    if (_betterPlayerController != null) {
      try {
        _betterPlayerController!.pause();
      } catch (_) {}
      try {
        _betterPlayerController!.dispose();
      } catch (_) {}
      _betterPlayerController = null;
    }

    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.channel.name,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (_currentServerIndex > 0 || _retryCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _retryCount > 0
                      ? 'Reintentando $_retryCount/$_maxRetries...'
                      : 'Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                child: SvgPicture.asset(
                  'assets/icons/player/caido.svg',
                  width: 56,
                  height: 56,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Problemas de conexión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Este canal no funciona temporalmente.\nEstamos trabajando para solucionarlo.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _currentServerIndex = 0;
                      _retryCount = 0;
                      _initializePlayer();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
    final bool useBetterPlayer = _betterPlayerController != null;

    if (useBetterPlayer) {
      if (!(_betterPlayerController!.isVideoInitialized() ?? false)) {
        return _buildLoadingWidget();
      }

      Widget videoContent;

      if (_aspectRatioType == AspectRatioType.stretch) {
        videoContent = ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: BetterPlayer(controller: _betterPlayerController!),
              ),
            ),
          ),
        );
      } else {
        videoContent = Center(
          child: AspectRatio(
            aspectRatio: _getAspectRatio(),
            child: BetterPlayer(controller: _betterPlayerController!),
          ),
        );
      }

      Widget playerWidget = Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: videoContent,
              ),
            ),
            Positioned.fill(
              child: CustomVideoControls(
                controller: DASHControllerAdapter(_betterPlayerController!),
                channelName: widget.channel.name,
                isFullScreen: _isFullScreen,
                onFullScreenToggle: _toggleFullScreen,
                aspectRatioLabel: _getAspectRatioLabel(),
                onAspectRatioChange: _changeAspectRatio,
                isMuted: _isMuted,
                onMuteToggle: _toggleMute,
                currentServer: _currentServerIndex + 1,
                totalServers: widget.channel.streamUrl.length,
              ),
            ),
          ],
        ),
      );

      return _isFullScreen
          ? MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: playerWidget,
            )
          : playerWidget;
    } else {
      if (_videoPlayerController == null ||
          !_videoPlayerController!.value.isInitialized) {
        return _buildLoadingWidget();
      }

      Widget videoContent;

      if (_aspectRatioType == AspectRatioType.stretch) {
        videoContent = ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
          ),
        );
      } else {
        final aspectRatio = _getAspectRatio();
        videoContent = Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
        );
      }

      Widget playerWidget = Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: videoContent,
              ),
            ),
            Positioned.fill(
              child: CustomVideoControls(
                controller: HLSControllerAdapter(_videoPlayerController!),
                channelName: widget.channel.name,
                isFullScreen: _isFullScreen,
                onFullScreenToggle: _toggleFullScreen,
                aspectRatioLabel: _getAspectRatioLabel(),
                onAspectRatioChange: _changeAspectRatio,
                isMuted: _isMuted,
                onMuteToggle: _toggleMute,
                currentServer: _currentServerIndex + 1,
                totalServers: widget.channel.streamUrl.length,
              ),
            ),
          ],
        ),
      );

      return _isFullScreen
          ? MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: playerWidget,
            )
          : playerWidget;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      try {
        setState(fn);
      } catch (_) {}
    }
  }
}