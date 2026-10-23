import 'package:material_ui/material_ui.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/url_helper.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../matches/domain/entities/match_entity.dart';
import '../../../domain/entities/match_details_entity.dart';
import '../../bloc/match_details_state.dart';
import '../penalty_shootout_events_card.dart';
import '../timeline_event_item.dart';
import 'match_details_skeletons.dart';

enum _EventFilter { highlights, all }

class MatchEventsTab extends StatefulWidget {
  final MatchDetailsState state;
  final MatchEntity match;
  final MatchEntity? initialMatch;
  final bool isDark;
  final bool isArabic;
  final Future<void> Function() onRefresh;
  final VoidCallback onShowMoreStats;

  const MatchEventsTab({
    super.key,
    required this.state,
    required this.match,
    this.initialMatch,
    required this.isDark,
    required this.isArabic,
    required this.onRefresh,
    required this.onShowMoreStats,
  });

  @override
  State<MatchEventsTab> createState() => _MatchEventsTabState();
}

class _MatchEventsTabState extends State<MatchEventsTab> {
  _EventFilter _eventFilter = _EventFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final match = widget.match;
    final isDark = widget.isDark;
    final isArabic = widget.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      return MatchDetailsSkeletons.buildEventsSkeleton(
        context,
        isDark: isDark,
        isArabic: isArabic,
        filterSelector: _buildEventFilterSelector(isDark, isArabic),
      );
    }

    final hasShootout = (state.penaltiesDetail != null &&
            state.penaltiesDetail!.hasKicks) ||
        match.hasPenalties ||
        (state.livePenaltyScore1 != null && state.livePenaltyScore2 != null);

    // Resolve Match Alert / Special Notice (if present)
    String? alertText = state.alert ??
        state.overview?.note ??
        match.note ??
        widget.initialMatch?.note;

    if (alertText == null || alertText.trim().isEmpty) {
      for (final sec in state.details) {
        final lowerTitle = sec.section.toLowerCase();
        if (lowerTitle.contains('alert') ||
            lowerTitle.contains('notice') ||
            lowerTitle.contains('hint') ||
            lowerTitle.contains('تنبيه') ||
            lowerTitle.contains('ملاحظة') ||
            lowerTitle.contains('إلغاء') ||
            lowerTitle.contains('تأجيل')) {
          if (sec.items.isNotEmpty) {
            final c = sec.items.first.content.trim();
            if (c.isNotEmpty) {
              alertText = c;
              break;
            }
          }
        }
      }
    }

    if (alertText == null || alertText.trim().isEmpty) {
      for (final e in state.events) {
        final t = e.type.toLowerCase();
        if (t == 'alert' ||
            t == 'notice' ||
            t == 'note' ||
            t == 'info' ||
            t == 'warning') {
          if (e.playerName.trim().isNotEmpty) {
            alertText = e.playerName.trim();
            break;
          }
        }
      }
    }

    // Filter events based on selected filter
    final displayedEvents = state.events.where((e) {
      final t = e.type.toLowerCase();
      // Exclude alert/notice pseudo-events from timeline list
      if (t == 'alert' || t == 'notice' || t == 'note' || t == 'info') {
        return false;
      }

      if (_eventFilter == _EventFilter.all) {
        // If the dedicated Shootout Box is rendered at top, don't duplicate full time / penalty shootout markers in timeline
        if (hasShootout && e.isPeriodMarker) {
          final name = e.playerName.trim().toLowerCase();
          if (name.contains('ترجيح') ||
              name.contains('shootout') ||
              name.contains('نهاية المباراة') ||
              name.contains('نهاية اللقاء') ||
              name.contains('full time') ||
              name == 'ft') {
            return false;
          }
        }
        return true;
      }

      // Highlights: ONLY Goals, Red Cards, VAR decisions, and video events
      if (e.hasVideo) return true;
      if (e.isPeriodMarker) return false;

      // Exclude substitutions
      if (t.contains('sub')) return false;
      // Exclude regular yellow cards (unless red card)
      if (t.contains('yellow') && !t.contains('red')) return false;
      // Exclude whistle/period markers
      if (t.contains('start-end') ||
          t.contains('period') ||
          t.contains('whistle')) {
        return false;
      }

      return t.contains('goal') ||
          t.contains('red') ||
          t.contains('var') ||
          t.contains('disallow') ||
          t == 'goal-x';
    }).toList();

    // Fallback: If highlights filter yields empty but events exist and NO shootout card, show all events
    final eventsToRender =
        (displayedEvents.isEmpty && state.events.isNotEmpty && !hasShootout)
            ? state.events
            : displayedEvents;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const PageStorageKey('events_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // ── Match Alert / Special Notice Card ─────────────────────────────
          if (alertText != null && alertText.trim().isNotEmpty) ...[
            MatchDetailsSkeletons.buildAlertCard(alertText, isDark: isDark),
            const SizedBox(height: AppDimensions.md),
          ],

          // ── Video Highlights Summary Chips ───────────────────────────────
          if (state.videos.hasVideo && state.videos.allChips.isNotEmpty) ...[
            _buildVideoSummaryChips(state.videos, isDark, isArabic),
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

          // ── Penalty Shootout Box (Yalla Shoot style) ─────────────────────
          if (hasShootout) ...[
            PenaltyShootoutEventsCard(
              penaltiesDetail: state.penaltiesDetail,
              penaltyScore1: state.penaltiesDetail?.homeScore ??
                  state.livePenaltyScore1 ??
                  match.penaltyScore1 ??
                  '0',
              penaltyScore2: state.penaltiesDetail?.awayScore ??
                  state.livePenaltyScore2 ??
                  match.penaltyScore2 ??
                  '0',
              fallbackAttempts1: match.penaltyAttempts1,
              fallbackAttempts2: match.penaltyAttempts2,
              fullTimeScore:
                  '${state.liveScore1 ?? match.score1 ?? '0'} - ${state.liveScore2 ?? match.score2 ?? '0'}',
              isDark: isDark,
              isArabic: isArabic,
            ),
          ],

          // ── Events Timeline Container ────────────────────────────────────
          if (eventsToRender.isEmpty && !hasShootout)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyView(
                titleKey: 'no_events',
                icon: Icons.timeline_rounded,
              ),
            )
          else if (eventsToRender.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: eventsToRender
                    .map((e) => TimelineEventItem(event: e))
                    .toList(),
              ),
            ),

          const SizedBox(height: AppDimensions.lg),

          // ── Mini Statistics Preview Card ─────────────────────────────────
          if (state.stats.isNotEmpty) ...[
            Text(
              isArabic ? 'الإحصائيات' : 'Statistics',
              style: AppTypography.getHeadingMedium(
                isDark: isDark,
                isArabic: isArabic,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            _buildMiniStatsPreviewCard(state.stats, isDark, isArabic),
            const SizedBox(height: AppDimensions.lg),
          ],
        ],
      ),
    );
  }

  Widget _buildEventFilterSelector(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
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
          color: isSelected ? AppColors.primary : Colors.transparent,
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
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSummaryChips(
    MatchVideosEntity videos,
    bool isDark,
    bool isArabic,
  ) {
    if (!videos.hasVideo || videos.allChips.isEmpty) {
      return const SizedBox.shrink();
    }

    final videoItems = videos.allChips;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: videoItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final video = videoItems[index];
          final isGoal = video.type == 'goals' ||
              video.title.contains('هدف') ||
              video.title.toLowerCase().contains('goal');

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              onTap: () {
                UrlHelper.navigateToVideo(
                  context,
                  url: video.url,
                  fallbackErrorMessage:
                      isArabic ? 'تعذر تشغيل الفيديو' : 'Could not play video',
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGoal
                          ? Icons.sports_soccer_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      video.title.isNotEmpty
                          ? video.title
                          : (isArabic ? 'ملخص المباراة' : 'Highlights'),
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStatsPreviewCard(
    List<MatchStatItemEntity> stats,
    bool isDark,
    bool isArabic,
  ) {
    final previewStats = stats.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
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
                  Expanded(
                    child: Text(
                      st.title,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: widget.onShowMoreStats,
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
}
