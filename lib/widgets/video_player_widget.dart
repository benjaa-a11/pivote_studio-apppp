import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'exoplayer_controller_simple.dart';
import 'exoplayer_view_simple.dart';

/// Widget de reproductor de video IPTV optimizado
/// Solo soporta M3U8/HLS - Sin DRM
class VideoPlayerWidget extends StatefulWidget {
  final Channel channel;
  final bool autoPlay;
  final bool showControls;
  final VoidCallback? onFullscreen;
  final Function(String)? onError;

  const VideoPlayerWidget({
    super.key,
    required this.channel,
    this.autoPlay = true,
    this.showControls = true,
    this.onFullscreen,
    this.onError,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  ExoPlayerController? _controller;

  // Estado del reproductor
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String? _errorMessage;

  // Servidor actual y fallbacks
  int _currentServerIndex = 0;
  List<String> _allServers = [];

  // Watchdog y retry
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Subscriptions
  StreamSubscription? _stateSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _stalledSubscription;

  @override
  void initState() {
    super.initState();
    _setupServers();
  }

  void _setupServers() {
    _allServers = widget.channel.streamUrl.map((s) => s.url).toList();
    debugPrint('📺 Servidores configurados: ${_allServers.length}');
  }

  Future<void> _onPlayerCreated(ExoPlayerController controller) async {
    _controller = controller;

    // Limpiar subscriptions previas
    await _cleanupSubscriptions();

    // Configurar listeners
    _stateSubscription = _controller!.onStateChange.listen(_onStateChanged);
    _playingSubscription =
        _controller!.onPlayingChange.listen(_onPlayingChanged);
    _errorSubscription = _controller!.onError.listen(_onPlayerError);
    _stalledSubscription =
        _controller!.onStreamStalled.listen(_onStreamStalled);

    // Inicializar con el primer servidor
    await _loadCurrentServer();
  }

  void _onStateChanged(PlayerState state) {
    if (!mounted) return;

    setState(() {
      _isBuffering = state == PlayerState.buffering;

      if (state == PlayerState.ready) {
        _isInitialized = true;
        _hasError = false;
        _errorMessage = null;
        _retryCount = 0; // Reset retry count on success
        debugPrint(
            '✅ Stream listo - Servidor ${_currentServerIndex + 1}/${_allServers.length}');
      } else if (state == PlayerState.ended) {
        debugPrint('🏁 Stream finalizado');
      }
    });
  }

  void _onPlayingChanged(bool isPlaying) {
    if (!mounted) return;
    setState(() {
      _isPlaying = isPlaying;
    });
  }

  void _onPlayerError(String error) {
    if (!mounted) return;

    debugPrint('❌ Error reproductor: $error');

    setState(() {
      _hasError = true;
      _errorMessage = error;
    });

    // Notificar al widget padre
    widget.onError?.call(error);

    // Intentar siguiente servidor automáticamente
    if (_currentServerIndex < _allServers.length - 1) {
      debugPrint('🔄 Cambiando a siguiente servidor automáticamente...');
      Future.delayed(const Duration(seconds: 1), _switchToNextServer);
    } else {
      // Ya probamos todos los servidores, intentar retry
      _scheduleRetry();
    }
  }

  void _onStreamStalled(dynamic _) {
    if (!mounted) return;

    debugPrint('🚨 WATCHDOG: Stream trabado > 15s');

    // Cambiar a siguiente servidor
    if (_currentServerIndex < _allServers.length - 1) {
      debugPrint('🔄 Cambiando servidor por stream trabado...');
      _switchToNextServer();
    } else {
      debugPrint('⚠️  No hay más servidores, intentando reload...');
      _reloadCurrentServer();
    }
  }

  Future<void> _loadCurrentServer() async {
    if (_controller == null || !mounted) return;

    final currentUrl = _allServers[_currentServerIndex];

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint(
        '🎬 Cargando servidor ${_currentServerIndex + 1}/${_allServers.length}');
    debugPrint(
        '📺 URL: ${currentUrl.substring(0, currentUrl.length > 80 ? 80 : currentUrl.length)}...');
    debugPrint('═══════════════════════════════════════════════════════');

    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await _controller!.initialize(currentUrl);

      if (widget.autoPlay) {
        await _controller!.play();
      }
    } catch (e) {
      debugPrint('❌ Error al cargar servidor: $e');
      _onPlayerError(e.toString());
    }
  }

  Future<void> _switchToNextServer() async {
    if (_currentServerIndex >= _allServers.length - 1) {
      debugPrint('⚠️  No hay más servidores disponibles');
      return;
    }

    _currentServerIndex++;
    await _loadCurrentServer();
  }

  Future<void> _reloadCurrentServer() async {
    debugPrint('🔄 Recargando servidor actual...');
    await _loadCurrentServer();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();

    if (_retryCount >= _maxRetries) {
      debugPrint('❌ Máximo de reintentos alcanzado');
      setState(() {
        _errorMessage = 'No se pudo conectar después de $_maxRetries intentos';
      });
      return;
    }

    _retryCount++;
    debugPrint(
        '🔄 Reintento $_retryCount/$_maxRetries en ${_retryDelay.inSeconds}s...');

    _retryTimer = Timer(_retryDelay, () {
      // Volver al primer servidor y reintentar
      _currentServerIndex = 0;
      _loadCurrentServer();
    });
  }

  Future<void> _cleanupSubscriptions() async {
    await _stateSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _stalledSubscription?.cancel();

    _stateSubscription = null;
    _playingSubscription = null;
    _errorSubscription = null;
    _stalledSubscription = null;
  }

  // Control manual de servidores
  Future<void> switchToServer(int index) async {
    if (index < 0 || index >= _allServers.length) return;
    if (index == _currentServerIndex) return;

    debugPrint('🔄 Cambio manual a servidor ${index + 1}');
    _currentServerIndex = index;
    _retryCount = 0; // Reset retry count
    await _loadCurrentServer();
  }

  // Controles del reproductor
  Future<void> play() async {
    await _controller?.play();
  }

  Future<void> pause() async {
    await _controller?.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          if (Platform.isAndroid)
            ExoPlayerView(
              onCreated: _onPlayerCreated,
            )
          else
            const Center(
              child: Text(
                'Solo disponible en Android',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Loading indicator
          if (_isBuffering && !_hasError)
            Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isInitialized ? 'Buffering...' : 'Cargando stream...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Servidor ${_currentServerIndex + 1}/${_allServers.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Error overlay
          if (_hasError)
            Container(
              color: Colors.black87,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error de Reproducción',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Error desconocido',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón reintentar
                          ElevatedButton.icon(
                            onPressed: _reloadCurrentServer,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),

                          // Botón siguiente servidor (si hay)
                          if (_currentServerIndex < _allServers.length - 1) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _switchToNextServer,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Siguiente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Mostrar todos los servidores si hay varios
                      if (_allServers.length > 1) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Servidores disponibles:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(_allServers.length, (index) {
                            final isCurrentServer =
                                index == _currentServerIndex;
                            return ChoiceChip(
                              label: Text('Servidor ${index + 1}'),
                              selected: isCurrentServer,
                              onSelected: (selected) {
                                if (selected && !isCurrentServer) {
                                  switchToServer(index);
                                }
                              },
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.grey[800],
                              labelStyle: TextStyle(
                                color: isCurrentServer
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Controles personalizados (opcional)
          if (widget.showControls && _isInitialized && !_hasError)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Play/Pause
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: togglePlayPause,
          ),

          const Spacer(),

          // Indicador de servidor
          if (_allServers.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.dns,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentServerIndex + 1}/${_allServers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 8),

          // Fullscreen
          if (widget.onFullscreen != null)
            IconButton(
              icon: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 32,
              ),
              onPressed: widget.onFullscreen,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🗑️  Disposing VideoPlayerWidget');
    _retryTimer?.cancel();
    _cleanupSubscriptions();
    _controller?.dispose();
    super.dispose();
  }
}

/// Versión simple sin controles
class SimpleVideoPlayer extends StatelessWidget {
  final Channel channel;

  const SimpleVideoPlayer({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(
      channel: channel,
      autoPlay: true,
      showControls: false,
    );
  }
}
