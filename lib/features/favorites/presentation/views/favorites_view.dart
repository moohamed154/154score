import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/team_resolver.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
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
            (name: 'الأهلي', id: '101745'),
            (name: 'الزمالك', id: '80591'),
            (name: 'ريال مدريد', id: '8633'),
            (name: 'برشلونة', id: '8634'),
            (name: 'مانشستر سيتي', id: '8456'),
            (name: 'ليفربول', id: '8650'),
            (name: 'الهلال', id: '2529'),
            (name: 'النصر', id: '101918'),
            (name: 'أرسنال', id: '9825'),
            (name: 'بايرن ميونخ', id: '9823'),
            (name: 'باريس سان جيرمان', id: '9847'),
            (name: 'مصر', id: '10255'),
          ]
        : const [
            (name: 'Real Madrid', id: '8633'),
            (name: 'Barcelona', id: '8634'),
            (name: 'Manchester City', id: '8456'),
            (name: 'Liverpool', id: '8650'),
            (name: 'Arsenal', id: '9825'),
            (name: 'Bayern Munich', id: '9823'),
            (name: 'Paris Saint-Germain', id: '9847'),
            (name: 'Al Ahly', id: '101745'),
            (name: 'Zamalek', id: '80591'),
            (name: 'Al Hilal', id: '2529'),
            (name: 'Al Nassr', id: '101918'),
            (name: 'Egypt', id: '10255'),
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
                      label: Text(team.name, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        context.read<FavoritesCubit>().toggleTeam(team.name, id: team.id);
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
                    final cleanTeam = team.trim();
                    final displayTitle =
                        state.teamTitles[cleanTeam] ??
                        TeamResolver.getLocalizedName(cleanTeam, isArabic: isArabic) ??
                        cleanTeam;
                    final teamId = int.tryParse(cleanTeam) != null
                        ? cleanTeam
                        : LocalStorageServiceImpl.knownTeamNameToId[cleanTeam.toLowerCase()];
                    final teamLogo = UrlHelper.resolveTeamLogo(teamId, size: 48);

                    return Chip(
                      avatar: teamLogo != null
                          ? ClipOval(
                              child: AppImage(
                                imageUrl: teamLogo,
                                width: 20,
                                height: 20,
                                borderRadius: 10,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.shield_outlined,
                              ),
                            )
                          : const Icon(Icons.shield_outlined, size: 18),
                      label: Text(displayTitle),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        context.read<FavoritesCubit>().toggleTeam(displayTitle, id: team);
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
                    final cleanComp = comp.trim();
                    final displayTitle = () {
                      final fromTitles = state.competitionTitles[cleanComp];
                      if (fromTitles != null &&
                          fromTitles.isNotEmpty &&
                          int.tryParse(fromTitles) == null) {
                        return LeagueResolver.resolveTitle(fromTitles, isArabic: isArabic);
                      }
                      final resolved = LeagueResolver.resolveTitle(cleanComp, isArabic: isArabic);
                      if (resolved.isNotEmpty && int.tryParse(resolved) == null) {
                        return resolved;
                      }
                      final fallback = LocalStorageServiceImpl.defaultKnownTitles[cleanComp];
                      if (fallback != null && fallback.isNotEmpty) {
                        return LeagueResolver.resolveTitle(fallback, isArabic: isArabic);
                      }
                      return cleanComp;
                    }();

                    final logoUrl = UrlHelper.resolveChampionshipLogo(cleanComp, isDark: isDark) ??
                        UrlHelper.resolveChampionshipLogo(LeagueResolver.resolveId(cleanComp), isDark: isDark) ??
                        UrlHelper.resolveChampionshipLogo(LeagueResolver.resolveId(displayTitle), isDark: isDark);

                    return Chip(
                      avatar: logoUrl != null
                          ? ClipOval(
                              child: AppImage(
                                imageUrl: logoUrl,
                                width: 20,
                                height: 20,
                                borderRadius: 10,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.emoji_events_outlined,
                              ),
                            )
                          : const Icon(Icons.emoji_events_outlined, size: 18),
                      label: Text(displayTitle),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        context.read<FavoritesCubit>().toggleCompetition(
                          id: cleanComp,
                          name: displayTitle,
                        );
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
