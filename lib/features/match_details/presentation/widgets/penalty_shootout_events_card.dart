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
    final homeAttempts =
        penaltiesDetail?.homeAttempts ?? fallbackAttempts1 ?? [];
    final awayAttempts =
        penaltiesDetail?.awayAttempts ?? fallbackAttempts2 ?? [];

    final homeScore = penaltiesDetail?.homeScore ?? penaltyScore1;
    final awayScore = penaltiesDetail?.awayScore ?? penaltyScore2;

    final homeKicks = penaltiesDetail?.homeKicks ?? [];
    final awayKicks = penaltiesDetail?.awayKicks ?? [];
    final maxKicks = homeKicks.length > awayKicks.length
        ? homeKicks.length
        : awayKicks.length;

    final cardBg = isDark ? const Color(0xFF141927) : const Color(0xFFF1F5F9);
    final borderColor =
        isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);

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
          // Perfectly centered score regardless of asymmetrical kick counts
          Row(
            children: [
              // Home Team Kick Balls (anchored towards the center score)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: homeAttempts.isNotEmpty
                      ? _buildBallRow(homeAttempts)
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 12),

              // Shootout Score - ALWAYS MATHEMATICALLY CENTERED
              Text(
                '$homeScore - $awayScore',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 12),

              // Away Team Kick Balls (anchored towards the center score)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: awayAttempts.isNotEmpty
                      ? _buildBallRow(awayAttempts)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── 3. Running FT Score & "Penalties" Label ──────────────────────
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

          // ── 4. Kick-by-Kick Shootout Takers in Order ──────────────────────
          if (maxKicks > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: borderColor,
              ),
            ),
            for (int i = 0; i < maxKicks; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Row(
                  children: [
                    // Home kicker on Left (Name then Ball)
                    Expanded(
                      child: i < homeKicks.length
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    homeKicks[i].playerName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildKickBall(homeKicks[i].isGoal),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Order Number Pill in the exact center
                    Container(
                      width: 24,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2638)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),

                    // Away kicker on Right (Ball then Name)
                    Expanded(
                      child: i < awayKicks.length
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildKickBall(awayKicks[i].isGoal),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    awayKicks[i].playerName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildKickBall(bool isGoal) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGoal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        border: Border.all(
          color: isGoal ? const Color(0xFF059669) : const Color(0xFFDC2626),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        isGoal ? Icons.sports_soccer_rounded : Icons.close_rounded,
        size: 11.5,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBallRow(List<bool> attempts) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: attempts.map((isGoal) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildKickBall(isGoal),
        );
      }).toList(),
    );
  }
}
