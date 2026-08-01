import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_video_engine.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_bottom_sheets.dart';
// Pivo Movie Player Controls


class MovieControlsOverlay extends StatefulWidget {
  final MovieVideoEngine engine;
  final Movie movie;
  final bool showControls;
  final VoidCallback onToggleControls;
  final VoidCallback onUserInteraction;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final Future<void> Function() onExit;
  final BoxFit videoFit;
  final VoidCallback onCycleFit;

  const MovieControlsOverlay({
    super.key,
    required this.engine,
    required this.movie,
    required this.showControls,
    required this.onToggleControls,
    required this.onUserInteraction,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onExit,
    required this.videoFit,
    required this.onCycleFit,
  });

  @override
  State<MovieControlsOverlay> createState() => _MovieControlsOverlayState();
}

class _MovieControlsOverlayState extends State<MovieControlsOverlay>
    with TickerProviderStateMixin {
  // Lock state
  bool _isLocked = false;

  // Double-tap cues
  bool _showLeftCue = false;
  bool _showRightCue = false;

  // Drag indicators (brightness & volume)
  bool _showBrightnessIndicator = false;
  double _brightnessLevel =
      1.0; // 0.0 to 1.0 (1.0 = fully bright/transparent, 0.0 = dark)
  Timer? _brightnessTimer;

  bool _showVolumeIndicator = false;
  Timer? _volumeTimer;

  // Horizontal drag / scrubbing
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;
  Duration _scrubStartPos = Duration.zero;
  Timer? _scrubTimer;

  // Manual single-tap vs double-tap disambiguation. We deliberately avoid
  // registering both `onTap` and `onDoubleTapDown` on the same
  // GestureDetector: Flutter's gesture arena then forces every single tap to
  // wait the full ~300ms double-tap timeout before firing, which is what
  // made the controls feel laggy/unprofessional. Handling it manually with
  // `onTapUp` lets us react immediately and only hold back the single-tap
  // action for a short, tunable window.
  Timer? _singleTapTimer;
  DateTime? _lastTapTime;
  Offset? _lastTapPos;
  static const Duration _doubleTapWindow = Duration(milliseconds: 260);
  static const double _doubleTapSlop = 60.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _brightnessTimer?.cancel();
    _volumeTimer?.cancel();
    _scrubTimer?.cancel();
    _singleTapTimer?.cancel();
    _fitTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints) {
    final now = DateTime.now();
    final pos = details.localPosition;

    final isSecondTap = _lastTapTime != null &&
        _lastTapPos != null &&
        now.difference(_lastTapTime!) < _doubleTapWindow &&
        (pos - _lastTapPos!).distance < _doubleTapSlop;

    if (isSecondTap) {
      // Second tap arrived in time: cancel the pending single-tap action
      // (toggle controls) and treat this as a double-tap seek instead.
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      _lastTapTime = null;
      _lastTapPos = null;
      _handleDoubleTap(pos, constraints);
      return;
    }

    // First tap: remember it and wait a short window for a possible second
    // tap. If none arrives, fire the single-tap action (toggle controls).
    _lastTapTime = now;
    _lastTapPos = pos;
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(_doubleTapWindow, () {
      _lastTapTime = null;
      _lastTapPos = null;
      if (!mounted) return;
      if (_isLocked) {
        widget.onUserInteraction();
      } else {
        HapticFeedback.lightImpact();
        widget.onToggleControls();
      }
    });
  }

  void _handleDoubleTap(Offset localPosition, BoxConstraints constraints) {
    if (_isLocked) {
      widget.onUserInteraction();
      return;
    }

    final double width = constraints.maxWidth;
    final double tapX = localPosition.dx;
    final bool isRight = tapX > (width / 2);

    HapticFeedback.lightImpact();
    widget.onUserInteraction();

    final currentPos = widget.engine.state.position;
    final totalDuration = widget.engine.state.duration;

    Duration targetPos;
    if (isRight) {
      setState(() => _showRightCue = true);
      Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showRightCue = false);
      });
      targetPos = currentPos + const Duration(seconds: 10);
      if (targetPos > totalDuration) targetPos = totalDuration;
    } else {
      setState(() => _showLeftCue = true);
      Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showLeftCue = false);
      });
      targetPos = currentPos - const Duration(seconds: 10);
      if (targetPos < Duration.zero) targetPos = Duration.zero;
    }

    widget.engine.seek(targetPos);
  }

  void _handleVerticalDragUpdate(
      DragUpdateDetails details, BoxConstraints constraints) {
    if (_isLocked) return;

    widget.onUserInteraction();
    final double height = constraints.maxHeight;
    final double width = constraints.maxWidth;
    final double deltaY = -details.primaryDelta!; // Upward drag = positive

    final double dragX = details.localPosition.dx;
    final bool isLeft = dragX < (width / 2);

    if (isLeft) {
      // BRIGHTNESS GESTURE (Left Side)
      setState(() {
        _showBrightnessIndicator = true;
        // Sensitivity factor 1.5x height
        _brightnessLevel =
            (_brightnessLevel + (deltaY / height) * 1.5).clamp(0.1, 1.0);
      });

      _brightnessTimer?.cancel();
      _brightnessTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showBrightnessIndicator = false);
      });
    } else {
      // VOLUME GESTURE (Right Side)
      final currentVol = widget.engine.state.volume;
      final newVol = (currentVol + (deltaY / height) * 1.5).clamp(0.0, 1.0);
      widget.engine.setVolume(newVol);

      setState(() {
        _showVolumeIndicator = true;
      });

      _volumeTimer?.cancel();
      _volumeTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showVolumeIndicator = false);
      });
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (_isLocked) return;
    HapticFeedback.selectionClick();
    widget.onDragStart();
    widget.onUserInteraction();
    setState(() {
      _isScrubbing = true;
      _scrubStartPos = widget.engine.state.position;
      _scrubPosition = _scrubStartPos;
    });
  }

  void _handleHorizontalDragUpdate(
      DragUpdateDetails details, BoxConstraints constraints) {
    if (_isLocked || !_isScrubbing) return;

    widget.onUserInteraction();
    final double deltaX = details.primaryDelta!;
    final totalDuration = widget.engine.state.duration;

    if (totalDuration == Duration.zero) return;

    // Map drag distance in pixels to seconds in video
    // 1 pixel = 150 milliseconds of video duration (for smooth scrubbing)
    final int changeMs = (deltaX * 150).toInt();

    setState(() {
      final targetMs = _scrubPosition.inMilliseconds + changeMs;
      _scrubPosition = Duration(
          milliseconds: targetMs.clamp(0, totalDuration.inMilliseconds));
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isLocked || !_isScrubbing) return;
    widget.engine.seek(_scrubPosition);
    setState(() {
      _isScrubbing = false;
    });
    widget.onDragEnd();
    widget.onUserInteraction();
  }

  // ── Settings Sheets (speed / subtitles / audio) ────────────────────────────

  /// Opens a bottom sheet while keeping the controls visible (pauses the
  /// auto-hide timer via onDragStart/onDragEnd, same as scrubbing).
  Future<void> _openSheet(Widget sheet) async {
    HapticFeedback.lightImpact();
    widget.onDragStart();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => sheet,
    );
    if (mounted) widget.onDragEnd();
  }

  void _showSpeedSheet() {
    _openSheet(
      SpeedSelectorSheet(
        currentSpeed: widget.engine.state.playbackSpeed,
        onSpeedSelected: (speed) {
          widget.engine.setPlaybackSpeed(speed);
        },
      ),
    );
  }

  void _showSubtitleSheet() {
    _openSheet(
      SubtitleSelectorSheet(
        tracks: widget.engine.state.tracks,
        selectedTrack: widget.engine.state.track.subtitle,
        onTrackSelected: (track) {
          widget.engine.setSubtitleTrack(track);
        },
      ),
    );
  }

  void _showAudioSheet() {
    _openSheet(
      AudioTrackSelectorSheet(
        tracks: widget.engine.state.tracks,
        selectedTrack: widget.engine.state.track.audio,
        onTrackSelected: (track) {
          widget.engine.setAudioTrack(track);
        },
      ),
    );
  }

  // ── Video Fit Toggle ──────────────────────────────────────────────────────

  bool _showFitIndicator = false;
  Timer? _fitTimer;

  String get _fitLabel => switch (widget.videoFit) {
        BoxFit.cover => 'Zoom',
        BoxFit.fill => 'Estirado',
        _ => 'Ajustado',
      };

  IconData get _fitIcon => switch (widget.videoFit) {
        BoxFit.cover => Icons.zoom_out_map_rounded,
        BoxFit.fill => Icons.aspect_ratio_rounded,
        _ => Icons.fit_screen_rounded,
      };

  void _handleCycleFit() {
    HapticFeedback.lightImpact();
    widget.onCycleFit();
    widget.onUserInteraction();
    setState(() => _showFitIndicator = true);
    _fitTimer?.cancel();
    _fitTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showFitIndicator = false);
    });
  }



  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final state = widget.engine.state;
        final isPlaying = state.isPlaying;
        final position = _isScrubbing ? _scrubPosition : state.position;
        final duration = state.duration;
        final remaining = duration - position;

        final sliderValue = position.inSeconds.toDouble().clamp(
              0.0,
              duration.inSeconds.toDouble() > 0.0
                  ? duration.inSeconds.toDouble()
                  : 1.0,
            );
        final sliderMax = duration.inSeconds.toDouble() > 0.0
            ? duration.inSeconds.toDouble()
            : 1.0;

        // Custom simulated brightness black overlay
        final double overlayOpacity = (1.0 - _brightnessLevel) * 0.85;

        return Stack(
          children: [
            // ── Brightness Dim Overlay ──
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: overlayOpacity),
                ),
              ),
            ),

            // ── Gesture Detection Layer ──
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => _handleTapUp(details, constraints),
                onVerticalDragStart: (_) {
                  if (_isLocked) return;
                  widget.onDragStart();
                },
                onVerticalDragUpdate: (details) =>
                    _handleVerticalDragUpdate(details, constraints),
                onVerticalDragEnd: (_) {
                  if (_isLocked) return;
                  widget.onDragEnd();
                  widget.onUserInteraction();
                },
                onHorizontalDragStart: _handleHorizontalDragStart,
                onHorizontalDragUpdate: (details) =>
                    _handleHorizontalDragUpdate(details, constraints),
                onHorizontalDragEnd: _handleHorizontalDragEnd,
              ),
            ),

            // ── Fast Forward / Rewind Double Tap Cues ──
            if (_showLeftCue)
              Positioned(
                left: constraints.maxWidth * 0.15,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fast_rewind_rounded,
                            color: Colors.white, size: 36),
                        const SizedBox(height: 6),
                        Text(
                          '-10s',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_showRightCue)
              Positioned(
                right: constraints.maxWidth * 0.15,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fast_forward_rounded,
                            color: Colors.white, size: 36),
                        const SizedBox(height: 6),
                        Text(
                          '+10s',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Brightness HUD Indicator ──
            if (_showBrightnessIndicator)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_rounded,
                          color: AppTheme.darkAccent, size: 20),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: _brightnessLevel,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.darkAccent),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(_brightnessLevel * 100).toInt()}%',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Volume HUD Indicator ──
            if (_showVolumeIndicator)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isMuted
                            ? Icons.volume_off_rounded
                            : (state.volume < 0.4
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded),
                        color: AppTheme.darkAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: state.isMuted ? 0.0 : state.volume,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.darkAccent),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.isMuted
                            ? 'Muted'
                            : '${(state.volume * 100).toInt()}%',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Video Fit HUD Indicator ──
            if (_showFitIndicator)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_fitIcon, color: AppTheme.darkAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _fitLabel,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Scrubbing Overlay ──
            if (_isScrubbing)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.darkAccent.withValues(alpha: 0.3),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkAccent.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(_scrubPosition),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(duration),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_scrubPosition >= _scrubStartPos)
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (_scrubPosition >= _scrubStartPos)
                                  ? '+${_formatDuration(_scrubPosition - _scrubStartPos)}'
                                  : '-${_formatDuration(_scrubStartPos - _scrubPosition)}',
                              style: GoogleFonts.spaceGrotesk(
                                color: (_scrubPosition >= _scrubStartPos)
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ── Cinematic Controls Overlay (Locked vs Unlocked) ──
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: widget.showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !widget.showControls,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) => _handleTapUp(details, constraints),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          stops: const [0.0, 0.25, 0.7, 1.0],
                        ),
                      ),
                      child: _isLocked
                          ? _buildLockedControls()
                          : _buildUnlockedControls(
                              sliderValue,
                              sliderMax,
                              position,
                              duration,
                              remaining,
                              isPlaying,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Locked Controls (Only Lock/Unlock key visible) ──────────────────────────
  Widget _buildLockedControls() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkAccent.withValues(alpha: 0.2),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.lock_rounded),
                  iconSize: 42,
                  color: AppTheme.darkAccent,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(18),
                    side: const BorderSide(
                        color: AppTheme.darkAccent, width: 1.5),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _isLocked = false;
                    });
                    widget.onUserInteraction();
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Controles Bloqueados',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Toca el candado para desbloquear',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Full Unlocked Controls ──────────────────────────────────────────────────
  Widget _buildUnlockedControls(
    double sliderValue,
    double sliderMax,
    Duration position,
    Duration duration,
    Duration remaining,
    bool isPlaying,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── TOP BAR ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onExit();
                  },
                ),
                const SizedBox(width: 14),
                // Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${widget.movie.year}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                  color: Colors.white38,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            widget.movie.duration,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.darkAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppTheme.darkAccent
                                      .withValues(alpha: 0.35),
                                  width: 0.8),
                            ),
                            child: Text(
                              '⭐ ${widget.movie.rating.toStringAsFixed(1)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Video Fit Toggle Button
                IconButton(
                  icon: Icon(_fitIcon, size: 20),
                  color: Colors.white70,
                  tooltip: 'Ajuste de pantalla',
                  onPressed: _handleCycleFit,
                ),

                // Playback Speed Button
                IconButton(
                  icon: widget.engine.state.playbackSpeed == 1.0
                      ? const Icon(Icons.speed_rounded, size: 20)
                      : Text(
                          '${widget.engine.state.playbackSpeed}x',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkAccent,
                          ),
                        ),
                  color: Colors.white70,
                  tooltip: 'Velocidad de reproducción',
                  onPressed: _showSpeedSheet,
                ),

                // Audio Track Button (only when there are multiple tracks)
                if (widget.engine.state.tracks.audio.length > 1)
                  IconButton(
                    icon: const Icon(Icons.translate_rounded, size: 20),
                    color: Colors.white70,
                    tooltip: 'Idioma / Pista de audio',
                    onPressed: _showAudioSheet,
                  ),

                // Subtitles Button (only when subtitle tracks exist)
                if (widget.engine.state.tracks.subtitle
                    .any((t) => t.id != 'auto' && t.id != 'no'))
                  IconButton(
                    icon: Icon(
                      widget.engine.state.track.subtitle.id == 'no'
                          ? Icons.closed_caption_off_rounded
                          : Icons.closed_caption_rounded,
                      size: 22,
                    ),
                    color: widget.engine.state.track.subtitle.id == 'no'
                        ? Colors.white70
                        : AppTheme.darkAccent,
                    tooltip: 'Subtítulos',
                    onPressed: _showSubtitleSheet,
                  ),

                // Lock Screen Button
                IconButton(
                  icon: const Icon(Icons.lock_open_rounded, size: 20),
                  color: Colors.white70,
                  tooltip: 'Bloquear Controles',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _isLocked = true;
                    });
                    widget.onUserInteraction();
                  },
                ),
              ],
            ),
          ),
        ),

        // ── CENTER CONTROLS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Seek Back -10s
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onUserInteraction();
                final target =
                    widget.engine.state.position - const Duration(seconds: 10);
                widget.engine
                    .seek(target < Duration.zero ? Duration.zero : target);
              },
              icon: const Icon(Icons.replay_10_rounded),
              iconSize: 38,
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(width: 40),
            // Play / Pause Circle
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (isPlaying) {
                  widget.engine.pause();
                } else {
                  widget.engine.play();
                }
                widget.onUserInteraction();
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.darkAccent, Color(0xFFACDE2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkAccent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 38,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
            // Seek Forward +10s
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onUserInteraction();
                final target =
                    widget.engine.state.position + const Duration(seconds: 10);
                final maxDur = widget.engine.state.duration;
                widget.engine.seek(target > maxDur ? maxDur : target);
              },
              icon: const Icon(Icons.forward_10_rounded),
              iconSize: 38,
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),

        // ── BOTTOM PROGRESS BAR & VOLUME ──
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timeline progress bar
                Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3.5,
                          activeTrackColor: AppTheme.darkAccent,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: AppTheme.darkAccent,
                          overlayColor:
                              AppTheme.darkAccent.withValues(alpha: 0.25),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: sliderValue,
                          max: sliderMax,
                          onChanged: (value) {
                            widget.onUserInteraction();
                            setState(() {
                              _isScrubbing = true;
                              _scrubPosition = Duration(seconds: value.toInt());
                            });
                          },
                          onChangeEnd: (value) {
                            widget.engine
                                .seek(Duration(seconds: value.toInt()));
                            setState(() {
                              _isScrubbing = false;
                            });
                            widget.onUserInteraction();
                          },
                        ),
                      ),
                    ),
                    Text(
                      remaining > Duration.zero
                          ? '-${_formatDuration(remaining)}'
                          : '00:00',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Volume slider & Extra info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Volume Control
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.engine.state.isMuted
                                ? Icons.volume_off_rounded
                                : (widget.engine.state.volume < 0.4
                                    ? Icons.volume_down_rounded
                                    : Icons.volume_up_rounded),
                            size: 18,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.engine
                                .setMuted(!widget.engine.state.isMuted);
                            widget.onUserInteraction();
                          },
                        ),
                        SizedBox(
                          width: 90,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 4),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: widget.engine.state.isMuted
                                  ? 0.0
                                  : widget.engine.state.volume,
                              onChanged: (val) {
                                widget.engine.setVolume(val);
                                if (widget.engine.state.isMuted) {
                                  widget.engine.setMuted(false);
                                }
                                widget.onUserInteraction();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Next episode / Future Series metadata placeholder or remaining warning
                    if (remaining < const Duration(seconds: 30) &&
                        duration > const Duration(minutes: 5))
                      Text(
                        'La película terminará pronto',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
