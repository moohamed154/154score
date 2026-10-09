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
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

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
    final cardColor = isDark ? const Color(0xFFFACC15) : const Color(0xFFEAB308);
    final borderColor = isDark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04);

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
    final cardColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final borderColor = isDark ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);

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
    final redBorder = isDark ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);
    final yellowColor = isDark ? const Color(0xFFFACC15) : const Color(0xFFEAB308);
    final yellowBorder = isDark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04);

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

  // ── Regular Goal (Green circle + soccer ball) ─────────────────────────────
  Widget _buildGoal(bool isDark) {
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.sports_soccer_rounded,
        size: isSmall ? 13 : 15,
        color: primaryColor,
      ),
    );
  }

  // ── Own Goal (Red circle + soccer ball) ───────────────────────────────────
  Widget _buildOwnGoal(bool isDark) {
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: redColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: redColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.sports_soccer_rounded,
        size: isSmall ? 13 : 15,
        color: redColor,
      ),
    );
  }

  // ── Converted Penalty (Green soccer ball + 'P' badge) ─────────────────────
  Widget _buildSuccessPenalty(bool isDark) {
    final size = isSmall ? 22.0 : 24.0;
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.sports_soccer_rounded,
              size: isSmall ? 13 : 15,
              color: primaryColor,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'P',
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Missed Penalty (Red soccer ball + Cross) ──────────────────────────────
  Widget _buildMissedPenalty(bool isDark) {
    final size = isSmall ? 22.0 : 24.0;
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
            decoration: BoxDecoration(
              color: redColor.withValues(alpha: isDark ? 0.15 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: redColor.withValues(alpha: isDark ? 0.35 : 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.sports_soccer_rounded,
              size: isSmall ? 13 : 15,
              color: redColor.withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
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
    final size = isSmall ? 22.0 : 24.0;
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
            decoration: BoxDecoration(
              color: redColor.withValues(alpha: isDark ? 0.15 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: redColor.withValues(alpha: isDark ? 0.35 : 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.sports_soccer_rounded,
              size: isSmall ? 13 : 15,
              color: redColor,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
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

  // ── Substitution (Cyan circle + swap icon) ────────────────────────────────
  Widget _buildSubstitution(bool isDark) {
    final subColor = isDark ? AppColors.substitution : const Color(0xFF0891B2);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: subColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: subColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.swap_horiz_rounded,
        size: isSmall ? 13 : 15,
        color: subColor,
      ),
    );
  }

  // ── Missed Chance (Amber circle + trending down) ──────────────────────────
  Widget _buildMissChance(bool isDark) {
    final amberColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: amberColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: amberColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.trending_down_rounded,
        size: isSmall ? 13 : 15,
        color: amberColor,
      ),
    );
  }

  // ── Shot Crossbar / Post (Orange circle + goalpost icon) ──────────────────
  Widget _buildShootCrossbar(bool isDark) {
    final orangeColor = isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C);
    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: orangeColor.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: orangeColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.vertical_align_top_rounded,
        size: isSmall ? 13 : 15,
        color: orangeColor,
      ),
    );
  }

  // ── Whistle / Period Marker (Theme-aware slate circle + whistle icon) ─────
  Widget _buildWhistle(bool isDark) {
    final bgColor = isDark
        ? const Color(0xFF64748B).withValues(alpha: 0.15)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? const Color(0xFF64748B).withValues(alpha: 0.35)
        : const Color(0xFFCBD5E1);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Container(
      padding: EdgeInsets.all(isSmall ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.sports_rounded,
        size: isSmall ? 13 : 15,
        color: iconColor,
      ),
    );
  }

  // ── Paused / Interrupted (Amber pause) ───────────────────────────────────
  Widget _buildPaused(bool isDark) {
    final pauseColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
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
