import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../domain/entities/player_profile_entity.dart';

class PlayerStatsTabView extends StatelessWidget {
  final List<PlayerStatisticEntity> statistics;
  final bool isGoalkeeper;
  final bool isDark;
  final bool isArabic;

  const PlayerStatsTabView({
    super.key,
    required this.statistics,
    required this.isGoalkeeper,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return EmptyView(
        titleKey: isArabic ? 'لا توجد إحصائيات' : 'No Statistics',
        customMessage: isArabic
            ? 'لا تتوفر إحصائيات للمواسم الحالية لهذا اللاعب'
            : 'No competition statistics available for this player',
        icon: Icons.bar_chart_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: statistics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stat = statistics[index];
        return _buildCompetitionCard(context, stat);
      },
    );
  }

  Widget _buildCompetitionCard(
    BuildContext context,
    PlayerStatisticEntity stat,
  ) {
    final l = stat.league;

    return Container(
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
          // Competition Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: isDark
                ? AppColors.darkCardElevated
                : AppColors.lightCardElevated,
            child: Row(
              children: [
                if (l.logo != null || l.logoLight != null) ...[
                  AppImage(
                    imageUrl: (!isDark &&
                            l.logoLight != null &&
                            l.logoLight!.isNotEmpty)
                        ? l.logoLight!
                        : (l.logo ?? ''),
                    width: 24,
                    height: 24,
                    placeholderIcon: Icons.emoji_events_outlined,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    l.name,
                    style: AppTypography.getBodyMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (l.ranking != null && l.ranking! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isArabic ? 'الترتيب ${l.ranking}' : 'Rank #${l.ranking}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Primary Stats Counter Banner
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBigStat(
                  label: isArabic ? 'مباريات' : 'Matches',
                  value: stat.appearances.toString(),
                  color: Colors.blueAccent,
                  icon: Icons.sports_soccer_rounded,
                ),
                if (isGoalkeeper)
                  _buildBigStat(
                    label: isArabic ? 'شباك نظيفة' : 'Clean Sheets',
                    value: stat.cleanSheets.toString(),
                    color: Colors.teal,
                    icon: Icons.shield_rounded,
                  )
                else
                  _buildBigStat(
                    label: isArabic ? 'أهداف' : 'Goals',
                    value: stat.goals.toString(),
                    color: Colors.green,
                    icon: Icons.sports_score_rounded,
                  ),
                _buildBigStat(
                  label: isArabic ? 'تمريرات حاسمة' : 'Assists',
                  value: stat.assists.toString(),
                  color: Colors.amber,
                  icon: Icons.assistant_photo_rounded,
                ),
                if (stat.manOfMatch > 0)
                  _buildBigStat(
                    label: isArabic ? 'رجل المباراة' : 'MOTM',
                    value: stat.manOfMatch.toString(),
                    color: Colors.purpleAccent,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
          ),

          // Secondary Detailed Stats Row (Cards, Penalties, Cancelled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground)
                  .withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  label: isArabic ? 'إنذارات' : 'Yellow',
                  value: stat.yellowCards.toString(),
                  badgeColor: Colors.amber,
                ),
                _buildMiniStat(
                  label: isArabic ? 'طرد' : 'Red',
                  value: stat.redCards.toString(),
                  badgeColor: Colors.redAccent,
                ),
                if (stat.scorePenalty > 0 || stat.missPenalty > 0)
                  _buildMiniStat(
                    label: isArabic ? 'ركلات جزاء' : 'Penalties',
                    value:
                        '${stat.scorePenalty}/${stat.scorePenalty + stat.missPenalty}',
                    badgeColor: Colors.indigoAccent,
                  ),
                if (!isGoalkeeper && stat.cleanSheets > 0)
                  _buildMiniStat(
                    label: isArabic ? 'شباك نظيفة' : 'Clean Sheets',
                    value: stat.cleanSheets.toString(),
                    badgeColor: Colors.teal,
                  ),
                if (stat.cancelGoal > 0)
                  _buildMiniStat(
                    label: isArabic ? 'أهداف ملغاة' : 'Disallowed',
                    value: stat.cancelGoal.toString(),
                    badgeColor: Colors.grey,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
              .copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color badgeColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
