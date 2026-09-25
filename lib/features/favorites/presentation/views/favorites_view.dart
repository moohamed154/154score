import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/team_resolver.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../cubit/favorites_cubit.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  void _showAddTeamDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    bool isDark,
  ) {
    final controller = TextEditingController();
    final popularTeams = isArabic
        ? const [
            'الأهلي',
            'الزمالك',
            'ريال مدريد',
            'برشلونة',
            'مانشستر سيتي',
            'ليفربول',
            'الهلال',
            'النصر',
            'أرسنال',
            'بايرن ميونخ',
            'باريس سان جيرمان',
            'مصر',
          ]
        : const [
            'Real Madrid',
            'Barcelona',
            'Manchester City',
            'Liverpool',
            'Arsenal',
            'Bayern Munich',
            'Paris Saint-Germain',
            'Al Ahly',
            'Zamalek',
            'Al Hilal',
            'Al Nassr',
            'Egypt',
          ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          title: Text(
            isArabic ? 'إضافة فريق إلى المفضلة' : 'Add Team to Favorites',
            style: AppTypography.getBodyLarge(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'اسم الفريق...' : 'Team name...',
                    prefixIcon: const Icon(Icons.shield_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'فرق مقترحة:' : 'Suggested Teams:',
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: popularTeams.map((team) {
                    return ActionChip(
                      label: Text(team, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        context.read<FavoritesCubit>().toggleTeam(team);
                        try {
                          context.read<MatchesBloc>().add(
                            const RefreshFavoritesEvent(),
                          );
                        } catch (_) {}
                        Navigator.of(dialogContext).pop();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  context.read<FavoritesCubit>().toggleTeam(text);
                  try {
                    context.read<MatchesBloc>().add(
                      const RefreshFavoritesEvent(),
                    );
                  } catch (_) {}
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(isArabic ? 'إضافة' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('favorites_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: isArabic ? 'إضافة فريق' : 'Add Team',
            onPressed: () => _showAddTeamDialog(context, l10n, isArabic, isDark),
          ),
        ],
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          final hasFavorites =
              state.favoriteTeams.isNotEmpty ||
              state.favoriteCompetitions.isNotEmpty ||
              state.favoriteMatches.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            children: [
              // Favorite Teams Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('favorite_teams'),
                    style: AppTypography.getHeadingMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isArabic ? 'إضافة' : 'Add'),
                    onPressed: () =>
                        _showAddTeamDialog(context, l10n, isArabic, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (state.favoriteTeams.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.favoriteTeams.map((team) {
                    final displayTitle =
                        TeamResolver.getLocalizedName(team, isArabic: isArabic) ??
                        state.teamTitles[team.trim()] ??
                        team;
                    return Chip(
                      avatar: const Icon(Icons.shield_outlined, size: 18),
                      label: Text(displayTitle),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        context.read<FavoritesCubit>().toggleTeam(team);
                        try {
                          context.read<MatchesBloc>().add(
                            const RefreshFavoritesEvent(),
                          );
                        } catch (_) {}
                      },
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    isArabic
                        ? 'لم تقم بإضافة أي فريق للمفضلة بعد. اضغط على "إضافة" لتحديد فرقك المفضلة.'
                        : 'No favorite teams added yet. Tap "Add" to select your favorite teams.',
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Favorite Competitions Section
              if (state.favoriteCompetitions.isNotEmpty) ...[
                Text(
                  l10n.translate('favorite_competitions'),
                  style: AppTypography.getHeadingMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.favoriteCompetitions.map((comp) {
                    final displayTitle =
                        state.competitionTitles[comp.trim()] ?? comp;
                    return Chip(
                      avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: Text(displayTitle),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        context.read<FavoritesCubit>().toggleCompetition(
                          name: comp,
                        );
                        try {
                          context.read<MatchesBloc>().add(
                            const RefreshFavoritesEvent(),
                          );
                        } catch (_) {}
                      },
                    );
                  }).toList(),
                ),
              ],

              if (!hasFavorites) ...[
                const SizedBox(height: 32),
                const EmptyView(
                  titleKey: 'no_favorites_yet',
                  icon: Icons.star_border_rounded,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
