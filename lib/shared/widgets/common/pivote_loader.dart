import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A modern, professional loading indicator designed with CSS-like aesthetics.
/// It uses a SweepGradient with a transparent start and a solid end on a circular stroke
/// to mimic a conic-gradient mask over a solid background, creating a sleek spinner.
class PivoteLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const PivoteLoader({
    super.key,
    this.size = 50.0,
    this.strokeWidth = 8.0,
    this.color,
  });

  @override
  State<PivoteLoader> createState() => _PivoteLoaderState();
}

class _PivoteLoaderState extends State<PivoteLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Slightly faster = snappier, more premium feel
      duration: const Duration(milliseconds: 850),
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to a premium cyan color if not specified
    final activeColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PivoteLoaderPainter(
              color: activeColor,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _PivoteLoaderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PivoteLoaderPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Comet-tail effect: transparent for first 15%, fades into full color
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.25),
          color,
        ],
        stops: const [0.0, 0.12, 0.65, 1.0],
        startAngle: 0.0,
        endAngle: 2 * math.pi,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PivoteLoaderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
