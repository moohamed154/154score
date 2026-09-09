import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../standings/presentation/bloc/standings_bloc.dart';
import '../../../standings/presentation/widgets/standings_table.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../bloc/match_details_bloc.dart';
import '../bloc/match_details_event.dart';
import '../bloc/match_details_state.dart';
import '../../domain/entities/match_details_entity.dart';
import '../widgets/lineup/lineup_tab_view.dart';
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

  bool _isSharing = false;
  final GlobalKey _screenBoundaryKey = GlobalKey();

  Future<void> _shareMatch(MatchEntity match, AppLocalizations l10n) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final boundary =
          _screenBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Render boundary is not available');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to generate image data');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final cleanId = match.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      final file = File('${tempDir.path}/154score_match_$cleanId.png');
      await file.writeAsBytes(pngBytes);

      final shareText = l10n.isArabic
          ? '⚽ تابع مباراة ${match.team1} ضد ${match.team2} وتغطية المباريات والتشكيلات لحظة بلحظة عبر تطبيق 154Score!\n\n📲 حمّل التطبيق الآن واستمتع بتغطية المباريات المباشرة:\nhttps://154score.com'
          : '⚽ Follow ${match.team1} vs ${match.team2} live scores, events, and lineups with 154Score app!\n\n📲 Download the app now:\nhttps://154score.com';

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                file.path,
                mimeType: 'image/png',
                name: '154score_$cleanId.png',
              ),
            ],
            text: shareText,
          ),
        );
      } catch (shareErr) {
        debugPrint('[Share] Native share unavailable, copying to clipboard: $shareErr');
        await Clipboard.setData(ClipboardData(text: shareText));
      }
    } catch (e) {
      debugPrint('[Share] Error sharing match screenshot: $e');
      final shareText = l10n.isArabic
          ? '⚽ تابع مباراة ${match.team1} ضد ${match.team2} عبر تطبيق 154Score!\nhttps://154score.com'
          : '⚽ Follow ${match.team1} vs ${match.team2} on 154Score!\nhttps://154score.com';
      try {
        await Clipboard.setData(ClipboardData(text: shareText));
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _getEffectiveLeagueTitle(MatchEntity match, MatchDetailsState state) {
    if (match.leagueTitle != null && match.leagueTitle!.isNotEmpty) {
      return match.leagueTitle!;
    }
    for (final section in state.details) {
      for (final item in section.items) {
        if (item.title.contains('البطولة') ||
            item.title.toLowerCase().contains('competition') ||
            item.title.toLowerCase().contains('league')) {
          return item.content;
        }
      }
    }
    return '';
  }

  Future<void> _handleRefresh() async {
    final bloc = context.read<MatchDetailsBloc>();
    final completer = Completer<void>();
    late final StreamSubscription sub;
    Timer? timeoutTimer;
    void cleanup() {
      timeoutTimer?.cancel();
      sub.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    timeoutTimer = Timer(const Duration(seconds: 8), cleanup);
    sub = bloc.stream.listen((state) {
      if (state.status != MatchDetailsStatus.loading) {
        cleanup();
      }
    });
    bloc.add(LoadMatchDetailsEvent(widget.matchId, isRefresh: true));
    return completer.future;
  }

  Widget _buildAppBarLeagueBadge(
    BuildContext context,
    MatchEntity match,
    MatchDetailsState state,
    bool isDark,
    bool isArabic,
  ) {
    final effectiveTitle = _getEffectiveLeagueTitle(match, state);
    final displayTitle = effectiveTitle.isNotEmpty
        ? effectiveTitle
        : (isArabic ? 'مركز المباراة' : 'Match Center');

    final effectiveLogo = match.leagueLogo;

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      onTap: () {
        if (match.leagueId != null || effectiveTitle.isNotEmpty) {
          final lId = match.leagueId ?? '937599';
          context.push(
            '/league/$lId',
            extra: {'title': displayTitle, 'logo': effectiveLogo},
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (effectiveLogo != null && effectiveLogo.isNotEmpty) ...[
              AppImage(
                imageUrl: effectiveLogo,
                width: 20,
                height: 20,
                borderRadius: 4,
                fit: BoxFit.contain,
                placeholderIcon: Icons.emoji_events_outlined,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                displayTitle,
                style: AppTypography.getBodyLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
          buildWhen: (prev, curr) => prev.details != curr.details,
          builder: (context, state) {
            return _buildAppBarLeagueBadge(
              context,
              fallbackMatch,
              state,
              isDark,
              isArabic,
            );
          },
        ),
        actions: [
          _isSharing
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: isArabic ? 'مشاركة المباراة' : 'Share Match',
                  onPressed: () => _shareMatch(fallbackMatch, l10n),
                ),
        ],
      ),
      body: RepaintBoundary(
        key: _screenBoundaryKey,
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
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
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
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
                        Tab(text: isArabic ? 'التشكيلة' : 'Lineups'),
                        Tab(text: isArabic ? 'الإحصائيات' : 'Stats'),
                        Tab(text: isArabic ? 'الترتيب' : 'Standings'),
                        Tab(text: isArabic ? 'الأخبار' : 'News'),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ── Tab Content ────────────────────────────────────────────
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
                            onRetry: () => context
                                .read<MatchDetailsBloc>()
                                .add(LoadMatchDetailsEvent(widget.matchId)),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              // 1. الأحداث (Events with Video chips, Highlights/All filter, Timeline & Stats Preview)
                              _buildEventsTab(
                                context,
                                state,
                                fallbackMatch,
                                isDark,
                                isArabic,
                              ),

                              // 2. التفاصيل (Details / Match Info)
                              _buildDetailsTab(
                                context,
                                state,
                                isDark,
                                isArabic,
                              ),

                              // 3. التشكيلة (Lineup)
                              LineupTabView(matchId: widget.matchId),

                              // 4. الإحصائيات (Full Statistics)
                              _buildStatsTab(
                                context,
                                state,
                                isDark,
                                isArabic,
                              ),

                              // 5. الترتيب (Standings)
                              _buildStandingsTab(context, isDark, isArabic),

                              // 6. الأخبار (News)
                              _buildNewsTab(context, state, isDark, isArabic),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
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
      // Highlights: Goals, disallowed goals, penalties, red cards, yellow cards, subs, period markers, and video events
      if (e.hasVideo) return true;
      final t = e.type.toLowerCase();
      return t.contains('goal') ||
          t.contains('penalty') ||
          t.contains('card') ||
          t.contains('red') ||
          t.contains('yellow') ||
          t.contains('sub') ||
          t.contains('event') ||
          t.contains('start-end') ||
          t.contains('period') ||
          t.contains('whistle') ||
          t == 'goal-x';
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _handleRefresh,
      child: ListView(
        key: const PageStorageKey('events_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
        // ── Video Highlights Summary Chips ───────────────────────────────
        _buildVideoSummaryChips(state.news, isDark, isArabic),
        const SizedBox(height: AppDimensions.md),

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
              children: displayedEvents
                  .map((e) => TimelineEventItem(event: e))
                  .toList(),
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
    ),
  );
}

  // ── Event Filter Selector: [ الأبرز | كل الأحداث ] ─────────────────────────
  Widget _buildEventFilterSelector(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardElevated
            : AppColors.lightCardElevated,
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
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style:
              AppTypography.getBodySmall(
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

  // ── Video Highlights Summary Chips ─────────────────────────────────────────
  Widget _buildVideoSummaryChips(
    List<MatchNewsItemEntity> news,
    bool isDark,
    bool isArabic,
  ) {
    final items = news.isNotEmpty
        ? news.take(4).toList()
        : [
            MatchNewsItemEntity(
              title: isArabic ? 'ملخص المباراة' : 'Match Highlights',
              link: '/video/${widget.matchId}',
            ),
          ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              onTap: () {
                final link = item.link;
                if (link != null && link.isNotEmpty) {
                  final videoMatch = RegExp(r'/video/(\d+)').firstMatch(link);
                  if (videoMatch != null) {
                    context.push('/video/${videoMatch.group(1)}');
                  } else if (link.startsWith('http://') ||
                      link.startsWith('https://')) {
                    UrlHelper.launchVideoUrl(
                      link,
                      thumbnail: item.image,
                      context: context,
                    );
                  } else {
                    context.push('/video/${Uri.encodeComponent(link)}');
                  }
                } else {
                  context.push('/video/${Uri.encodeComponent(widget.matchId)}');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
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
                      item.title.isNotEmpty
                          ? item.title
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
        color: isDark
            ? AppColors.darkCardElevated
            : AppColors.lightCardElevated,
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
                      style:
                          AppTypography.getBodyMedium(
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
                  style:
                      AppTypography.getBodyMedium(
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
    final detailsList = List<MatchInfoSectionEntity>.from(state.details);

    if (widget.initialMatch != null) {
      final m = widget.initialMatch!;

      final fallbackItems = <MatchInfoItemEntity>[];
      if (m.leagueTitle != null && m.leagueTitle!.isNotEmpty) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'البطولة' : 'Competition',
            content: m.leagueTitle!,
          ),
        );
      }
      if (m.date != null && m.date!.isNotEmpty) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'تاريخ المباراة' : 'Match Date',
            content: m.date!,
          ),
        );
      }
      if (m.time != null &&
          m.time!.trim().isNotEmpty &&
          m.time!.trim() != '-' &&
          m.time != 'null') {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'وقت المباراة' : 'Match Time',
            content: m.time!,
          ),
        );
      }
      if (m.status != null &&
          m.status!.trim().isNotEmpty &&
          m.status != '-' &&
          m.status != 'null') {
        final statusContent = m.minute != null && m.minute!.isNotEmpty
            ? '${m.status!} (${m.minute}\')'
            : m.status!;
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'حالة المباراة' : 'Match Status',
            content: statusContent,
          ),
        );
      }
      fallbackItems.add(
        MatchInfoItemEntity(
          title: isArabic ? 'صاحب الأرض' : 'Home Team',
          content: m.team1,
        ),
      );
      fallbackItems.add(
        MatchInfoItemEntity(
          title: isArabic ? 'الضيف' : 'Away Team',
          content: m.team2,
        ),
      );
      if (m.score1 != null && m.score2 != null && m.score1!.isNotEmpty) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'النتيجة الحالية' : 'Current Score',
            content: '${m.score1} : ${m.score2}',
          ),
        );
      }
      if (m.hasHalfTimeScore) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'نتيجة الشوط الأول' : 'Half-time Score',
            content: '${m.halfTimeScore1} : ${m.halfTimeScore2}',
          ),
        );
      }

      final existingInfoIndex = detailsList.indexWhere(
        (s) =>
            s.section.contains('معلومات') ||
            s.section.toLowerCase().contains('info'),
      );

      if (existingInfoIndex >= 0) {
        final existingSection = detailsList[existingInfoIndex];
        final mergedItems = List<MatchInfoItemEntity>.from(
          existingSection.items,
        );
        for (final item in fallbackItems) {
          if (!mergedItems.any((it) => it.title == item.title)) {
            mergedItems.add(item);
          }
        }
        detailsList[existingInfoIndex] = MatchInfoSectionEntity(
          section: existingSection.section,
          items: mergedItems,
        );
      } else {
        detailsList.insert(
          0,
          MatchInfoSectionEntity(
            section: isArabic ? 'معلومات اللقاء' : 'Match Information',
            items: fallbackItems,
          ),
        );
      }
    }

    if (detailsList.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyView(
              titleKey: 'tab_overview',
              icon: Icons.info_outline_rounded,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _handleRefresh,
      child: ListView(
        key: const PageStorageKey('details_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [...detailsList.map((sec) => MatchInfoCard(section: sec))],
      ),
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
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyView(
              titleKey: 'tab_stats',
              icon: Icons.bar_chart_rounded,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _handleRefresh,
      child: ListView.builder(
        key: const PageStorageKey('stats_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        itemCount: state.stats.length,
        itemBuilder: (context, index) {
          return StatComparisonBar(stat: state.stats[index]);
        },
      ),
    );
  }

  String? _resolveLeagueId() {
    final rawId = widget.initialMatch?.leagueId;
    if (rawId != null && rawId.isNotEmpty && rawId != 'null') {
      return rawId;
    }
    final title = widget.initialMatch?.leagueTitle?.toLowerCase() ?? '';
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

  // ── Tab 5: الترتيب (Standings) ─────────────────────────────────────────────
  Widget _buildStandingsTab(BuildContext context, bool isDark, bool isArabic) {
    final leagueId = _resolveLeagueId();

    if (leagueId == null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                context.read<StandingsBloc>().add(LoadStandingsEvent(leagueId));
                await _handleRefresh();
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

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<StandingsBloc>().add(LoadStandingsEvent(leagueId));
              await _handleRefresh();
            },
            child: ListView(
              key: const PageStorageKey('match_standings_tab_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      StandingsTable(
                        rows: groupEntry.value,
                        highlightedTeamNames: [
                          if (widget.initialMatch?.team1 != null)
                            widget.initialMatch!.team1,
                          if (widget.initialMatch?.team2 != null)
                            widget.initialMatch!.team2,
                        ],
                      ),
                    ],
                  );
                }),
              ] else ...[
                StandingsTable(
                  rows: standings.rows,
                  highlightedTeamNames: [
                    if (widget.initialMatch?.team1 != null)
                      widget.initialMatch!.team1,
                    if (widget.initialMatch?.team2 != null)
                      widget.initialMatch!.team2,
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
                            style:
                                AppTypography.getBodySmall(
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

  // ── Tab 6: الأخبار (News) ──────────────────────────────────────────────────
  Widget _buildNewsTab(
    BuildContext context,
    MatchDetailsState state,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.news.isEmpty) {
      return const EmptyView(titleKey: 'tab_news', icon: Icons.article_rounded);
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
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.article_rounded),
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
