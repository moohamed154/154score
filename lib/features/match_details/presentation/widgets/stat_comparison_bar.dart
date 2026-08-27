import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/match_details_entity.dart';

class StatComparisonBar extends StatelessWidget {
  final MatchStatItemEntity stat;

  const StatComparisonBar({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final homePercent = stat.homePercentage.clamp(0.0, 1.0);
    final homeFlex = (homePercent * 100).toInt().clamp(1, 99);
    final awayFlex = ((1.0 - homePercent) * 100).toInt().clamp(1, 99);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hMargin,
        vertical: isSmall ? 6 : 8,
      ),
      child: Column(
        children: [
          // Labels Row: Home Value -- Stat Title -- Away Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.homeValue,
                style:
                    AppTypography.getBodyLarge(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmall ? 13 : 15,
                      color: homePercent >= 0.5
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                    ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    stat.title,
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmall ? 11 : 12,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                stat.awayValue,
                style:
                    AppTypography.getBodyLarge(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmall ? 13 : 15,
                      color: homePercent < 0.5
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Dual Comparison Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: SizedBox(
              height: isSmall ? 5 : 6,
              child: Row(
                children: [
                  Expanded(
                    flex: homeFlex,
                    child: Container(
                      color: homePercent >= 0.5
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: awayFlex,
                    child: Container(
                      color: homePercent < 0.5
                          ? AppColors.accent
                          : (isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
