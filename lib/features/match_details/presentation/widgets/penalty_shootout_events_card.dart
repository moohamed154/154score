import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/match_details_entity.dart';

/// Renders the Yalla Shoot styled Penalty Shootout header box in the Events tab.
class PenaltyShootoutEventsCard extends StatelessWidget {
  final PenaltyShootoutDetailEntity? penaltiesDetail;
  final String penaltyScore1;
  final String penaltyScore2;
  final List<bool>? fallbackAttempts1;
  final List<bool>? fallbackAttempts2;
  final String fullTimeScore;
  final bool isDark;
  final bool isArabic;

  const PenaltyShootoutEventsCard({
    super.key,
    this.penaltiesDetail,
    required this.penaltyScore1,
    required this.penaltyScore2,
    this.fallbackAttempts1,
    this.fallbackAttempts2,
    this.fullTimeScore = '0 - 0',
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final homeAttempts = penaltiesDetail?.homeAttempts ?? fallbackAttempts1 ?? [];
    final awayAttempts = penaltiesDetail?.awayAttempts ?? fallbackAttempts2 ?? [];

    final homeScore = penaltiesDetail?.homeScore ?? penaltyScore1;
    final awayScore = penaltiesDetail?.awayScore ?? penaltyScore2;

    final homeKicks = penaltiesDetail?.homeKicks ?? [];
    final awayKicks = penaltiesDetail?.awayKicks ?? [];
    final maxKicks = homeKicks.length > awayKicks.length ? homeKicks.length : awayKicks.length;

    final cardBg = isDark ? const Color(0xFF141927) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Top Whistle + Full Time Label ─────────────────────────────
          const Icon(
            Icons.sports_rounded,
            size: 20,
            color: Color(0xFF38BDF8),
          ),
          const SizedBox(height: 3),
          Text(
            isArabic ? 'نهاية المباراة' : 'Full-Time',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // ── 2. Shootout Row: [Dots]  Score  [Dots] ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home Team Kick Balls
              if (homeAttempts.isNotEmpty) ...[
                _buildBallRow(homeAttempts),
                const SizedBox(width: 14),
              ],

              // Shootout Score
              Text(
                '$homeScore - $awayScore',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),

              // Away Team Kick Balls
              if (awayAttempts.isNotEmpty) ...[
                const SizedBox(width: 14),
                _buildBallRow(awayAttempts),
              ],
            ],
          ),

          // ── 3. Kick-by-Kick Details Rows ────────────────────────────────
          if (maxKicks > 0) ...[
            const SizedBox(height: 14),
            for (int i = 0; i < maxKicks; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    // Home kicker on Left
                    Expanded(
                      child: i < homeKicks.length
                          ? _buildHomeKickerText(homeKicks[i], isDark, isArabic)
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 12),
                    // Away kicker on Right
                    Expanded(
                      child: i < awayKicks.length
                          ? _buildAwayKickerText(awayKicks[i], isDark, isArabic)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 12),

          // ── 4. Running FT Score & "Penalties" Label ──────────────────────
          Text(
            fullTimeScore,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isArabic ? 'ركلات الترجيح' : 'Penalties',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeKickerText(
    PenaltyKickItemEntity kick,
    bool isDark,
    bool isArabic,
  ) {
    final status = kick.isGoal
        ? (isArabic ? 'هدف' : 'Goal')
        : (isArabic ? 'ضائعة' : 'Missed');
    return Text(
      '${kick.order}- ${kick.playerName} ($status)',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
    );
  }

  Widget _buildAwayKickerText(
    PenaltyKickItemEntity kick,
    bool isDark,
    bool isArabic,
  ) {
    final status = kick.isGoal
        ? (isArabic ? 'هدف' : 'Goal')
        : (isArabic ? 'ضائعة' : 'Missed');
    return Text(
      '${kick.playerName} ($status) -${kick.order}',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
    );
  }

  Widget _buildBallRow(List<bool> attempts) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: attempts.map((isGoal) {
        return Container(
          width: 17,
          height: 17,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isGoal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            border: Border.all(
              color: isGoal ? const Color(0xFF059669) : const Color(0xFFDC2626),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.sports_soccer_rounded,
            size: 11.5,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }
}
