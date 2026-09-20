import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../../../standings/presentation/widgets/standings_table.dart';
import '../bloc/league_bloc.dart';
import '../bloc/league_event.dart';
import '../bloc/league_state.dart';
import '../widgets/league_header_card.dart';
import '../widgets/top_scorers_table.dart';

class LeagueView extends StatefulWidget {
  final String leagueId;
  final String? initialTitle;
  final String? initialLogo;
  final int initialTabIndex;

  const LeagueView({
    super.key,
    required this.leagueId,
    this.initialTitle,
    this.initialLogo,
    this.initialTabIndex = 0,
  });

  @override
  State<LeagueView> createState() => _LeagueViewState();
}

class _LeagueViewState extends State<LeagueView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    context.read<LeagueBloc>().add(LoadLeagueDetailsEvent(widget.leagueId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return BlocBuilder<LeagueBloc, LeagueState>(
      builder: (context, state) {
        final title =
            state.leagueTitle ??
            widget.initialTitle ??
            l10n.translate('standings_title');

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Column(
            children: [
              // League Hero Header
              BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, favState) {
                  final isFav =
                      favState.favoriteCompetitions.contains(title) ||
                      favState.favoriteCompetitions.contains(widget.leagueId);

                  return LeagueHeaderCard(
                    title: title,
                    logo: state.leagueLogo ?? widget.initialLogo,
                    country: state.country,
                    season: state.season,
                    isFavorite: isFav,
                    onFavoriteTap: () {
                      context.read<FavoritesCubit>().toggleCompetition(title);
                    },
                  );
                },
              ),

              // Tab Bar
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  labelStyle: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: isArabic ? 'المباريات' : 'Matches'),
                    Tab(text: isArabic ? 'الترتيب' : 'Standings'),
                    Tab(text: isArabic ? 'الهدافون' : 'Top Scorers'),
                    Tab(text: isArabic ? 'صناع اللعب' : 'Assists'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tab Body with RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final completer = Completer<void>();
                    context.read<LeagueBloc>().add(
                      LoadLeagueDetailsEvent(
                        widget.leagueId,
                        isRefresh: true,
                        completer: completer,
                      ),
                    );
                    try {
                      await completer.future.timeout(const Duration(seconds: 3));
                    } catch (_) {}
                  },
                  child: state.status == LeagueStatus.loading
                      ? Skeletonizer(
                          enabled: true,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
                            children: [
                              SectionHeader(
                                title: isArabic ? 'المباريات' : 'Matches',
                              ),
                              ...List.generate(
                                3,
                                (_) => const MatchCard(
                                  match: MatchEntity(
                                    id: 'skeleton',
                                    team1: 'Arsenal FC',
                                    team2: 'Chelsea FC',
                                    score1: '2',
                                    score2: '1',
                                    status: 'Finished',
                                    time: '20:00',
                                    leagueTitle: 'Premier League',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SectionHeader(
                                title: isArabic ? 'جدول الترتيب' : 'Standings',
                              ),
                              ...List.generate(
                                4,
                                (_) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : state.status == LeagueStatus.error
                      ? ErrorView(
                          message: state.errorMessage,
                          onRetry: () => context.read<LeagueBloc>().add(
                            LoadLeagueDetailsEvent(widget.leagueId),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildMatchesTab(context, state, isDark, isArabic),
                            _buildStandingsTab(
                              context,
                              state,
                              isDark,
                              isArabic,
                            ),
                            _buildTopScorersTab(
                              context,
                              state,
                              isDark,
                              isArabic,
                            ),
                            _buildTopAssistsTab(
                              context,
                              state,
                              isDark,
                              isArabic,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<MatchEntity>> _groupLeagueMatches(
    List<MatchEntity> matches,
    bool isArabic,
  ) {
    final grouped = <String, List<MatchEntity>>{};
    if (matches.isEmpty) return grouped;

    String formatDayHeader(DateTime dt) {
      final arabicDays = [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ];
      final englishDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = isArabic
          ? arabicDays[dt.weekday - 1]
          : englishDays[dt.weekday - 1];
      final dayStr = dt.day.toString().padLeft(2, '0');
      final monthStr = dt.month.toString().padLeft(2, '0');
      final yearStr = dt.year.toString();
      return '$dayName $dayStr-$monthStr-$yearStr';
    }

    int parseTimeMinutes(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty || timeStr == '-') return 0;
      final clean = timeStr.trim();
      final match =
          RegExp(r'(\d{1,2}):(\d{2})\s*([صم]|AM|PM|am|pm)?').firstMatch(clean);
      if (match == null) return 0;
      var h = int.tryParse(match.group(1) ?? '0') ?? 0;
      final m = int.tryParse(match.group(2) ?? '0') ?? 0;
      final period = match.group(3);
      if ((period == 'م' || period?.toUpperCase() == 'PM') && h < 12) {
        h += 12;
      } else if ((period == 'ص' || period?.toUpperCase() == 'AM') && h == 12) {
        h = 0;
      }
      return h * 60 + m;
    }

    DateTime currentUpcomingDate = DateTime.now();
    int lastUpcomingMinutes = -1;

    DateTime currentPastDate = DateTime.now().subtract(
      Duration(
        days: (DateTime.now().weekday == DateTime.sunday)
            ? 7
            : (DateTime.now().weekday == DateTime.monday
                ? 1
                : DateTime.now().weekday % 7),
      ),
    );
    int finishedCountInCurrentDay = 0;
    int currentDayCapacity = 4;

    for (final match in matches) {
      final status = match.status;
      final isFinished = status?.contains('انتهت') == true ||
          status?.contains('FT') == true;

      if (match.date != null && match.date!.isNotEmpty) {
        grouped.putIfAbsent(match.date!, () => <MatchEntity>[]).add(match);
        continue;
      }

      if (!isFinished) {
        final matchMinutes = parseTimeMinutes(match.time);
        if (lastUpcomingMinutes != -1 && matchMinutes < lastUpcomingMinutes) {
          // Time dropped -> next match day
          final daysToAdd = (currentUpcomingDate.weekday == DateTime.friday)
              ? 1
              : (currentUpcomingDate.weekday == DateTime.saturday)
                  ? 1
                  : (currentUpcomingDate.weekday == DateTime.sunday)
                      ? 5
                      : (DateTime.friday - currentUpcomingDate.weekday + 7) % 7;
          currentUpcomingDate = currentUpcomingDate.add(
            Duration(days: daysToAdd > 0 ? daysToAdd : 1),
          );
        } else if (lastUpcomingMinutes != -1 &&
            matchMinutes == lastUpcomingMinutes &&
            currentUpcomingDate.day == DateTime.now().day) {
          final daysToFriday =
              (DateTime.friday - currentUpcomingDate.weekday + 7) % 7;
          currentUpcomingDate = currentUpcomingDate.add(
            Duration(days: daysToFriday > 0 ? daysToFriday : 4),
          );
        }

        lastUpcomingMinutes = matchMinutes;
        final headerKey = formatDayHeader(currentUpcomingDate);
        grouped.putIfAbsent(headerKey, () => <MatchEntity>[]).add(match);
      } else {
        if (finishedCountInCurrentDay >= currentDayCapacity) {
          finishedCountInCurrentDay = 0;
          if (currentPastDate.weekday == DateTime.sunday) {
            currentPastDate =
                currentPastDate.subtract(const Duration(days: 1));
            currentDayCapacity = 5;
          } else if (currentPastDate.weekday == DateTime.saturday) {
            currentPastDate =
                currentPastDate.subtract(const Duration(days: 6));
            currentDayCapacity = 3;
          } else if (currentPastDate.weekday == DateTime.friday) {
            currentPastDate =
                currentPastDate.subtract(const Duration(days: 5));
            currentDayCapacity = 4;
          } else {
            currentPastDate =
                currentPastDate.subtract(const Duration(days: 1));
            currentDayCapacity = 4;
          }
        }

        finishedCountInCurrentDay++;
        final headerKey = formatDayHeader(currentPastDate);
        grouped.putIfAbsent(headerKey, () => <MatchEntity>[]).add(match);
      }
    }

    return grouped;
  }

  Widget _buildMatchesTab(
    BuildContext context,
    LeagueState state,
    bool isDark,
    bool isArabic,
  ) {
    if (state.matches.isEmpty) {
      return EmptyView(
        titleKey: 'no_matches_date',
        customMessage: isArabic
            ? 'لا توجد مباريات متاحة لهذه البطولة حاليًا'
            : 'No matches available for this league',
        icon: Icons.sports_soccer_rounded,
      );
    }

    final groupedMatches = _groupLeagueMatches(state.matches, isArabic);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: groupedMatches.entries.map((entry) {
        final headerText = entry.key;
        final List<MatchEntity> matches = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    headerText,
                    style: AppTypography.getBodyMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...matches.map(
              (MatchEntity m) => MatchCard(key: ValueKey(m.id), match: m),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStandingsTab(
    BuildContext context,
    LeagueState state,
    bool isDark,
    bool isArabic,
  ) {
    if (state.standings == null || state.standings!.rows.isEmpty) {
      return EmptyView(
        titleKey: 'no_matches_date',
        customMessage: isArabic
            ? 'لا توجد بيانات جدول الترتيب متاحة لهذه البطولة'
            : 'No standings data available for this competition',
        icon: Icons.table_chart_outlined,
      );
    }

    final standings = state.standings!;
    final hasGroups = standings.hasMultipleGroups;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [
        if (hasGroups) ...[
          ...standings.groups!.entries.map((groupEntry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    groupEntry.key,
                    style: AppTypography.getHeadingMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontSize: 16),
                  ),
                ),
                StandingsTable(rows: groupEntry.value),
              ],
            );
          }),
        ] else ...[
          StandingsTable(rows: standings.rows),
        ],
        if (standings.legends != null && standings.legends!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xl,
              vertical: 12,
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: standings.legends!.map((item) {
                Color itemColor = AppColors.primary;
                try {
                  final hex = item.colorHex.replaceFirst('#', '');
                  if (hex.length == 6) {
                    itemColor = Color(int.parse('0xFF$hex'));
                  }
                } catch (_) {}

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: itemColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        if (standings.rulesList != null && standings.rulesList!.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: hMargin,
              vertical: 8,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.rule_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'معايير كسر التعادل' : 'Tiebreaker Rules',
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...standings.rulesList!.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final rule = entry.value;
                  final isPreamble = idx == 0 && rule.contains('في حالة');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isPreamble) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            rule,
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontSize: isPreamble ? 12 : 11.5,
                              fontWeight: isPreamble ? FontWeight.w600 : FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTopScorersTab(
    BuildContext context,
    LeagueState state,
    bool isDark,
    bool isArabic,
  ) {
    if (state.topScorers.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات للهدافين حاليًا'
            : 'No top scorers available for this competition',
        icon: Icons.emoji_events_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [
        TopScorersTable(
          scorers: state.topScorers,
          isAssists: false,
        ),
      ],
    );
  }

  Widget _buildTopAssistsTab(
    BuildContext context,
    LeagueState state,
    bool isDark,
    bool isArabic,
  ) {
    if (state.topAssists.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات لصناع اللعب حاليًا'
            : 'No top assists available for this competition',
        icon: Icons.emoji_events_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [
        TopScorersTable(
          scorers: state.topAssists,
          isAssists: true,
        ),
      ],
    );
  }
}
