import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/radio.dart' as radio_model;
import '../providers/audio_manager.dart';
import '../providers/radio_provider.dart';

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
  late AnimationController _pulseController;
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

    // Pulse animation for LIVE indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

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
    _slideAnimationController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Stop radio playback when the player is dismissed
          context.read<AudioManager>().stop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
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
                // 1. Background Image with Blur
                _buildBlurBackground(widget.radio.logoUrl),

                // 2. Animated Glow Backdrop (centered behind logo)
                _buildAnimatedGlow(context),

                // 3. Main Content
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(context),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              bool isTall = constraints.maxHeight > 500;
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (isTall) const Spacer(flex: 2),
                                  _buildMainArt(context, size),
                                  if (isTall) const Spacer(flex: 2),
                                  _buildRadioMeta(context),
                                  if (isTall) const Spacer(flex: 2),
                                  _buildMainControls(context),
                                  if (isTall) const Spacer(flex: 3),
                                ],
                              );
                            },
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

  Widget _buildBlurBackground(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, e) => Container(color: Colors.black),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedGlow(BuildContext context) {
    // Generate a soft glow based on a secondary color or just Indigo/Emerald from theme
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo
                      .withValues(alpha: 0.15 * _pulseController.value),
                  blurRadius: 100 + (50 * _pulseController.value),
                  spreadRadius: 20 + (30 * _pulseController.value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _dismissPlayer,
            icon: const Icon(Icons.expand_more_rounded,
                color: Colors.white, size: 36),
          ),
          const Spacer(),
          Text(
            'EN VIVO',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.2).animate(_pulseController),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.redAccent, blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
          ),
          const Spacer(),
          Consumer<RadioProvider>(
            builder: (context, provider, _) {
              final isFav =
                  provider.getRadioById(widget.radio.id)?.isFavorite ?? false;
              return IconButton(
                onPressed: () => provider.toggleFavorite(widget.radio),
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : Colors.white70,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainArt(BuildContext context, Size size) {
    final artSize = size.width * 0.75;
    return Center(
      child: Hero(
        tag: 'radio_tile_logo_${widget.radio.id}',
        child: Container(
          width: artSize,
          height: artSize,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.radio.logoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, _) =>
                      Container(color: Colors.grey[900]),
                ),
                // Glass overlay on the image
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioMeta(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.radio.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            widget.radio.frequency,
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls(BuildContext context) {
    return Consumer<AudioManager>(
      builder: (context, audioManager, _) {
        final isCorrect = audioManager.currentRadio?.id == widget.radio.id;
        final isPlaying = isCorrect && audioManager.isPlaying;
        final isLoading = isCorrect && audioManager.isLoading;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSmallControl(
              icon: Icons.skip_previous_rounded,
              onTap: () => _navigateRadio(context, -1),
            ),

            // Play/Pause Big Button
            GestureDetector(
              onTap: () {
                if (isPlaying) {
                  audioManager.pause();
                } else if (isCorrect) {
                  audioManager.resume();
                } else {
                  audioManager.playRadio(widget.radio);
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 3)
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 48,
                        ),
                ),
              ),
            ),

            _buildSmallControl(
              icon: Icons.skip_next_rounded,
              onTap: () => _navigateRadio(context, 1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallControl(
      {required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 42),
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
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }
}
