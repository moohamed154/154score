import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Standard visual event types according to MOBILE_ENDPOINTS.md Section 5:
/// Event & Lineup Visual Icons Catalog
enum MatchVisualEventType {
  goal, // ic_goal: Regular goal
  ownGoal, // ic_own_goal: Own goal
  successPenalty, // ic_success_penalty: Converted penalty
  missedPenalty, // ic_missed_penalty: Missed penalty
  disallowedGoal, // ic_disallowed_goal: Disallowed goal (VAR)
  yellowCard, // ic_yellow_card: Yellow card
  redCard, // ic_red_card: Red card
  yellowRedCard, // ic_yellow_red_card: Second yellow / Red card
  substitution, // ic_substitution: Substitution
  missChance, // ic_miss_chance: Missed chance
  shootCrossbar, // ic_shoot_crossbar: Shot on crossbar/post
  whistle, // ic_whistle: Whistle / Half-time / Full-time
  paused, // ic_paused: Match paused / interruption
  video, // ic_video: Video replay available
  varDecision, // VAR decision
}

class MatchEventVisualIcon extends StatelessWidget {
  final MatchVisualEventType type;
  final bool isSmall;
  final bool? isDark;

  const MatchEventVisualIcon({
    super.key,
    required this.type,
    this.isSmall = false,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);

    switch (type) {
      case MatchVisualEventType.yellowCard:
        return _buildYellowCard(effectiveDark);
      case MatchVisualEventType.redCard:
        return _buildRedCard(effectiveDark);
      case MatchVisualEventType.yellowRedCard:
        return _buildYellowRedCard(effectiveDark);
      case MatchVisualEventType.goal:
        return _buildGoal(effectiveDark);
      case MatchVisualEventType.ownGoal:
        return _buildOwnGoal(effectiveDark);
      case MatchVisualEventType.successPenalty:
        return _buildSuccessPenalty(effectiveDark);
      case MatchVisualEventType.missedPenalty:
        return _buildMissedPenalty(effectiveDark);
      case MatchVisualEventType.disallowedGoal:
        return _buildDisallowedGoal(effectiveDark);
      case MatchVisualEventType.substitution:
        return _buildSubstitution(effectiveDark);
      case MatchVisualEventType.missChance:
        return _buildMissChance(effectiveDark);
      case MatchVisualEventType.shootCrossbar:
        return _buildShootCrossbar(effectiveDark);
      case MatchVisualEventType.whistle:
        return _buildWhistle(effectiveDark);
      case MatchVisualEventType.paused:
        return _buildPaused(effectiveDark);
      case MatchVisualEventType.video:
        return _buildVideo(effectiveDark);
      case MatchVisualEventType.varDecision:
        return _buildVar(effectiveDark);
    }
  }

  // ── 1. Yellow Card (Vertical rounded referee card) ──────────────────────────
  Widget _buildYellowCard(bool isDark) {
    final width = isSmall ? 10.0 : 12.0;
    final height = isSmall ? 14.0 : 16.0;
    final cardColor =
        isDark ? const Color(0xFFFACC15) : const Color(0xFFEAB308);
    final borderColor =
        isDark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFFACC15).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  // ── 2. Red Card (Vertical rounded referee card) ─────────────────────────────
  Widget _buildRedCard(bool isDark) {
    final width = isSmall ? 10.0 : 12.0;
    final height = isSmall ? 14.0 : 16.0;
    final cardColor =
        isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final borderColor =
        isDark ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  // ── 3. Second Yellow / Red Card (Overlapping Yellow & Red cards) ─────────────
  Widget _buildYellowRedCard(bool isDark) {
    final cardW = isSmall ? 9.0 : 11.0;
    final cardH = isSmall ? 13.0 : 15.0;
    final totalW = isSmall ? 14.0 : 16.0;
    final totalH = isSmall ? 15.0 : 17.0;

    final redColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final redBorder =
        isDark ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);
    final yellowColor =
        isDark ? const Color(0xFFFACC15) : const Color(0xFFEAB308);
    final yellowBorder =
        isDark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04);

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: cardW,
              height: cardH,
              decoration: BoxDecoration(
                color: redColor,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: redBorder, width: 0.6),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: cardW,
              height: cardH,
              decoration: BoxDecoration(
                color: yellowColor,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: yellowBorder, width: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.2),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Regular Goal (Crisp Vector Classic Football) ──────────────────────────
  Widget _buildGoal(bool isDark) {
    final size = isSmall ? 15.0 : 17.0;
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoalPainter(
          color: primaryColor,
          isDark: isDark,
        ),
      ),
    );
  }

  // ── 5. Own Goal (Crisp Vector Classic Football in Red) ─────────────────────
  Widget _buildOwnGoal(bool isDark) {
    final size = isSmall ? 15.0 : 17.0;
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoalPainter(
          color: redColor,
          isDark: isDark,
        ),
      ),
    );
  }

  // ── 6. Penalty Scored (Goal Net with Football inside) ───────────────────────
  Widget _buildSuccessPenalty(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 14.0 : 16.0;
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GoalNetPainter(
          color: primaryColor,
          isDark: isDark,
        ),
      ),
    );
  }

  // ── 7. Missed Penalty (Goal Frame with Red ✕) ─────────────────────────────
  Widget _buildMissedPenalty(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 14.0 : 16.0;
    final frameColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final crossColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MissedPenaltyPainter(
          frameColor: frameColor,
          crossColor: crossColor,
        ),
      ),
    );
  }

  // ── 8. Disallowed Goal (Football with Red Diagonal Slash ⃠) ───────────────
  Widget _buildDisallowedGoal(bool isDark) {
    final size = isSmall ? 16.0 : 18.0;
    final ballColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cancelColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DisallowedGoalPainter(
          ballColor: ballColor,
          cancelColor: cancelColor,
        ),
      ),
    );
  }

  // ── 9. Substitution (Clean horizontal swap arrows) ─────────────────────────
  Widget _buildSubstitution(bool isDark) {
    final subColor = isDark ? AppColors.substitution : const Color(0xFF0891B2);
    return Icon(
      Icons.swap_horiz_rounded,
      size: isSmall ? 15 : 17,
      color: subColor,
    );
  }

  // ── 10. Missed Chance (Soccer ball with impact spark rays as in Yalla Shoot) ──
  Widget _buildMissChance(bool isDark) {
    final width = isSmall ? 19.0 : 21.0;
    final height = isSmall ? 16.0 : 18.0;
    final color = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MissedChancePainter(
          color: color,
          isDark: isDark,
        ),
      ),
    );
  }

  // ── 11. Shot Crossbar / Post (Goal frame with impact dot on crossbar) ──────
  Widget _buildShootCrossbar(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 13.0 : 15.0;
    final frameColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final hitColor = isDark ? AppColors.redCard : const Color(0xFFEF4444);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CrossbarPainter(
          frameColor: frameColor,
          hitColor: hitColor,
        ),
      ),
    );
  }

  // ── 12. Whistle / Period Marker (Sky blue referee whistle as in Yalla Shoot) ──
  Widget _buildWhistle(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 16.0 : 18.0;
    const whistleColor = Color(0xFF38BDF8);

    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(
        painter: _WhistlePainter(
          color: whistleColor,
        ),
      ),
    );
  }

  // ── 13. Paused / Interrupted (Amber pause) ───────────────────────────────────
  Widget _buildPaused(bool isDark) {
    final pauseColor =
        isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: pauseColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.pause_circle_filled_rounded,
        size: isSmall ? 14 : 16,
        color: pauseColor,
      ),
    );
  }

  // ── 14. Video Replay (Solid vibrant circle with white play triangle) ──────
  Widget _buildVideo(bool isDark) {
    final playColor = isDark ? AppColors.primary : const Color(0xFF16A34A);
    final size = isSmall ? 18.0 : 20.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: playColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: playColor.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_arrow_rounded,
        size: isSmall ? 12 : 13.5,
        color: Colors.white,
      ),
    );
  }

  // ── 15. VAR Decision (Referee TV screen monitor) ──────────────────────────
  Widget _buildVar(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 15.0 : 17.0;
    final varColor = isDark ? AppColors.varEvent : const Color(0xFF2563EB);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _VarPainter(
          color: varColor,
          isDark: isDark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Yalla Shoot-styled Match Events
// ─────────────────────────────────────────────────────────────────────────────

/// Vector football icon matching Yalla Shoot's classic ball geometry
class _GoalPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _GoalPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 1.0;

    // Outer circle outline
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(center, radius, outlinePaint);

    // Center pentagon
    final pentagonRadius = radius * 0.42;
    final pentagonPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * (pi / 180);
      final x = center.dx + pentagonRadius * cos(angle);
      final y = center.dy + pentagonRadius * sin(angle);
      if (i == 0) {
        pentagonPath.moveTo(x, y);
      } else {
        pentagonPath.lineTo(x, y);
      }
    }
    pentagonPath.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(pentagonPath, fillPaint);

    // Seam lines connecting pentagon vertices to outer perimeter
    final seamPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * (pi / 180);
      final x1 = center.dx + pentagonRadius * cos(angle);
      final y1 = center.dy + pentagonRadius * sin(angle);
      final x2 = center.dx + radius * cos(angle);
      final y2 = center.dy + radius * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), seamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}

/// Goal net with ball inside for Penalty Scored
class _GoalNetPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _GoalNetPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final netPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Goal frame: Left post, top crossbar, right post
    final path = Path()
      ..moveTo(2, size.height - 1)
      ..lineTo(2, 2.5)
      ..lineTo(size.width - 2, 2.5)
      ..lineTo(size.width - 2, size.height - 1);
    canvas.drawPath(path, framePaint);

    // Ground bottom line
    canvas.drawLine(
      Offset(2, size.height - 1),
      Offset(size.width - 2, size.height - 1),
      netPaint,
    );

    // Vertical net grid lines
    final stepX = (size.width - 4) / 4;
    for (int i = 1; i <= 3; i++) {
      final x = 2 + stepX * i;
      canvas.drawLine(Offset(x, 2.5), Offset(x, size.height - 1), netPaint);
    }
    // Horizontal net grid line
    canvas.drawLine(
      Offset(2, size.height * 0.52),
      Offset(size.width - 2, size.height * 0.52),
      netPaint,
    );

    // Soccer ball inside the net
    final ballCenter = Offset(size.width * 0.5, size.height * 0.65);
    const ballRadius = 3.2;
    final ballPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    final innerPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, 1.2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _GoalNetPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}

/// Goal frame with red cross for Missed Penalty
class _MissedPenaltyPainter extends CustomPainter {
  final Color frameColor;
  final Color crossColor;

  const _MissedPenaltyPainter({
    required this.frameColor,
    required this.crossColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final netPaint = Paint()
      ..color = frameColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    // Goal frame
    final path = Path()
      ..moveTo(2, size.height - 1)
      ..lineTo(2, 2.5)
      ..lineTo(size.width - 2, 2.5)
      ..lineTo(size.width - 2, size.height - 1);
    canvas.drawPath(path, framePaint);

    // Ground line
    canvas.drawLine(
      Offset(2, size.height - 1),
      Offset(size.width - 2, size.height - 1),
      netPaint,
    );

    // Red Cross mark across the goal
    final crossPaint = Paint()
      ..color = crossColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height * 0.55;
    const r = 4.2;

    canvas.drawLine(Offset(cx - r, cy - r), Offset(cx + r, cy + r), crossPaint);
    canvas.drawLine(Offset(cx + r, cy - r), Offset(cx - r, cy + r), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _MissedPenaltyPainter oldDelegate) =>
      oldDelegate.frameColor != frameColor || oldDelegate.crossColor != crossColor;
}

/// Disallowed goal with red diagonal slash
class _DisallowedGoalPainter extends CustomPainter {
  final Color ballColor;
  final Color cancelColor;

  const _DisallowedGoalPainter({
    required this.ballColor,
    required this.cancelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 1.0;

    // Base soccer ball outline
    final ballPaint = Paint()
      ..color = ballColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(center, radius, ballPaint);

    // Pentagon
    final pentagonRadius = radius * 0.38;
    final pentagonPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * (pi / 180);
      final x = center.dx + pentagonRadius * cos(angle);
      final y = center.dy + pentagonRadius * sin(angle);
      if (i == 0) {
        pentagonPath.moveTo(x, y);
      } else {
        pentagonPath.lineTo(x, y);
      }
    }
    pentagonPath.close();
    final fillPaint = Paint()
      ..color = ballColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pentagonPath, fillPaint);

    // Red cancel circle with diagonal slash
    final cancelCirclePaint = Paint()
      ..color = cancelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius + 0.5, cancelCirclePaint);

    final slashPaint = Paint()
      ..color = cancelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const offsetAngle = 45 * (pi / 180);
    final dx = (radius + 0.5) * cos(offsetAngle);
    final dy = (radius + 0.5) * sin(offsetAngle);
    canvas.drawLine(
      Offset(center.dx - dx, center.dy + dy),
      Offset(center.dx + dx, center.dy - dy),
      slashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DisallowedGoalPainter oldDelegate) =>
      oldDelegate.ballColor != ballColor || oldDelegate.cancelColor != cancelColor;
}

/// Missed chance with deflection trajectory & radiating sparks
class _MissedChancePainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _MissedChancePainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Soccer ball on bottom-left
    final ballCenter = Offset(size.width * 0.34, size.height * 0.64);
    const ballRadius = 4.2;

    final ballStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(ballCenter, ballRadius, ballStroke);

    // Inner pentagon pattern
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, 1.8, innerPaint);

    // Deflection trajectory arc
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final arcPath = Path()
      ..moveTo(ballCenter.dx + ballRadius * 0.7, ballCenter.dy - ballRadius * 0.7)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.45,
        size.width * 0.72,
        size.height * 0.35,
      );
    canvas.drawPath(arcPath, arcPaint);

    // Impact burst / sparks radiating to top-right
    final sparkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // Ray 1 (diagonal)
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.32),
      Offset(size.width * 0.92, size.height * 0.16),
      sparkPaint,
    );
    // Ray 2 (upward)
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.26),
      Offset(size.width * 0.68, size.height * 0.08),
      sparkPaint,
    );
    // Ray 3 (rightward)
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.46),
      Offset(size.width * 0.95, size.height * 0.46),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MissedChancePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}

/// Goalpost with impact dot on crossbar
class _CrossbarPainter extends CustomPainter {
  final Color frameColor;
  final Color hitColor;

  const _CrossbarPainter({
    required this.frameColor,
    required this.hitColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Goal frame: Left post, top crossbar, right post
    final path = Path()
      ..moveTo(2, size.height - 1)
      ..lineTo(2, 2.5)
      ..lineTo(size.width - 2, 2.5)
      ..lineTo(size.width - 2, size.height - 1);
    canvas.drawPath(path, framePaint);

    // Impact dot on the crossbar
    final hitCenter = Offset(size.width * 0.5, 2.5);
    final hitPaint = Paint()
      ..color = hitColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hitCenter, 2.5, hitPaint);

    // Inner bright reflection
    final innerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hitCenter, 0.9, innerDot);
  }

  @override
  bool shouldRepaint(covariant _CrossbarPainter oldDelegate) =>
      oldDelegate.frameColor != frameColor || oldDelegate.hitColor != hitColor;
}

/// Referee whistle with sound waves
class _WhistlePainter extends CustomPainter {
  final Color color;

  const _WhistlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Whistle body: cylinder + ball chamber
    final chamberCenter = Offset(size.width * 0.40, size.height * 0.60);
    const chamberRadius = 3.6;
    canvas.drawCircle(chamberCenter, chamberRadius, paint);

    // Whistle inner ball
    canvas.drawCircle(chamberCenter, 1.2, fillPaint);

    // Whistle mouthpiece extending to left
    final mouthPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.44)
      ..lineTo(size.width * 0.40, size.height * 0.44)
      ..moveTo(size.width * 0.15, size.height * 0.58)
      ..lineTo(size.width * 0.32, size.height * 0.58)
      ..lineTo(size.width * 0.15, size.height * 0.58)
      ..lineTo(size.width * 0.15, size.height * 0.44);
    canvas.drawPath(mouthPath, paint);

    // Blow-hole / top window
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.36),
      Offset(size.width * 0.44, size.height * 0.36),
      paint,
    );

    // Sound waves on top-right radiating out
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // Wave 1
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.48, size.height * 0.48),
        radius: 4.8,
      ),
      -1.0,
      1.2,
      false,
      wavePaint,
    );
    // Wave 2
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.48, size.height * 0.48),
        radius: 7.8,
      ),
      -1.0,
      1.2,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WhistlePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// VAR TV screen monitor on stand
class _VarPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _VarPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Monitor screen rectangle
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height * 0.68),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(screenRect, framePaint);

    // Stand neck and base
    final standPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.68 + 2)
      ..lineTo(size.width * 0.5, size.height - 1.5)
      ..moveTo(size.width * 0.32, size.height - 1.5)
      ..lineTo(size.width * 0.68, size.height - 1.5);
    canvas.drawPath(standPath, framePaint);

    // Text "VAR" inside screen
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'VAR',
        style: TextStyle(
          color: color,
          fontSize: 6.5,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height * 0.68 + 2 - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _VarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
