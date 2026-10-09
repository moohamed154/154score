import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../../../matches/presentation/bloc/matches_state.dart';
import '../../../matches/presentation/widgets/date_navigation_buttons.dart';
import '../../../matches/presentation/widgets/league_section_widget.dart';
import '../../../matches/presentation/widgets/match_filter_bottom_sheet.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const int _kInitialPage = 10000;
  late final PageController _pageController;
  late final DateTime _baseDate;
  int _currentPage = _kInitialPage;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);

    final matchesBloc = context.read<MatchesBloc>();
    final selected = matchesBloc.state.selectedDate;
    _currentPage = _indexForDate(selected);
    _pageController = PageController(initialPage: _currentPage);

    if (matchesBloc.state.status == MatchesStatus.initial) {
      matchesBloc.add(LoadMatchesEvent(date: selected));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateForIndex(int pageIndex) {
    final offset = pageIndex - _kInitialPage;
    return DateTime(_baseDate.year, _baseDate.month, _baseDate.day + offset);
  }

  int _indexForDate(DateTime date) {
    final baseUtc = DateTime.utc(_baseDate.year, _baseDate.month, _baseDate.day);
    final targetUtc = DateTime.utc(date.year, date.month, date.day);
    return _kInitialPage + targetUtc.difference(baseUtc).inDays;
  }

  void _goToDate(DateTime date, {bool animate = false}) {
    final targetIndex = _indexForDate(date);
    final bloc = context.read<MatchesBloc>();

    if (targetIndex == _currentPage &&
        DateFormatter.isSameDay(date, bloc.state.selectedDate)) {
      return;
    }

    _isProgrammaticScroll = true;
    _currentPage = targetIndex;

    if (_pageController.hasClients) {
      if (animate) {
        _pageController
            .animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              _isProgrammaticScroll = false;
            });
      } else {
        _pageController.jumpToPage(targetIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isProgrammaticScroll = false;
        });
      }
    } else {
      _isProgrammaticScroll = false;
    }

    bloc.add(LoadMatchesEvent(date: date));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + topPadding),
        child: BlocBuilder<MatchesBloc, MatchesState>(
          buildWhen: (prev, curr) =>
              prev.selectedDate != curr.selectedDate ||
              prev.hasActiveFilter != curr.hasActiveFilter,
          builder: (context, matchesState) {
            return Material(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status bar spacer
                  SizedBox(height: topPadding),

                  // Top toolbar row
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        // Logo + Title
                        AppBrandLogo(size: 40, isDark: isDark),
                        const SizedBox(width: 10),
                        Text(
                          '154Score',
                          style: AppTypography.getHeadingLarge(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        // Actions row ordered: Filter -> Search -> Date Navigation (<, 📅, >)
                        Row(
                          textDirection: TextDirection.ltr,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Filter Icon with active badge indicator
                            IconButton(
                              icon: Badge(
                                isLabelVisible: matchesState.hasActiveFilter,
                                backgroundColor: AppColors.primary,
                                smallSize: 8,
                                child: Icon(
                                  matchesState.hasActiveFilter
                                      ? Icons.filter_alt_rounded
                                      : Icons.filter_alt_outlined,
                                  color: matchesState.hasActiveFilter
                                      ? AppColors.primary
                                      : null,
                                ),
                              ),
                              tooltip: l10n.translate('filter_title'),
                              onPressed: () =>
                                  MatchFilterBottomSheet.show(context),
                            ),
                            // Search Icon
                            IconButton(
                              icon: const Icon(Icons.search_rounded),
                              tooltip: l10n.translate('nav_search'),
                              onPressed: () => context.push('/search'),
                            ),
                            // Date Navigation Buttons (<, 📅, >)
                            DateNavigationButtons(
                              selectedDate: matchesState.selectedDate,
                              onDateSelected: (date) {
                                final targetIndex = _indexForDate(date);
                                final currentPos = _pageController.hasClients
                                    ? (_pageController.page?.round() ?? _currentPage)
                                    : _currentPage;
                                final diff = (targetIndex - currentPos).abs();
                                _goToDate(date, animate: diff == 1);
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom divider
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ],
              ),
            );
          },
        ),
      ),

      body: MultiBlocListener(
        listeners: [
          BlocListener<FavoritesCubit, FavoritesState>(
            listener: (context, favState) {
              final bloc = context.read<MatchesBloc>();
              bloc.add(
                RefreshFavoritesEvent(
                  favoriteMatches: favState.favoriteMatches,
                  favoriteTeams: favState.favoriteTeams,
                  favoriteCompetitions: favState.favoriteCompetitions,
                ),
              );
              bloc.add(
                ApplyMatchesFilterEvent(
                  filter: bloc.state.activeFilter,
                  sortOrder: bloc.state.sortOrder,
                ),
              );
            },
          ),
          BlocListener<MatchesBloc, MatchesState>(
            listenWhen: (prev, curr) =>
                !DateFormatter.isSameDay(prev.selectedDate, curr.selectedDate),
            listener: (context, state) {
              if (_isProgrammaticScroll) return;
              final targetIndex = _indexForDate(state.selectedDate);
              if (_currentPage != targetIndex) {
                _currentPage = targetIndex;
                if (_pageController.hasClients &&
                    (_pageController.page?.round() ?? -1) != targetIndex) {
                  _isProgrammaticScroll = true;
                  _pageController.jumpToPage(targetIndex);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _isProgrammaticScroll = false;
                  });
                }
              }
            },
          ),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            onPageChanged: (pageIndex) {
              _currentPage = pageIndex;
              if (_isProgrammaticScroll) return;
              final newDate = _dateForIndex(pageIndex);
              final bloc = context.read<MatchesBloc>();
              if (!DateFormatter.isSameDay(newDate, bloc.state.selectedDate)) {
                bloc.add(LoadMatchesEvent(date: newDate));
              }
            },
            itemBuilder: (context, index) {
              final pageDate = _dateForIndex(index);
              return Directionality(
                textDirection:
                    isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: _HomeDayPage(
                  key: ValueKey('day_${DateFormatter.toApiDateString(pageDate)}'),
                  pageDate: pageDate,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeDayPage extends StatelessWidget {
  final DateTime pageDate;
  final bool isDark;
  final bool isArabic;

  const _HomeDayPage({
    super.key,
    required this.pageDate,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MatchesBloc>();

    return BlocBuilder<MatchesBloc, MatchesState>(
      buildWhen: (prev, curr) {
        final isThisSelected = DateFormatter.isSameDay(pageDate, curr.selectedDate);
        final wasThisSelected = DateFormatter.isSameDay(pageDate, prev.selectedDate);

        if (isThisSelected || wasThisSelected) return true;

        if (prev.activeFilter != curr.activeFilter ||
            prev.sortOrder != curr.sortOrder ||
            prev.hideFavorites != curr.hideFavorites ||
            prev.timeFormat != curr.timeFormat) {
          return true;
        }

        return false;
      },
      builder: (context, matchesState) {
        final isSelectedDate =
            DateFormatter.isSameDay(pageDate, matchesState.selectedDate);

        final List<LeagueGroupEntity>? leagues;
        final bool isLoading;
        final bool isError;
        final String? errorMessage;

        if (isSelectedDate) {
          isLoading = (matchesState.status == MatchesStatus.loading ||
                  matchesState.status == MatchesStatus.initial) &&
              matchesState.allLeagues.isEmpty;
          isError = matchesState.status == MatchesStatus.error &&
              matchesState.allLeagues.isEmpty;
          errorMessage = matchesState.errorMessage;
          leagues = matchesState.filteredLeagues;
        } else {
          final cached = bloc.getFilteredLeaguesForDate(pageDate);
          if (cached != null) {
            isLoading = false;
            isError = false;
            errorMessage = null;
            leagues = cached;
          } else {
            isLoading = true;
            isError = false;
            errorMessage = null;
            leagues = null;
          }
        }

        final dateKey = DateFormatter.toApiDateString(pageDate);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final matchesCompleter = Completer<void>();
            bloc.add(
              LoadMatchesEvent(
                date: pageDate,
                isRefresh: true,
                completer: matchesCompleter,
              ),
            );
            try {
              await matchesCompleter.future.timeout(const Duration(seconds: 3));
            } catch (_) {}
          },
          child: isLoading
              ? ListView(
                  key: PageStorageKey<String>('skel_$dateKey'),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
                  children: [
                    _buildMatchesSkeleton(context, isDark, isArabic, pageDate),
                  ],
                )
              : isError
                  ? ListView(
                      key: PageStorageKey<String>('err_$dateKey'),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
                      children: [
                        _buildDateHeader(pageDate, isDark, isArabic),
                        ErrorView(
                          message: errorMessage,
                          onRetry: () =>
                              bloc.add(LoadMatchesEvent(date: pageDate)),
                        ),
                      ],
                    )
                  : _buildMatchesContent(
                      context: context,
                      pageDate: pageDate,
                      displayLeagues: leagues ?? const [],
                      state: matchesState,
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        _formatDate(date, isArabic),
        style: AppTypography.getBodyLarge(
          isDark: isDark,
          isArabic: isArabic,
        ).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date, bool isArabic) {
    const englishDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayIndex = date.weekday - 1;
    final dayName = isArabic ? arabicDays[dayIndex] : englishDays[dayIndex];
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return isArabic ? '$dayName، $dd/$mm/$yyyy' : '$dayName, $dd/$mm/$yyyy';
  }

  Widget _buildMatchesContent({
    required BuildContext context,
    required DateTime pageDate,
    required List<LeagueGroupEntity> displayLeagues,
    required MatchesState state,
    required bool isDark,
    required bool isArabic,
  }) {
    final dateHeader = _buildDateHeader(pageDate, isDark, isArabic);

    if (displayLeagues.isEmpty) {
      Widget emptyContent;
      if (state.activeFilter == MatchFilterType.live) {
        emptyContent = const EmptyView(
          titleKey: 'no_live_matches',
          icon: Icons.live_tv_outlined,
        );
      } else if (state.activeFilter == MatchFilterType.favorites) {
        emptyContent = const EmptyView(
          titleKey: 'no_favorites_matches',
          icon: Icons.star_border_rounded,
        );
      } else {
        emptyContent = const EmptyView(
          titleKey: 'no_matches_date',
          icon: Icons.sports_soccer_rounded,
        );
      }

      return ListView(
        key: PageStorageKey<String>(
          'empty_${DateFormatter.toApiDateString(pageDate)}',
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
        children: [
          dateHeader,
          emptyContent,
        ],
      );
    }

    // Extract Favorite Matches (pinned on top like Yalla Shoot) - Optimized O(N) lookup
    final List<MatchEntity> favoriteMatches = [];
    final seenMatchIds = <String>{};
    if (state.activeFilter != MatchFilterType.favorites && !state.hideFavorites) {
      for (final league in displayLeagues) {
        for (final m in league.matches) {
          if (m.isFavorite && seenMatchIds.add(m.id)) {
            favoriteMatches.add(m);
          }
        }
      }
    }

    final hasFavorites = favoriteMatches.isNotEmpty;
    final totalCount = 1 + (hasFavorites ? 1 : 0) + displayLeagues.length;
    final dateKey = DateFormatter.toApiDateString(pageDate);

    return ListView.builder(
      key: PageStorageKey<String>('matches_$dateKey'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return dateHeader;
        }

        if (hasFavorites && index == 1) {
          return LeagueSectionWidget(
            key: ValueKey('fav_section_${dateKey}_${state.timeFormat}'),
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

        final leagueIndex = hasFavorites ? index - 2 : index - 1;
        final league = displayLeagues[leagueIndex];
        return LeagueSectionWidget(
          key: ValueKey('${league.leagueTitle}_${dateKey}_${state.timeFormat}'),
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

  static Widget _buildMatchesSkeleton(
    BuildContext context,
    bool isDark,
    bool isArabic, [
    DateTime? selectedDate,
  ]) {
    final title = selectedDate != null
        ? _formatDate(selectedDate, isArabic)
        : (isArabic ? 'المباريات' : 'Matches');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            title,
            style: AppTypography.getBodyLarge(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        Skeletonizer(
          enabled: true,
          ignoreContainers: false,
          effect: ShimmerEffect(
            baseColor: isDark
                ? const Color(0xFF222F3E)
                : const Color(0xFFE2E8F0),
            highlightColor: isDark
                ? const Color(0xFF384B66)
                : const Color(0xFFF1F5F9),
            duration: const Duration(milliseconds: 1500),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(6, (index) {
                return Container(
                  height: 72,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 70,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 70,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
