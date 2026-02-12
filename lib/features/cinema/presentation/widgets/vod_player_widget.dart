import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/vod_content.dart';
import '../../data/services/video_extractor.dart';
import '../../data/services/video_source_manager.dart';
import 'vod_player_controls.dart';

/// Reproductor profesional VOD para películas, series y programas
/// Características:
/// - Extracción automática de URLs desde embeds
/// - Múltiples servidores con failover
/// - Controles completos (play/pause, seek, volumen)
/// - Gestos (doble tap para adelantar/retroceder)
/// - Guardado automático de progreso
/// - Cambio dinámico de calidad/servidor
class VodPlayerWidget extends StatefulWidget {
  final VodContent content;
  final Episode? episode; // Si es serie
  final Function(WatchProgress)? onProgressUpdate;
  final WatchProgress? initialProgress;

  const VodPlayerWidget({
    super.key,
    required this.content,
    this.episode,
    this.onProgressUpdate,
    this.initialProgress,
  });

  @override
  State<VodPlayerWidget> createState() => _VodPlayerWidgetState();
}

class _VodPlayerWidgetState extends State<VodPlayerWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ═══════════════════════════════════════
  // Controllers & Managers
  // ═══════════════════════════════════════
  VideoPlayerController? _videoController;
  VideoSourceManager? _sourceManager;

  // ═══════════════════════════════════════
  // State
  // ═══════════════════════════════════════
  List<VideoServer> _availableServers = [];
  int _currentServerIndex = 0;
  ExtractedVideoData? _currentSource;

  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;
  bool _isDisposed = false;

  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;

  // ═══════════════════════════════════════
  // Timers
  // ═══════════════════════════════════════
  Timer? _progressSaveTimer;
  // ignore: unused_field
  Timer? _bufferingTimer;
  Timer? _orientationMonitor;

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

    _initializePlayer();
    _startProgressSaver();
    _startOrientationMonitor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _videoController?.pause();
      _saveProgress();
    } else if (state == AppLifecycleState.resumed) {
      // No auto-play al volver
    }
  }

  // ═══════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════

  Future<void> _initializePlayer() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Inicializar VideoSourceManager
      _sourceManager = await VideoSourceManager.create();

      // 2. Obtener servidores disponibles
      _availableServers = _getServersForContent();

      if (_availableServers.isEmpty) {
        throw Exception('No hay servidores disponibles');
      }

      _localDebugPrint('📺 ${widget.content.title}');
      if (widget.episode != null) {
        _localDebugPrint('📺 ${widget.episode!.displayTitle}');
      }
      _localDebugPrint('🔢 Servidores: ${_availableServers.length}');

      // 3. Intentar con el servidor actual
      await _loadServer(_currentServerIndex);
    } catch (e, st) {
      _localDebugPrint('❌ Error inicializando: $e\n$st');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar el contenido';
        });
      }
    }
  }

  List<VideoServer> _getServersForContent() {
    if (widget.episode != null) {
      return widget.episode!.servers;
    } else if (widget.content is Movie) {
      return (widget.content as Movie).servers;
    }
    return [];
  }

  Future<void> _loadServer(int serverIndex) async {
    if (_isDisposed || serverIndex >= _availableServers.length) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentServerIndex = serverIndex;
      });
    }

    try {
      final server = _availableServers[serverIndex];
      _localDebugPrint('🔄 Cargando servidor: ${server.name}');

      // 1. Obtener fuente de video (con caché)
      final result = await _sourceManager!.getVideoSource(server.embedUrl);

      if (!result.isSuccess) {
        throw Exception(result.error ?? 'No se pudo extraer la URL');
      }

      _currentSource = result.data!;
      _localDebugPrint('✅ URL obtenida (${result.source})');

      // 2. Inicializar VideoPlayer
      await _initializeVideoPlayer(_currentSource!.videoUrl);

      // 3. Restaurar progreso si existe
      if (widget.initialProgress != null && _videoController != null) {
        await _videoController!.seekTo(widget.initialProgress!.position);
      }
    } catch (e) {
      _localDebugPrint('❌ Error cargando servidor: $e');

      // Intentar siguiente servidor
      if (serverIndex < _availableServers.length - 1) {
        _localDebugPrint('🔄 Intentando siguiente servidor...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadServer(serverIndex + 1);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'No se pudo cargar el video.\nIntenta con otro servidor.';
          });
        }
      }
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    if (_isDisposed) return;

    await _disposeVideoController();

    _localDebugPrint('🎬 Inicializando VideoPlayer');

    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
    };

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
      httpHeaders: headers,
    );

    _videoController!.addListener(_videoListener);

    await _videoController!.initialize();

    if (_isDisposed || !mounted) return;

    _fadeController.forward();

    setState(() {
      _isLoading = false;
      _duration = _videoController!.value.duration;
    });

    _localDebugPrint('✅ VideoPlayer listo (${_formatDuration(_duration)})');
  }

  void _videoListener() {
    if (_isDisposed || !mounted || _videoController == null) return;

    final value = _videoController!.value;

    if (mounted) {
      setState(() {
        _currentPosition = value.position;
        _duration = value.duration;
        _isPlaying = value.isPlaying;
        _isBuffering = value.isBuffering;
      });
    }

    // Detectar errores
    if (value.hasError && !_isLoading) {
      _localDebugPrint('⚠️ Error en reproducción: ${value.errorDescription}');
      _handlePlaybackError();
    }
  }

  void _handlePlaybackError() {
    // Intentar revalidar la fuente
    if (_currentSource != null &&
        _sourceManager != null &&
        !_currentSource!.isStillValid) {
      _localDebugPrint('🔄 Revalidando fuente...');
      _revalidateAndReload();
    }
  }

  Future<void> _revalidateAndReload() async {
    if (_isDisposed) return;

    try {
      final server = _availableServers[_currentServerIndex];
      final result = await _sourceManager!.revalidateSource(server.embedUrl);

      if (result.isSuccess) {
        final currentPos = _currentPosition;
        await _initializeVideoPlayer(result.data!.videoUrl);
        await _videoController?.seekTo(currentPos);
        await _videoController?.play();
      }
    } catch (e) {
      _localDebugPrint('❌ Error revalidando: $e');
    }
  }

  // ═══════════════════════════════════════
  // Orientation Monitor
  // ═══════════════════════════════════════

  void _startOrientationMonitor() {
    _orientationMonitor?.cancel();
    _orientationMonitor =
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

    if (!isLandscape && _isFullScreen) {
      setState(() {
        _isFullScreen = false;
      });
    } else if (isLandscape && !_isFullScreen) {
      setState(() {
        _isFullScreen = true;
      });
    }
  }

  // ═══════════════════════════════════════
  // Progress Tracking
  // ═══════════════════════════════════════

  void _startProgressSaver() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      _saveProgress();
    });
  }

  void _saveProgress() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final progress = WatchProgress(
      contentId: widget.content.id,
      episodeId: widget.episode?.id,
      position: _currentPosition,
      duration: _duration,
      lastWatched: DateTime.now(),
    );

    widget.onProgressUpdate?.call(progress);
  }

  // ═══════════════════════════════════════
  // Playback Controls
  // ═══════════════════════════════════════

  void _togglePlayPause() {
    if (_videoController == null) return;

    if (_isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  Future<void> _seekTo(Duration position) async {
    if (_videoController == null) return;
    await _videoController!.seekTo(position);
  }

  Future<void> _seekRelative(Duration delta) async {
    final newPosition = _currentPosition + delta;
    final clamped = Duration(
      milliseconds:
          newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await _seekTo(clamped);
  }

  void _toggleFullScreen() {
    if (mounted) {
      setState(() {
        _isFullScreen = !_isFullScreen;
      });
    }

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

  // ═══════════════════════════════════════
  // Server Management
  // ═══════════════════════════════════════

  Future<void> changeServer(int newIndex) async {
    if (newIndex == _currentServerIndex ||
        newIndex >= _availableServers.length) {
      return;
    }

    final currentPos = _currentPosition;
    await _loadServer(newIndex);

    // Restaurar posición
    if (_videoController != null) {
      await _videoController!.seekTo(currentPos);
      await _videoController!.play();
    }
  }

  // ═══════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════

  Future<void> _disposeVideoController() async {
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      try {
        await _videoController!.pause();
        await _videoController!.dispose();
      } catch (e) {
        _localDebugPrint('⚠️ Error disposing controller: $e');
      }
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _localDebugPrint('🗑️ Disposing VodPlayerWidget');
    _isDisposed = true;

    _saveProgress();

    WidgetsBinding.instance.removeObserver(this);

    _progressSaveTimer?.cancel();
    _orientationMonitor?.cancel();
    _fadeController.dispose();

    _disposeVideoController();

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
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
          brightness: Brightness.dark,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    return _buildPlayer();
  }

  Widget _buildLoading() {
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
              'Cargando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _availableServers.isNotEmpty
                  ? 'Servidor ${_currentServerIndex + 1}/${_availableServers.length}'
                  : '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
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
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  _currentServerIndex = 0;
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

  Widget _buildPlayer() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: _videoController != null &&
                      _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : Container(color: Colors.black),
            ),
          ),
          VodPlayerControls(
            controller: _videoController,
            contentTitle: widget.content.title,
            episodeTitle: widget.episode?.displayTitle,
            currentPosition: _currentPosition,
            duration: _duration,
            isPlaying: _isPlaying,
            isBuffering: _isBuffering,
            isFullScreen: _isFullScreen,
            availableServers: _availableServers,
            currentServerIndex: _currentServerIndex,
            onPlayPause: _togglePlayPause,
            onSeek: _seekTo,
            onSeekRelative: _seekRelative,
            onFullScreenToggle: _toggleFullScreen,
            onServerChange: changeServer,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

void _localDebugPrint(String message) {
  if (kDebugMode) {
    debugPrint('[VodPlayer] $message');
  }
}
