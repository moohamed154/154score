import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../bloc/match_details_bloc.dart';
import '../bloc/match_details_event.dart';
import '../bloc/match_details_state.dart';
import '../../domain/entities/match_details_entity.dart';
import '../widgets/lineup_unavailable_widget.dart';
import '../widgets/match_header_banner.dart';
import '../widgets/match_info_card.dart';
import '../widgets/stat_comparison_bar.dart';
import '../widgets/timeline_event_item.dart';

// Filter for Events tab: الأبرز (Highlights) vs كل الأحداث (All Events)
enum _EventFilter { highlights, all }

class MatchDetailsView extends StatefulWidget {
  final String matchId;
  final MatchEntity? initialMatch;

  const MatchDetailsView({super.key, required this.matchId, this.initialMatch});

  @override
  State<MatchDetailsView> createState() => _MatchDetailsViewState();
}

class _MatchDetailsViewState extends State<MatchDetailsView>
    with SingleTickerProviderStateMixin {
  // Main tabs: الأحداث | التفاصيل | التشكيلة | الإحصائيات | الترتيب | الأخبار
  late TabController _tabController;

  // Events tab inner filter
  _EventFilter _eventFilter = _EventFilter.highlights;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        leading: IconButton(
          icon: Icon(
            isArabic
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          '${fallbackMatch.team1} vs ${fallbackMatch.team2}',
          style: AppTypography.getBodyLarge(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
        builder: (context, state) {
          return Column(
            children: [
              // ── Top Score Hero Banner ──────────────────────────────────
              MatchHeaderBanner(
                match: fallbackMatch,
                liveScore1: state.liveScore1,
                liveScore2: state.liveScore2,
                liveStatus: state.liveStatus,
                penaltyScore1: fallbackMatch.penaltyScore1,
                penaltyScore2: fallbackMatch.penaltyScore2,
              ),

              // ── Main Horizontal Scrollable Tab Bar ─────────────────────
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
                    Tab(text: isArabic ? 'الأحداث' : 'Events'),
                    Tab(text: isArabic ? 'التفاصيل' : 'Details'),
                    Tab(text: isArabic ? 'التشكيلة' : 'Lineup'),
                    Tab(text: isArabic ? 'الإحصائيات' : 'Stats'),
                    Tab(text: isArabic ? 'الترتيب' : 'Standings'),
                    Tab(text: isArabic ? 'الأخبار' : 'News'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Tab Content ────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<MatchDetailsBloc>().add(
                      LoadMatchDetailsEvent(widget.matchId, isRefresh: true),
                    );
                  },
                  child: state.status == MatchDetailsStatus.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : state.status == MatchDetailsStatus.error
                      ? ErrorView(
                          message: state.errorMessage,
                          onRetry: () =>
                              context.read<MatchDetailsBloc>().add(
                                LoadMatchDetailsEvent(widget.matchId),
                              ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. الأحداث (Events with Video chips, Highlights/All filter, Timeline & Stats Preview)
                            _buildEventsTab(context, state, fallbackMatch, isDark, isArabic),

                            // 2. التفاصيل (Details / Match Info)
                            _buildDetailsTab(context, state, isDark, isArabic),

                            // 3. التشكيلة (Lineup)
                            const LineupUnavailableWidget(),

                            // 4. الإحصائيات (Full Statistics)
                            _buildStatsTab(context, state, isDark, isArabic),

                            // 5. الترتيب (Standings)
                            _buildStandingsTab(context, isDark, isArabic),

                            // 6. الأخبار (News)
                            _buildNewsTab(context, state, isDark, isArabic),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: الأحداث (Events) ────────────────────────────────────────────────
  Widget _buildEventsTab(
    BuildContext context,
    MatchDetailsState state,
    MatchEntity match,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    // Filter events based on selected filter
    final displayedEvents = state.events.where((e) {
      if (_eventFilter == _EventFilter.all) return true;
      // Highlights: Goals, disallowed goals, penalties, red cards, second yellows, and period markers
      final t = e.type.toLowerCase();
      return t.contains('goal') ||
          t.contains('penalty') ||
          t.contains('red') ||
          t.contains('start-end') ||
          t.contains('period') ||
          t.contains('whistle') ||
          t == 'goal-x';
    }).toList();

    return ListView(
      key: const PageStorageKey('events_tab_list'),
      padding: EdgeInsets.all(hMargin),
      children: [
        // ── Video Highlights Summary Chips ───────────────────────────────
        if (state.news.isNotEmpty) ...[
          _buildVideoSummaryChips(state.news, isDark, isArabic),
          const SizedBox(height: AppDimensions.md),
        ],

        // ── Section Title & Filter (الأحداث + [الأبرز | كل الأحداث]) ─────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'الأحداث' : 'Events',
              style: AppTypography.getHeadingMedium(
                isDark: isDark,
                isArabic: isArabic,
              ),
            ),
            _buildEventFilterSelector(isDark, isArabic),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),

        // ── Events Timeline Container ────────────────────────────────────
        if (displayedEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyView(
              titleKey: 'no_events',
              icon: Icons.timeline_rounded,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: displayedEvents.map((e) => TimelineEventItem(event: e)).toList(),
            ),
          ),

        const SizedBox(height: AppDimensions.lg),

        // ── Mini Statistics Preview Card (from screenshot 3) ─────────────
        if (state.stats.isNotEmpty) ...[
          Text(
            isArabic ? 'الإحصائيات' : 'Statistics',
            style: AppTypography.getHeadingMedium(
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          _buildMiniStatsPreviewCard(state.stats, match, isDark, isArabic),
          const SizedBox(height: AppDimensions.lg),
        ],
      ],
    );
  }

  // ── Event Filter Selector: [ الأبرز | كل الأحداث ] ─────────────────────────
  Widget _buildEventFilterSelector(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterPill(
            key: const ValueKey('filter_highlights'),
            label: isArabic ? 'الأبرز' : 'Highlights',
            isSelected: _eventFilter == _EventFilter.highlights,
            isDark: isDark,
            isArabic: isArabic,
            onTap: () => setState(() => _eventFilter = _EventFilter.highlights),
          ),
          const SizedBox(width: 4),
          _buildFilterPill(
            key: const ValueKey('filter_all'),
            label: isArabic ? 'كل الأحداث' : 'All Events',
            isSelected: _eventFilter == _EventFilter.all,
            isDark: isDark,
            isArabic: isArabic,
            onTap: () => setState(() => _eventFilter = _EventFilter.all),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required Key key,
    required String label,
    required bool isSelected,
    required bool isDark,
    required bool isArabic,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTypography.getBodySmall(
            isDark: isSelected ? true : isDark,
            isArabic: isArabic,
          ).copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  // ── Video Highlights Summary Chips ─────────────────────────────────────────
  Widget _buildVideoSummaryChips(
    List<MatchNewsItemEntity> news,
    bool isDark,
    bool isArabic,
  ) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: news.take(4).length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = news[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_library_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  item.title.isNotEmpty ? item.title : (isArabic ? 'ملخص المباراة' : 'Highlights'),
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Mini Statistics Preview Card (from screenshot 3) ───────────────────────
  Widget _buildMiniStatsPreviewCard(
    List<MatchStatItemEntity> stats,
    MatchEntity match,
    bool isDark,
    bool isArabic,
  ) {
    final previewStats = stats.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...previewStats.map((st) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Team 1 Home Value
                  SizedBox(
                    width: 36,
                    child: Text(
                      st.homeValue,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // Stat Title Center
                  Expanded(
                    child: Text(
                      st.title,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Team 2 Away Value
                  SizedBox(
                    width: 36,
                    child: Text(
                      st.awayValue,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 20),

          // "أظهر المزيد" (Show more) Button
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () {
              // Animate to Statistics tab (Index 3)
              _tabController.animateTo(3);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text(
                  isArabic ? 'أظهر المزيد' : 'Show More',
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: التفاصيل (Details / Match Info) ──────────────────────────────────
  Widget _buildDetailsTab(
    BuildContext context,
    MatchDetailsState state,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.details.isEmpty) {
      return const EmptyView(
        titleKey: 'tab_overview',
        icon: Icons.info_outline_rounded,
      );
    }

    return ListView(
      key: const PageStorageKey('details_tab_list'),
      padding: EdgeInsets.all(hMargin),
      children: [
        ...state.details.map((sec) => MatchInfoCard(section: sec)),
      ],
    );
  }

  // ── Tab 4: الإحصائيات (Full Statistics) ────────────────────────────────────
  Widget _buildStatsTab(
    BuildContext context,
    MatchDetailsState state,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.stats.isEmpty) {
      return const EmptyView(
        titleKey: 'tab_stats',
        icon: Icons.bar_chart_rounded,
      );
    }

    return ListView.builder(
      key: const PageStorageKey('stats_tab_list'),
      padding: EdgeInsets.all(hMargin),
      itemCount: state.stats.length,
      itemBuilder: (context, index) {
        return StatComparisonBar(stat: state.stats[index]);
      },
    );
  }

  // ── Tab 5: الترتيب (Standings) ─────────────────────────────────────────────
  Widget _buildStandingsTab(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    return Center(
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
              isArabic ? 'جدول الترتيب متاح في صفحة البطولة' : 'Standings available in League view',
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 6: الأخبار (News) ──────────────────────────────────────────────────
  Widget _buildNewsTab(
    BuildContext context,
    MatchDetailsState state,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.news.isEmpty) {
      return const EmptyView(
        titleKey: 'tab_news',
        icon: Icons.article_rounded,
      );
    }

    return ListView.separated(
      key: const PageStorageKey('news_tab_list'),
      padding: EdgeInsets.all(hMargin),
      itemCount: state.news.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) {
        final item = state.news[index];
        return Card(
          child: ListTile(
            leading: item.image != null && item.image!.isNotEmpty
                ? Image.network(
                    item.image!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.article_rounded),
                  )
                : const Icon(Icons.article_rounded),
            title: Text(
              item.title,
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: item.date != null
                ? Text(
                    item.date!,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
