import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/exo_player_widget.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:pivote/features/video/presentation/widgets/stream_url_resolver.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

// ════════════════════════════════════════════════════════════════════════════
// Pivote VideoPlayerWidget — Native Media3 ExoPlayer Engine (Clean & Fast)
// ════════════════════════════════════════════════════════════════════════════

class VideoPlayerWidget extends StatefulWidget {
  final Channel channel;
  final Widget Function(
    BuildContext context,
    PivotePlayerController controller,
    bool isFullScreen,
    VoidCallback toggleFullScreen,
  )? controlsBuilder;

  const VideoPlayerWidget({
    super.key,
    required this.channel,
    this.controlsBuilder,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  late final PivotePlayerController _controller;

  /// Key constante para que el AndroidView nativo JAMÁS se desmonte ni recree
  /// al cambiar entre pantalla completa, retrato o modos de relación de aspecto.
  final GlobalKey _nativeViewKey = GlobalKey();

  // ── State ─────────────────────────────────────────────────────────────────
  StreamSource? _currentStream;
  bool _isFullScreen = false;
  AspectRatioType _aspectRatio = AspectRatioType.ratio16_9;
  int _serverIndex = 0;
  bool _disposed = false;
  bool _allServersFailed = false;
  bool _isFailoverInProgress = false;

  Timer? _orientationTimer;
  Timer? _serverTimeout;

  @override
  void initState() {
    super.initState();
    _disposed = false;
    _controller = PivotePlayerController();

    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onPlayerState);

    _playCurrentServer();
    _startOrientationMonitor();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id ||
        oldWidget.channel.name != widget.channel.name) {
      _serverIndex = 0;
      _allServersFailed = false;
      _isFailoverInProgress = false;
      _playCurrentServer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    // IMPORTANTE: Solo pausar en `paused` o `hidden` (cuando la app va a segundo plano real).
    // NUNCA pausar en `inactive`, porque Android dispara `inactive` durante el giro de
    // orientación (entrar/salir de pantalla completa) o al bajar la barra de estado.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_allServersFailed) {
        _controller.play();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _orientationTimer?.cancel();
    _serverTimeout?.cancel();
    _controller.removeListener(_onPlayerState);
    _controller.dispose();
    super.dispose();
  }

  void _onPlayerState() {
    if (_disposed || !mounted) return;

    if (_controller.firstFrameRendered ||
        _controller.isReady ||
        _controller.isPlaying) {
      _allServersFailed = false;
      _isFailoverInProgress = false;
      _serverTimeout?.cancel();
    }

    if (_controller.hasError && !_isFailoverInProgress) {
      _handlePlaybackError();
      return;
    }

    setState(() {});
  }

  void _handlePlaybackError() {
    if (_isFailoverInProgress || _disposed || !mounted) return;
    _isFailoverInProgress = true;
    _serverTimeout?.cancel();
    debugPrint(
        '⚠️ Error en servidor ${_serverIndex + 1}/${widget.channel.streamUrl.length}: ${_controller.errorMessage} (${_controller.errorCode})');
    _nextServer();
  }

  void _nextServer() {
    if (_disposed || !mounted) return;
    if (_serverIndex + 1 < widget.channel.streamUrl.length) {
      _serverIndex++;
      debugPrint(
          '➡️ Conmutando automáticamente al servidor ${_serverIndex + 1}/${widget.channel.streamUrl.length}...');
      _playCurrentServer();
    } else {
      debugPrint('❌ Se agotaron todos los servidores del canal.');
      setState(() {
        _isFailoverInProgress = false;
        _allServersFailed = true;
      });
    }
  }

  Future<void> _playCurrentServer() async {
    if (_disposed || widget.channel.streamUrl.isEmpty) return;

    if (_serverIndex >= widget.channel.streamUrl.length) {
      _serverIndex = 0;
    }

    _allServersFailed = false;
    _isFailoverInProgress = false;
    _currentStream = widget.channel.streamUrl[_serverIndex];
    String url = _currentStream!.url.trim();
    final Map<String, String> headers = {
      if (_currentStream!.headers != null) ..._currentStream!.headers!,
    };

    _serverTimeout?.cancel();
    // Timeout ágil (9 segundos) para saltar automáticamente al siguiente servidor si no responde
    _serverTimeout = Timer(const Duration(seconds: 9), () {
      if (!_disposed &&
          mounted &&
          !_controller.isReady &&
          !_controller.firstFrameRendered &&
          !_controller.isPlaying) {
        debugPrint(
            '⏱️ Timeout en servidor ${_serverIndex + 1} — cambiando automáticamente al siguiente...');
        _nextServer();
      }
    });

    // Si es una página PHP / Web sin extensión directa ni DRM, resolver a M3U8 primero
    if (!_currentStream!.hasDrm &&
        !url.toLowerCase().contains('.mpd') &&
        !url.toLowerCase().contains('.m3u8')) {
      try {
        final resolved = await StreamUrlResolver.resolve(url);
        if (_disposed) return;
        if (resolved.url.isNotEmpty) {
          url = resolved.url;
          if (resolved.referer != null && !headers.containsKey('Referer')) {
            headers['Referer'] = resolved.referer!;
          }
        }
      } catch (_) {}
    }

    final clearkeys = _currentStream!.effectiveClearkeys;
    final drmLicenseUri =
        _currentStream!.effectiveDrmLicenseUri ?? _currentStream!.drmLicenseUri;
    final isWidevine =
        _currentStream!.drmLicenseUri?.contains('widevine') == true;
    final drmType = isWidevine
        ? 'WIDEVINE'
        : (_currentStream!.hasDrm ||
                (drmLicenseUri != null && drmLicenseUri.isNotEmpty)
            ? 'CLEARKEY'
            : null);

    debugPrint(
        '▶️ Preparando servidor ${_serverIndex + 1}/${widget.channel.streamUrl.length} (DRM: $drmType): $url');

    await _controller.prepare(
      url: url,
      type: widget.channel.type,
      channelName: widget.channel.name,
      icono: widget.channel.logoUrl.isNotEmpty
          ? widget.channel.logoUrl.first
          : null,
      headers: headers,
      clearkeys: clearkeys,
      k1: _currentStream!.k1,
      k2: _currentStream!.k2,
      drmType: drmType,
      drmLicenseUri: drmLicenseUri,
      widevineLicenseUrl: isWidevine ? _currentStream!.drmLicenseUri : null,
    );
  }

  List<ServerInfo> _buildServerInfoList() {
    final list = <ServerInfo>[];
    for (int i = 0; i < widget.channel.streamUrl.length; i++) {
      final s = widget.channel.streamUrl[i];
      final rawLabel = s.label?.trim() ?? '';
      final label = rawLabel.isNotEmpty ? rawLabel : 'Opción ${i + 1}';
      final ServerType type = s.isDash
          ? ServerType.dash
          : (s.isHls ? ServerType.hls : ServerType.unknown);
      list.add(ServerInfo(index: i, label: label, type: type));
    }
    return list;
  }

  // ── Fullscreen & Aspect Ratio ─────────────────────────────────────────────

  void _startOrientationMonitor() {
    _orientationTimer?.cancel();
    _orientationTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (_disposed || !mounted) return;
      final landscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      if (landscape != _isFullScreen) {
        setState(() => _isFullScreen = landscape);
      }
    });
  }

  void _toggleFullScreen() {
    final targetFullScreen = !_isFullScreen;
    setState(() {
      _isFullScreen = targetFullScreen;
    });

    if (targetFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _changeAspectRatio() {
    setState(() {
      _aspectRatio = _aspectRatio.next;
    });

    if (_aspectRatio == AspectRatioType.stretch) {
      _controller.setResizeMode('stretch');
    } else {
      _controller.setResizeMode('fit');
    }
  }

  void _toggleMute() {
    _controller.toggleMute();
  }

  // ── UI Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isVideoVisible = _controller.firstFrameRendered ||
        _controller.isReady ||
        _controller.isPlaying;

    // IMPORTANTE: Mantener SIEMPRE la misma estructura de árbol de widgets tanto en
    // retrato como en pantalla completa para que Flutter jamás desmonte el PlatformView
    // nativo ni detenga la reproducción de video al rotar la pantalla.
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullScreen) {
          _toggleFullScreen();
        }
      },
      child: ClipRRect(
        borderRadius:
            _isFullScreen ? BorderRadius.zero : BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Capa de Video Nativo (Con GlobalKey fijo para preservar el surface)
              Positioned.fill(
                child: PivotePlayerView(
                  key: _nativeViewKey,
                  controller: _controller,
                ),
              ),

              // 2. Loader limpio inicial (SOLO mientras conecta por primera vez)
              if (!isVideoVisible && !_allServersFailed)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: PivoteLoader(size: 44, strokeWidth: 4),
                  ),
                ),

              // 3. Pantalla de Error si todos los servidores fallaron
              if (_allServersFailed) _buildErrorOverlay(),

              // 4. Controles personalizados de Video
              if (!_allServersFailed)
                Positioned.fill(
                  child: widget.controlsBuilder != null
                      ? widget.controlsBuilder!(
                          context,
                          _controller,
                          _isFullScreen,
                          _toggleFullScreen,
                        )
                      : CustomVideoControls(
                          controller: _controller,
                          channelName: widget.channel.name,
                          onFullScreenToggle: _toggleFullScreen,
                          isFullScreen: _isFullScreen,
                          aspectRatioLabel: _aspectRatio.label,
                          onAspectRatioChange: _changeAspectRatio,
                          onMuteToggle: _toggleMute,
                          isMuted: _controller.isMuted,
                          currentServer: _serverIndex + 1,
                          totalServers: widget.channel.streamUrl.length,
                          serverList: _buildServerInfoList(),
                          onServerSelect: (idx) {
                            if (idx == _serverIndex && !_allServersFailed) {
                              return;
                            }
                            _serverIndex = idx;
                            _allServersFailed = false;
                            _isFailoverInProgress = false;
                            _playCurrentServer();
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFFF5252),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Canal temporalmente no disponible',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _controller.userMessage ??
                    'No se pudo conectar con la señal del canal.',
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _serverIndex = 0;
                  _allServersFailed = false;
                  _isFailoverInProgress = false;
                  _playCurrentServer();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Volver a intentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
