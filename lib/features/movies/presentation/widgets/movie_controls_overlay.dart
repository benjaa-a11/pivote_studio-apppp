import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_video_engine.dart';

class MovieControlsOverlay extends StatefulWidget {
  final MovieVideoEngine engine;
  final Movie movie;
  final bool showControls;
  final VoidCallback onToggleControls;
  final VoidCallback onUserInteraction;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const MovieControlsOverlay({
    super.key,
    required this.engine,
    required this.movie,
    required this.showControls,
    required this.onToggleControls,
    required this.onUserInteraction,
    required this.onDragStart,
    required this.onDragEnd,
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
  double _brightnessLevel = 1.0; // 0.0 to 1.0
  Timer? _brightnessTimer;

  bool _showVolumeIndicator = false;
  Timer? _volumeTimer;

  // Horizontal drag / scrubbing
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;

  @override
  void dispose() {
    _brightnessTimer?.cancel();
    _volumeTimer?.cancel();
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

  void _handleDoubleTap(TapDownDetails details, BoxConstraints constraints) {
    if (_isLocked) {
      widget.onUserInteraction();
      return;
    }

    final double width = constraints.maxWidth;
    final double tapX = details.localPosition.dx;
    final bool isRight = tapX > (width / 2);

    HapticFeedback.lightImpact();
    widget.onUserInteraction();

    final currentPos = widget.engine.state.position;
    final totalDuration = widget.engine.state.duration;

    Duration targetPos;
    if (isRight) {
      setState(() => _showRightCue = true);
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showRightCue = false);
      });
      targetPos = currentPos + const Duration(seconds: 10);
      if (targetPos > totalDuration) targetPos = totalDuration;
    } else {
      setState(() => _showLeftCue = true);
      Timer(const Duration(milliseconds: 600), () {
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
        _brightnessLevel = (_brightnessLevel + (deltaY / height) * 1.5).clamp(0.1, 1.0);
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final state = widget.engine.state;
        final isPlaying = state.isPlaying;
        final position = _isScrubbing ? _scrubPosition : state.position;
        final duration = state.duration;

        final sliderValue = position.inSeconds.toDouble().clamp(
              0.0,
              duration.inSeconds.toDouble() > 0.0
                  ? duration.inSeconds.toDouble()
                  : 1.0,
            );
        final sliderMax = duration.inSeconds.toDouble() > 0.0
            ? duration.inSeconds.toDouble()
            : 1.0;

        final double overlayOpacity = (1.0 - _brightnessLevel) * 0.85;

        return Stack(
          children: [
            // ── Brightness Dim Overlay ──
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: Colors.black.withValues(alpha: overlayOpacity),
                ),
              ),
            ),

            // ── Gesture Detection Layer ──
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onToggleControls();
                },
                onDoubleTapDown: (details) => _handleDoubleTap(details, constraints),
                onVerticalDragStart: (_) => widget.onDragStart(),
                onVerticalDragUpdate: (details) => _handleVerticalDragUpdate(details, constraints),
                onVerticalDragEnd: (_) => widget.onDragEnd(),
              ),
            ),

            // ── Fast Forward / Rewind Double Tap Cues ──
            if (_showLeftCue)
              Positioned(
                left: constraints.maxWidth * 0.15,
                top: 0,
                bottom: 0,
                child: const Center(
                  child: DoubleTapCue(isRight: false),
                ),
              ),

            if (_showRightCue)
              Positioned(
                right: constraints.maxWidth * 0.15,
                top: 0,
                bottom: 0,
                child: const Center(
                  child: DoubleTapCue(isRight: true),
                ),
              ),

            // ── Brightness HUD Indicator (Fade) ──
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showBrightnessIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showBrightnessIndicator,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.light_mode_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: _brightnessLevel,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
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
                ),
              ),
            ),

            // ── Volume HUD Indicator (Fade with custom SVGs) ──
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showVolumeIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showVolumeIndicator,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            state.isMuted
                                ? 'assets/icons/player-movies/icon_volumemuted.svg'
                                : 'assets/icons/player-movies/icon_volumeloud.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: state.isMuted ? 0.0 : state.volume,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.isMuted ? 'Muted' : '${(state.volume * 100).toInt()}%',
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
                ),
              ),
            ),

            // ── Cinematic Controls Overlay (Locked vs Unlocked Stack) ──
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !widget.showControls,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onToggleControls();
                  },
                  child: Stack(
                    children: [
                      // Backdrop gradient transition
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: widget.showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
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
                          ),
                        ),
                      ),

                      if (_isLocked)
                        _buildLockedControls()
                      else ...[
                        // TOP BAR: Slides from top
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          top: widget.showControls ? 0.0 : -100.0,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: widget.showControls ? 1.0 : 0.0,
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: Row(
                                  children: [
                                    // Back Button (Solid Black with White Icon)
                                    SpringyIconButton(
                                      size: 40,
                                      padding: 8,
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                                      onPressed: () async {
                                        HapticFeedback.mediumImpact();
                                        final navigator = Navigator.of(context);
                                        await widget.engine.stop();
                                        await SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                        ]);
                                        if (mounted) {
                                          navigator.pop();
                                        }
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
                                                      color: Colors.white38, shape: BoxShape.circle)),
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
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      width: 0.8),
                                                ),
                                                child: Text(
                                                  '⭐ ${widget.movie.rating.toStringAsFixed(1)}',
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Lock Button (Solid Black with White Icon)
                                    SpringyIconButton(
                                      size: 40,
                                      padding: 8,
                                      icon: const Icon(Icons.lock_open_rounded, size: 20, color: Colors.white),
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
                          ),
                        ),

                        // CENTER CONTROLS: Scales from center
                        Center(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutBack,
                            scale: widget.showControls ? 1.0 : 0.85,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: widget.showControls ? 1.0 : 0.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Seek Back -10s with SVG
                                  SpringyIconButton(
                                    size: 54,
                                    padding: 12,
                                    icon: SvgPicture.asset(
                                      'assets/icons/player-movies/icon_skiprewind10sec.svg',
                                      width: 26,
                                      height: 26,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      widget.onUserInteraction();
                                      final target = widget.engine.state.position - const Duration(seconds: 10);
                                      widget.engine.seek(target < Duration.zero ? Duration.zero : target);
                                    },
                                  ),
                                  const SizedBox(width: 32),
                                  // Play / Pause Circle (Solid Black with White SVG Icon)
                                  AnimatedPlayPauseButton(
                                    isPlaying: isPlaying,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      if (isPlaying) {
                                        widget.engine.pause();
                                      } else {
                                        widget.engine.play();
                                      }
                                      widget.onUserInteraction();
                                    },
                                  ),
                                  const SizedBox(width: 32),
                                  // Seek Forward +10s with SVG
                                  SpringyIconButton(
                                    size: 54,
                                    padding: 12,
                                    icon: SvgPicture.asset(
                                      'assets/icons/player-movies/icon_skipfastforward10sec.svg',
                                      width: 26,
                                      height: 26,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      widget.onUserInteraction();
                                      final target = widget.engine.state.position + const Duration(seconds: 10);
                                      final maxDur = widget.engine.state.duration;
                                      widget.engine.seek(target > maxDur ? maxDur : target);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // BOTTOM PROGRESS BAR: Slides from bottom (Minimalist, without surrounding container)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          bottom: widget.showControls ? 0.0 : -80.0,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: widget.showControls ? 1.0 : 0.0,
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                child: Row(
                                  children: [
                                    // Full-width Slider Track
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: _isScrubbing ? 5.5 : 3.5,
                                          activeTrackColor: AppTheme.darkAccent,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: AppTheme.darkAccent,
                                          overlayColor: AppTheme.darkAccent.withValues(alpha: 0.2),
                                          thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: _isScrubbing ? 8.0 : 5.0,
                                            elevation: 4,
                                          ),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
                                            widget.engine.seek(Duration(seconds: value.toInt()));
                                            setState(() {
                                              _isScrubbing = false;
                                            });
                                            widget.onUserInteraction();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Timestamps at the right: Position / Duration
                                    Text(
                                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
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
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Locked Controls (Only Lock/Unlock key visible with scale/fade animations) ──────────────────────────
  Widget _buildLockedControls() {
    return Center(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        scale: widget.showControls ? 1.0 : 0.85,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: widget.showControls ? 1.0 : 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpringyIconButton(
                size: 64,
                padding: 16,
                icon: const Icon(Icons.lock_rounded, size: 28, color: Colors.white),
                backgroundColor: Colors.black,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isLocked = false;
                  });
                  widget.onUserInteraction();
                },
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
      ),
    );
  }
}

// ── Secondary Springy Button Widget (Solid Black, White Icon) ────────────────
class SpringyIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double size;
  final double padding;

  const SpringyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.black,
    this.size = 54,
    this.padding = 12,
  });

  @override
  State<SpringyIconButton> createState() => _SpringyIconButtonState();
}

class _SpringyIconButtonState extends State<SpringyIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}

// ── Interactive Springy Play/Pause Button Widget (Solid Black, White SVG Icon, Non-Rotating) ───
class AnimatedPlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const AnimatedPlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<AnimatedPlayPauseButton> createState() => _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: widget.isPlaying
                  ? SvgPicture.asset(
                      'assets/icons/player-movies/icon_pause.svg',
                      key: const ValueKey('pause'),
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    )
                  : SvgPicture.asset(
                      'assets/icons/player-movies/icon_play.svg',
                      key: const ValueKey('play'),
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Interactive Double Tap Cue Ripple Animation (Solid Black background, White SVG Icon) ──────────────
class DoubleTapCue extends StatefulWidget {
  final bool isRight;
  const DoubleTapCue({super.key, required this.isRight});

  @override
  State<DoubleTapCue> createState() => _DoubleTapCueState();
}

class _DoubleTapCueState extends State<DoubleTapCue> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.65),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                widget.isRight
                    ? 'assets/icons/player-movies/icon_skipfastforward10sec.svg'
                    : 'assets/icons/player-movies/icon_skiprewind10sec.svg',
                width: 34,
                height: 34,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isRight ? '+10s' : '-10s',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
