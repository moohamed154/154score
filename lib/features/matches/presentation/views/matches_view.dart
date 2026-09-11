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
                    context.read<MatchesBloc>().add(
                      LoadMatchesEvent(
                        date: state.selectedDate,
                        isRefresh: true,
                      ),
                    );
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
    if (state.status == MatchesStatus.loading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.builder(
          itemCount: 6,
          padding: const EdgeInsets.only(top: AppDimensions.sm),
          itemBuilder: (_, __) => const MatchCard(match: _dummyMatch),
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
