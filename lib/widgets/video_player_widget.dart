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
  VideoPlayerController? _videoPlayerController;
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

  // Buffering y recuperación
  int _bufferingCount = 0;
  bool _isRecoveringFromBuffer = false;
  DateTime? _lastSuccessfulPlayTime;
  bool _listenerAttached = false;
  bool _internalPause = false;
  int _serverAttempt = 0;

  // Animación para transiciones suaves
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;

    // Inicializar animación
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
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      if (!_internalPause) {
        try {
          _videoPlayerController?.play();
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

    String url = widget.channel.streamUrl[_currentServerIndex].trim();

    // Resolver URLs dinámicas optimizado
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

    if (url.isEmpty || (!url.contains('.m3u8') && !url.contains('.mp4'))) {
      debugPrint('⚠️ URL inválida: $url');
      throw Exception('URL inválida');
    }

    // Timeout ultra-corto (5s) para cambiar de servidor más rápido
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

    await _initializeVideoPlayer(url);
  }

  Future<String?> _resolveDynamicM3u8Url(String url) async {
    debugPrint('🔍 Resolviendo URL: $url');

    HttpClient? httpClient;
    try {
      final uri = Uri.parse(url);
      httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5); // Timeout más corto

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
      if (_videoPlayerController != null) {
        if (_listenerAttached) {
          _videoPlayerController!.removeListener(_videoListener);
          _listenerAttached = false;
        }
        await _videoPlayerController!.pause();
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }

      debugPrint('🎬 Servidor ${_currentServerIndex + 1}: $url');

      // Headers optimizados
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

      // Buffer inicial ULTRA-OPTIMIZADO - súper rápido (1.5s max)
      debugPrint('📦 Esperando buffer inicial...');
      final startWait = DateTime.now();
      const maxWait = Duration(milliseconds: 1500); // Reducido de 3s a 1.5s
      bool gotBuffer = false;

      while (DateTime.now().difference(startWait) < maxWait &&
          !_isDisposed &&
          mounted) {
        await Future.delayed(
            const Duration(milliseconds: 100)); // Más frecuente
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

      // Auto-play ULTRA-AGRESIVO - inicio instantáneo
      debugPrint('▶️ Iniciando reproducción...');
      bool playbackStarted = false;
      int playAttempts = 0;
      const maxAttempts = 5; // Aumentado a 5 intentos

      while (!playbackStarted &&
          playAttempts < maxAttempts &&
          !_isDisposed &&
          mounted) {
        playAttempts++;
        try {
          await _videoPlayerController!.play();
          await Future.delayed(
              const Duration(milliseconds: 150)); // Reducido de 250 a 150

          if (_videoPlayerController!.value.isPlaying) {
            playbackStarted = true;
            _lastSuccessfulPlayTime = DateTime.now();
            debugPrint('✅ Play OK intento #$playAttempts');

            // Fade in suave al mostrar el video
            _fadeController.forward();
          } else {
            final delay =
                Duration(milliseconds: 100 * playAttempts); // Reducido
            await Future.delayed(delay);
          }
        } catch (e) {
          debugPrint('❌ Error play #$playAttempts: $e');
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }

      if (!playbackStarted) {
        debugPrint('🔴 Intento final...');
        try {
          await _videoPlayerController?.play();
        } catch (e) {
          debugPrint('❌ Intento final falló: $e');
        }
      }

      // Watchdog mejorado
      _startWatchdog();

      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _retryCount = 0;
      });

      debugPrint('✅ Servidor ${_currentServerIndex + 1} OK');
    } catch (e, st) {
      debugPrint('❌ Error servidor ${_currentServerIndex + 1}: $e\n$st');

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
  }

  void _videoListener() {
    if (_isDisposed || !mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;
    final now = DateTime.now();

    // Actualizar última reproducción exitosa
    if (value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError) {
      _lastSuccessfulPlayTime = now;
    }

    // Manejo de errores críticos
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
              widget.channel.streamUrl[_currentServerIndex]);
        } else {
          if (_currentServerIndex < widget.channel.streamUrl.length - 1) {
            _currentServerIndex++;
            _retryCount = 0;
            await _tryCurrentServer();
          } else {
            _safeSetState(() {
              _error = 'Error de reproducción: $errorDesc';
              _isLoading = false;
            });
          }
        }
      });
    }

    // Debounce mejorado
    _bufferDebounceTimer?.cancel();
    _bufferDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_isDisposed || _videoPlayerController == null) return;

      final v = _videoPlayerController!.value;

      if (v.isBuffering) {
        _bufferingCount++;
        debugPrint('📊 Buffering (contador: $_bufferingCount)');

        // Recuperación ULTRA-AGRESIVA (1 en lugar de 2)
        if (_bufferingCount >= 1 && !_isRecoveringFromBuffer) {
          _isRecoveringFromBuffer = true;
          debugPrint('🔄 RECUPERACIÓN AUTO (buffers: $_bufferingCount)');

          _internalPause = true;
          try {
            await _videoPlayerController?.pause();
          } catch (_) {}

          // Tiempo adaptativo ULTRA-CORTO
          final recoveryTime = _bufferingCount >= 5
              ? const Duration(milliseconds: 2000)
              : const Duration(milliseconds: 1000);

          debugPrint('⏱️ Esperando ${recoveryTime.inMilliseconds}ms...');
          await Future.delayed(recoveryTime);

          if (_isDisposed || _videoPlayerController == null) return;

          // Reintentos ULTRA-MEJORADOS
          bool resumed = false;
          int attempts = 0;
          const attemptsMax = 8; // Aumentado a 8

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
      } else {
        if (_bufferingCount > 0) _bufferingCount = max(0, _bufferingCount - 1);

        // Forzar play si está detenido sin razón
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

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    // Watchdog ULTRA-FRECUENTE (1s para detección instantánea)
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
    final ms = min(6000, (400 * pow(2, attempt)).toInt()); // Reducido tope
    return Duration(milliseconds: ms);
  }

  void _toggleFullScreen() {
    if (_isDisposed || _videoPlayerController == null) return;

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
        return _videoPlayerController?.value.aspectRatio ?? 16 / 9;
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
    if (_isDisposed || _videoPlayerController == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    try {
      _videoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
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
            // Spinner más pequeño y elegante
            SizedBox(
              width: 50, // Reducido de 70
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3, // Reducido de 4
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20), // Reducido de 24
            const Text(
              'Conectando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16, // Reducido de 18
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6), // Reducido de 8
            Text(
              widget.channel.name,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14, // Reducido de 15
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
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return _buildLoadingWidget();
    }

    final aspectRatio = _getAspectRatio();

    Widget videoContent = Center(
      child: _aspectRatioType == AspectRatioType.stretch
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoPlayerController!.value.size.width,
                  height: _videoPlayerController!.value.size.height,
                  child: VideoPlayer(_videoPlayerController!),
                ),
              ),
            )
          : AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            ),
    );

    // Fade in suave al mostrar video
    Widget playerWidget = Container(
      color: Colors.black,
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: videoContent,
          ),
          Positioned.fill(
            child: CustomVideoControls(
              controller: _videoPlayerController!,
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

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      try {
        setState(fn);
      } catch (_) {}
    }
  }
}
