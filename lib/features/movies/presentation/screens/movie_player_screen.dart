import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_video_engine.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_controls_overlay.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_loading_overlay.dart';
import 'package:pivote/features/movies/presentation/providers/movies_provider.dart';

class MoviePlayerScreen extends StatefulWidget {
  final Movie movie;
  final Duration startPosition;

  const MoviePlayerScreen({
    super.key,
    required this.movie,
    this.startPosition = Duration.zero,
  });

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen>
    with SingleTickerProviderStateMixin {
  late MovieVideoEngine _engine;
  
  // Animation states
  bool _isReady = false;

  // Controls Visibility
  bool _showControls = false; // Start hidden while loading
  bool _hasShownInitialControls = false;
  bool _isDragging = false;
  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;

  // True once the first frame has ever been shown. After that, buffering
  // never blacks out the screen again — only a small spinner appears.
  bool _hasStartedPlayback = false;

  // Guards against double-invocation of the exit flow (e.g. rapid double tap
  // on the back button, or system-back racing with an on-screen tap).
  bool _isExiting = false;

  // Video fit mode: contain (default) -> cover (zoom) -> fill (stretch)
  BoxFit _videoFit = BoxFit.contain;

  void _cycleVideoFit() {
    setState(() {
      _videoFit = switch (_videoFit) {
        BoxFit.contain => BoxFit.cover,
        BoxFit.cover => BoxFit.fill,
        _ => BoxFit.contain,
      };
    });
  }

  @override
  void initState() {
    super.initState();

    // Lock to landscape & hide status bar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Enable Wake Lock
    WakelockPlus.enable();

    // Initialize Video Engine
    _engine = MovieVideoEngine();

    // Delay building the UI until orientation change completes (solid black screen)
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });

    // Start video loading
    _engine.load(widget.movie.streamUrl, startPosition: widget.startPosition);

    // Watch engine state changes
    _engine.addListener(_onEngineStateChange);

    _startProgressSaving();
  }

  void _onEngineStateChange() {
    if (!mounted) return;

    if (_engine.state.hasStartedPlayback && !_hasStartedPlayback) {
      setState(() {
        _hasStartedPlayback = true;
      });
    }

    // When playback starts, show controls briefly if we haven't shown them yet
    if (_engine.state.status == MoviePlayerStatus.playing && !_hasShownInitialControls) {
      _hasShownInitialControls = true;
      setState(() {
        _showControls = true;
      });
      _startHideControlsTimer();
    }

    // Automatically hide controls after movie starts playing
    if (_engine.state.status == MoviePlayerStatus.playing && _showControls && _hideControlsTimer == null) {
      _startHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_isDragging) {
      _hideControlsTimer = null;
      return;
    }
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls && _engine.state.status == MoviePlayerStatus.playing && !_isDragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onDragStart() {
    if (mounted) {
      setState(() {
        _isDragging = true;
      });
      _hideControlsTimer?.cancel();
      _hideControlsTimer = null;
    }
  }

  void _onDragEnd() {
    if (mounted) {
      setState(() {
        _isDragging = false;
      });
      _startHideControlsTimer();
    }
  }

  void _onToggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
      _hideControlsTimer = null;
    }
  }

  void _onUserInteraction() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _startHideControlsTimer();
  }

  /// Real network pre-buffer progress (0-99) shown on the cinematic loading
  /// screen, computed from how much media has actually been cached ahead of
  /// the playhead versus the target pre-buffer configured on the engine.
  /// Clamped below 100 so it never reads "100%" while still on this screen —
  /// once we truly reach playback, this overlay unmounts entirely.
  double? get _bufferPercent {
    final targetMs = (MovieEngineConfig.cacheSecs * 1000).round();
    if (targetMs <= 0) return null;
    final bufferedMs = _engine.state.buffered.inMilliseconds;
    if (bufferedMs <= 0) return 0;
    return (bufferedMs / targetMs * 100).clamp(0, 99).toDouble();
  }

  /// Single source of truth for leaving the player. ALWAYS stops the engine
  /// (killing video + audio) before popping the route, restores portrait
  /// orientation, and restores system UI. Every exit path (system back,
  /// on-screen back button, error screen) must funnel through this so audio
  /// never keeps playing after the screen is gone.
  Future<void> _exitPlayer() async {
    if (_isExiting || !mounted) return;
    _isExiting = true;

    final navigator = Navigator.of(context);
    await _engine.stop();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    if (mounted) {
      navigator.pop();
    }
  }

  void _startProgressSaving() {
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_engine.state.status == MoviePlayerStatus.playing) {
        _saveCurrentPosition();
      }
    });
  }

  void _saveCurrentPosition() {
    final pos = _engine.state.position;
    final dur = _engine.state.duration;
    
    // Don't save if position is too close to end (e.g. within last 30s) or duration is 0
    if (dur > Duration.zero && (dur - pos) > const Duration(seconds: 30)) {
      context.read<MoviesProvider>().savePlaybackPosition(widget.movie.id, pos, duration: dur);
    } else if (dur > Duration.zero && (dur - pos) <= const Duration(seconds: 30)) {
      context.read<MoviesProvider>().clearPlaybackPosition(widget.movie.id);
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    
    // Save final position before leaving
    if (_engine.state.status != MoviePlayerStatus.completed) {
      _saveCurrentPosition();
    } else {
      context.read<MoviesProvider>().clearPlaybackPosition(widget.movie.id);
    }

    _engine.removeListener(_onEngineStateChange);
    _engine.dispose();

    // Disable Wake Lock
    WakelockPlus.disable();

    // Restore Portrait Orientation & show system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _exitPlayer();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: !_isReady
            ? const SizedBox.shrink() // Solid black screen during transition
            : ListenableBuilder(
                listenable: _engine,
                builder: (context, _) {
                  final state = _engine.state;

                  return AnimatedOpacity(
                    opacity: _isReady ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Stack(
                      children: [
                        // ── Video Surface ──
                        Positioned.fill(
                          child: Container(
                            color: Colors.black,
                            child: Video(
                              controller: _engine.videoController,
                              controls: null, // Null is custom controls handled by us
                              fit: _videoFit,
                            ),
                          ),
                        ),

                        // ── Custom Gesture-Based Controls Layer ──
                        // ONLY rendered once the first frame has decoded and playback has started
                        if (_hasStartedPlayback &&
                            (state.status == MoviePlayerStatus.playing ||
                             state.status == MoviePlayerStatus.paused ||
                             state.status == MoviePlayerStatus.buffering ||
                             state.status == MoviePlayerStatus.completed) && !state.hasError)
                          MovieControlsOverlay(
                            engine: _engine,
                            movie: widget.movie,
                            showControls: _showControls,
                            onToggleControls: _onToggleControls,
                            onUserInteraction: _onUserInteraction,
                            onDragStart: _onDragStart,
                            onDragEnd: _onDragEnd,
                            onExit: _exitPlayer,
                            videoFit: _videoFit,
                            onCycleFit: _cycleVideoFit,
                          ),

                        // ── Cinematic Loading Screen (ONLY before first frame decoded) ──
                        if (!_hasStartedPlayback &&
                            !state.hasError &&
                            (state.status == MoviePlayerStatus.loading ||
                             state.status == MoviePlayerStatus.idle ||
                             state.status == MoviePlayerStatus.buffering))
                          MovieLoadingOverlay(
                            movie: widget.movie,
                            retryAttempt: state.retryAttempt,
                            bufferPercent: _bufferPercent,
                          ),

                        // ── Lightweight Buffering Spinner (video stays visible) ──
                        if (_hasStartedPlayback &&
                            state.status == MoviePlayerStatus.buffering &&
                            !state.hasError)
                          const MovieBufferingSpinner(),

                        // ── Error Message Overlay ──
                        if (state.hasError)
                          _buildErrorOverlay(state.errorMessage ?? 'Error desconocido de reproducción'),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildErrorOverlay(String message) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.darkDanger,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Ups! Algo salió mal',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Volver'),
                    onPressed: _exitPlayer,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkAccent,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reintentar'),
                    onPressed: () {
                      _engine.retry();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
