import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
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

  const LeagueView({
    super.key,
    required this.leagueId,
    this.initialTitle,
    this.initialLogo,
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
    _tabController = TabController(length: 4, vsync: this);
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
              LeagueHeaderCard(
                title: title,
                logo: state.leagueLogo ?? widget.initialLogo,
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
                    Tab(text: l10n.translate('tab_overview')),
                    Tab(text: l10n.translate('nav_matches')),
                    Tab(text: l10n.translate('nav_standings')),
                    Tab(text: isArabic ? 'الهدافون' : 'Top Scorers'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tab Body with RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<LeagueBloc>().add(
                      LoadLeagueDetailsEvent(widget.leagueId, isRefresh: true),
                    );
                  },
                  child: state.status == LeagueStatus.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
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
                          children: [
                            _buildOverviewTab(context, state, isDark, isArabic),
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

  Widget _buildOverviewTab(
    BuildContext context,
    LeagueState state,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    final hasStandings =
        state.standings != null && state.standings!.rows.isNotEmpty;
    final hasMatches = state.matches.isNotEmpty;
    final hasScorers = state.topScorers.isNotEmpty;

    if (!hasStandings && !hasMatches && !hasScorers) {
      return const EmptyView(
        titleKey: 'tab_overview',
        customMessage: 'No competition data currently available',
        icon: Icons.emoji_events_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [
        // 1. Matches Preview
        if (hasMatches) ...[
          SectionHeader(
            title: l10n.translate('nav_matches'),
            actionText: l10n.translate('view_all'),
            onActionTap: () => _tabController.animateTo(1),
          ),
          ...state.matches.take(4).map((m) => MatchCard(match: m)),
          const SizedBox(height: 12),
        ],

        // 2. Standings Preview (Top 5)
        if (hasStandings) ...[
          SectionHeader(
            title: l10n.translate('nav_standings'),
            actionText: l10n.translate('view_all'),
            onActionTap: () => _tabController.animateTo(2),
          ),
          StandingsTable(rows: state.standings!.rows.take(5).toList()),
          const SizedBox(height: 12),
        ],

        // 3. Top Scorers Preview (Top 5)
        if (hasScorers) ...[
          SectionHeader(
            title: isArabic ? 'أبرز الهدافين' : 'Top Scorers',
            actionText: l10n.translate('view_all'),
            onActionTap: () => _tabController.animateTo(3),
          ),
          TopScorersTable(scorers: state.topScorers, maxRows: 5),
          const SizedBox(height: 12),
        ],
      ],
    );
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.matches.length,
      itemBuilder: (context, index) {
        return MatchCard(match: state.matches[index]);
      },
    );
  }

  Widget _buildStandingsTab(
    BuildContext context,
    LeagueState state,
    bool isDark,
    bool isArabic,
  ) {
    if (state.standings == null || state.standings!.rows.isEmpty) {
      return const EmptyView(
        titleKey: 'no_matches_date',
        customMessage: 'No standings data available for this competition',
        icon: Icons.table_chart_outlined,
      );
    }

    final standings = state.standings!;
    final hasGroups = standings.hasMultipleGroups;

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
      return const EmptyView(
        titleKey: 'tab_overview',
        customMessage: 'No top scorers available for this competition',
        icon: Icons.emoji_events_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [TopScorersTable(scorers: state.topScorers)],
    );
  }
}
