import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The official global loader for the Pivote app.
/// Based exactly on the user-provided CSS design:
/// /* HTML: <div class="loader"></div> */
/// .loader {
///   width: 50px;
///   padding: 8px;
///   aspect-ratio: 1;
///   border-radius: 50%;
///   background: #25b09b;
///   --_m: 
///     conic-gradient(#0000 10%,#000),
///     linear-gradient(#000 0 0) content-box;
///   -webkit-mask: var(--_m);
///           mask: var(--_m);
///   -webkit-mask-composite: source-out;
///           mask-composite: subtract;
///   animation: l3 1s infinite linear;
/// }
/// @keyframes l3 {to{transform: rotate(1turn)}}
class PivoteLoader extends StatefulWidget {
  final double size;
  final double? strokeWidth;
  final Color? color;

  const PivoteLoader({
    super.key,
    this.size = 50.0,
    this.strokeWidth, // If null, defaults dynamically to size * 0.16 (matching the 8px padding/50px ratio)
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
      duration: const Duration(milliseconds: 1000), // 1s loop as in CSS
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adapt automatically to the primary theme color if no color is provided
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final resolvedStrokeWidth = widget.strokeWidth ?? (widget.size * 0.16);

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
                strokeWidth: resolvedStrokeWidth,
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
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    // Rotate canvas around center: starting from 12 o'clock (-pi/2) and rotating clockwise
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi - math.pi / 2);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0), // 0% is transparent
          color.withValues(alpha: 0.0), // 10% remains transparent (the gap)
          color,                  // 100% is fully opaque (the tail fade)
        ],
        stops: const [
          0.0,
          0.1,
          1.0,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; // Flat edges exactly matching the CSS conic-gradient/mask effect

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PivoteCSSLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth;
  }
}

