import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/channel.dart';
import 'custom_video_controls.dart';
import 'exoplayer_controller.dart';
import 'exoplayer_view.dart';
import 'unified_video_controller.dart';

enum AspectRatioType {
  auto,
  ratio16_9,
  ratio4_3,
  stretch,
}

enum PlayerType {
  videoPlayer,  // Para HLS (M3U8)
  exoPlayer,    // Para DASH con/sin DRM
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
  
  // Players
  VideoPlayerController? _videoPlayerController;
  ExoPlayerController? _exoPlayerController;
  
  // State
  PlayerType? _playerType;
  StreamSource? _currentStream;
  StreamType? _streamType;
  
  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;
  AspectRatioType _aspectRatioType = AspectRatioType.ratio16_9;
  int _currentServerIndex = 0;

  Timer? _serverTimeoutTimer;
  Timer? _errorRecoveryTimer;
  Timer? _watchdogTimer;
  Timer? _stateCheckTimer;

  bool _isMuted = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  DateTime? _lastSuccessfulPlayTime;
  DateTime? _lastStateChange;
  int _serverAttempt = 0;
  
  // Watchdog para detectar streams trabados
  PlayerState? _lastKnownState;
  int _stuckCounter = 0;

  // Animación
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Listeners para ExoPlayer
  StreamSubscription? _exoPlayerStateSubscription;
  StreamSubscription? _exoPlayerPlayingSubscription;
  StreamSubscription? _exoPlayerErrorSubscription;

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
    
    debugPrint('🎬 VideoPlayerWidget iniciando para canal: ${widget.channel.name}');
    _initializePlayer();
    _startWatchdog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('⏸️ App en background - pausando');
      _videoPlayerController?.pause();
      _exoPlayerController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ App en foreground - resumiendo');
      _videoPlayerController?.play();
      _exoPlayerController?.play();
    }
  }

  /// Watchdog para detectar si el player se traba
  void _startWatchdog() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      // Verificar ExoPlayer
      if (_playerType == PlayerType.exoPlayer && _exoPlayerController != null) {
        final currentState = _exoPlayerController!.state;
        
        if (currentState == PlayerState.buffering) {
          _stuckCounter++;
          debugPrint('⚠️ Watchdog: Buffering por ${_stuckCounter * 5}s');
          
          // Si está buffering por más de 15 segundos, cambiar servidor
          if (_stuckCounter >= 3) {
            debugPrint('🔄 Watchdog: Stream trabado, cambiando servidor');
            _stuckCounter = 0;
            _handleServerFailure();
          }
        } else if (currentState == PlayerState.ready) {
          _stuckCounter = 0;
        }
      }

      // Verificar VideoPlayer
      if (_playerType == PlayerType.videoPlayer && _videoPlayerController != null) {
        if (_videoPlayerController!.value.isBuffering) {
          _stuckCounter++;
          debugPrint('⚠️ Watchdog: VideoPlayer buffering por ${_stuckCounter * 5}s');
          
          if (_stuckCounter >= 3) {
            debugPrint('🔄 Watchdog: Stream trabado, cambiando servidor');
            _stuckCounter = 0;
            _handleServerFailure();
          }
        } else if (_videoPlayerController!.value.isPlaying) {
          _stuckCounter = 0;
        }
      }
    });
  }

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
    debugPrint('🎬 Stream type: $_streamType');
    debugPrint('📺 URL: $url');

    // Resolve dynamic URLs for M3U8
    if (url.contains('phpcode/lista01.php') && url.contains('token=')) {
      try {
        final resolvedUrl = await _resolveDynamicM3u8Url(url);
        if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
          url = resolvedUrl;
          debugPrint('✅ URL resuelta: $url');
        }
      } catch (e) {
        debugPrint('❌ Error resolviendo URL dinámica: $e');
      }
    }

    if (url.isEmpty) {
      throw Exception('URL vacía');
    }

    // Timeout de 10 segundos para cambiar de servidor
    _serverTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted &&
          !_isDisposed &&
          _isLoading &&
          _currentServerIndex < widget.channel.streamUrl.length - 1) {
        debugPrint('⏱️ Timeout servidor ${_currentServerIndex + 1}, siguiente...');
        _currentServerIndex++;
        _tryCurrentServer();
      }
    });

    // Decidir qué reproductor usar
    if (_streamType == StreamType.dash) {
      // DASH (con o sin DRM) → ExoPlayer nativo
      _playerType = PlayerType.exoPlayer;
      await _initializeExoPlayer(url, _currentStream!.k1, _currentStream!.k2);
    } else if (_streamType == StreamType.m3u8) {
      // HLS → VideoPlayer
      _playerType = PlayerType.videoPlayer;
      await _initializeVideoPlayer(url);
    } else {
      // Fallback a VideoPlayer
      _playerType = PlayerType.videoPlayer;
      await _initializeVideoPlayer(url);
    }
  }

  Future<String?> _resolveDynamicM3u8Url(String url) async {
    debugPrint('🔍 Resolviendo URL dinámica: $url');

    HttpClient? httpClient;
    try {
      final uri = Uri.parse(url);
      httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..badCertificateCallback = (cert, host, port) => true; // Aceptar certificados

      final request = await httpClient.headUrl(uri);
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36',
      );

      final response = await request.close();

      if (response.redirects.isNotEmpty) {
        final redirected = response.redirects.last.location.toString();
        debugPrint('✅ URL resuelta: $redirected');
        return redirected;
      }

      return url;
    } catch (e) {
      debugPrint('❌ Error resolviendo: $e');
      return url;
    } finally {
      httpClient?.close(force: true);
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 Inicializando VideoPlayer (HLS)');
      debugPrint('📺 Servidor ${_currentServerIndex + 1}: $url');

      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
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
      
      debugPrint('⏳ Inicializando VideoPlayerController...');
      await _videoPlayerController!.initialize();

      if (_isDisposed || !mounted) return;

      _serverTimeoutTimer?.cancel();

      await _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
      
      debugPrint('▶️ Iniciando reproducción...');
      await _videoPlayerController!.play();

      _lastSuccessfulPlayTime = DateTime.now();
      _fadeController.forward();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
        _stuckCounter = 0;
      });

      debugPrint('✅ VideoPlayer Servidor ${_currentServerIndex + 1} OK');
    } catch (e, st) {
      debugPrint('❌ Error VideoPlayer servidor ${_currentServerIndex + 1}: $e\n$st');
      await _handleServerFailure();
    }
  }
  Future<void> _initializeExoPlayer(String url, String? k1, String? k2) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      final hasDrm = k1 != null && k2 != null;
      debugPrint('🎬 Inicializando ExoPlayer ${hasDrm ? "(DRM ClearKey)" : ""}');
      debugPrint('📺 Servidor ${_currentServerIndex + 1}: $url');
      if (hasDrm) {
        debugPrint('🔐 K1: ${k1.substring(0, 16)}...');
        debugPrint('🔐 K2: ${k2.substring(0, 16)}...');
      }

      // Crear controller de ExoPlayer
      // El viewId será generado por la PlatformView
      _exoPlayerController = ExoPlayerController(0); // Placeholder, se actualizará

      // Suscribirse a eventos
      _exoPlayerStateSubscription = _exoPlayerController!.onStateChange.listen((state) {
        debugPrint('📺 ExoPlayer State: $state');
        _lastStateChange = DateTime.now();
        _lastKnownState = state;
        
        if (state == PlayerState.ready) {
          _serverTimeoutTimer?.cancel();
          _lastSuccessfulPlayTime = DateTime.now();
          _fadeController.forward();
          _stuckCounter = 0;
          
          _safeSetState(() {
            _isLoading = false;
            _isInitializing = false;
            _retryCount = 0;
          });
          
          debugPrint('✅ ExoPlayer Servidor ${_currentServerIndex + 1} OK');
        } else if (state == PlayerState.buffering) {
          debugPrint('⏳ ExoPlayer buffering...');
        } else if (state == PlayerState.idle) {
          debugPrint('⚠️ ExoPlayer IDLE - verificando...');
          // Si está en IDLE por más de 10s, reintentar
          Timer(const Duration(seconds: 10), () {
            if (_exoPlayerController?.state == PlayerState.idle && !_isDisposed) {
              debugPrint('❌ ExoPlayer stuck in IDLE - retrying');
              _handleServerFailure();
            }
          });
        }
        
        _safeSetState(() {});
      });

      _exoPlayerPlayingSubscription = _exoPlayerController!.onPlayingChange.listen((isPlaying) {
        debugPrint('▶️ ExoPlayer Playing: $isPlaying');
        if (isPlaying) {
          _lastSuccessfulPlayTime = DateTime.now();
          _stuckCounter = 0;
        }
        _safeSetState(() {});
      });

      _exoPlayerErrorSubscription = _exoPlayerController!.onError.listen((error) {
        debugPrint('❌ ExoPlayer Error: $error');
        _handleServerFailure();
      });

      _safeSetState(() {
        _playerType = PlayerType.exoPlayer;
      });

    } catch (e, st) {
      debugPrint('❌ Error ExoPlayer servidor ${_currentServerIndex + 1}: $e\n$st');
      await _handleServerFailure();
    }
  }

  /// Callback cuando se crea la PlatformView de ExoPlayer
  Future<void> _onExoPlayerViewCreated(ExoPlayerController controller) async {
    if (_isDisposed) return;

    try {
      debugPrint('🏗️ ExoPlayerView creada, inicializando...');
      
      // Actualizar referencia al controller
      _exoPlayerController = controller;
      
      // Re-suscribir a eventos con el controller real
      await _exoPlayerStateSubscription?.cancel();
      await _exoPlayerPlayingSubscription?.cancel();
      await _exoPlayerErrorSubscription?.cancel();
      
      _exoPlayerStateSubscription = controller.onStateChange.listen((state) {
        debugPrint('📺 State: $state');
        _lastStateChange = DateTime.now();
        _lastKnownState = state;
        
        if (state == PlayerState.ready) {
          _serverTimeoutTimer?.cancel();
          _lastSuccessfulPlayTime = DateTime.now();
          _fadeController.forward();
          _stuckCounter = 0;
          
          _safeSetState(() {
            _isLoading = false;
            _isInitializing = false;
            _retryCount = 0;
          });
          
          debugPrint('✅ ExoPlayer READY');
        }
        
        _safeSetState(() {});
      });

      _exoPlayerPlayingSubscription = controller.onPlayingChange.listen((isPlaying) {
        debugPrint('▶️ Playing: $isPlaying');
        if (isPlaying) {
          _lastSuccessfulPlayTime = DateTime.now();
        }
        _safeSetState(() {});
      });

      _exoPlayerErrorSubscription = controller.onError.listen((error) {
        debugPrint('❌ Error: $error');
        _handleServerFailure();
      });

      // Ahora sí inicializar el reproductor nativo
      debugPrint('🔧 Llamando initialize nativo...');
      await controller.initialize(
        _currentStream!.url,
        k1: _currentStream!.k1,
        k2: _currentStream!.k2,
      );

      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      debugPrint('✅ ExoPlayer nativo inicializado');

    } catch (e, st) {
      debugPrint('❌ Error inicializando ExoPlayer nativo: $e\n$st');
      await _handleServerFailure();
    }
  }

  void _videoListener() {
    if (_isDisposed || !mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;

    if (value.isInitialized && value.isPlaying && !value.hasError) {
      _lastSuccessfulPlayTime = DateTime.now();
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

    // ExoPlayer
    if (_exoPlayerController != null) {
      await _exoPlayerStateSubscription?.cancel();
      await _exoPlayerPlayingSubscription?.cancel();
      await _exoPlayerErrorSubscription?.cancel();
      
      try {
        await _exoPlayerController!.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing ExoPlayer: $e');
      }
      _exoPlayerController = null;
    }
  }

  Future<void> _handleServerFailure() async {
    if (_isDisposed) return;

    debugPrint('⚠️ Servidor ${_currentServerIndex + 1} falló');
    
    if (_currentServerIndex < widget.channel.streamUrl.length - 1) {
      _currentServerIndex++;
      debugPrint('🔄 Intentando servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}');
      
      await Future.delayed(_backoffDurationForAttempt(_serverAttempt));
      _serverAttempt++;
      
      await _tryCurrentServer();
    } else {
      debugPrint('❌ No quedan más servidores');
      if (mounted && !_isDisposed) {
        _safeSetState(() {
          _isLoading = false;
          _error = 'No se pudo conectar a ningún servidor';
          _isInitializing = false;
        });
      }
    }
  }

  Duration _backoffDurationForAttempt(int attempt) {
    final ms = min(6000, (500 * pow(2, attempt)).toInt());
    return Duration(milliseconds: ms);
  }

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
    _exoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing VideoPlayerWidget');
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _serverTimeoutTimer?.cancel();
    _errorRecoveryTimer?.cancel();
    _watchdogTimer?.cancel();
    _stateCheckTimer?.cancel();
    _fadeController.dispose();

    _disposeExistingControllers();

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
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (_currentServerIndex > 0 || _retryCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _retryCount > 0
                      ? 'Reintentando $_retryCount/$_maxRetries...'
                      : 'Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
                      _stuckCounter = 0;
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
    Widget videoContent;

    if (_playerType == PlayerType.exoPlayer && _exoPlayerController != null) {
      // ExoPlayer (DASH con/sin DRM)
      videoContent = ExoPlayerView(
        controller: _exoPlayerController!,
        onCreated: _onExoPlayerViewCreated,
      );
    } else if (_playerType == PlayerType.videoPlayer && _videoPlayerController != null) {
      // VideoPlayer (HLS)
      if (!_videoPlayerController!.value.isInitialized) {
        return _buildLoadingWidget();
      }

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
        videoContent = Center(
          child: AspectRatio(
            aspectRatio: _getAspectRatio(),
            child: VideoPlayer(_videoPlayerController!),
          ),
        );
      }
    } else {
      return _buildLoadingWidget();
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
              controller: _createUnifiedController(),
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

  UnifiedVideoController _createUnifiedController() {
    if (_playerType == PlayerType.videoPlayer && _videoPlayerController != null) {
      return HLSControllerAdapter(_videoPlayerController!);
    } else if (_playerType == PlayerType.exoPlayer && _exoPlayerController != null) {
      return ExoPlayerControllerAdapter(_exoPlayerController!);
    } else {
      // Fallback
      return HLSControllerAdapter(_videoPlayerController ?? VideoPlayerController.asset(''));
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