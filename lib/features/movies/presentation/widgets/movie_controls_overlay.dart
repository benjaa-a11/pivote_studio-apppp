import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_video_engine.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_bottom_sheets.dart';

class MovieControlsOverlay extends StatefulWidget {
  final MovieVideoEngine engine;
  final Movie movie;
  final bool showControls;
  final VoidCallback onToggleControls;
  final VoidCallback onUserInteraction;

  const MovieControlsOverlay({
    super.key,
    required this.engine,
    required this.movie,
    required this.showControls,
    required this.onToggleControls,
    required this.onUserInteraction,
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
  Duration _scrubStartPos = Duration.zero;
  Timer? _scrubTimer;

  // ── SVG Constants ──
  static const String _svgPlay = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 5.14v13.72a2 2 0 0 0 3.05 1.71l10.29-6.86a2 2 0 0 0 0-3.42L11.05 3.43A2 2 0 0 0 8 5.14z" fill="currentColor"/>
  </svg>''';

  static const String _svgPause = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="5" y="4" width="4" height="16" rx="2" fill="currentColor"/>
  <rect x="15" y="4" width="4" height="16" rx="2" fill="currentColor"/>
  </svg>''';

  static const String _svgVolumeHigh = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 5L6 9H2v6h4l5 4V5z" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
  <path d="M15.5 8.5c1.5 1.5 1.5 3.5 0 5M18.5 5.5c3.5 3.5 3.5 7.5 0 11" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  </svg>''';

  static const String _svgVolumeLow = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 5L6 9H2v6h4l5 4V5z" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
  <path d="M15.5 8.5c1.5 1.5 1.5 3.5 0 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  </svg>''';

  static const String _svgVolumeMute = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 5L6 9H2v6h4l5 4V5z" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
  <path d="M22 9l-6 6M16 9l6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>''';

  static const String _svgSpeed = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="2"/>
  <path d="M12 7v5l3 2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>''';

  static const String _svgLockLocked = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="11" width="18" height="11" rx="2.5" stroke="currentColor" stroke-width="2"/>
  <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  </svg>''';

  static const String _svgLockUnlocked = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="11" width="18" height="11" rx="2.5" stroke="currentColor" stroke-width="2"/>
  <path d="M7 11V7a5 5 0 0 1 9.9-1" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  </svg>''';

  static const String _svgArrowBack = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 19l-7-7 7-7" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>''';

  static const String _svgReplay10 = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12.5 3a9 9 0 1 0 7.8 4.5M20 3v5h-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="12" y="15" font-size="7" font-weight="900" font-family="system-ui" text-anchor="middle" fill="currentColor">10</text>
  </svg>''';

  static const String _svgForward10 = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11.5 3a9 9 0 1 1-7.8 4.5M4 3v5h5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="12" y="15" font-size="7" font-weight="900" font-family="system-ui" text-anchor="middle" fill="currentColor">10</text>
  </svg>''';

  static const String _svgBrightness = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="5" stroke="currentColor" stroke-width="2"/>
  <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  </svg>''';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _brightnessTimer?.cancel();
    _volumeTimer?.cancel();
    _scrubTimer?.cancel();
    super.dispose();
  }

  Widget _getSvgIcon(String svgContent, {double size = 24, Color color = Colors.white}) {
    return SvgPicture.string(
      svgContent,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
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

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (_isLocked) return;
    HapticFeedback.selectionClick();
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
    widget.onUserInteraction();
  }

  void _showSpeedSheet() {
    widget.onUserInteraction();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SpeedSelectorSheet(
        currentSpeed: widget.engine.state.playbackSpeed,
        onSpeedSelected: (speed) {
          widget.engine.setPlaybackSpeed(speed);
        },
      ),
    );
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onToggleControls();
                },
                onDoubleTapDown: (details) => _handleDoubleTap(details, constraints),
                onVerticalDragUpdate: (details) => _handleVerticalDragUpdate(details, constraints),
                onHorizontalDragStart: _handleHorizontalDragStart,
                onHorizontalDragUpdate: (details) => _handleHorizontalDragUpdate(details, constraints),
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
                        _getSvgIcon(_svgReplay10, size: 36, color: Colors.white),
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
                        _getSvgIcon(_svgForward10, size: 36, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getSvgIcon(_svgBrightness, size: 20, color: AppTheme.darkAccent),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: _brightnessLevel,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.darkAccent),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getSvgIcon(
                        state.isMuted
                            ? _svgVolumeMute
                            : (state.volume < 0.4 ? _svgVolumeLow : _svgVolumeHigh),
                        size: 20,
                        color: AppTheme.darkAccent,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: state.isMuted ? 0.0 : state.volume,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.darkAccent),
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

            // ── Scrubbing Overlay ──
            if (_isScrubbing)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !widget.showControls,
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
                  icon: _getSvgIcon(_svgLockLocked, size: 28, color: AppTheme.darkAccent),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(18),
                    side: const BorderSide(color: AppTheme.darkAccent, width: 1.5),
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
                  icon: _getSvgIcon(_svgArrowBack, size: 16, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white12),
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await widget.engine.stop();
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                    if (mounted) {
                      Navigator.pop(context);
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
                              color: AppTheme.darkAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppTheme.darkAccent.withValues(alpha: 0.35),
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

                // Settings & Options Buttons
                IconButton(
                  icon: _getSvgIcon(_svgSpeed, size: 20, color: Colors.white),
                  tooltip: 'Velocidad',
                  onPressed: _showSpeedSheet,
                ),
                IconButton(
                  icon: _getSvgIcon(_svgLockUnlocked, size: 20, color: Colors.white70),
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
                final target = widget.engine.state.position - const Duration(seconds: 10);
                widget.engine.seek(target < Duration.zero ? Duration.zero : target);
              },
              icon: _getSvgIcon(_svgReplay10, size: 30, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
                  child: _getSvgIcon(isPlaying ? _svgPause : _svgPlay, size: 26, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 40),
            // Seek Forward +10s
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onUserInteraction();
                final target = widget.engine.state.position + const Duration(seconds: 10);
                final maxDur = widget.engine.state.duration;
                widget.engine.seek(target > maxDur ? maxDur : target);
              },
              icon: _getSvgIcon(_svgForward10, size: 30, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ],
        ),

        // ── BOTTOM PROGRESS BAR & VOLUME (INTEGRATED) ──
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.2),
              ),
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
                            overlayColor: AppTheme.darkAccent.withValues(alpha: 0.25),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
                      Text(
                        remaining > Duration.zero ? '-${_formatDuration(remaining)}' : '00:00',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Integrated controls and volume slider row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Volume Control (Integrated!)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: _getSvgIcon(
                              widget.engine.state.isMuted
                                  ? _svgVolumeMute
                                  : (widget.engine.state.volume < 0.4 ? _svgVolumeLow : _svgVolumeHigh),
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.engine.setMuted(!widget.engine.state.isMuted);
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
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: widget.engine.state.isMuted ? 0.0 : widget.engine.state.volume,
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

                      // Warning details or info
                      if (remaining < const Duration(seconds: 45) && duration > const Duration(minutes: 5))
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
        ),
      ],
    );
  }
}
