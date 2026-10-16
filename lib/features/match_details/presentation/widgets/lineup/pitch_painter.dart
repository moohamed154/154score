import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Paints an authentic, high-definition football pitch with alternating grass stripes,
/// touchlines, center circle, penalty boxes, penalty spots, and penalty arcs.
class PitchPainter extends CustomPainter {
  final bool isDark;
  final Color? baseGrassColor;
  final Color? lineColor;

  const PitchPainter({
    required this.isDark,
    this.baseGrassColor,
    this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Turf Color
    final grassColor = baseGrassColor ??
        (isDark ? const Color(0xFF143B25) : const Color(0xFF1E663B));
    final grassPaint = Paint()..color = grassColor;
    final pitchRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(pitchRect, grassPaint);

    // 2. Alternating Mowing Grass Stripes
    const stripeCount = 12;
    final stripeHeight = h / stripeCount;
    final stripePaint = Paint()
      ..color = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.045);

    for (int i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, w, stripeHeight),
        stripePaint,
      );
    }

    // 3. Pitch Lines Paint
    final strokeColor = lineColor ?? Colors.white.withValues(alpha: 0.7);
    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final fillDotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Safe Inset Margin for Chalk Lines
    final marginX = w * 0.04;
    final marginY = h * 0.03;
    final fieldW = w - (marginX * 2);
    final fieldH = h - (marginY * 2);
    final fieldRect = Rect.fromLTWH(marginX, marginY, fieldW, fieldH);

    // Outer Boundary Box
    canvas.drawRect(fieldRect, linePaint);

    // Halfway Line
    final midY = marginY + (fieldH / 2);
    canvas.drawLine(
      Offset(marginX, midY),
      Offset(marginX + fieldW, midY),
      linePaint,
    );

    // Center Circle & Center Spot
    final centerX = marginX + (fieldW / 2);
    final centerCircleRadius = fieldW * 0.17;
    canvas.drawCircle(Offset(centerX, midY), centerCircleRadius, linePaint);
    canvas.drawCircle(Offset(centerX, midY), 3.0, fillDotPaint);

    // 4. Top Penalty Area & Goal Area (Away Side)
    final penaltyBoxW = fieldW * 0.52;
    final penaltyBoxH = fieldH * 0.16;
    final penaltyBoxLeft = centerX - (penaltyBoxW / 2);
    final topPenaltyRect = Rect.fromLTWH(
      penaltyBoxLeft,
      marginY,
      penaltyBoxW,
      penaltyBoxH,
    );
    canvas.drawRect(topPenaltyRect, linePaint);

    final goalBoxW = fieldW * 0.26;
    final goalBoxH = fieldH * 0.06;
    final goalBoxLeft = centerX - (goalBoxW / 2);
    final topGoalRect = Rect.fromLTWH(goalBoxLeft, marginY, goalBoxW, goalBoxH);
    canvas.drawRect(topGoalRect, linePaint);

    // Top Penalty Spot & Arc
    final topSpotY = marginY + (fieldH * 0.11);
    canvas.drawCircle(Offset(centerX, topSpotY), 2.5, fillDotPaint);

    // Top Penalty Arc (facing downwards outside penalty box)
    final arcRectTop = Rect.fromCircle(
      center: Offset(centerX, topSpotY),
      radius: centerCircleRadius * 0.65,
    );
    canvas.drawArc(
      arcRectTop,
      math.pi * 0.18,
      math.pi * 0.64,
      false,
      linePaint,
    );

    // 5. Bottom Penalty Area & Goal Area (Home Side)
    final bottomPenaltyY = marginY + fieldH - penaltyBoxH;
    final bottomPenaltyRect = Rect.fromLTWH(
      penaltyBoxLeft,
      bottomPenaltyY,
      penaltyBoxW,
      penaltyBoxH,
    );
    canvas.drawRect(bottomPenaltyRect, linePaint);

    final bottomGoalY = marginY + fieldH - goalBoxH;
    final bottomGoalRect = Rect.fromLTWH(
      goalBoxLeft,
      bottomGoalY,
      goalBoxW,
      goalBoxH,
    );
    canvas.drawRect(bottomGoalRect, linePaint);

    // Bottom Penalty Spot & Arc
    final bottomSpotY = marginY + fieldH - (fieldH * 0.11);
    canvas.drawCircle(Offset(centerX, bottomSpotY), 2.5, fillDotPaint);

    // Bottom Penalty Arc (facing upwards outside penalty box)
    final arcRectBottom = Rect.fromCircle(
      center: Offset(centerX, bottomSpotY),
      radius: centerCircleRadius * 0.65,
    );
    canvas.drawArc(
      arcRectBottom,
      -math.pi * 0.82,
      math.pi * 0.64,
      false,
      linePaint,
    );

    // 6. Corner Arcs
    const cornerRadius = 8.0;
    // Top-Left
    canvas.drawArc(
      Rect.fromCircle(center: Offset(marginX, marginY), radius: cornerRadius),
      0,
      math.pi / 2,
      false,
      linePaint,
    );
    // Top-Right
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(marginX + fieldW, marginY),
        radius: cornerRadius,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );
    // Bottom-Left
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(marginX, marginY + fieldH),
        radius: cornerRadius,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );
    // Bottom-Right
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(marginX + fieldW, marginY + fieldH),
        radius: cornerRadius,
      ),
      math.pi,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PitchPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.baseGrassColor != baseGrassColor ||
        oldDelegate.lineColor != lineColor;
  }
}
