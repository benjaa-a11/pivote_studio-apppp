import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A highly advanced, professional loading indicator.
/// Designed with a sleek, multi-layered aesthetic combining orbits,
/// segmented rings, and glowing elements for a premium user experience.
class PivoteLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const PivoteLoader({
    super.key,
    this.size = 50.0,
    this.strokeWidth = 3.0,
    this.color,
  });

  @override
  State<PivoteLoader> createState() => _PivoteLoaderState();
}

class _PivoteLoaderState extends State<PivoteLoader>
    with TickerProviderStateMixin {
  late AnimationController _mainRotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Main rotation, smooth and continuous, energetic pace
    _mainRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Breathing pulse for the core and glow (heartbeat-like)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainRotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium primary color fallback
    final activeColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainRotationController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _AdvancedPivoteLoaderPainter(
              color: activeColor,
              strokeWidth: widget.strokeWidth,
              rotationProgress: _mainRotationController.value,
              pulseProgress: Curves.easeInOutSine.transform(_pulseController.value),
            ),
          );
        },
      ),
    );
  }
}

class _AdvancedPivoteLoaderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double rotationProgress;
  final double pulseProgress;

  _AdvancedPivoteLoaderPainter({
    required this.color,
    required this.strokeWidth,
    required this.rotationProgress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Scale the whole loader slightly with the pulse for a "breathing" effect
    final scale = 0.95 + (pulseProgress * 0.05);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    // --- 0. Ambient Glow ---
    final glowRadius = radius * 0.7 + (pulseProgress * radius * 0.15);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15 + (pulseProgress * 0.1))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, glowRadius, glowPaint);

    // --- 1. Outer Track (Thin, Static-ish background) ---
    final outerRadius = radius - strokeWidth;
    final outerTrackPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5;
    canvas.drawCircle(center, outerRadius, outerTrackPaint);

    // --- 2. Outer Orbit (Two Comets, Clockwise) ---
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final outerRotation = rotationProgress * 2 * math.pi;
    
    // We draw two arcs opposite to each other
    _drawComet(
      canvas: canvas,
      rect: outerRect,
      startAngle: outerRotation,
      sweepAngle: math.pi * 0.7,
      color: color,
      strokeWidth: strokeWidth,
    );
    _drawComet(
      canvas: canvas,
      rect: outerRect,
      startAngle: outerRotation + math.pi, // Opposite side
      sweepAngle: math.pi * 0.7,
      color: color,
      strokeWidth: strokeWidth,
    );

    // --- 3. Middle Segmented Ring (Counter-Rotating) ---
    final middleRadius = outerRadius - strokeWidth * 2.5;
    if (middleRadius > 0) {
      final middlePaint = Paint()
        ..color = color.withValues(alpha: 0.5 + (pulseProgress * 0.3))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.7
        ..strokeCap = StrokeCap.round;

      // 4 segments
      const segmentCount = 4;
      final segmentSweep = (math.pi * 2) / segmentCount * 0.5; // Half segment, half gap
      final middleRotation = -(rotationProgress * 2 * math.pi) * 1.2; // 1.2x speed, counter-clockwise

      for (int i = 0; i < segmentCount; i++) {
        final startAngle = middleRotation + (i * (math.pi * 2 / segmentCount));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: middleRadius),
          startAngle,
          segmentSweep,
          false,
          middlePaint,
        );
      }
    }

    // --- 4. Inner Orbit (Fast Clockwise) ---
    final innerRadius = middleRadius - strokeWidth * 2.0;
    if (innerRadius > 0) {
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      final innerRotation = rotationProgress * 2 * math.pi * 2.0; // 2.0x speed
      
      _drawComet(
        canvas: canvas,
        rect: innerRect,
        startAngle: innerRotation,
        sweepAngle: math.pi * 0.9,
        color: color.withValues(alpha: 0.8),
        strokeWidth: strokeWidth * 0.8,
      );
    }

    // --- 5. Pulsing Core ---
    final coreRadius = strokeWidth * (0.8 + pulseProgress * 0.5);
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    
    // Core intense glow
    final coreGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.6 * pulseProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(center, coreRadius * 2.5, coreGlowPaint);
    canvas.drawCircle(center, coreRadius, corePaint);

    canvas.restore();
  }

  void _drawComet({
    required Canvas canvas,
    required Rect rect,
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required double strokeWidth,
  }) {
    final sweepRatio = sweepAngle / (math.pi * 2);
    
    final gradient = SweepGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.3),
        color,
        color, // ensure the rest of the gradient is covered
      ],
      stops: [
        0.0,
        sweepRatio * 0.5,
        sweepRatio,
        1.0,
      ],
      transform: GradientRotation(startAngle),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AdvancedPivoteLoaderPainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
