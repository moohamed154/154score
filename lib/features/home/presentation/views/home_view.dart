import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../../../matches/presentation/bloc/matches_state.dart';
import '../../../matches/presentation/widgets/date_navigation_buttons.dart';
import '../../../matches/presentation/widgets/league_section_widget.dart';
import '../../../matches/presentation/widgets/live_match_card.dart';
import '../../../matches/presentation/widgets/match_filter_bottom_sheet.dart';
import '../../../matches/presentation/widgets/swipe_date_detector.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';

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
          now.add(const Duration(days: 1)),       // tomorrow
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
                        // Logo + Title + Date
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sports_soccer_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
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
                        // Actions row ordered from left: Date Selector -> Search -> Filter
                        Row(
                          textDirection: TextDirection.ltr,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 4),
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
                            // Search Icon
                            IconButton(
                              icon: const Icon(Icons.search_rounded),
                              tooltip: l10n.translate('nav_search'),
                              onPressed: () => context.push('/search'),
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
                              onPressed: () => MatchFilterBottomSheet.show(context),
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

      body: BlocBuilder<MatchesBloc, MatchesState>(
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
                  await matchesCompleter.future
                      .timeout(const Duration(seconds: 3));
                } catch (_) {}
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
              children: [
                // Selected date label (updates when swiping days)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _formatDate(matchesState.selectedDate, isArabic),
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),

                if (isHomeLoading)
                  _buildMatchesSkeleton(context, isDark, isArabic)
                else ...[
                  // 1. LIVE NOW Section (if any live matches)
                  _buildLiveNowSection(
                    context,
                    matchesState,
                    isDark,
                    isArabic,
                  ),

                  // 2. Matches for Selected Date
                  _buildMatchesSection(
                    context,
                    matchesState,
                    isDark,
                    isArabic,
                  ),
                ],
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date, bool isArabic) {
    const englishDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const arabicDays = [
      'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
      'الجمعة', 'السبت', 'الأحد',
    ];
    final dayIndex = date.weekday - 1; // weekday: 1=Monday … 7=Sunday
    final dayName = isArabic ? arabicDays[dayIndex] : englishDays[dayIndex];
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dayName, $dd/$mm/$yyyy';
  }

  Widget _buildLiveNowSection(
    BuildContext context,
    MatchesState matchesState,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    // Extract all live matches from state
    final liveMatches = <dynamic>[];
    for (final league in matchesState.allLeagues) {
      for (final m in league.matches) {
        if (m.status != null &&
            (m.status!.toLowerCase().contains('live') ||
                m.status!.toLowerCase().contains('مباشر') ||
                m.status!.toLowerCase().contains('شوط') ||
                m.status!.toLowerCase().contains('half') ||
                m.status!.toLowerCase().contains('استراحة'))) {
          liveMatches.add(m);
        }
      }
    }

    if (liveMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('live_now'),
          leading: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.liveRed,
            ),
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            itemCount: liveMatches.length,
            itemBuilder: (context, index) {
              return LiveMatchCard(match: liveMatches[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMatchesSection(
    BuildContext context,
    MatchesState state,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    final displayLeagues = state.filteredLeagues;

    if ((state.status == MatchesStatus.loading ||
            state.status == MatchesStatus.initial) &&
        displayLeagues.isEmpty) {
      return _buildMatchesSkeleton(context, isDark, isArabic);
    }

    if (state.status == MatchesStatus.error && displayLeagues.isEmpty) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () => context.read<MatchesBloc>().add(
          LoadMatchesEvent(date: state.selectedDate),
        ),
      );
    }

    if (displayLeagues.isEmpty) {
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

    final maxCount = state.hasActiveFilter ? 10 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('nav_matches'),
          actionText: l10n.translate('view_all'),
          onActionTap: () => context.go('/matches'),
        ),
        ...displayLeagues.take(maxCount).map((league) {
          return LeagueSectionWidget(
            key: ValueKey(league.leagueTitle),
            league: league,
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
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('nav_matches'),
          actionText: l10n.translate('view_all'),
          onActionTap: () => context.go('/matches'),
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
