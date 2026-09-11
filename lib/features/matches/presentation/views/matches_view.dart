import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/match_entity.dart';
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import '../bloc/matches_state.dart';
import '../widgets/horizontal_date_selector.dart';
import '../widgets/league_section_widget.dart';
import '../widgets/match_card.dart';
import '../widgets/match_filters_bar.dart';

class MatchesView extends StatefulWidget {
  const MatchesView({super.key});

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  static const _dummyMatch = MatchEntity(
    id: 'skeleton',
    team1: 'Arsenal FC',
    team2: 'Chelsea FC',
    score1: '2',
    score2: '1',
    status: 'Finished',
    time: '20:00',
    leagueTitle: 'Premier League',
  );

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('nav_matches'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
        ],
      ),
      body: BlocBuilder<MatchesBloc, MatchesState>(
        builder: (context, state) {
          return Column(
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
                      hintText: AppLocalizations.of(context).translate('search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (query) {
                      context.read<MatchesBloc>().add(SearchMatchesEvent(query));
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
                      await completer.future.timeout(const Duration(seconds: 3));
                    } catch (_) {}
                  },
                  child: _buildBody(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MatchesState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = AppLocalizations.of(context).isArabic;

    if (state.status == MatchesStatus.loading) {
      return Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: isDark ? const Color(0xFF222F3E) : const Color(0xFFE2E8F0),
          highlightColor: isDark ? const Color(0xFF384B66) : const Color(0xFFF1F5F9),
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      itemCount: state.filteredLeagues.length,
      itemBuilder: (context, index) {
        final league = state.filteredLeagues[index];
        return LeagueSectionWidget(
          key: ValueKey(league.leagueTitle),
          league: league,
          onFavoriteMatchTap: (matchId) {
            context.read<MatchesBloc>().add(ToggleMatchFavoriteEvent(matchId));
          },
        );
      },
    );
  }
}
