import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/video/presentation/widgets/video_player_widget.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';

class MoviePlayerScreen extends StatefulWidget {
  final Movie movie;

  const MoviePlayerScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  Timer? _hideTimer;
  double? _dragValue;
  bool _showLeftCue = false;
  bool _showRightCue = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Force landscape mode and full screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();

    // Restore portrait mode and show system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.forward();
        _startHideTimer();
      } else {
        _fadeController.reverse();
        _hideTimer?.cancel();
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && _dragValue == null) {
        setState(() {
          _showControls = false;
          _fadeController.reverse();
        });
      }
    });
  }

  void _onInteraction() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
        _fadeController.forward();
      });
    }
    _startHideTimer();
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

  void _performDoubleTapSeek(bool isRight, UnifiedVideoController controller) {
    HapticFeedback.lightImpact();
    final currentPos = controller.position;
    final totalDuration = controller.duration;
    
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

    controller.seek(targetPos);
    _onInteraction();
  }

  @override
  Widget build(BuildContext context) {
    final movieChannel = widget.movie.toChannel();

    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoPlayerWidget(
        channel: movieChannel,
        controlsBuilder: (context, controller, isFullScreen, toggleFullScreen) {
          // Listen to controller status updates
          return ListenableBuilder(
            listenable: controller as Listenable,
            builder: (context, _) {
              final position = _dragValue != null
                  ? Duration(seconds: _dragValue!.toInt())
                  : controller.position;
              final duration = controller.duration;
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

              return Stack(
                children: [
                  // ──── Double-Tap Gestures Layer ────
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Left double-tap region
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _toggleControls,
                            onDoubleTap: () => _performDoubleTapSeek(false, controller),
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: _showLeftCue ? 1.0 : 0.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 28),
                                        SizedBox(height: 4),
                                        Text(
                                          '-10s',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right double-tap region
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _toggleControls,
                            onDoubleTap: () => _performDoubleTapSeek(true, controller),
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: _showRightCue ? 1.0 : 0.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.fast_forward_rounded, color: Colors.white, size: 28),
                                        SizedBox(height: 4),
                                        Text(
                                          '+10s',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Cinematic Controls Overlays ───
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.22, 0.72, 1.0],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Bar metadata
                              _buildTopBar(context, controller),

                              // Center seek / play actions
                              _buildCenterPlayPause(controller),

                              // Bottom bar Scrubber and remaining controls
                              _buildBottomScrubber(
                                controller,
                                sliderValue,
                                sliderMax,
                                position,
                                remaining,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Top Bar Metadata Overlay ──────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, UnifiedVideoController controller) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            // Immersive Back Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Movie Metas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
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
                          shape: BoxShape.circle,
                        ),
                      ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.darkAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.darkAccent.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
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
            // Quality Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                '4K UHD',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Center Controls ───────────────────────────────────────────────────────
  Widget _buildCenterPlayPause(UnifiedVideoController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Seek -10s
        IconButton(
          onPressed: () => _performDoubleTapSeek(false, controller),
          icon: const Icon(Icons.replay_10_rounded),
          iconSize: 42,
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 32),
        // Play / Pause
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (controller.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
            _onInteraction();
          },
          child: AnimatedScale(
            scale: _showControls ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkAccent,
                    AppTheme.darkAccent.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkAccent.withValues(alpha: 0.35),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  controller.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 38,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Seek +10s
        IconButton(
          onPressed: () => _performDoubleTapSeek(true, controller),
          icon: const Icon(Icons.forward_10_rounded),
          iconSize: 42,
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  // ── Bottom Scrubber progress bar & controls ────────────────────────────────
  Widget _buildBottomScrubber(
    UnifiedVideoController controller,
    double sliderValue,
    double sliderMax,
    Duration position,
    Duration remaining,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrubber drag slider
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
                      trackHeight: 4,
                      activeTrackColor: AppTheme.darkAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppTheme.darkAccent,
                      overlayColor: AppTheme.darkAccent.withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      value: sliderValue,
                      max: sliderMax,
                      onChanged: (value) {
                        _onInteraction();
                        setState(() {
                          _dragValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        controller.seek(Duration(seconds: value.toInt()));
                        setState(() {
                          _dragValue = null;
                        });
                        _onInteraction();
                      },
                    ),
                  ),
                ),
                Text(
                  remaining > Duration.zero
                      ? '-${_formatDuration(remaining)}'
                      : _formatDuration(Duration.zero),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Bottom Volume and Fullscreen controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left volume controller
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.setMuted(!controller.isMuted);
                        _onInteraction();
                      },
                      icon: Icon(
                        controller.isMuted
                            ? Icons.volume_off_rounded
                            : (controller.volume < 0.4
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded),
                      ),
                      color: Colors.white,
                      iconSize: 20,
                    ),
                    SizedBox(
                      width: 100,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2.5,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: controller.isMuted ? 0.0 : controller.volume,
                          onChanged: (vol) {
                            controller.setVolume(vol);
                            if (controller.isMuted) controller.setMuted(false);
                            _onInteraction();
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Center server / buffering info
                if (controller.isBuffering)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Buffering...',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                // Right fullscreen / details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AUTO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
