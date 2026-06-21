import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';

class MovieLoadingOverlay extends StatefulWidget {
  final int retryAttempt;

  const MovieLoadingOverlay({
    super.key,
    this.retryAttempt = 0,
  });

  @override
  State<MovieLoadingOverlay> createState() => _MovieLoadingOverlayState();
}

class _MovieLoadingOverlayState extends State<MovieLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController1;
  late AnimationController _rotationController2;
  late AnimationController _pulseController;
  int _textIndex = 0;
  final List<String> _loadingTexts = [
    'Preparando película...',
    'Cargando buffer de video...',
    'Ajustando calidad óptima...',
    'Casi listo para comenzar...',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _rotationController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _cycleTexts();
  }

  void _cycleTexts() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingTexts.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _rotationController1.dispose();
    _rotationController2.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = widget.retryAttempt > 0
        ? 'Reconectando (Intento ${widget.retryAttempt}/3)...'
        : _loadingTexts[_textIndex];

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withValues(alpha: 0.75),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dual concentric professional loader
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing ring
                      RotationTransition(
                        turns: _rotationController1,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.darkAccent,
                              ],
                              stops: [0.1, 1.0],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.5),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF090B0F), // deep dark bg
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Inner reverse-rotating ring
                      RotationTransition(
                        turns: _rotationController2,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.darkAccent.withValues(alpha: 0.4),
                              ],
                              stops: const [0.2, 1.0],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF090B0F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Central pulsing movie icon
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.6, end: 1.0).animate(
                            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled_rounded,
                            size: 32,
                            color: AppTheme.darkAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Animated text fading/changing with custom slide/fade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      statusText,
                      key: ValueKey<String>(statusText),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Espera un momento',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
