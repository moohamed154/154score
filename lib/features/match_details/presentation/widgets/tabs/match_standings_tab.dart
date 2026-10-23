import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/utils/league_resolver.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../matches/domain/entities/match_entity.dart';
import '../../../../standings/domain/entities/standings_entity.dart';
import '../../../../standings/presentation/bloc/standings_bloc.dart';
import '../../../../standings/presentation/widgets/standings_table.dart';
import '../../bloc/match_details_state.dart';

class MatchStandingsTab extends StatelessWidget {
  final MatchDetailsState state;
  final MatchEntity match;
  final MatchEntity? initialMatch;
  final bool isDark;
  final bool isArabic;
  final Future<void> Function() onRefresh;

  const MatchStandingsTab({
    super.key,
    required this.state,
    required this.match,
    this.initialMatch,
    required this.isDark,
    required this.isArabic,
    required this.onRefresh,
  });

  static String? resolveLeagueId({
    MatchEntity? match,
    MatchEntity? initialMatch,
  }) {
    final rawId = match?.leagueId ?? initialMatch?.leagueId;
    if (rawId != null && rawId.isNotEmpty && rawId != 'null') {
      return rawId;
    }
    final title =
        (match?.leagueTitle ?? initialMatch?.leagueTitle ?? '').toLowerCase();
    final resolved = LeagueResolver.resolveId(title);
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    if (title.contains('إسباني') ||
        title.contains('laliga') ||
        title.contains('spain')) {
      return '938652';
    }
    if (title.contains('إنجليزي') ||
        title.contains('premier') ||
        title.contains('england')) {
      return '937599';
    }
    if (title.contains('روسي') ||
        title.contains('russian') ||
        title.contains('russia')) {
      return '938370';
    }
    if (title.contains('إيطالي') ||
        title.contains('serie a') ||
        title.contains('italy')) {
      return '936357';
    }
    if (title.contains('ألماني') ||
        title.contains('bundesliga') ||
        title.contains('germany')) {
      return '938769';
    }
    if (title.contains('فرنسي') ||
        title.contains('ligue 1') ||
        title.contains('france')) {
      return '937873';
    }
    if (title.contains('أبطال أوروبا') || title.contains('champions')) {
      return '904988';
    }
    if (title.contains('سعودي') || title.contains('roshn')) {
      return '941825';
    }
    if (title.contains('مصري') || title.contains('egypt')) {
      return '943009';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final leagueId = state.championshipId ??
        match.leagueId ??
        resolveLeagueId(match: match, initialMatch: initialMatch);

    if (leagueId == null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.format_list_numbered_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'جدول الترتيب غير متوفر لهذه البطولة حالياً'
                          : 'Standings not available for this competition',
                      style: AppTypography.getBodyLarge(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider<StandingsBloc>(
      create: (_) => sl<StandingsBloc>()..add(LoadStandingsEvent(leagueId)),
      child: BlocBuilder<StandingsBloc, StandingsState>(
        builder: (context, state) {
          if (state.status == StandingsStatus.loading) {
            return Skeletonizer(
              enabled: true,
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: AppDimensions.xxxl,
                ),
                children: [
                  StandingsTable(
                    rows: List.generate(
                      8,
                      (index) => StandingRowEntity(
                        position: index + 1,
                        teamName: isArabic ? 'ريال مدريد' : 'Real Madrid',
                        played: 28,
                        wins: 21,
                        draws: 5,
                        losses: 2,
                        goalsFor: 62,
                        goalsAgainst: 20,
                        goalDiff: 42,
                        points: 68 - (index * 3),
                      ),
                    ),
                    showFullStats: true,
                  ),
                ],
              ),
            );
          }

          if (state.status == StandingsStatus.error) {
            return ErrorView(
              message: state.errorMessage,
              onRetry: () {
                context.read<StandingsBloc>().add(LoadStandingsEvent(leagueId));
              },
            );
          }

          if (state.standings == null || state.standings!.rows.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final standingsCompleter = Completer<void>();
                context.read<StandingsBloc>().add(
                      LoadStandingsEvent(
                        leagueId,
                        isRefresh: true,
                        completer: standingsCompleter,
                      ),
                    );
                await Future.wait([
                  standingsCompleter.future.timeout(
                    const Duration(seconds: 4),
                    onTimeout: () {},
                  ),
                  onRefresh(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyView(
                    titleKey: 'standings_title',
                    customMessage: isArabic
                        ? 'لا يوجد جدول ترتيب متوفر لهذه البطولة حالياً'
                        : 'No standings data available for this competition',
                    icon: Icons.table_chart_outlined,
                  ),
                ],
              ),
            );
          }

          final standings = state.standings!;
          final hasGroups = standings.hasMultipleGroups;

          final t1Name = (match.team1.isNotEmpty
                  ? match.team1
                  : (initialMatch?.team1 ?? ''))
              .trim();
          final t2Name = (match.team2.isNotEmpty
                  ? match.team2
                  : (initialMatch?.team2 ?? ''))
              .trim();
          final t1Id = (match.team1Id?.isNotEmpty == true
                  ? match.team1Id
                  : initialMatch?.team1Id)
              ?.trim();
          final t2Id = (match.team2Id?.isNotEmpty == true
                  ? match.team2Id
                  : initialMatch?.team2Id)
              ?.trim();

          List<MapEntry<String, List<StandingRowEntity>>> sortedGroupEntries =
              [];
          if (hasGroups) {
            final rawEntries = standings.groups!.entries.toList();

            bool rowMatchesTeam(StandingRowEntity row) {
              final rName = row.teamName.trim().toLowerCase();
              final rId = row.teamId?.trim();

              if (t1Id != null && t1Id.isNotEmpty && rId == t1Id) return true;
              if (t2Id != null && t2Id.isNotEmpty && rId == t2Id) return true;

              if (t1Name.isNotEmpty) {
                final target = t1Name.toLowerCase();
                if (rName == target ||
                    rName.contains(target) ||
                    target.contains(rName)) {
                  return true;
                }
              }
              if (t2Name.isNotEmpty) {
                final target = t2Name.toLowerCase();
                if (rName == target ||
                    rName.contains(target) ||
                    target.contains(rName)) {
                  return true;
                }
              }
              return false;
            }

            int countMatchingTeams(
                MapEntry<String, List<StandingRowEntity>> entry) {
              int count = 0;
              for (final row in entry.value) {
                if (rowMatchesTeam(row)) {
                  count++;
                }
              }
              return count;
            }

            final matchGroups = <MapEntry<String, List<StandingRowEntity>>>[];
            final otherGroups = <MapEntry<String, List<StandingRowEntity>>>[];

            for (final entry in rawEntries) {
              if (countMatchingTeams(entry) > 0) {
                matchGroups.add(entry);
              } else {
                otherGroups.add(entry);
              }
            }

            matchGroups.sort(
              (a, b) => countMatchingTeams(b).compareTo(countMatchingTeams(a)),
            );
            sortedGroupEntries = [...matchGroups, ...otherGroups];
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final standingsCompleter = Completer<void>();
              context.read<StandingsBloc>().add(
                    LoadStandingsEvent(
                      leagueId,
                      isRefresh: true,
                      completer: standingsCompleter,
                    ),
                  );
              await Future.wait([
                standingsCompleter.future.timeout(
                  const Duration(seconds: 4),
                  onTimeout: () {},
                ),
                onRefresh(),
              ]);
            },
            child: ListView(
              key: const PageStorageKey('match_standings_tab_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (hasGroups) ...[
                  ...sortedGroupEntries.map((groupEntry) {
                    final isMatchGroup = sortedGroupEntries.isNotEmpty &&
                        groupEntry == sortedGroupEntries.first &&
                        (t1Name.isNotEmpty || t2Name.isNotEmpty);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .formatGroupName(groupEntry.key),
                                style: AppTypography.getHeadingMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(fontSize: 16),
                              ),
                              if (isMatchGroup) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    isArabic
                                        ? 'مجموعة المباراة'
                                        : 'Match Group',
                                    style: AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: isArabic,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        StandingsTable(
                          rows: groupEntry.value,
                          highlightedTeamNames: [
                            if (t1Name.isNotEmpty) t1Name,
                            if (t2Name.isNotEmpty) t2Name,
                          ],
                        ),
                      ],
                    );
                  }),
                ] else ...[
                  StandingsTable(
                    rows: standings.rows,
                    highlightedTeamNames: [
                      if (t1Name.isNotEmpty) t1Name,
                      if (t2Name.isNotEmpty) t2Name,
                    ],
                  ),
                ],

                // Promotion / Relegation Legend
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
                          final hex = item.colorHex.replaceAll('#', '');
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
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.description,
                              style: AppTypography.getBodySmall(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
