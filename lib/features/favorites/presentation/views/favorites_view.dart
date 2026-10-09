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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('favorites_title')),
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
              Text(
                l10n.translate('favorite_teams'),
                style: AppTypography.getHeadingMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ),
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
                    final teamLogo = state.teamLogos[cleanTeam] ??
                        (teamId != null ? state.teamLogos[teamId] : null) ??
                        state.teamLogos[displayTitle] ??
                        UrlHelper.resolveTeamLogo(
                          teamId,
                          size: 48,
                          teamName: displayTitle,
                        );

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
                        ? 'لم تقم بإضافة أي فريق للمفضلة بعد.'
                        : 'No favorite teams added yet.',
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

                    final logoUrl = state.competitionLogos[cleanComp] ??
                        state.competitionLogos[displayTitle] ??
                        UrlHelper.resolveChampionshipLogo(cleanComp, isDark: isDark) ??
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
