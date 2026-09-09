import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../bloc/team_bloc.dart';
import '../bloc/team_event.dart';
import '../bloc/team_state.dart';
import '../widgets/team_header_card.dart';

class TeamView extends StatefulWidget {
  final String teamId;
  final String? initialName;
  final String? initialLogo;
  final String? leagueId;

  const TeamView({
    super.key,
    required this.teamId,
    this.initialName,
    this.initialLogo,
    this.leagueId,
  });

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<TeamBloc>().add(
      LoadTeamProfileEvent(
        widget.teamId,
        teamName: widget.initialName,
        leagueId: widget.leagueId,
      ),
    );
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

    return BlocBuilder<TeamBloc, TeamState>(
      builder: (context, state) {
        final displayName =
            state.profile?.teamName ??
            state.teamName ??
            widget.initialName ??
            'Team';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              displayName,
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
              // Team Header Card
              TeamHeaderCard(
                profile: state.profile,
                fallbackName: displayName,
                fallbackLogo: state.teamLogo ?? widget.initialLogo,
              ),

              // Tab Bar
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  unselectedLabelColor: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  labelStyle: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: l10n.translate('tab_overview')),
                    Tab(text: isArabic ? 'المباريات القادمة' : 'Fixtures'),
                    Tab(text: isArabic ? 'النتائج السابقة' : 'Results'),
                    Tab(text: isArabic ? 'تشكيلة الفريق' : 'Squad'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tab Body with RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<TeamBloc>().add(
                      LoadTeamProfileEvent(
                        widget.teamId,
                        teamName: widget.initialName,
                        leagueId: widget.leagueId,
                        isRefresh: true,
                      ),
                    );
                  },
                  child: state.status == TeamStatus.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : state.status == TeamStatus.error
                      ? ErrorView(
                          message: state.errorMessage,
                          onRetry: () => context.read<TeamBloc>().add(
                            LoadTeamProfileEvent(
                              widget.teamId,
                              teamName: widget.initialName,
                              leagueId: widget.leagueId,
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(context, state, isDark, isArabic),
                            _buildFixturesTab(context, state, isDark, isArabic),
                            _buildResultsTab(context, state, isDark, isArabic),
                            _buildSquadTab(context, state, isDark, isArabic),
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
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    final profile = state.profile;
    final hasUpcoming = profile != null && profile.upcomingMatches.isNotEmpty;
    final hasRecent = profile != null && profile.recentMatches.isNotEmpty;

    if (!hasUpcoming && !hasRecent) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد مباريات مسجلة لهذا الفريق حاليًا'
            : 'No matches currently recorded for this team',
        icon: Icons.sports_soccer_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [
        // 1. Next Upcoming Match
        if (hasUpcoming) ...[
          SectionHeader(
            title: isArabic ? 'المباراة القادمة' : 'Next Match',
            actionText: l10n.translate('view_all'),
            onActionTap: () => _tabController.animateTo(1),
          ),
          MatchCard(match: profile.upcomingMatches.first),
          const SizedBox(height: 12),
        ],

        // 2. Recent Results Preview
        if (hasRecent) ...[
          SectionHeader(
            title: isArabic ? 'آخر النتائج' : 'Recent Results',
            actionText: l10n.translate('view_all'),
            onActionTap: () => _tabController.animateTo(2),
          ),
          ...profile.recentMatches.take(3).map((m) => MatchCard(match: m)),
          const SizedBox(height: 12),
        ],

        // 3. League shortcut if standingRow exists
        if (profile.leagueId != null && profile.leagueName != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: 8,
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '/league/${profile.leagueId}',
                  extra: {'title': profile.leagueName},
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: Text(
                '${isArabic ? "جدول ترتيب" : "View"} ${profile.leagueName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFixturesTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final fixtures = state.profile?.upcomingMatches ?? [];

    if (fixtures.isEmpty) {
      return EmptyView(
        titleKey: 'no_matches_date',
        customMessage: isArabic
            ? 'لا توجد مباريات قادمة مجدولة'
            : 'No upcoming fixtures scheduled',
        icon: Icons.calendar_month_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: fixtures.length,
      itemBuilder: (context, index) {
        return MatchCard(match: fixtures[index]);
      },
    );
  }

  Widget _buildResultsTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final results = state.profile?.recentMatches ?? [];

    if (results.isEmpty) {
      return EmptyView(
        titleKey: 'no_matches_date',
        customMessage: isArabic
            ? 'لا توجد نتائج سابقة مسجلة'
            : 'No past match results recorded',
        icon: Icons.history_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return MatchCard(match: results[index]);
      },
    );
  }

  Widget _buildSquadTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final squad = state.profile?.squad ?? [];

    if (squad.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات تشكيلة مسجلة لهذا الفريق حالياً'
            : 'No squad roster data available for this team',
        icon: Icons.groups_rounded,
      );
    }

    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      itemCount: squad.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = squad[index];

        return InkWell(
          onTap: player.id.isNotEmpty
              ? () => context.push(
                    '/player/${player.id}?slug=${Uri.encodeComponent(player.name)}',
                  )
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                // Player Number Badge
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    player.number?.isNotEmpty == true ? player.number! : '-',
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Player Photo
                AppImage(
                  imageUrl: player.photo,
                  width: 36,
                  height: 36,
                  borderRadius: 18,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.person_rounded,
                ),
                const SizedBox(width: 12),

                // Name & Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.name,
                        style: AppTypography.getBodyMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (player.position != null &&
                          player.position!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          player.position!,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Position Badge
                if (player.position != null && player.position!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Text(
                      player.position!,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      },
    );
  }
}
