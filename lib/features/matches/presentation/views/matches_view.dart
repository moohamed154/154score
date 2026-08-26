import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import '../bloc/matches_state.dart';
import '../widgets/horizontal_date_selector.dart';
import '../widgets/league_section_widget.dart';
import '../widgets/match_filters_bar.dart';

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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.translate('search_placeholder'),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                onChanged: (val) {
                  context.read<MatchesBloc>().add(SearchMatchesEvent(val));
                },
              )
            : Text(l10n.translate('nav_matches')),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  context.read<MatchesBloc>().add(const SearchMatchesEvent(''));
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
              // 1. Horizontal Date Strip
              HorizontalDateSelector(
                selectedDate: state.selectedDate,
                onDateSelected: (date) {
                  context.read<MatchesBloc>().add(LoadMatchesEvent(date: date));
                },
              ),

              const SizedBox(height: 8),

              // 2. Filters Bar
              MatchFiltersBar(
                activeFilter: state.activeFilter,
                liveCount: state.liveMatchesCount,
                onFilterSelected: (filter) {
                  context.read<MatchesBloc>().add(ChangeFilterEvent(filter));
                },
              ),

              const SizedBox(height: 8),

              // 3. Main Matches Content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<MatchesBloc>().add(
                          LoadMatchesEvent(date: state.selectedDate, isRefresh: true),
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
      return ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.only(top: AppDimensions.sm),
        itemBuilder: (_, __) => const MatchCardSkeleton(),
      );
    }

    if (state.status == MatchesStatus.error) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () {
          context.read<MatchesBloc>().add(LoadMatchesEvent(date: state.selectedDate));
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
