import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../domain/entities/top_scorer_entity.dart';

class TopScorersTable extends StatelessWidget {
  final List<TopScorerEntity> scorers;
  final int? maxRows;

  const TopScorersTable({super.key, required this.scorers, this.maxRows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (scorers.isEmpty) {
      return const EmptyView(
        titleKey: 'tab_overview',
        customMessage: 'No top scorers data available',
        icon: Icons.emoji_events_outlined,
      );
    }

    final displayRows = maxRows != null
        ? scorers.take(maxRows!).toList()
        : scorers;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 14,
              vertical: 10,
            ),
            color: isDark
                ? AppColors.darkCardElevated
                : AppColors.lightCardElevated,
            child: Row(
              children: [
                SizedBox(
                  width: isSmall ? 28 : 34,
                  child: Text(
                    '#',
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? 'اللاعب' : 'Player',
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                  ),
                ),
                SizedBox(
                  width: isSmall ? 40 : 50,
                  child: Text(
                    isArabic ? 'الأهداف' : 'Goals',
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayRows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final scorer = displayRows[index];
              return _buildScorerRow(
                context,
                scorer,
                isDark,
                isArabic,
                isSmall,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScorerRow(
    BuildContext context,
    TopScorerEntity scorer,
    bool isDark,
    bool isArabic,
    bool isSmall,
  ) {
    final rankBg = switch (scorer.rank) {
      1 => const Color(0xFFFFD700), // Gold
      2 => const Color(0xFFC0C0C0), // Silver
      3 => const Color(0xFFCD7F32), // Bronze
      _ => Colors.transparent,
    };

    final isTopThree = scorer.rank <= 3;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 14,
        vertical: isSmall ? 8 : 10,
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: isSmall ? 28 : 34,
            height: isSmall ? 24 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTopThree
                  ? rankBg.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              scorer.rank.toString(),
              style:
                  AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: isTopThree ? FontWeight.w800 : FontWeight.w600,
                    color: isTopThree
                        ? (isDark ? rankBg : const Color(0xFFB8860B))
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    fontSize: isSmall ? 12 : 13,
                  ),
            ),
          ),
          const SizedBox(width: 8),

          // Player Image & Name & Club
          Expanded(
            child: Row(
              children: [
                if (scorer.playerImage != null &&
                    scorer.playerImage!.isNotEmpty) ...[
                  AppImage(
                    imageUrl: scorer.playerImage,
                    width: isSmall ? 28 : 34,
                    height: isSmall ? 28 : 34,
                    borderRadius: (isSmall ? 28 : 34) / 2,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.person_rounded,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scorer.playerName,
                        style:
                            AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: isSmall ? 12 : 14,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (scorer.teamName != null) ...[
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () {
                            final tId =
                                scorer.teamId ??
                                Uri.encodeComponent(scorer.teamName!);
                            context.push(
                              '/team/$tId',
                              extra: {
                                'name': scorer.teamName,
                                'logo': scorer.teamLogo,
                              },
                            );
                          },
                          child: Row(
                            children: [
                              if (scorer.teamLogo != null) ...[
                                AppImage(
                                  imageUrl: scorer.teamLogo,
                                  width: 14,
                                  height: 14,
                                  borderRadius: 7,
                                  fit: BoxFit.contain,
                                  placeholderIcon: Icons.shield_outlined,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  scorer.teamName!,
                                  style:
                                      AppTypography.getBodySmall(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ).copyWith(
                                        fontSize: isSmall ? 10 : 11,
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Goals Badge
          Container(
            width: isSmall ? 40 : 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              scorer.goals.toString(),
              style:
                  AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: isSmall ? 12 : 13,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
