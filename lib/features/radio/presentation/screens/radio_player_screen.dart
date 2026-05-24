import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/core/services/app_activity_service.dart';

class RadioPlayerScreen extends StatefulWidget {
  final radio_model.Radio radio;

  const RadioPlayerScreen({
    super.key,
    required this.radio,
  });

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen>
    with TickerProviderStateMixin {
  // Drag gesture variables
  double _dragStartY = 0.0;
  double _dragCurrentY = 0.0;

  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    // Slide animation for drag to dismiss
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Subtle rotation for the logo/disc
    _rotateController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Ensure the manager plays this radio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = context.read<AudioManager>();
      if (audioManager.currentRadio?.id != widget.radio.id) {
        audioManager.playRadio(widget.radio);
      }
      try {
        Provider.of<AppActivityService>(context, listen: false).trackRadioListen();
      } catch (e) {
        debugPrint('Error tracking radio listen: $e');
      }

      // Control rotation based on playing state
      if (audioManager.isPlaying) {
        _rotateController.repeat();
      }
    });

    // Set initial system UI for player
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Listen to changes in AudioManager
    _setupManagerListener();
  }

  void _setupManagerListener() {
    final audioManager = context.read<AudioManager>();
    audioManager.addListener(_onAudioManagerChanged);
  }

  void _onAudioManagerChanged() {
    if (!mounted) return;
    final audioManager = context.read<AudioManager>();
    
    // Manage rotation state dynamically
    if (audioManager.isPlaying) {
      if (!_rotateController.isAnimating) {
        _rotateController.repeat();
      }
    } else {
      if (_rotateController.isAnimating) {
        _rotateController.stop();
      }
    }

    if (audioManager.status == AudioManagerStatus.error &&
        audioManager.errorMessage != null) {
      AppNotifications.showError(context, audioManager.errorMessage!);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragStartY = details.globalPosition.dy;
      _dragCurrentY = details.globalPosition.dy;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragCurrentY = details.globalPosition.dy;
    });

    final dragDistance = _dragCurrentY - _dragStartY;
    if (dragDistance > 0) {
      final dragPercentage =
          (dragDistance / MediaQuery.of(context).size.height).clamp(0.0, 1.0);
      _slideAnimationController.value = dragPercentage;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final dragDistance = _dragCurrentY - _dragStartY;
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (dragDistance > 150 || velocity > 500) {
      _dismissPlayer();
    } else {
      _slideAnimationController.animateTo(0.0);
    }
  }

  void _dismissPlayer() {
    _slideAnimationController.animateTo(1.0).then((_) {
      context.read<AudioManager>().stop();
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    context.read<AudioManager>().removeListener(_onAudioManagerChanged);
    _slideAnimationController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<AudioManager>().stop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GestureDetector(
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final slideValue = _slideAnimation.value;
              return Transform.translate(
                offset: Offset(0, slideValue * size.height),
                child: Opacity(
                  opacity: (1.0 - slideValue).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Premium Background Gradient & Blur Glows
                _buildDynamicBackground(context, isDark),

                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape = constraints.maxHeight < constraints.maxWidth;
                      final isTablet = constraints.maxWidth > 600;

                      if (isLandscape) {
                        return _buildLandscapeLayout(context, isDark, constraints);
                      } else {
                        return _buildPortraitLayout(context, isDark, constraints, isTablet);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBackground(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      children: [
        // Solid theme-colored base
        Container(
          color: theme.scaffoldBackgroundColor,
        ),
        // Glowing radial blobs
        Positioned(
          top: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: isDark ? 0.06 : 0.03),
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Overlay gradient for depth
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              context.read<AudioManager>().stop();
              Navigator.pop(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: textColor.withValues(alpha: 0.8),
                size: 24,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull down indicator cue
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'RADIO EN VIVO',
                style: GoogleFonts.spaceGrotesk(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Custom share/info bottom sheet
              _showInfoBottomSheet(context, isDark);
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: textColor.withValues(alpha: 0.8),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    bool isDark,
    BoxConstraints constraints,
    bool isTablet,
  ) {
    // Avoid large height overflows on small devices like J7 by using a SingleChildScrollView
    // while keeping content nicely centered on tall screens.
    final double maxArtSize = isTablet
        ? 340
        : (constraints.maxHeight * 0.32).clamp(180, 280);

    return Column(
      children: [
        _buildHeader(context, isDark),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 64 : 24,
                vertical: 16,
              ),
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 80, // compensate for header
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPlayerArt(context, maxArtSize, isDark),
                  const SizedBox(height: 24),
                  _buildPlayerInfo(context, isDark),
                  const SizedBox(height: 16),
                  _buildVisualizerSection(context),
                  const SizedBox(height: 20),
                  _buildPlayerControls(context, isDark),
                  const SizedBox(height: 28),
                  _buildVolumeController(context, isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    bool isDark,
    BoxConstraints constraints,
  ) {
    final double maxArtSize = (constraints.maxHeight * 0.55).clamp(140.0, 240.0);

    return Column(
      children: [
        _buildHeader(context, isDark),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                // Left Column: Art & Visualizer
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlayerArt(context, maxArtSize, isDark),
                      const SizedBox(height: 16),
                      _buildVisualizerSection(context),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Column: Controls, Info & Volume
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildPlayerInfo(context, isDark),
                        const SizedBox(height: 16),
                        _buildPlayerControls(context, isDark),
                        const SizedBox(height: 24),
                        _buildVolumeController(context, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerArt(BuildContext context, double artSize, bool isDark) {
    return Center(
      child: Container(
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Hero(
          tag: 'radio_tile_logo_${widget.radio.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CachedNetworkImage(
              cacheManager: ImageCacheHelper.customCacheManager,
              imageUrl: widget.radio.logoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                child: const Center(
                  child: PivoteLoader(
                    size: 30,
                    strokeWidth: 3,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                child: Icon(
                  Icons.radio_rounded,
                  color: isDark ? Colors.white24 : Colors.black12,
                  size: artSize * 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context, bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.radio.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            widget.radio.frequency,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizerSection(BuildContext context) {
    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        return _VisualizerBars(isPlaying: audioManager.isPlaying);
      },
    );
  }

  Widget _buildPlayerControls(BuildContext context, bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        final isPlaying = audioManager.isPlaying;
        final isLoading = audioManager.isLoading;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skip Prev
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _navigateRadio(context, -1);
              },
              icon: Icon(
                Icons.skip_previous_rounded,
                color: textColor.withValues(alpha: 0.8),
                size: 38,
              ),
            ),
            const SizedBox(width: 24),
            // Play / Pause Circle
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (isPlaying) {
                  audioManager.pause();
                } else {
                  audioManager.resume();
                }
              },
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: PivoteLoader(
                            color: Colors.white,
                            strokeWidth: 3.5,
                            size: 28,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Skip Next
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _navigateRadio(context, 1);
              },
              icon: Icon(
                Icons.skip_next_rounded,
                color: textColor.withValues(alpha: 0.8),
                size: 38,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeController(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        return StreamBuilder<double>(
          stream: audioManager.volumeStream,
          initialData: audioManager.volume,
          builder: (context, snapshot) {
            final vol = snapshot.data ?? 1.0;
            final isMuted = vol == 0.0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      audioManager.setVolume(isMuted ? 1.0 : 0.0);
                    },
                    icon: Icon(
                      isMuted
                          ? Icons.volume_off_rounded
                          : vol < 0.4
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded,
                      color: textColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: vol,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          audioManager.setVolume(val);
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(vol * 100).toInt()}%',
                    style: GoogleFonts.spaceGrotesk(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateRadio(BuildContext context, int offset) {
    final radioProvider = context.read<RadioProvider>();
    final radios = radioProvider.radios;
    if (radios.isNotEmpty) {
      final currentIndex = radios.indexWhere((r) => r.id == widget.radio.id);
      if (currentIndex != -1) {
        final nextIndex =
            (currentIndex + offset + radios.length) % radios.length;
        final nextRadio = radios[nextIndex];

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RadioPlayerScreen(radio: nextRadio),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  void _showInfoBottomSheet(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: widget.radio.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.radio, color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.radio.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.radio.frequency,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Streaming oficial en vivo',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ENTENDIDO',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _VisualizerBars extends StatefulWidget {
  final bool isPlaying;

  const _VisualizerBars({required this.isPlaying});

  @override
  State<_VisualizerBars> createState() => _VisualizerBarsState();
}

class _VisualizerBarsState extends State<_VisualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [0.2, 0.5, 0.8, 0.4, 0.7, 0.3, 0.6, 0.9, 0.5, 0.8, 0.3, 0.6, 0.4, 0.7, 0.2];
  final int _barCount = 15;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _VisualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (index) {
              double multiplier = 1.0;
              if (widget.isPlaying) {
                // Generate dynamic wavy values using sine wave offset by bar index
                final phase = (_controller.value * 2 * 3.14159) + (index * 0.5);
                multiplier = (0.2 + 0.8 * ((math.sin(phase) + 1.0) / 2.0));
              } else {
                multiplier = 0.15;
              }

              final height = 24.0 * _baseHeights[index] * multiplier;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 3.5,
                height: height.clamp(3.0, 24.0),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? primaryColor.withValues(alpha: 0.85 - (index % 3) * 0.1)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

