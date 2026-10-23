import 'package:material_ui/material_ui.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../matches/domain/entities/match_entity.dart';
import '../../../domain/entities/match_details_entity.dart';
import '../../bloc/match_details_state.dart';
import '../stat_comparison_bar.dart';
import 'match_details_skeletons.dart';

class MatchStatsTab extends StatelessWidget {
  final MatchDetailsState state;
  final MatchEntity match;
  final MatchEntity? initialMatch;
  final bool isDark;
  final bool isArabic;
  final Future<void> Function() onRefresh;

  const MatchStatsTab({
    super.key,
    required this.state,
    required this.match,
    this.initialMatch,
    required this.isDark,
    required this.isArabic,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      return MatchDetailsSkeletons.buildStatsSkeleton(
        context,
        isDark: isDark,
        isArabic: isArabic,
      );
    }

    final effectiveStats = state.stats.isNotEmpty
        ? state.stats
        : _buildStatsFromQuickStats(state.overview?.quickStats, isArabic);

    if (effectiveStats.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyView(titleKey: 'tab_stats', icon: Icons.bar_chart_rounded),
          ],
        ),
      );
    }

    final homeName = (match.team1.isNotEmpty && match.team1 != 'Home Team')
        ? match.team1
        : (initialMatch?.team1 ?? (isArabic ? 'صاحب الأرض' : 'Home'));
    final awayName = (match.team2.isNotEmpty && match.team2 != 'Away Team')
        ? match.team2
        : (initialMatch?.team2 ?? (isArabic ? 'الضيف' : 'Away'));
    final homeLogo = match.team1Logo ?? initialMatch?.team1Logo;
    final awayLogo = match.team2Logo ?? initialMatch?.team2Logo;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('stats_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // Team Comparison Header
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home Team
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (homeLogo != null && homeLogo.isNotEmpty) ...[
                        AppImage(
                          imageUrl: homeLogo,
                          width: 24,
                          height: 24,
                          placeholderIcon: Icons.shield_outlined,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          homeName,
                          style: AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center vs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isArabic ? 'الإحصائيات' : 'Stats',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Away Team
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          awayName,
                          style: AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (awayLogo != null && awayLogo.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        AppImage(
                          imageUrl: awayLogo,
                          width: 24,
                          height: 24,
                          placeholderIcon: Icons.shield_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Rows
          if (effectiveStats.any(
            (s) => s.category != null && s.category!.trim().isNotEmpty,
          )) ...[
            ..._buildCategorizedStatsWidgets(effectiveStats, isDark, isArabic),
          ] else ...[
            ...effectiveStats.map((stat) => StatComparisonBar(stat: stat)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedStatsWidgets(
    List<MatchStatItemEntity> stats,
    bool isDark,
    bool isArabic,
  ) {
    final Map<String, List<MatchStatItemEntity>> grouped = {};
    for (final s in stats) {
      final cat = (s.category != null && s.category!.trim().isNotEmpty)
          ? s.category!.trim()
          : (isArabic ? 'إحصائيات عامة' : 'General');
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      IconData icon = Icons.analytics_outlined;
      final lower = entry.key.toLowerCase();
      if (lower.contains('هجوم') || lower.contains('attack')) {
        icon = Icons.sports_soccer_rounded;
      } else if (lower.contains('تمرير') ||
          lower.contains('تحكم') ||
          lower.contains('pass') ||
          lower.contains('control')) {
        icon = Icons.swap_horiz_rounded;
      } else if (lower.contains('دفاع') ||
          lower.contains('انضباط') ||
          lower.contains('defen') ||
          lower.contains('discip')) {
        icon = Icons.shield_outlined;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(
            top: AppDimensions.md,
            bottom: AppDimensions.xs,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardElevated.withValues(alpha: 0.6)
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      );

      widgets.addAll(entry.value.map((stat) => StatComparisonBar(stat: stat)));
    }
    return widgets;
  }

  List<MatchStatItemEntity> _buildStatsFromQuickStats(
    MatchQuickStatsEntity? qs,
    bool isArabic,
  ) {
    if (qs == null || qs.isEmpty) return [];
    final list = <MatchStatItemEntity>[];
    if (qs.homePossession != null || qs.awayPossession != null) {
      final hVal = double.tryParse(qs.homePossession ?? '50') ?? 50;
      final aVal = double.tryParse(qs.awayPossession ?? '50') ?? 50;
      final total = hVal + aVal;
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'الاستحواذ' : 'Ball Possession',
          homeValue: '${qs.homePossession ?? '50'}%',
          awayValue: '${qs.awayPossession ?? '50'}%',
          homePercentage: total > 0 ? (hVal / total) : 0.5,
        ),
      );
    }
    if (qs.homeShots != null || qs.awayShots != null) {
      final h = qs.homeShots ?? 0;
      final a = qs.awayShots ?? 0;
      final total = (h + a).toDouble();
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'إجمالي التسديدات' : 'Total Shots',
          homeValue: '$h',
          awayValue: '$a',
          homePercentage: total > 0 ? (h / total) : 0.5,
        ),
      );
    }
    if (qs.homeFouls != null || qs.awayFouls != null) {
      final h = qs.homeFouls ?? 0;
      final a = qs.awayFouls ?? 0;
      final total = (h + a).toDouble();
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'الأخطاء' : 'Fouls',
          homeValue: '$h',
          awayValue: '$a',
          homePercentage: total > 0 ? (h / total) : 0.5,
        ),
      );
    }
    if (qs.homeOffsides != null || qs.awayOffsides != null) {
      final h = qs.homeOffsides ?? 0;
      final a = qs.awayOffsides ?? 0;
      final total = (h + a).toDouble();
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'التسلل' : 'Offsides',
          homeValue: '$h',
          awayValue: '$a',
          homePercentage: total > 0 ? (h / total) : 0.5,
        ),
      );
    }
    return list;
  }
}
