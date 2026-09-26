import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
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
import '../../../matches/presentation/widgets/swipe_date_detector.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    final matchesBloc = context.read<MatchesBloc>();
    if (matchesBloc.state.status == MatchesStatus.initial) {
      matchesBloc.add(LoadMatchesEvent(date: matchesBloc.state.selectedDate));
    }

    // After today renders, silently pre-warm yesterday & tomorrow in background
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final now = DateTime.now();
      context.read<MatchesBloc>().add(
        PreloadMatchesEvent([
          now.subtract(const Duration(days: 1)), // yesterday
          now.add(const Duration(days: 1)), // tomorrow
        ]),
      );
    });
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
                          style:
                              AppTypography.getHeadingLarge(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const Spacer(),
                        // Actions row ordered: Notification -> Filter -> Search -> Date Navigation (<, 📅, >)
                        Row(
                          textDirection: TextDirection.ltr,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Notifications Icon with unread badge
                            BlocBuilder<NotificationsBloc, NotificationsState>(
                              builder: (context, notifState) {
                                final unreadCount = notifState.unreadCount;
                                return IconButton(
                                  icon: Badge(
                                    isLabelVisible: unreadCount > 0,
                                    label: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: AppColors.primary,
                                    child: Icon(
                                      unreadCount > 0
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_none_rounded,
                                    ),
                                  ),
                                  tooltip: l10n.translate('notifications_title'),
                                  onPressed: () => context.push('/notifications'),
                                );
                              },
                            ),
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
                                context.read<MatchesBloc>().add(
                                  LoadMatchesEvent(date: date),
                                );
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

      body: BlocListener<FavoritesCubit, FavoritesState>(
        listener: (context, favState) {
          final bloc = context.read<MatchesBloc>();
          bloc.add(
            ApplyMatchesFilterEvent(
              filter: bloc.state.activeFilter,
              sortOrder: bloc.state.sortOrder,
            ),
          );
        },
        child: BlocListener<FavoritesCubit, FavoritesState>(
          listener: (context, favState) {
            context.read<MatchesBloc>().add(const RefreshFavoritesEvent());
          },
          child: BlocBuilder<MatchesBloc, MatchesState>(
            builder: (context, matchesState) {
              final isHomeLoading =
                  (matchesState.status == MatchesStatus.loading ||
                      matchesState.status == MatchesStatus.initial) &&
                  matchesState.allLeagues.isEmpty;

              return SwipeDateDetector(
                currentDate: matchesState.selectedDate,
                onDateChanged: (date) {
                  context.read<MatchesBloc>().add(LoadMatchesEvent(date: date));
                },
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final matchesCompleter = Completer<void>();
                    context.read<MatchesBloc>().add(
                      LoadMatchesEvent(
                        date: matchesState.selectedDate,
                        isRefresh: true,
                        completer: matchesCompleter,
                      ),
                    );

                    try {
                      await matchesCompleter.future.timeout(
                        const Duration(seconds: 3),
                      );
                    } catch (_) {}
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.xxxl,
                    ),
                    children: [
                      if (isHomeLoading)
                        _buildMatchesSkeleton(
                          context,
                          isDark,
                          isArabic,
                          matchesState.selectedDate,
                        )
                      else
                        _buildMatchesSection(
                          context,
                          matchesState,
                          isDark,
                          isArabic,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool isArabic) {
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
    final dayIndex = date.weekday - 1; // weekday: 1=Monday … 7=Sunday
    final dayName = isArabic ? arabicDays[dayIndex] : englishDays[dayIndex];
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return isArabic ? '$dayName، $dd/$mm/$yyyy' : '$dayName, $dd/$mm/$yyyy';
  }

  Widget _buildMatchesSection(
    BuildContext context,
    MatchesState state,
    bool isDark,
    bool isArabic,
  ) {
    final displayLeagues = state.filteredLeagues;

    // Clean Date Header directly above the match list matching Yalla Shoot layout
    final dateHeader = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        _formatDate(state.selectedDate, isArabic),
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

    if ((state.status == MatchesStatus.loading ||
            state.status == MatchesStatus.initial) &&
        displayLeagues.isEmpty) {
      return _buildMatchesSkeleton(
        context,
        isDark,
        isArabic,
        state.selectedDate,
      );
    }

    if (state.status == MatchesStatus.error && displayLeagues.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dateHeader,
          ErrorView(
            message: state.errorMessage,
            onRetry: () => context.read<MatchesBloc>().add(
              LoadMatchesEvent(date: state.selectedDate),
            ),
          ),
        ],
      );
    }

    if (displayLeagues.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dateHeader,
          if (state.activeFilter == MatchFilterType.live)
            const EmptyView(
              titleKey: 'no_live_matches',
              icon: Icons.live_tv_outlined,
            )
          else if (state.activeFilter == MatchFilterType.favorites)
            const EmptyView(
              titleKey: 'no_favorites_matches',
              icon: Icons.star_border_rounded,
            )
          else
            const EmptyView(
              titleKey: 'no_matches_date',
              icon: Icons.sports_soccer_rounded,
            ),
        ],
      );
    }

    // Extract Favorite Matches for today (pinned on top like Yalla Shoot)
    // Always pinned on top across all filters and sorting orders
    final List<MatchEntity> favoriteMatches = [];
    if (state.activeFilter != MatchFilterType.favorites) {
      for (final league in displayLeagues) {
        for (final m in league.matches) {
          if (m.isFavorite && !favoriteMatches.any((fav) => fav.id == m.id)) {
            favoriteMatches.add(m);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dateHeader,

        // Pinned Favorites section if any matches favorited
        if (favoriteMatches.isNotEmpty)
          LeagueSectionWidget(
            key: ValueKey('fav_section_${state.selectedDate.day}'),
            league: LeagueGroupEntity(
              leagueTitle: isArabic ? 'المفضلة' : 'Favorites',
              matches: favoriteMatches,
            ),
            timeFormat: state.timeFormat,
            onFavoriteMatchTap: (matchId) {
              context.read<MatchesBloc>().add(
                ToggleMatchFavoriteEvent(matchId),
              );
              try {
                context.read<FavoritesCubit>().loadFavorites();
              } catch (_) {}
            },
          ),

        // Championship / League Sections
        ...displayLeagues.map((league) {
          return LeagueSectionWidget(
            key: ValueKey('${league.leagueTitle}_${state.timeFormat}'),
            league: league,
            timeFormat: state.timeFormat,
            isTimeSorted: state.sortOrder == MatchesSortOrder.time,
            onFavoriteMatchTap: (matchId) {
              context.read<MatchesBloc>().add(
                ToggleMatchFavoriteEvent(matchId),
              );
              try {
                context.read<FavoritesCubit>().loadFavorites();
              } catch (_) {}
            },
          );
        }),
      ],
    );
  }

  Widget _buildMatchesSkeleton(
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
          child: Column(
            children: [
              LeagueSectionWidget(
                key: const ValueKey('sk_league_1'),
                league: LeagueGroupEntity(
                  leagueTitle: isArabic ? 'الدوري الإسباني' : 'La Liga',
                  matches: const [
                    MatchEntity(
                      id: 'sk1',
                      team1: 'راسينغ',
                      team2: 'ألافيس',
                      time: '15:00',
                      status: 'لم تبدأ',
                    ),
                    MatchEntity(
                      id: 'sk2',
                      team1: 'أوساسونا',
                      team2: 'إسبانيول',
                      time: '17:15',
                      status: 'لم تبدأ',
                    ),
                    MatchEntity(
                      id: 'sk3',
                      team1: 'أتلتيك بلباو',
                      team2: 'إلتشي',
                      time: '19:30',
                      status: 'لم تبدأ',
                    ),
                    MatchEntity(
                      id: 'sk4',
                      team1: 'ريال مدريد',
                      team2: 'رايو فاليكانو',
                      time: '22:00',
                      status: 'لم تبدأ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LeagueSectionWidget(
                key: const ValueKey('sk_league_2'),
                league: LeagueGroupEntity(
                  leagueTitle: isArabic ? 'الدوري الفرنسي' : 'Ligue 1',
                  matches: const [
                    MatchEntity(
                      id: 'sk5',
                      team1: 'ستراسبورغ',
                      team2: 'موناكو',
                      time: '18:15',
                      status: 'لم تبدأ',
                    ),
                    MatchEntity(
                      id: 'sk6',
                      team1: 'أوكسير',
                      team2: 'نيس',
                      time: '21:45',
                      status: 'لم تبدأ',
                    ),
                    MatchEntity(
                      id: 'sk7',
                      team1: 'لوهافر',
                      team2: 'أنجيه',
                      time: '21:45',
                      status: 'لم تبدأ',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
