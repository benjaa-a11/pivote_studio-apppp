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
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
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
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Cycle through text to give a premium dynamic feel
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
    _rotationController.dispose();
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
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom cinematic loader spinner with gradient accent
                  RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.darkAccent,
                          ],
                          stops: [0.2, 1.0],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Animated text fading/changing
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
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
