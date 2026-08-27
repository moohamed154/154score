import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../bloc/match_details_bloc.dart';
import '../bloc/match_details_event.dart';
import '../bloc/match_details_state.dart';
import '../widgets/match_header_banner.dart';
import '../widgets/match_info_card.dart';
import '../widgets/stat_comparison_bar.dart';
import '../widgets/timeline_event_item.dart';

class MatchDetailsView extends StatefulWidget {
  final String matchId;
  final MatchEntity? initialMatch;

  const MatchDetailsView({super.key, required this.matchId, this.initialMatch});

  @override
  State<MatchDetailsView> createState() => _MatchDetailsViewState();
}

class _MatchDetailsViewState extends State<MatchDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<MatchDetailsBloc>().add(LoadMatchDetailsEvent(widget.matchId));
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

    final fallbackMatch =
        widget.initialMatch ??
        MatchEntity(id: widget.matchId, team1: 'Home Team', team2: 'Away Team');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${fallbackMatch.team1} vs ${fallbackMatch.team2}',
          style: AppTypography.getBodyLarge(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
        builder: (context, state) {
          return Column(
            children: [
              // Top Score Hero Banner
              MatchHeaderBanner(
                match: fallbackMatch,
                liveScore1: state.liveScore1,
                liveScore2: state.liveScore2,
                liveStatus: state.liveStatus,
              ),

              // Sticky Sports Tab Bar
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
                    Tab(text: l10n.translate('tab_events')),
                    Tab(text: l10n.translate('tab_stats')),
                    Tab(text: l10n.translate('tab_info')),
                    Tab(text: l10n.translate('tab_news')),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tab Views
              Expanded(
                child: state.status == MatchDetailsStatus.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : state.status == MatchDetailsStatus.error
                    ? ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<MatchDetailsBloc>().add(
                          LoadMatchDetailsEvent(widget.matchId),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(context, state, fallbackMatch),
                          _buildEventsTab(context, state),
                          _buildStatsTab(context, state),
                          _buildInfoTab(context, state),
                          _buildNewsTab(context, state),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    MatchDetailsState state,
    MatchEntity match,
  ) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        // Quick Stats summary if available
        if (state.stats.isNotEmpty) ...[
          Text(
            l10n.translate('tab_stats'),
            style: AppTypography.getHeadingMedium(
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...state.stats.take(3).map((stat) => StatComparisonBar(stat: stat)),
          const SizedBox(height: AppDimensions.lg),
        ],

        // Quick Events summary if available
        if (state.events.isNotEmpty) ...[
          Text(
            l10n.translate('tab_events'),
            style: AppTypography.getHeadingMedium(
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...state.events.take(4).map((e) => TimelineEventItem(event: e)),
          const SizedBox(height: AppDimensions.lg),
        ],

        // Quick Details cards
        if (state.details.isNotEmpty)
          ...state.details.take(2).map((sec) => MatchInfoCard(section: sec)),

        if (state.events.isEmpty &&
            state.stats.isEmpty &&
            state.details.isEmpty)
          EmptyView(
            titleKey: 'tab_overview',
            customMessage: l10n.translate('status_not_started'),
            icon: Icons.sports_soccer_rounded,
          ),
      ],
    );
  }

  Widget _buildEventsTab(BuildContext context, MatchDetailsState state) {
    if (state.events.isEmpty) {
      return const EmptyView(
        titleKey: 'no_events',
        icon: Icons.timeline_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        return TimelineEventItem(event: state.events[index]);
      },
    );
  }

  Widget _buildStatsTab(BuildContext context, MatchDetailsState state) {
    if (state.stats.isEmpty) {
      return const EmptyView(
        titleKey: 'no_stats',
        icon: Icons.bar_chart_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      itemCount: state.stats.length,
      itemBuilder: (context, index) {
        return StatComparisonBar(stat: state.stats[index]);
      },
    );
  }

  Widget _buildInfoTab(BuildContext context, MatchDetailsState state) {
    if (state.details.isEmpty) {
      return const EmptyView(
        titleKey: 'tab_info',
        icon: Icons.info_outline_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      itemCount: state.details.length,
      itemBuilder: (context, index) {
        return MatchInfoCard(section: state.details[index]);
      },
    );
  }

  Widget _buildNewsTab(BuildContext context, MatchDetailsState state) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    if (state.news.isEmpty) {
      return const EmptyView(
        titleKey: 'no_matches_date',
        customMessage: 'No news found for this match',
        icon: Icons.newspaper_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.lg),
      itemCount: state.news.length,
      itemBuilder: (context, index) {
        final item = state.news[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              if (item.image != null)
                AppImage(
                  imageUrl: item.image,
                  width: 90,
                  height: 70,
                  borderRadius: AppDimensions.radiusMd,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.getBodyMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.date!,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ),
                        ),
                      ],
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
}
