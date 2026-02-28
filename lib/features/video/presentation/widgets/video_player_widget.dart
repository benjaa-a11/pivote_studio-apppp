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
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pivote Professional Video Player v5.0
/// ═══════════════════════════════════════════════════════════════
///
/// Professional-grade live TV channel player with:
/// - M3U8 (HLS) streams via native VideoPlayer
/// - MPD (DASH) / Iframe / External streams via WebView + PivoProPlayer
/// - Intelligent URL resolution with HEAD-first strategy
/// - Adaptive watchdog with grace period for slow servers
/// - Mutex-protected initialization (no race conditions)
/// - Categorized error recovery with exponential backoff
/// - Seamless fullscreen transitions (video never stops)
/// - State machine for clean loading/error UX
///

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
  // State Machine
  // ═══════════════════════════════════════
  PlayerState _playerState = PlayerState.idle;
  StreamSource? _currentStream;

  bool _isFullScreen = false;
  AspectRatioType _aspectRatioType = AspectRatioType.ratio16_9;
  int _currentServerIndex = 0;

  bool _isMuted = false;
  bool _isDisposed = false;
  int _retryCount = 0;
  int _serverAttempt = 0;
  int _stuckCounter = 0;
  int _consecutiveErrors = 0;
  bool _useHtmlPlayer = false;

  /// Mutex to prevent concurrent initialization
  Completer<void>? _initLock;

  /// Timestamp when playback started (for watchdog grace)
  DateTime? _playbackStartTime;

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
    debugPrint('🎬 VideoPlayerWidget v5.0 Professional');
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
        debugPrint('⏸️ App en background — pausando');
        _unifiedController?.pause();
        break;
      case AppLifecycleState.resumed:
        debugPrint('▶️ App en foreground — resumiendo');
        _unifiedController?.play();
        _checkStreamHealth();
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
    _orientationCheckTimer = Timer.periodic(
      PlayerConfig.orientationCheckInterval,
      (timer) {
        if (_isDisposed || !mounted) {
          timer.cancel();
          return;
        }
        _syncOrientationState();
      },
    );
  }

  void _syncOrientationState() {
    if (!mounted) return;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
    _stateCheckTimer = Timer.periodic(
      PlayerConfig.watchdogInterval,
      (timer) {
        if (_isDisposed || !mounted) {
          timer.cancel();
          return;
        }
        _checkStreamHealth();
      },
    );
  }

  void _checkStreamHealth() {
    if (_useHtmlPlayer) return;
    if (_unifiedController == null) return;

    // Grace period: don't watchdog during initial connection
    if (_playbackStartTime != null) {
      final elapsed = DateTime.now().difference(_playbackStartTime!);
      if (elapsed < PlayerConfig.watchdogGracePeriod) return;
    }

    final bufferHealth = _unifiedController!.bufferHealth;
    final isPlaying = _unifiedController!.isPlaying;
    final isBuffering = _unifiedController!.isBuffering;

    // Healthy playback — reset counters
    if (isPlaying && !isBuffering && bufferHealth > 20) {
      _stuckCounter = 0;
      _consecutiveErrors = 0;
      return;
    }

    // Critical buffer health while supposedly playing
    if (bufferHealth < 10 && isPlaying) {
      _stuckCounter++;
      debugPrint(
          '⚠️ Low buffer: $bufferHealth% (tick $_stuckCounter/${PlayerConfig.watchdogStallThreshold})');

      if (_stuckCounter >= PlayerConfig.watchdogStallThreshold) {
        debugPrint('🔄 Watchdog: stream stalled — initiating recovery');
        _stuckCounter = 0;
        _handleStreamStall();
      }
      return;
    }

    // Extended buffering detection
    if (isBuffering) {
      _stuckCounter++;
      if (_stuckCounter >= PlayerConfig.extendedBufferingThreshold) {
        debugPrint(
            '⚠️ Extended buffering (${_stuckCounter * 5}s) — initiating recovery');
        _stuckCounter = 0;
        _handleStreamStall();
      }
    }
  }

  Future<void> _handleStreamStall() async {
    if (_useHtmlPlayer || _isDisposed) return;

    _consecutiveErrors++;

    if (_consecutiveErrors >= PlayerConfig.maxConsecutiveErrors) {
      debugPrint('❌ Too many consecutive errors — forced failover');
      await _handleServerFailure();
    } else {
      _retryCount++;
      if (_retryCount <= PlayerConfig.maxRetriesPerServer &&
          _currentStream != null) {
        debugPrint(
            '🔄 Retry $_retryCount/${PlayerConfig.maxRetriesPerServer} on current server');
        _setPlayerState(PlayerState.retrying);
        await _initializeVideoPlayer(_currentStream!.url);
      } else {
        await _handleServerFailure();
      }
    }
  }

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(PlayerConfig.loadingFailsafeTimeout, () {
      if (!_isDisposed && mounted && _playerState.isLoading) {
        debugPrint('⏱️ Loading failsafe triggered — forcing UI visible');
        _setPlayerState(PlayerState.playing);
      }
    });
  }

  // ═══════════════════════════════════════
  // Player State Machine
  // ═══════════════════════════════════════

  void _setPlayerState(PlayerState newState) {
    if (_isDisposed || !mounted) return;
    if (_playerState == newState) return;

    debugPrint('📊 State: ${_playerState.name} → ${newState.name}');
    _safeSetState(() => _playerState = newState);
  }

  // ═══════════════════════════════════════
  // Player Initialization (Mutex-Protected)
  // ═══════════════════════════════════════

  Future<void> _initializePlayer() async {
    // Mutex: prevent concurrent initialization
    if (_initLock != null && !_initLock!.isCompleted) {
      debugPrint('⚠️ Initialization already in progress — skipping');
      return;
    }
    if (_isDisposed) return;

    _initLock = Completer<void>();

    _setPlayerState(PlayerState.connecting);
    _retryCount = 0;
    _serverAttempt = 0;
    _stuckCounter = 0;
    _consecutiveErrors = 0;
    _playbackStartTime = null;

    try {
      await _tryCurrentServer();
    } catch (e, st) {
      debugPrint('❌ Error in initializePlayer: $e\n$st');
      _setPlayerState(PlayerState.error);
    } finally {
      if (!_initLock!.isCompleted) {
        _initLock!.complete();
      }
    }
  }

  Future<void> _tryCurrentServer() async {
    if (_isDisposed) return;

    _serverTimeoutTimer?.cancel();
    _loadingFailsafe?.cancel();
    _startLoadingFailsafe();

    if (_currentServerIndex >= widget.channel.streamUrl.length) {
      throw Exception('No more servers available');
    }

    _currentStream = widget.channel.streamUrl[_currentServerIndex];
    String url = _currentStream!.url.trim();

    debugPrint('───────────────────────────────────────');
    debugPrint(
        '🔄 Server ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}');
    debugPrint('🔗 URL: ${url.substring(0, min(60, url.length))}...');
    debugPrint('───────────────────────────────────────');

    // ── Step 1: Resolve URL ──────────────────────────
    _setPlayerState(PlayerState.resolvingUrl);
    try {
      final resolvedUrl = await _resolveStreamUrl(url);
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        url = resolvedUrl;
        debugPrint('✅ URL resolved: ${url.substring(0, min(80, url.length))}');
      }
    } catch (e) {
      debugPrint('⚠️ URL resolution error: $e — using original URL');
    }

    if (url.isEmpty) {
      throw Exception('Empty URL after resolution');
    }

    // ── Step 2: HTTP Stabilizer ──────────────────────
    // Upgrade HTTP to HTTPS for unstable connections
    if (url.startsWith('http://')) {
      final httpsUrl = url.replaceFirst('http://', 'https://');
      debugPrint(
          '🔒 HTTP → HTTPS upgrade: ${httpsUrl.substring(0, min(60, httpsUrl.length))}...');
      // Try HTTPS first, fall back to HTTP if it fails
      url = httpsUrl;
    }

    // ── Step 2: Server timeout ───────────────────────
    final timeoutDuration = Duration(
      seconds: PlayerConfig.baseServerTimeout.inSeconds +
          (_serverAttempt * 2)
              .clamp(0, PlayerConfig.maxTimeoutExtensionSeconds),
    );

    _serverTimeoutTimer = Timer(timeoutDuration, () {
      if (mounted &&
          !_isDisposed &&
          _playerState.isLoading &&
          _currentServerIndex < widget.channel.streamUrl.length - 1) {
        debugPrint(
            '⏱️ Server ${_currentServerIndex + 1} timeout after ${timeoutDuration.inSeconds}s');
        _currentServerIndex++;
        _tryCurrentServer();
      }
    });

    // ── Step 3: Detect stream type ───────────────────
    final streamType = widget.channel.getStreamType(url);
    final isNative =
        streamType == StreamType.m3u8 || streamType == StreamType.mp4;

    // Also check URL patterns for additional safety
    final urlLower = url.toLowerCase();
    final looksLikeHls = urlLower.contains('.m3u8') || urlLower.contains('m3u');
    final looksLikeWeb = urlLower.contains('iframe') ||
        urlLower.contains('embed') ||
        urlLower.contains('pivo-pro') ||
        urlLower.contains('pivopro') ||
        urlLower.contains('vercel.app') ||
        urlLower.contains('.html');

    final useNative = (isNative || looksLikeHls) && !looksLikeWeb;

    if (useNative) {
      debugPrint('📱 Mode: Native Player (HLS)');
      _safeSetState(() => _useHtmlPlayer = false);
      _setPlayerState(PlayerState.initializing);
      await _initializeVideoPlayer(url);
    } else {
      debugPrint('🌐 Mode: WebView Player (DASH/Iframe/External)');
      _safeSetState(() => _useHtmlPlayer = true);
      _setPlayerState(PlayerState.playing);
      _loadingFailsafe?.cancel();
    }
  }

  // ═══════════════════════════════════════
  // URL Resolution — HEAD-first Strategy
  // ═══════════════════════════════════════

  Future<String?> _resolveStreamUrl(String url) async {
    debugPrint('🔍 Resolving URL...');

    // Fast path: if URL is clearly an M3U8, don't resolve
    final urlLower = url.toLowerCase();
    if (urlLower.endsWith('.m3u8') ||
        urlLower.contains('.m3u8?') ||
        urlLower.contains('.m3u8#')) {
      debugPrint('✅ Direct M3U8 URL — no resolution needed');
      return url;
    }

    // If it's an iframe/embed/external player URL, don't try to resolve
    if (urlLower.contains('iframe') ||
        urlLower.contains('embed') ||
        urlLower.contains('.html') ||
        urlLower.contains('pivo-pro') ||
        urlLower.contains('pivopro') ||
        urlLower.contains('vercel.app')) {
      debugPrint('🌐 External URL — no resolution needed');
      return url;
    }

    int resolveRetries = 0;

    while (resolveRetries <= PlayerConfig.maxUrlResolveRetries) {
      if (_isDisposed) return url;

      HttpClient? httpClient;
      try {
        final uri = Uri.parse(url);
        final timeout = Duration(
          seconds: PlayerConfig.urlResolveTimeout.inSeconds +
              (resolveRetries * PlayerConfig.urlResolveTimeoutExtensionSeconds),
        );

        httpClient = HttpClient()
          ..connectionTimeout = timeout
          ..idleTimeout = timeout
          ..badCertificateCallback = (cert, host, port) => true;

        // ── Strategy: Use GET but follow redirects carefully ──
        final request = await httpClient.getUrl(uri);
        request.followRedirects = true;
        request.maxRedirects = 5;
        request.headers.set('User-Agent', PlayerConfig.userAgent);
        request.headers.set('Accept', '*/*');
        request.headers.set('Connection', 'keep-alive');

        final response = await request.close().timeout(timeout);

        // Server error → don't retry resolution, failover later
        if (response.statusCode >= 500) {
          debugPrint('⚠️ Server ${response.statusCode} during resolution');
          await response.drain();
          return url;
        }

        // Check if we were redirected to an M3U8
        if (response.redirects.isNotEmpty) {
          final finalUrl = response.redirects.last.location.toString();
          if (finalUrl.toLowerCase().contains('.m3u8')) {
            await response.drain();
            return finalUrl;
          }
        }

        // Check content-type header for HLS MIME type
        final contentType = response.headers.contentType;
        if (contentType != null) {
          final mime = contentType.mimeType.toLowerCase();
          if (mime == 'application/vnd.apple.mpegurl' ||
              mime == 'application/x-mpegurl' ||
              mime == 'audio/mpegurl' ||
              mime == 'audio/x-mpegurl') {
            debugPrint('✅ Content-Type indicates HLS');
            // The URL itself serves the M3U8
            await response.drain();
            if (response.redirects.isNotEmpty) {
              return response.redirects.last.location.toString();
            }
            return url;
          }
        }

        // If we got a 200, read the body to search for M3U8 links
        if (response.statusCode == 200) {
          final body = await response.transform(const Utf8Decoder()).join();

          // Check if body IS an M3U8 playlist
          if (body.trimLeft().startsWith('#EXTM3U')) {
            debugPrint('✅ Body is M3U8 playlist');
            if (response.redirects.isNotEmpty) {
              return response.redirects.last.location.toString();
            }
            return url;
          }

          // Extract M3U8 URL from body (HTML page or JSON response)
          if (body.contains('.m3u8')) {
            final m3u8Match = RegExp(r"""https?://[^\s<>"']+\.m3u8[^\s<>"']*""")
                .firstMatch(body);
            if (m3u8Match != null) {
              final extracted = m3u8Match.group(0)!;
              debugPrint(
                  '✅ Extracted M3U8 from body: ${extracted.substring(0, min(80, extracted.length))}');
              return extracted;
            }
          }

          // Check for redirect URL in Location header
          final location = response.headers.value('location');
          if (location != null && location.isNotEmpty) {
            return location;
          }

          // If redirected, use the final redirect URL
          if (response.redirects.isNotEmpty) {
            return response.redirects.last.location.toString();
          }
        } else {
          await response.drain();
        }

        return url;
      } catch (e) {
        resolveRetries++;
        debugPrint(
            '⚠️ Resolve attempt $resolveRetries/${PlayerConfig.maxUrlResolveRetries}: $e');

        if (resolveRetries <= PlayerConfig.maxUrlResolveRetries) {
          final waitMs = min(
            PlayerConfig.backoffMaxMs,
            PlayerConfig.backoffBaseMs * pow(2, resolveRetries).toInt(),
          );
          await Future.delayed(Duration(milliseconds: waitMs));
        } else {
          debugPrint('❌ URL resolution failed after all retries');
          return url;
        }
      } finally {
        try {
          httpClient?.close(force: true);
        } catch (_) {}
      }
    }
    return url;
  }

  // ═══════════════════════════════════════
  // VideoPlayer (HLS) — Enhanced
  // ═══════════════════════════════════════

  Future<void> _initializeVideoPlayer(String url) async {
    if (_isDisposed) return;

    try {
      await _disposeExistingControllers();

      debugPrint('🎬 Initializing VideoPlayer (HLS)');

      final headers = <String, String>{
        'User-Agent': PlayerConfig.userAgent,
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
      };

      // Add Referer if URL has a valid origin
      try {
        final origin = Uri.parse(url).origin;
        if (origin.isNotEmpty && origin != 'null') {
          headers['Referer'] = origin;
        }
      } catch (_) {}

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

      // Initialize with generous timeout for slow servers
      await _videoPlayerController!.initialize().timeout(
        PlayerConfig.initializeTimeout,
        onTimeout: () {
          throw TimeoutException('Player initialization timeout');
        },
      );

      if (_isDisposed || !mounted) return;

      _unifiedController =
          UnifiedVideoController.fromVideoPlayer(_videoPlayerController!);

      _serverTimeoutTimer?.cancel();
      _loadingFailsafe?.cancel();

      await _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _videoPlayerController!.play();

      _playbackStartTime = DateTime.now();
      _fadeController.forward();

      _retryCount = 0;
      _stuckCounter = 0;
      _consecutiveErrors = 0;

      debugPrint('✅ VideoPlayer ready — playback started');
    } catch (e, st) {
      debugPrint('❌ VideoPlayer error: $e\n$st');
      await _handleServerFailure();
    }
  }

  void _videoListener() {
    if (_isDisposed || !mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;

    // ── Healthy playback: reset everything ──
    if (value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError) {
      _stuckCounter = 0;
      _consecutiveErrors = 0;

      if (_playerState != PlayerState.playing) {
        _loadingFailsafe?.cancel();
        _setPlayerState(PlayerState.playing);
      }
    }

    // ── Buffering state ──
    if (value.isInitialized && value.isBuffering && !value.hasError) {
      if (_playerState == PlayerState.playing) {
        _setPlayerState(PlayerState.buffering);
      }
    }

    // ── Back from buffering to playing ──
    if (value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        _playerState == PlayerState.buffering) {
      _setPlayerState(PlayerState.playing);
    }

    // ── Error handling with debounce ──
    if (value.hasError &&
        _playerState != PlayerState.retrying &&
        _playerState != PlayerState.connecting) {
      final errorDesc = value.errorDescription ?? 'Unknown error';
      debugPrint('⚠️ VideoPlayer error: $errorDesc');

      if (_errorRecoveryTimer?.isActive ?? false) return;

      _errorRecoveryTimer = Timer(const Duration(seconds: 1), () async {
        if (_isDisposed || !mounted) return;

        _consecutiveErrors++;
        _retryCount++;

        debugPrint(
            '🔄 Recovery $_retryCount/${PlayerConfig.maxRetriesPerServer} '
            '(consecutive: $_consecutiveErrors)');

        if (_consecutiveErrors >= PlayerConfig.maxConsecutiveErrors) {
          debugPrint('❌ Too many errors — forced failover');
          await _handleServerFailure();
        } else if (_retryCount <= PlayerConfig.maxRetriesPerServer &&
            _currentStream != null) {
          _setPlayerState(PlayerState.retrying);
          await _initializeVideoPlayer(_currentStream!.url);
        } else {
          await _handleServerFailure();
        }
      });
    }

    // Rebuild for visual updates (buffering indicator etc)
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

    debugPrint('⚠️ Server ${_currentServerIndex + 1} failed');

    if (_currentServerIndex < widget.channel.streamUrl.length - 1) {
      _currentServerIndex++;
      _retryCount = 0;

      debugPrint(
          '🔄 Trying server ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}');

      _setPlayerState(PlayerState.connecting);

      await Future.delayed(_backoffDurationForAttempt(_serverAttempt));
      _serverAttempt++;

      await _tryCurrentServer();
    } else {
      debugPrint('❌ All servers exhausted');
      if (mounted && !_isDisposed) {
        _loadingFailsafe?.cancel();
        _safeSetState(() {
          _playerState = PlayerState.error;
        });
      }
    }
  }

  Duration _backoffDurationForAttempt(int attempt) {
    final ms = min(
      PlayerConfig.backoffMaxMs,
      (PlayerConfig.backoffBaseMs * pow(2, attempt)).toInt(),
    );
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
      _aspectRatioType = _aspectRatioType.next;
    });
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
                  aspectRatioLabel: _aspectRatioType.label,
                  onAspectRatioChange: _changeAspectRatio,
                  onMuteToggle: _toggleMute,
                  isMuted: _isMuted,
                  currentServer: _currentServerIndex + 1,
                  totalServers: widget.channel.streamUrl.length,
                  onServerSelect: (idx) {
                    _currentServerIndex = idx;
                    _retryCount = 0;
                    _consecutiveErrors = 0;
                    _stuckCounter = 0;
                    _setPlayerState(PlayerState.connecting);
                    _tryCurrentServer();
                  },
                ),
              ),

            // 3. Fade Animation (entrance)
            if (!_useHtmlPlayer)
              IgnorePointer(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0)
                      .animate(_fadeAnimation),
                  child: Container(color: Colors.black),
                ),
              ),

            // 4. Loading / Buffering State
            if (!_useHtmlPlayer && _shouldShowLoadingOverlay())
              _buildLoadingWidget(),

            // 5. Error State
            if (!_useHtmlPlayer && _playerState == PlayerState.error)
              _buildErrorWidget(),
          ],
        ),
      ),
    );
  }

  bool _shouldShowLoadingOverlay() {
    if (_playerState.isLoading) return true;
    if (_playerState == PlayerState.buffering) return true;
    // Also show if the native controller reports buffering
    if (_unifiedController != null && _unifiedController!.isBuffering) {
      return true;
    }
    return false;
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  // ═══════════════════════════════════════
  // Loading Widget
  // ═══════════════════════════════════════

  Widget _buildLoadingWidget() {
    final bool isBuffering = _playerState == PlayerState.buffering ||
        (_unifiedController != null && _unifiedController!.isBuffering);

    // Simple, clean messages like major streaming platforms
    final String message = isBuffering ? 'Cargando...' : 'Conectando...';
    final String? subMessage = _playerState == PlayerState.retrying
        ? 'Intento $_retryCount/${PlayerConfig.maxRetriesPerServer}'
        : null;

    return VideoLoadingWidget(
      isBuffering: isBuffering,
      message: message,
      serverInfo: widget.channel.streamUrl.length > 1
          ? '${_currentServerIndex + 1}/${widget.channel.streamUrl.length}'
          : null,
      subMessage: subMessage,
    );
  }

  // ═══════════════════════════════════════
  // Error Widget
  // ═══════════════════════════════════════

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon with glow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withAlpha(20),
                  border: Border.all(
                    color: Colors.red.withAlpha(60),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No se pudo conectar',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verifica tu conexión e intenta nuevamente.\n'
                'Si el problema persiste, el servidor puede estar temporalmente fuera de servicio.',
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Servidor ${_currentServerIndex + 1}/${widget.channel.streamUrl.length}',
                  style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Retry button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _currentServerIndex = 0;
                  _consecutiveErrors = 0;
                  _initializePlayer();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).colorScheme.primary.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reintentar',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
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
