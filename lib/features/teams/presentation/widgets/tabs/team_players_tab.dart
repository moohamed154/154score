import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../domain/entities/team_entity.dart';
import '../../bloc/team_state.dart';

class TeamPlayersTab extends StatelessWidget {
  final TeamState state;
  final bool isDark;
  final bool isArabic;

  const TeamPlayersTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final catSquad = state.profile?.categorizedSquad;
    final flatSquad = state.profile?.squad ?? [];
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (catSquad == null && flatSquad.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات تشكيلة مسجلة لهذا الفريق حالياً'
            : 'No squad roster data available for this team',
        icon: Icons.groups_rounded,
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      children: [
        // 1. Coach Card (if available)
        if (catSquad?.coach != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (catSquad!.coach!.id.isNotEmpty &&
                        catSquad.coach!.id != '0')
                    ? () {
                        final slug = Uri.encodeComponent(
                          catSquad.coach!.name.trim().replaceAll(
                                RegExp(r'\s+'),
                                '-',
                              ),
                        );
                        context.push('/coach/${catSquad.coach!.id}/$slug');
                      }
                    : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      AppImage(
                        imageUrl: catSquad.coach!.photo,
                        width: 44,
                        height: 44,
                        borderRadius: 22,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.sports_rounded,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catSquad.coach!.name,
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isArabic ? 'المدير الفني' : 'Head Coach',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (catSquad.coach!.id.isNotEmpty &&
                          catSquad.coach!.id != '0')
                        Icon(
                          isArabic
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // 2. Position Categories
        if (catSquad != null &&
            (catSquad.goalkeepers.isNotEmpty ||
                catSquad.defenders.isNotEmpty ||
                catSquad.midfielders.isNotEmpty ||
                catSquad.attackers.isNotEmpty)) ...[
          if (catSquad.goalkeepers.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'حراس المرمى' : 'Goalkeepers'),
            ...catSquad.goalkeepers.map(
              (p) => _buildPlayerTile(context, p),
            ),
            const SizedBox(height: 12),
          ],
          if (catSquad.defenders.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'المدافعون' : 'Defenders'),
            ...catSquad.defenders.map(
              (p) => _buildPlayerTile(context, p),
            ),
            const SizedBox(height: 12),
          ],
          if (catSquad.midfielders.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'لاعبو الوسط' : 'Midfielders'),
            ...catSquad.midfielders.map(
              (p) => _buildPlayerTile(context, p),
            ),
            const SizedBox(height: 12),
          ],
          if (catSquad.attackers.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'المهاجمون' : 'Attackers'),
            ...catSquad.attackers.map(
              (p) => _buildPlayerTile(context, p),
            ),
            const SizedBox(height: 12),
          ],
        ] else ...[
          // Fallback to flat list
          ...flatSquad.map(
            (p) => _buildPlayerTile(context, p),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerTile(BuildContext context, TeamSquadPlayerEntity player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: player.id.isNotEmpty
            ? () => context.push(
                  '/player/${player.id}?slug=${Uri.encodeComponent(player.name)}',
                )
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Shirt Number
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.number?.isNotEmpty == true ? player.number! : '-',
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Player Photo
              AppImage(
                imageUrl: player.photo,
                width: 38,
                height: 38,
                borderRadius: 19,
                fit: BoxFit.cover,
                placeholderIcon: Icons.person_rounded,
              ),
              const SizedBox(width: 12),

              // Name & Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.position != null &&
                        player.position!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        player.position!,
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Position Badge
              if (player.position != null && player.position!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    player.position!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
