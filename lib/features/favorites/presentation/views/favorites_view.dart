import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
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
      appBar: AppBar(title: Text(l10n.translate('favorites_title'))),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          final hasFavorites =
              state.favoriteTeams.isNotEmpty ||
              state.favoriteCompetitions.isNotEmpty ||
              state.favoriteMatches.isNotEmpty;

          if (!hasFavorites) {
            return const EmptyView(
              titleKey: 'no_favorites_yet',
              icon: Icons.star_border_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            children: [
              // Favorite Teams Section
              if (state.favoriteTeams.isNotEmpty) ...[
                Text(
                  l10n.translate('favorite_teams'),
                  style: AppTypography.getHeadingMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.favoriteTeams.map((team) {
                    return Chip(
                      avatar: const Icon(Icons.shield_outlined, size: 18),
                      label: Text(team),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        context.read<FavoritesCubit>().toggleTeam(team);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

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
                        context
                            .read<FavoritesCubit>()
                            .toggleCompetition(name: comp);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
