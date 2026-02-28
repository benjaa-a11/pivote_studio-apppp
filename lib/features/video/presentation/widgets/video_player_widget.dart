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
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:pivote/features/video/presentation/widgets/pivo_pro_player.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional video player widget with support for:
/// - M3U8 (HLS) streams via native VideoPlayer
/// - MPD (DASH) / Iframe / External streams via WebView + PivoProPlayer
/// - Automatic intelligent server failover
/// - Advanced error recovery with exponential backoff
/// - Stream health monitoring and auto-healing
/// - Professional UX with smooth transitions
///
/// @version 4.0 (Professional Edition)

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
  UnifiedVideoController? _unifiedController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
  int _consecutiveErrors = 0;
  bool _useHtmlPlayer = false;

  static const int _maxRetries = 3;
  static const int _watchdogThreshold = 3;
  static const int _maxConsecutiveErrors = 5;

  // ═══════════════════════════════════════
  // Timers
  // ═══════════════════════════════════════
  Timer? _serverTimeoutTimer;
  Timer? _errorRecoveryTimer;
  Timer? _stateCheckTimer;
  Timer? _orientationCheckTimer;
  Timer? _loadingFailsafe;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    debugPrint('═══════════════════════════════════════');
    debugPrint('🎬 VideoPlayerWidget v4.0 Professional');
    debugPrint('📺 Canal: ${widget.channel.name}');
    debugPrint('🔢 Servidores: ${widget.channel.streamUrl.length}');
    debugPrint('═══════════════════════════════════════');

    _initializePlayer();
    _startWatchdog();
    _startOrientationMonitor();
    _startLoadingFailsafe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('⏸️ App en background - pausando');
        _unifiedController?.pause();
        break;
      case AppLifecycleState.resumed:
        debugPrint('▶️ App en foreground - resumiendo');
        _unifiedController?.play();
        _checkStreamHealth(); // Health check on resume
        break;
      default:
        break;
    }
  }

  // ═══════════════════════════════════════
  // Orientation Monitor
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

    if (!isLandscape && _isFullScreen) {
      _safeSetState(() => _isFullScreen = false);
    } else if (isLandscape && !_isFullScreen) {
      _safeSetState(() => _isFullScreen = true);
    }
  }

  // ═══════════════════════════════════════
  // Watchdog & Health Monitoring
  // ═══════════════════════════════════════

  void _startWatchdog() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      _checkStreamHealth();
    });
  }

  void _checkStreamHealth() {
    if (_useHtmlPlayer) return; // HTML player has its own monitoring

    if (_unifiedController != null) {
      final bufferHealth = _unifiedController!.bufferHealth;

      // Critical buffer health
      if (bufferHealth < 10 && _unifiedController!.isPlaying) {
        _stuckCounter++;
        debugPrint(
            '⚠️ Critical buffer: $bufferHealth% (${_stuckCounter * 5}s)');

        if (_stuckCounter >= _watchdogThreshold) {
          debugPrint('🔄 Watchdog: Stream stalled - recovering');
          _stuckCounter = 0;
          _handleStreamStall();
        }
      } else if (_unifiedController!.isPlaying &&
          !_unifiedController!.isBuffering) {
        _stuckCounter = 0;
        _consecutiveErrors = 0; // Reset error counter on healthy stream
      }

      // Monitor buffering time
      if (_unifiedController!.isBuffering) {
        _stuckCounter++;
        if (_stuckCounter >= _watchdogThreshold * 2) {
          debugPrint('⚠️ Extended buffering detected');
          _handleStreamStall();
        }
      }
    }
  }

  Future<void> _handleStreamStall() async {
    if (_useHtmlPlayer) return;

    _consecutiveErrors++;

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('❌ Demasiados errores consecutivos - failover forzado');
      await _handleServerFailure();
    } else {
      debugPrint('🔄 Intentando recuperar stream actual');
      _retryCount++;
      if (_retryCount <= _maxRetries) {
        await _initializeVideoPlayer(_currentStream!.url);
      } else {
        await _handleServerFailure();
      }
    }
  }

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(const Duration(seconds: 10), () {
      if (!_isDisposed && mounted && _isLoading) {
        debugPrint('⏱️ Loading failsafe triggered');
        _safeSetState(() => _isLoading = false);
      }
    });
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
      _consecutiveErrors = 0;
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
    _loadingFailsafe?.cancel();
    _startLoadingFailsafe();

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

    // Resolve URLs
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

    // Server timeout with progressive increase (faster)
    final timeoutDuration =
        Duration(seconds: 8 + (_serverAttempt * 2).clamp(0, 6));

    _serverTimeoutTimer = Timer(timeoutDuration, () {
      if (mounted &&
          !_isDisposed &&
          _isLoading &&
          _currentServerIndex < widget.channel.streamUrl.length - 1) {
        debugPrint('⏱️ Timeout servidor ${_currentServerIndex + 1}');
        _currentServerIndex++;
        _tryCurrentServer();
      }
    });

    // Strategy: HLS = Native, Others = WebView
    final isNative = url.toLowerCase().contains('.m3u8') ||
        url.toLowerCase().contains('m3u');

    if (isNative) {
      debugPrint('📱 Mode: Native Player (HLS)');
      _safeSetState(() => _useHtmlPlayer = false);
      await _initializeVideoPlayer(url);
    } else {
      debugPrint('🌐 Mode: WebView Player (DASH/Iframe)');
      _safeSetState(() {
        _useHtmlPlayer = true;
        _isLoading = false;
        _isInitializing = false;
      });
      _loadingFailsafe?.cancel();
    }
  }

  Future<String?> _resolveStreamUrl(String url) async {
    debugPrint('🔍 Resolviendo URL...');

    if (url.toLowerCase().endsWith('.m3u8')) {
      return url;
    }

    int resolveRetries = 0;
    const maxResolveRetries = 3;

    while (resolveRetries <= maxResolveRetries) {
      if (_isDisposed) return url;

      HttpClient? httpClient;
      try {
        final uri = Uri.parse(url);
        httpClient = HttpClient()
          ..connectionTimeout = Duration(seconds: 5 + (resolveRetries * 2))
          ..badCertificateCallback = (cert, host, port) => true;

        final request = await httpClient.getUrl(uri);
        request.headers.set(
          'User-Agent',
          'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36',
        );
        request.headers.set('Accept', '*/*');
        request.headers.set('Connection', 'keep-alive');

        final response = await request.close();

        if (response.statusCode >= 500 && response.statusCode <= 599) {
          throw Exception('Server error: ${response.statusCode}');
        }

        if (response.redirects.isNotEmpty) {
          final finalUrl = response.redirects.last.location.toString();

          if (finalUrl.toLowerCase().endsWith('.m3u8')) {
            return finalUrl;
          }

          final body = await response.transform(const Utf8Decoder()).join();
          if (body.contains('.m3u8')) {
            final m3u8Match =
                RegExp(r'https?://[^\s<>"]+\.m3u8').firstMatch(body);
            if (m3u8Match != null) {
              return m3u8Match.group(0)!;
            }
          }
          return finalUrl;
        }

        final location = response.headers.value('location');
        if (location != null) {
          return location;
        }

        if (response.statusCode == 200) {
          final contentType = response.headers.contentType;
          if (contentType?.mimeType == 'application/vnd.apple.mpegurl' ||
              contentType?.mimeType == 'application/x-mpegURL') {
            return url;
          }

          final body = await response.transform(const Utf8Decoder()).join();
          if (body.contains('.m3u8')) {
            final m3u8Match =
                RegExp(r'https?://[^\s<>"]+\.m3u8').firstMatch(body);
            if (m3u8Match != null) {
              return m3u8Match.group(0)!;
            }
          }
        }

        return url;
      } catch (e) {
        resolveRetries++;
        debugPrint(
            '⚠️ Intento $resolveRetries/$maxResolveRetries para resolver URL fallido: $e');

        if (resolveRetries <= maxResolveRetries) {
          // Exponential backoff
          final waitMs = 500 * pow(2, resolveRetries).toInt();
          await Future.delayed(Duration(milliseconds: waitMs));
        } else {
          debugPrint(
              '❌ Falla definitiva en resolución URL después de $maxResolveRetries intentos.');
          return url;
        }
      } finally {
        httpClient?.close(force: true);
      }
    }
    return url;
  }

  // ═══════════════════════════════════════
  // VideoPlayer (HLS) - Enhanced
  // ═══════════════════════════════════════

  Future<void> _initializeVideoPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 Inicializando VideoPlayer (HLS)');

      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
        'Referer': Uri.parse(url).origin,
      };

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        formatHint: VideoFormat.hls,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: headers,
      );

      _videoPlayerController!.addListener(_videoListener);

      // Initialize with timeout
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Timeout inicializando player');
        },
      );

      if (_isDisposed || !mounted) return;

      _unifiedController =
          UnifiedVideoController.fromVideoPlayer(_videoPlayerController!);

      _serverTimeoutTimer?.cancel();
      _loadingFailsafe?.cancel();

      await _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _videoPlayerController!.play();

      _fadeController.forward();

      _safeSetState(() {
        _isInitializing = false;
        _retryCount = 0;
        _stuckCounter = 0;
        _consecutiveErrors = 0;
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

    // Reset counters on healthy playback
    if (value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError) {
      _stuckCounter = 0;
      _consecutiveErrors = 0;

      if (_isLoading) {
        _loadingFailsafe?.cancel();
        _safeSetState(() => _isLoading = false);
      }
    }

    // Handle errors with debounce
    if (value.hasError && !_isLoading && !_isInitializing) {
      final errorDesc = value.errorDescription ?? 'Error desconocido';
      debugPrint('⚠️ Error VideoPlayer: $errorDesc');

      if (_errorRecoveryTimer?.isActive ?? false) return;

      _errorRecoveryTimer = Timer(const Duration(seconds: 1), () async {
        if (_isDisposed || !mounted) return;

        _consecutiveErrors++;
        _retryCount++;

        debugPrint(
            '🔄 Recuperación $_retryCount/$_maxRetries (Errores consecutivos: $_consecutiveErrors)');

        if (_consecutiveErrors >= _maxConsecutiveErrors) {
          debugPrint('❌ Demasiados errores - failover forzado');
          await _handleServerFailure();
        } else if (_retryCount <= _maxRetries) {
          await _initializeVideoPlayer(_currentStream!.url);
        } else {
          await _handleServerFailure();
        }
      });
    }

    _safeSetState(() {});
  }

  // ═══════════════════════════════════════
  // Error Handling & Server Failover
  // ═══════════════════════════════════════

  Future<void> _disposeExistingControllers() async {
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
        _loadingFailsafe?.cancel();
        _safeSetState(() {
          _isLoading = false;
          _error =
              'No se pudo conectar a ningún servidor.\n\nVerifica tu conexión e intenta nuevamente.';
          _isInitializing = false;
        });
      }
    }
  }

  Duration _backoffDurationForAttempt(int attempt) {
    // Exponential backoff: 300ms, 600ms, 1.2s, 2.4s, max 4s
    final ms = min(4000, (300 * pow(2, attempt)).toInt());
    return Duration(milliseconds: ms);
  }

  // ═══════════════════════════════════════
  // UI Controls
  // ═══════════════════════════════════════

  void _toggleFullScreen() {
    if (_isDisposed) return;

    setState(() => _isFullScreen = !_isFullScreen);

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

    setState(() => _isMuted = !_isMuted);
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
    _loadingFailsafe?.cancel();
    _fadeController.dispose();

    _disposeExistingControllers();

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
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Video Layer
            Center(
              child: _useHtmlPlayer
                  ? PivoProPlayer(
                      url: _currentStream!.url,
                      channelName: widget.channel.name,
                      onRefresh: _handleServerFailure,
                      currentServer: _currentServerIndex + 1,
                      totalServers: widget.channel.streamUrl.length,
                    )
                  : AspectRatio(
                      aspectRatio: _getAspectRatio(),
                      child: (_videoPlayerController != null &&
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
                  onServerSelect: (idx) {
                    _currentServerIndex = idx;
                    _retryCount = 0;
                    _consecutiveErrors = 0;
                    _tryCurrentServer();
                  },
                ),
              ),

            // 5. Fade Animation
            if (!_useHtmlPlayer)
              IgnorePointer(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0)
                      .animate(_fadeAnimation),
                  child: Container(color: Colors.black),
                ),
              ),

            // 6. Loading Indicator (Only for Native Player) - Rendered on TOP
            if (!_useHtmlPlayer &&
                (_isLoading ||
                    (_unifiedController != null &&
                        _unifiedController!.isBuffering)))
              _buildLoadingWidget(),

            // 7. Error Message (Only for Native Player)
            if (!_useHtmlPlayer && _error != null && !_isLoading)
              _buildErrorWidget(_error!),
          ],
        ),
      ),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Widget _buildLoadingWidget() {
    final isBuffering = !_isLoading &&
        _unifiedController != null &&
        _unifiedController!.isBuffering;

    String message = 'Conectando...';
    if (isBuffering) {
      message = 'Cargando...';
    } else if (_retryCount > 0) {
      message = 'Reintentando...';
    }

    return VideoLoadingWidget(
      isBuffering: isBuffering,
      message: message,
      serverInfo:
          '${_currentServerIndex + 1}/${widget.channel.streamUrl.length}',
      subMessage: _retryCount > 0 ? 'Intento $_retryCount/$_maxRetries' : null,
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
                size: 56,
              ),
              const SizedBox(height: 24),
              Text(
                errorMessage,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}',
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  _currentServerIndex = 0;
                  _consecutiveErrors = 0;
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
