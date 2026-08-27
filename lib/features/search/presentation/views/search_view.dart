import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_state.dart';
import '../../../matches/presentation/widgets/match_card.dart';

class GlobalSearchView extends StatefulWidget {
  const GlobalSearchView({super.key});

  @override
  State<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<GlobalSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<(String, String, String)> _popularCompetitions = [
    ('937599', 'Premier League', 'الدوري الإنجليزي الممتاز'),
    ('938652', 'LaLiga', 'الدوري الإسباني - لا ليغا'),
    ('936357', 'Serie A', 'الدوري الإيطالي'),
    ('938769', 'Bundesliga', 'الدوري الألماني'),
    ('937873', 'Ligue 1', 'الدوري الفرنسي'),
    ('904988', 'UEFA Champions League', 'دوري أبطال أوروبا'),
    ('943009', 'Egyptian League', 'الدوري المصري الممتاز'),
    ('941825', 'Saudi Pro League', 'دوري روشن السعودي للمحترفين'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.translate('search_placeholder'),
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              fontSize: 15,
            ),
          ),
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onChanged: (val) {
            setState(() => _query = val.trim().toLowerCase());
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? _buildPopularSuggestions(context, isDark, isArabic)
          : _buildSearchResults(context, isDark, isArabic),
    );
  }

  Widget _buildPopularSuggestions(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        Text(
          l10n.translate('popular_competitions'),
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ),
        ),
        const SizedBox(height: 12),
        ..._popularCompetitions.map((comp) {
          final title = isArabic ? comp.$3 : comp.$2;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                title,
                style: AppTypography.getBodyMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                context.push('/standings/${comp.$1}');
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context, bool isDark, bool isArabic) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, matchesState) {
        final matchingMatches = <dynamic>[];
        for (final l in matchesState.allLeagues) {
          for (final m in l.matches) {
            if (m.team1.toLowerCase().contains(_query) ||
                m.team2.toLowerCase().contains(_query) ||
                (m.leagueTitle?.toLowerCase().contains(_query) ?? false)) {
              matchingMatches.add(m);
            }
          }
        }

        final matchingCompetitions = _popularCompetitions.where((c) {
          return c.$2.toLowerCase().contains(_query) ||
              c.$3.toLowerCase().contains(_query);
        }).toList();

        if (matchingMatches.isEmpty && matchingCompetitions.isEmpty) {
          return const EmptyView(
            titleKey: 'search_no_results',
            icon: Icons.search_off_rounded,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          children: [
            if (matchingCompetitions.isNotEmpty) ...[
              Text(
                'Competitions',
                style: AppTypography.getHeadingMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(height: 8),
              ...matchingCompetitions.map((comp) {
                final title = isArabic ? comp.$3 : comp.$2;
                return ListTile(
                  leading: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(title),
                  onTap: () => context.push('/standings/${comp.$1}'),
                );
              }),
              const SizedBox(height: 16),
            ],

            if (matchingMatches.isNotEmpty) ...[
              Text(
                'Matches',
                style: AppTypography.getHeadingMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(height: 8),
              ...matchingMatches.map((m) => MatchCard(match: m)),
            ],
          ],
        );
      },
    );
  }
}
