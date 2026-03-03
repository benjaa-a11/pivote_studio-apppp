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

    // Subtle rotation/breathing for the logo
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Ensure the manager plays this radio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = context.read<AudioManager>();
      if (audioManager.currentRadio?.id != widget.radio.id) {
        audioManager.playRadio(widget.radio);
      }
    });

    // Set initial system UI for player
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Listen to errors from AudioManager
    _setupErrorListener();
  }

  void _setupErrorListener() {
    final audioManager = context.read<AudioManager>();
    audioManager.addListener(_onAudioManagerChanged);
  }

  void _onAudioManagerChanged() {
    if (!mounted) return;
    final audioManager = context.read<AudioManager>();
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
      // Stop radio playback when the player is dismissed as per user request
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
                // Background Gradient/Glow (Subtle)
                _buildDynamicBackground(context, isDark),

                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, isDark),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 2),
                              _buildPlayerArt(context, size),
                              const Spacer(flex: 2),
                              _buildPlayerInfo(context, isDark),
                              const Spacer(flex: 2),
                              _buildPlayerControls(context, isDark),
                              const Spacer(flex: 3),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.inverseSurface,
                ]
              : [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context)
                      .colorScheme
                      .inverseSurface
                      .withValues(alpha: 0.05),
                ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              context.read<AudioManager>().stop();
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.chevron_left_rounded,
              color: textColor.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RADIO EN VIVO',
                style: GoogleFonts.syne(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Show more options (e.g. share / info)
            },
            icon: Icon(
              Icons.more_horiz_rounded,
              color: textColor.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArt(BuildContext context, Size size) {
    final artSize = size.width * 0.8;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle radial glow behind album art
          Container(
            width: artSize * 1.15,
            height: artSize * 1.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Hero(
            tag: 'radio_tile_logo_${widget.radio.id}',
            child: Container(
              width: artSize,
              height: artSize,
              decoration: ShapeDecoration(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(96),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(96),
                  ),
                ),
                child: CachedNetworkImage(
                  cacheManager: ImageCacheHelper.customCacheManager,
                  imageUrl: widget.radio.logoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    child: Icon(Icons.radio,
                        color: isDark ? Colors.white24 : Colors.black12,
                        size: 64),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context, bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Text(
          widget.radio.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.radio.frequency,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(BuildContext context, bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        final isPlaying = audioManager.isPlaying;
        final isLoading = audioManager.isLoading;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () => _navigateRadio(context, -1),
              icon: Icon(
                Icons.skip_previous_rounded,
                color: textColor,
                size: 44,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (isPlaying) {
                  audioManager.pause();
                } else {
                  audioManager.resume();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _navigateRadio(context, 1),
              icon: Icon(
                Icons.skip_next_rounded,
                color: textColor,
                size: 44,
              ),
            ),
          ],
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
}
