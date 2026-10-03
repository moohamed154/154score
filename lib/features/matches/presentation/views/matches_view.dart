import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/match_entity.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import '../bloc/matches_state.dart';
import '../widgets/date_navigation_buttons.dart';
import '../widgets/horizontal_date_selector.dart';
import '../widgets/league_section_widget.dart';
import '../widgets/match_filter_bottom_sheet.dart';
import '../widgets/match_filters_bar.dart';
import '../widgets/swipe_date_detector.dart';

class MatchesView extends StatefulWidget {
  const MatchesView({super.key});

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MatchesBloc>();
    if (bloc.state.status == MatchesStatus.initial) {
      bloc.add(LoadMatchesEvent(date: bloc.state.selectedDate));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = AppLocalizations.of(context).isArabic;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrandLogo(size: 40, isDark: isDark),
            const SizedBox(width: 10),
            Text(
              '154Score',
              style: AppTypography.getHeadingLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Row(
            textDirection: TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              BlocBuilder<MatchesBloc, MatchesState>(
                buildWhen: (prev, curr) =>
                    prev.selectedDate != curr.selectedDate,
                builder: (context, state) {
                  return DateNavigationButtons(
                    selectedDate: state.selectedDate,
                    onDateSelected: (date) {
                      context.read<MatchesBloc>().add(
                        LoadMatchesEvent(date: date),
                      );
                    },
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  );
                },
              ),
              IconButton(
                icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchController.clear();
                      context.read<MatchesBloc>().add(
                        const SearchMatchesEvent(''),
                      );
                    }
                  });
                },
              ),
              BlocBuilder<MatchesBloc, MatchesState>(
                buildWhen: (prev, curr) =>
                    prev.hasActiveFilter != curr.hasActiveFilter,
                builder: (context, state) {
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: state.hasActiveFilter,
                      backgroundColor: AppColors.primary,
                      smallSize: 8,
                      child: Icon(
                        state.hasActiveFilter
                            ? Icons.filter_alt_rounded
                            : Icons.filter_alt_outlined,
                        color: state.hasActiveFilter ? AppColors.primary : null,
                      ),
                    ),
                    tooltip: AppLocalizations.of(context)
                        .translate('filter_title'),
                    onPressed: () => MatchFilterBottomSheet.show(context),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
      body: BlocListener<FavoritesCubit, FavoritesState>(
        listener: (context, favState) {
          context.read<MatchesBloc>().add(
            RefreshFavoritesEvent(
              favoriteMatches: favState.favoriteMatches,
              favoriteTeams: favState.favoriteTeams,
              favoriteCompetitions: favState.favoriteCompetitions,
            ),
          );
        },
        child: BlocBuilder<MatchesBloc, MatchesState>(
          builder: (context, state) {
            return SwipeDateDetector(
              currentDate: state.selectedDate,
              onDateChanged: (date) {
                context.read<MatchesBloc>().add(LoadMatchesEvent(date: date));
              },
              child: Column(
                children: [
                  // 1. Date Selector Strip
                  HorizontalDateSelector(
                    selectedDate: state.selectedDate,
                    onDateSelected: (date) {
                      context.read<MatchesBloc>().add(
                        LoadMatchesEvent(date: date),
                      );
                    },
                  ),

                  // Search Box if visible
                  if (_isSearchVisible)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.xs,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                              .translate('search_hint'),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (query) {
                          context.read<MatchesBloc>().add(
                            SearchMatchesEvent(query),
                          );
                        },
                      ),
                    ),

                  // 2. Filter Tabs (Live, Finished, Upcoming, All)
                  MatchFiltersBar(
                    activeFilter: state.activeFilter,
                    liveCount: state.liveMatchesCount,
                    onFilterSelected: (filter) {
                      context.read<MatchesBloc>().add(
                        ChangeFilterEvent(filter),
                      );
                    },
                  ),

                  // 3. Main Matches Content
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        final completer = Completer<void>();
                        context.read<MatchesBloc>().add(
                          LoadMatchesEvent(
                            date: state.selectedDate,
                            isRefresh: true,
                            completer: completer,
                          ),
                        );
                        try {
                          await completer.future.timeout(
                            const Duration(seconds: 3),
                          );
                        } catch (_) {}
                      },
                      child: _buildBody(context, state),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MatchesState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = AppLocalizations.of(context).isArabic;

    if (state.status == MatchesStatus.loading &&
        state.filteredLeagues.isEmpty) {
      return Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: isDark ? const Color(0xFF222F3E) : const Color(0xFFE2E8F0),
          highlightColor: isDark
              ? const Color(0xFF384B66)
              : const Color(0xFFF1F5F9),
          duration: const Duration(milliseconds: 1500),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: AppDimensions.sm),
          children: [
            LeagueSectionWidget(
              league: LeagueGroupEntity(
                leagueTitle: isArabic
                    ? 'الدوري الإسباني - الجولة 28'
                    : 'La Liga - Round 28',
                matches: const [
                  MatchEntity(
                    id: 's1',
                    team1: 'ريال مدريد',
                    team2: 'برشلونة',
                    score1: '2',
                    score2: '1',
                    status: 'Finished',
                    time: '21:00',
                  ),
                  MatchEntity(
                    id: 's2',
                    team1: 'أتلتيكو مدريد',
                    team2: 'إشبيلية',
                    score1: '1',
                    score2: '0',
                    status: 'Finished',
                    time: '18:30',
                  ),
                  MatchEntity(
                    id: 's3',
                    team1: 'فالنسيا',
                    team2: 'فياريال',
                    score1: '0',
                    score2: '0',
                    status: 'Upcoming',
                    time: '22:00',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == MatchesStatus.error) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () {
          context.read<MatchesBloc>().add(
            LoadMatchesEvent(date: state.selectedDate),
          );
        },
      );
    }

    if (state.filteredLeagues.isEmpty) {
      if (state.activeFilter == MatchFilterType.live) {
        return const EmptyView(
          titleKey: 'no_live_matches',
          icon: Icons.live_tv_outlined,
        );
      }
      if (state.activeFilter == MatchFilterType.favorites) {
        return const EmptyView(
          titleKey: 'no_favorites_matches',
          icon: Icons.star_border_rounded,
        );
      }
      return const EmptyView(
        titleKey: 'no_matches_date',
        icon: Icons.sports_soccer_rounded,
      );
    }

    // Extract Favorite Matches for today (pinned on top)
    final List<MatchEntity> favoriteMatches = [];
    if (state.activeFilter != MatchFilterType.favorites) {
      for (final league in state.filteredLeagues) {
        for (final m in league.matches) {
          if (m.isFavorite && !favoriteMatches.any((fav) => fav.id == m.id)) {
            favoriteMatches.add(m);
          }
        }
      }
    }

    final hasFavorites = favoriteMatches.isNotEmpty;
    final leagues = state.filteredLeagues;
    final totalCount = leagues.length + (hasFavorites ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (hasFavorites && index == 0) {
          return LeagueSectionWidget(
            key: ValueKey('fav_section_${state.selectedDate.day}'),
            league: LeagueGroupEntity(
              leagueTitle: isArabic ? 'المفضلة' : 'Favorites',
              matches: favoriteMatches,
            ),
            timeFormat: state.timeFormat,
            onFavoriteMatchTap: (matchId) {
              context.read<FavoritesCubit>().toggleMatch(matchId);
            },
          );
        }

        final leagueIndex = hasFavorites ? index - 1 : index;
        final league = leagues[leagueIndex];
        return LeagueSectionWidget(
          key: ValueKey('${league.leagueTitle}_${state.timeFormat}'),
          league: league,
          timeFormat: state.timeFormat,
          isTimeSorted: state.sortOrder == MatchesSortOrder.time,
          onFavoriteMatchTap: (matchId) {
            context.read<FavoritesCubit>().toggleMatch(matchId);
          },
        );
      },
    );
  }
}
