import 'package:flutter/material.dart';

/// Paints a refined soccer pitch outline (cancha de fútbol)
/// with center circle, halfway line, penalty boxes, goal areas and corner arcs.
class SoccerPitchPainter extends CustomPainter {
  final Color lineColor;
  final double strokeWidth;

  const SoccerPitchPainter({
    required this.lineColor,
    this.strokeWidth = 1.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: lineColor.a * 0.6)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Outer border
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, w - 8, h - 8),
      const Radius.circular(18),
    );
    canvas.drawRRect(borderRect, paint);

    // Halfway line (vertical)
    final midX = w / 2;
    canvas.drawLine(Offset(midX, 4), Offset(midX, h - 4), paint);

    // Center circle
    final centerCircleRadius = h * 0.24;
    canvas.drawCircle(Offset(midX, h / 2), centerCircleRadius, paint);

    // Center spot
    canvas.drawCircle(Offset(midX, h / 2), 2.5, fillPaint);

    // Left Penalty Area (Area grande)
    final boxW = w * 0.17;
    final boxH = h * 0.54;
    final boxTop = (h - boxH) / 2;
    canvas.drawRect(Rect.fromLTWH(4, boxTop, boxW, boxH), paint);

    // Left Goal Area (Area chica)
    final smallBoxW = boxW * 0.44;
    final smallBoxH = boxH * 0.52;
    final smallBoxTop = (h - smallBoxH) / 2;
    canvas.drawRect(Rect.fromLTWH(4, smallBoxTop, smallBoxW, smallBoxH), paint);

    // Left penalty spot
    final leftSpotX = 4 + boxW * 0.68;
    canvas.drawCircle(Offset(leftSpotX, h / 2), 2.0, fillPaint);

    // Right Penalty Area (Area grande)
    final rightBoxLeft = w - 4 - boxW;
    canvas.drawRect(Rect.fromLTWH(rightBoxLeft, boxTop, boxW, boxH), paint);

    // Right Goal Area (Area chica)
    final rightSmallBoxLeft = w - 4 - smallBoxW;
    canvas.drawRect(
        Rect.fromLTWH(rightSmallBoxLeft, smallBoxTop, smallBoxW, smallBoxH),
        paint);

    // Right penalty spot
    final rightSpotX = w - 4 - boxW * 0.68;
    canvas.drawCircle(Offset(rightSpotX, h / 2), 2.0, fillPaint);

    // Corner arcs
    const cornerR = 9.0;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(4, 4), radius: cornerR),
      0,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(4, h - 4), radius: cornerR),
      -1.57,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - 4, 4), radius: cornerR),
      1.57,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - 4, h - 4), radius: cornerR),
      3.14,
      1.57,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SoccerPitchPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
