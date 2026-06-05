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
  
  // Animation/Rotation states
  double _rotationTurns = -0.25; // start rotated 90 degrees
  double _scale = 0.9;
  double _opacity = 0.0;

  // Controls Visibility
  bool _showControls = false; // Start hidden while loading
  bool _hasShownInitialControls = false;
  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;

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

    // Start UI entry animations
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _rotationTurns = 0.0;
          _scale = 1.0;
          _opacity = 1.0;
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
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && _engine.state.status == MoviePlayerStatus.playing) {
        setState(() {
          _showControls = false;
        });
      }
    });
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
        final navigator = Navigator.of(context);
        // Stop playback immediately to kill audio and video
        await _engine.stop();
        // Restore Portrait Orientation & show system UI
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
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ListenableBuilder(
          listenable: _engine,
          builder: (context, _) {
            final state = _engine.state;

            return Stack(
              children: [
                // ── Entrance Animated Video Surface ──
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    child: AnimatedRotation(
                      turns: _rotationTurns,
                      duration: const Duration(milliseconds: 750),
                      curve: Curves.easeOutCubic,
                      child: AnimatedScale(
                        scale: _scale,
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          color: Colors.black,
                          child: Video(
                            controller: _engine.videoController,
                            controls: null, // Null is custom controls handled by us
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Custom Gesture-Based Controls Layer ──
                if (state.status != MoviePlayerStatus.loading && !state.hasError)
                  MovieControlsOverlay(
                    engine: _engine,
                    movie: widget.movie,
                    showControls: _showControls,
                    onToggleControls: _onToggleControls,
                    onUserInteraction: _onUserInteraction,
                  ),

                // ── Loading Screen Shimmer/Overlay ──
                if (state.status == MoviePlayerStatus.loading || state.status == MoviePlayerStatus.idle)
                  MovieLoadingOverlay(retryAttempt: state.retryAttempt),

                // ── Error Message Overlay ──
                if (state.hasError)
                  _buildErrorOverlay(state.errorMessage ?? 'Error desconocido de reproducción'),
              ],
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
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _engine.stop();
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      if (mounted) {
                        navigator.pop();
                      }
                    },
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
