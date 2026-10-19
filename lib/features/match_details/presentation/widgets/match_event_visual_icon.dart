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

  // ── Yellow Card (Vertical rounded referee card) ──────────────────────────
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

  // ── Red Card (Vertical rounded referee card) ─────────────────────────────
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

  // ── Second Yellow / Red Card (Overlapping Yellow & Red cards) ─────────────
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
          // Back card: Red
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
          // Front card: Yellow
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

  // ── Regular Goal (Crisp soccer ball) ────────────────────────────────────
  Widget _buildGoal(bool isDark) {
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);
    return Icon(
      Icons.sports_soccer_rounded,
      size: isSmall ? 15 : 17,
      color: primaryColor,
    );
  }

  // ── Own Goal (Red soccer ball) ───────────────────────────────────────────
  Widget _buildOwnGoal(bool isDark) {
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);
    return Icon(
      Icons.sports_soccer_rounded,
      size: isSmall ? 15 : 17,
      color: redColor,
    );
  }

  // ── Converted Penalty (Soccer ball + 'P' badge) ──────────────────────────
  // ── Converted Penalty / Penalty Scored (Goal Net with Soccer Ball inside) ─
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

  // ── Missed Penalty (Red soccer ball + Cross) ──────────────────────────────
  Widget _buildMissedPenalty(bool isDark) {
    final size = isSmall ? 17.0 : 19.0;
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_soccer_rounded,
            size: isSmall ? 15 : 17,
            color: redColor.withValues(alpha: 0.65),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: redColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 7,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Disallowed Goal (Red soccer ball + Cancel overlay) ───────────────────
  Widget _buildDisallowedGoal(bool isDark) {
    final size = isSmall ? 17.0 : 19.0;
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_soccer_rounded,
            size: isSmall ? 15 : 17,
            color: redColor,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: redColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.block_rounded,
                size: 6.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Substitution (Clean swap icon) ────────────────────────────────────────
  Widget _buildSubstitution(bool isDark) {
    final subColor = isDark ? AppColors.substitution : const Color(0xFF0891B2);
    return Icon(
      Icons.swap_horiz_rounded,
      size: isSmall ? 14 : 16,
      color: subColor,
    );
  }

  // ── Missed Chance (Soccer ball with impact spark rays as in Yalla Shoot) ──
  Widget _buildMissChance(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 15.0 : 17.0;
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

  // ── Shot Crossbar / Post (Goal frame with impact dot on crossbar) ────────
  Widget _buildShootCrossbar(bool isDark) {
    final width = isSmall ? 18.0 : 20.0;
    final height = isSmall ? 13.0 : 15.0;
    final frameColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const hitColor = Color(0xFFEF4444);

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

  // ── Whistle / Period Marker (Sky blue whistle as in Yalla Shoot) ──────────
  Widget _buildWhistle(bool isDark) {
    return Icon(
      Icons.sports_rounded,
      size: isSmall ? 15 : 18,
      color: const Color(0xFF38BDF8),
    );
  }

  // ── Paused / Interrupted (Amber pause) ───────────────────────────────────
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

  // ── Video Replay (Play button) ───────────────────────────────────────────
  Widget _buildVideo(bool isDark) {
    final playColor = isDark ? AppColors.primary : const Color(0xFF16A34A);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: playColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_circle_fill_rounded,
        size: isSmall ? 13 : 15,
        color: playColor,
      ),
    );
  }

  // ── VAR Decision (TV screen icon) ────────────────────────────────────────
  Widget _buildVar(bool isDark) {
    final varColor = isDark ? AppColors.varEvent : const Color(0xFF2563EB);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: varColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: varColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.tv_rounded,
        size: isSmall ? 13 : 15,
        color: varColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Yalla Shoot-styled Match Events
// ─────────────────────────────────────────────────────────────────────────────

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
    final ballCenter = Offset(size.width * 0.5, size.height * 0.62);
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

class _MissedChancePainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _MissedChancePainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Soccer ball
    final ballCenter = Offset(size.width * 0.36, size.height * 0.62);
    const ballRadius = 4.2;

    final ballStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(ballCenter, ballRadius, ballStroke);

    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, 1.8, innerPaint);

    // Impact burst / sparks radiating from ball on top-right
    final sparkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // Ray 1 (diagonal)
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.40),
      Offset(size.width * 0.85, size.height * 0.18),
      sparkPaint,
    );
    // Ray 2 (vertical-ish)
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.28),
      Offset(size.width * 0.44, size.height * 0.08),
      sparkPaint,
    );
    // Ray 3 (horizontal-ish)
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.58),
      Offset(size.width * 0.94, size.height * 0.58),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MissedChancePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}

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

    // Goal frame
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
    canvas.drawCircle(hitCenter, 2.4, hitPaint);
  }

  @override
  bool shouldRepaint(covariant _CrossbarPainter oldDelegate) =>
      oldDelegate.frameColor != frameColor || oldDelegate.hitColor != hitColor;
}
