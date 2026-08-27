import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';
import '../utils/score_helper.dart';
import 'animated_score_text.dart';
import 'penalty_shootout_widget.dart';

class MatchScoreWidget extends StatelessWidget {
  final String? score1;
  final String? score2;
  final String? penaltyScore1;
  final String? penaltyScore2;
  final String? halfTimeScore1;
  final String? halfTimeScore2;
  final bool isLive;
  final bool isLarge;

  const MatchScoreWidget({
    super.key,
    required this.score1,
    required this.score2,
    this.penaltyScore1,
    this.penaltyScore2,
    this.halfTimeScore1,
    this.halfTimeScore2,
    this.isLive = false,
    this.isLarge = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final s1 = ScoreHelper.normalizeScore(score1);
    final s2 = ScoreHelper.normalizeScore(score2);

    final hasPenalties =
        penaltyScore1 != null &&
        penaltyScore1!.isNotEmpty &&
        penaltyScore2 != null &&
        penaltyScore2!.isNotEmpty;

    final hasHalfTime =
        halfTimeScore1 != null &&
        halfTimeScore1!.isNotEmpty &&
        halfTimeScore2 != null &&
        halfTimeScore2!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Match Score
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScoreText(score: s1, isLarge: isLarge, isLive: isLive),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                ':',
                style:
                    (isLarge
                            ? AppTypography.getScoreLarge(isDark: isDark)
                            : AppTypography.getScoreMedium(isDark: isDark))
                        .copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
              ),
            ),
            AnimatedScoreText(score: s2, isLarge: isLarge, isLive: isLive),
          ],
        ),

        // Half-Time Score subtitle
        if (hasHalfTime && isLarge) ...[
          const SizedBox(height: 2),
          Text(
            isArabic
                ? '(الشوط الأول: $halfTimeScore1 - $halfTimeScore2)'
                : '(HT: $halfTimeScore1 - $halfTimeScore2)',
            style:
                AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
          ),
        ],

        // Penalty Shootout Result
        if (hasPenalties) ...[
          const SizedBox(height: 6),
          PenaltyShootoutWidget(
            penaltyScore1: penaltyScore1!,
            penaltyScore2: penaltyScore2!,
            isCompact: !isLarge,
          ),
        ],
      ],
    );
  }
}
