import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/match_details_entity.dart';

class MatchQuickStatsCard extends StatelessWidget {
  final MatchQuickStatsEntity stats;

  const MatchQuickStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

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
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'إحصائيات سريعة' : 'Quick Match Statistics',
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Stat bars
            if (stats.homePossession != null || stats.awayPossession != null)
              _buildStatRow(
                title: isArabic ? 'الاستحواذ' : 'Ball Possession',
                homeValStr: '${stats.homePossession ?? '50'}%',
                awayValStr: '${stats.awayPossession ?? '50'}%',
                homeVal: double.tryParse(stats.homePossession ?? '50') ?? 50,
                awayVal: double.tryParse(stats.awayPossession ?? '50') ?? 50,
                isDark: isDark,
                isArabic: isArabic,
              ),

            if (stats.homeShots != null || stats.awayShots != null) ...[
              const SizedBox(height: 10),
              _buildStatRow(
                title: isArabic ? 'إجمالي التسديدات' : 'Total Shots',
                homeValStr: '${stats.homeShots ?? 0}',
                awayValStr: '${stats.awayShots ?? 0}',
                homeVal: (stats.homeShots ?? 0).toDouble(),
                awayVal: (stats.awayShots ?? 0).toDouble(),
                isDark: isDark,
                isArabic: isArabic,
              ),
            ],

            if (stats.homeFouls != null || stats.awayFouls != null) ...[
              const SizedBox(height: 10),
              _buildStatRow(
                title: isArabic ? 'الأخطاء' : 'Fouls',
                homeValStr: '${stats.homeFouls ?? 0}',
                awayValStr: '${stats.awayFouls ?? 0}',
                homeVal: (stats.homeFouls ?? 0).toDouble(),
                awayVal: (stats.awayFouls ?? 0).toDouble(),
                isDark: isDark,
                isArabic: isArabic,
              ),
            ],

            if (stats.homeOffsides != null || stats.awayOffsides != null) ...[
              const SizedBox(height: 10),
              _buildStatRow(
                title: isArabic ? 'التسلل' : 'Offsides',
                homeValStr: '${stats.homeOffsides ?? 0}',
                awayValStr: '${stats.awayOffsides ?? 0}',
                homeVal: (stats.homeOffsides ?? 0).toDouble(),
                awayVal: (stats.awayOffsides ?? 0).toDouble(),
                isDark: isDark,
                isArabic: isArabic,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String title,
    required String homeValStr,
    required String awayValStr,
    required double homeVal,
    required double awayVal,
    required bool isDark,
    required bool isArabic,
  }) {
    final total = homeVal + awayVal;
    final homePct = total > 0 ? (homeVal / total).clamp(0.05, 0.95) : 0.5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeValStr,
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              title,
              style: AppTypography.getBodySmall(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              awayValStr,
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (homePct * 100).toInt(),
                  child: Container(color: AppColors.primary),
                ),
                Expanded(
                  flex: ((1.0 - homePct) * 100).toInt(),
                  child: Container(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
