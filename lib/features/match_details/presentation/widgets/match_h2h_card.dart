import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/match_details_entity.dart';

class MatchH2HCard extends StatelessWidget {
  final MatchH2HSummaryEntity summary;

  const MatchH2HCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final total = summary.totalMatches;
    final homeWins = summary.homeWins;
    final awayWins = summary.awayWins;
    final draws = summary.draws;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'سجل المواجهات المباشرة' : 'Head-to-Head Record',
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (total > 0)
                  Text(
                    isArabic ? '$total مباريات' : '$total Matches',
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Stat numbers & team labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home team wins
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$homeWins',
                        style: AppTypography.getHeadingLarge(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: AppColors.uclGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.homeTeamName?.isNotEmpty == true
                            ? summary.homeTeamName!
                            : (isArabic ? 'فوز المضيف' : 'Home Wins'),
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Draws
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$draws',
                        style: AppTypography.getHeadingLarge(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic ? 'تعادل' : 'Draws',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Away team wins
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$awayWins',
                        style: AppTypography.getHeadingLarge(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: AppColors.relegationRed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.awayTeamName?.isNotEmpty == true
                            ? summary.awayTeamName!
                            : (isArabic ? 'فوز الضيف' : 'Away Wins'),
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Distribution Bar
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      if (homeWins > 0)
                        Expanded(
                          flex: homeWins,
                          child: Container(color: AppColors.uclGreen),
                        ),
                      if (draws > 0)
                        Expanded(
                          flex: draws,
                          child: Container(
                            color: isDark
                                ? AppColors.darkTextMuted.withValues(alpha: 0.4)
                                : AppColors.lightTextMuted.withValues(alpha: 0.4),
                          ),
                        ),
                      if (awayWins > 0)
                        Expanded(
                          flex: awayWins,
                          child: Container(color: AppColors.relegationRed),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
