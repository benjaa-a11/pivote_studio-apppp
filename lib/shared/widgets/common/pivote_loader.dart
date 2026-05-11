import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The official global loader for the Pivote app.
/// Based on the user-provided CSS design:
/// .loader {
///   width: 50px;
///   padding: 8px;
///   aspect-ratio: 1;
///   border-radius: 50%;
///   background: #25b09b;
///   --_m: 
///     conic-gradient(#0000 10%,#000),
///     linear-gradient(#000 0 0) content-box;
///   ...
/// }
class PivoteLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const PivoteLoader({
    super.key,
    this.size = 50.0,
    this.strokeWidth = 6.0, // Matches the 8px padding/50px ratio approximately
    this.color,
  });

  @override
  State<PivoteLoader> createState() => _PivoteLoaderState();
}

class _PivoteLoaderState extends State<PivoteLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Primary color from CSS or theme
    final baseColor = widget.color ?? const Color(0xFF25B09B);

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _PivoteCSSLoaderPainter(
                color: baseColor,
                strokeWidth: widget.strokeWidth,
                progress: _controller.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PivoteCSSLoaderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  _PivoteCSSLoaderPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // 1. Subtle Glow Effect (Premium enhancement)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    _drawArc(canvas, center, radius, glowPaint);

    // 2. Main Loader Ring (Matches CSS)
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Using round for a more premium feel, but sharp is possible too

    _drawArc(canvas, center, radius, mainPaint);
    
    // 3. Highlight/Shine (Premium enhancement)
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.4
      ..strokeCap = StrokeCap.round;
    
    // Draw a shorter, thinner arc for the shine at the leading edge
    final rotation = progress * 2 * math.pi;
    final shineStart = rotation + (0.1 * 2 * math.pi) + (0.7 * 2 * math.pi); // Near the end of the arc
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      shineStart - (math.pi / 2),
      0.15 * 2 * math.pi,
      false,
      shinePaint,
    );
  }

  void _drawArc(Canvas canvas, Offset center, double radius, Paint paint) {
    final rotation = progress * 2 * math.pi;
    
    // The CSS conic-gradient(#0000 10%,#000) means:
    // 0-10% is transparent (the gap)
    // 10-100% is solid (the ring)
    
    final startAngle = (0.1 * 2 * math.pi) - (math.pi / 2) + rotation;
    const sweepAngle = 0.9 * 2 * math.pi;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PivoteCSSLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth;
  }
}

