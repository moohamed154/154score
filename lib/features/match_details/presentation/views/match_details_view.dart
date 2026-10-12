import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/utils/text_direction_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../standings/presentation/bloc/standings_bloc.dart';
import '../../../standings/presentation/widgets/standings_table.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../bloc/match_details_bloc.dart';
import '../bloc/match_details_event.dart';
import '../bloc/match_details_state.dart';
import '../../domain/entities/match_details_entity.dart';
import '../widgets/lineup/lineup_tab_view.dart';
import '../widgets/match_header_banner.dart';
import '../widgets/match_form_card.dart';
import '../widgets/match_h2h_card.dart';
import '../widgets/match_info_card.dart';
import '../widgets/match_quick_stats_card.dart';
import '../widgets/match_return_leg_card.dart';
import '../widgets/stat_comparison_bar.dart';
import '../widgets/timeline_event_item.dart';
import '../widgets/penalty_shootout_events_card.dart';

import '../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../leagues/presentation/bloc/league_event.dart';
import '../../../leagues/presentation/bloc/league_state.dart';
import '../../../leagues/presentation/widgets/top_scorers_table.dart';
import '../../../live_activity/presentation/cubit/live_activity_cubit.dart';
import '../../../live_activity/presentation/widgets/live_activity_toggle_button.dart';

// Filter for Events tab: الأبرز (Highlights) vs كل الأحداث (All Events)
enum _EventFilter { highlights, all }

// Dynamic tabs available in Match Details screen
enum _MatchTabType {
  events,
  details,
  lineups,
  stats,
  standings,
  scorers,
  assists,
  news,
}

class MatchDetailsView extends StatefulWidget {
  final String matchId;
  final MatchEntity? initialMatch;

  const MatchDetailsView({super.key, required this.matchId, this.initialMatch});

  @override
  State<MatchDetailsView> createState() => _MatchDetailsViewState();
}

class _MatchDetailsViewState extends State<MatchDetailsView> {
  // Dynamic tabs: Events & Stats only when started or ended, plus League Scorers & Assists
  List<_MatchTabType> _currentTabs = const [];
  LeagueBloc? _leagueBloc;
  String? _currentLeagueId;

  bool _computeIsCancelledOrPostponed({
    MatchEntity? match,
    MatchDetailsState? state,
  }) {
    final effectiveMatch = match ?? widget.initialMatch;
    if (effectiveMatch != null) {
      if (ScoreHelper.isCancelledOrPostponed(
            effectiveMatch.status,
            effectiveMatch.statusCode,
          )) {
        return true;
      }
      final phase = MatchStatusHelper.parseMatch(effectiveMatch);
      if (MatchStatusHelper.isPostponedOrCancelled(phase)) {
        return true;
      }
    }
    if (widget.initialMatch != null) {
      if (ScoreHelper.isCancelledOrPostponed(
            widget.initialMatch!.status,
            widget.initialMatch!.statusCode,
          )) {
        return true;
      }
      final phase = MatchStatusHelper.parseMatch(widget.initialMatch!);
      if (MatchStatusHelper.isPostponedOrCancelled(phase)) {
        return true;
      }
    }
    if (state != null) {
      if (ScoreHelper.isCancelledOrPostponed(
            state.liveStatus,
            state.liveStatusCode,
          )) {
        return true;
      }
      if (ScoreHelper.isCancelledOrPostponed(state.overview?.status)) {
        return true;
      }
    }
    return false;
  }

  List<_MatchTabType> _getTabsForStatus({required bool isCancelledOrPostponed}) {
    if (isCancelledOrPostponed) {
      return const [
        _MatchTabType.details,
        _MatchTabType.lineups,
        _MatchTabType.standings,
        _MatchTabType.scorers,
        _MatchTabType.assists,
        _MatchTabType.news,
      ];
    } else {
      return const [
        _MatchTabType.events,
        _MatchTabType.details,
        _MatchTabType.lineups,
        _MatchTabType.stats,
        _MatchTabType.standings,
        _MatchTabType.scorers,
        _MatchTabType.assists,
        _MatchTabType.news,
      ];
    }
  }

  void _ensureLeagueBloc(String? leagueId, String? title, String? logo) {
    if (leagueId == null || leagueId.isEmpty) return;
    if (_leagueBloc == null || _currentLeagueId != leagueId) {
      _leagueBloc?.close();
      _currentLeagueId = leagueId;
      _leagueBloc = sl<LeagueBloc>(
        param1: leagueId,
        param2: {'title': title, 'logo': logo},
      )..add(LoadLeagueDetailsEvent(leagueId));
    }
  }

  // Events tab inner filter (defaults to All Events)
  _EventFilter _eventFilter = _EventFilter.all;

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
        debugPrint(
          '[Share] Native share unavailable, copying to clipboard: $shareErr',
        );
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

  bool _isMatchNotificationActive(MatchEntity match, [FavoritesState? favState]) {
    if (match.id.isEmpty) return false;
    try {
      final storage = sl<LocalStorageService>();
      if (storage.isMatchNotificationEnabled(match.id)) {
        return true;
      }
      if (favState != null && favState.isFavoriteMatch(match.id)) {
        return true;
      }

      final homeId = match.team1Id;
      final homeName = match.team1;
      if (_isTeamNotificationActive(storage, homeId, homeName, favState)) {
        return true;
      }

      final awayId = match.team2Id;
      final awayName = match.team2;
      if (_isTeamNotificationActive(storage, awayId, awayName, favState)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool _isTeamNotificationActive(
    LocalStorageService storage,
    String? id,
    String? name,
    FavoritesState? favState,
  ) {
    final key = (id != null && id.trim().isNotEmpty) ? id.trim() : (name?.trim() ?? '');
    if (key.isEmpty) return false;
    if (storage.isTeamNotificationMuted(key)) return false;
    if (storage.isTeamNotificationEnabled(key)) return true;
    final isFav = favState != null
        ? favState.isFavoriteTeam(id: id, name: name)
        : storage.isFavoriteTeam(name ?? '', id: id);
    return isFav;
  }

  Future<void> _toggleMatchNotification(MatchEntity match, AppLocalizations l10n) async {
    final matchId = match.id;
    if (matchId.isEmpty) return;

    final storage = sl<LocalStorageService>();
    final isCurrentlyActive = _isMatchNotificationActive(match);

    try {
      final nextStatus = !isCurrentlyActive;
      if (nextStatus) {
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_off_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.isArabic
                          ? 'يرجى تفعيل إذن الإشعارات من إعدادات الهاتف لتلقي التنبيهات'
                          : 'Please enable notifications in device settings to receive alerts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      await storage.setMatchNotificationEnabled(matchId, nextStatus);

      if (mounted) {
        try {
          context.read<MatchesBloc>().add(const RefreshFavoritesEvent());
        } catch (_) {}
        try {
          context.read<FavoritesCubit>().loadFavorites();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  nextStatus ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: nextStatus ? AppColors.primary : const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextStatus
                        ? (l10n.isArabic
                            ? 'تم تفعيل إشعارات المباراة'
                            : 'Match notifications enabled')
                        : (l10n.isArabic
                            ? 'تم إيقاف إشعارات المباراة'
                            : 'Match notifications disabled'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: nextStatus
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : const Color(0xFF334155),
                width: 1,
              ),
            ),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MatchDetailsView] _toggleMatchNotification error: $e');
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

  MatchEntity _resolveActiveMatch({
    required MatchEntity fallbackMatch,
    MatchEntity? liveFromMatches,
    required MatchDetailsState state,
  }) {
    // 1. Resolve Team 1 (Home)
    String effectiveTeam1 = fallbackMatch.team1;
    if (effectiveTeam1 == 'Home Team' ||
        effectiveTeam1.isEmpty ||
        effectiveTeam1 == 'الفريق الأول') {
      final fromOverview = state.overview?.homeTeamName?.trim();
      final fromLineup = state.lineup?.home?.displayName.trim();
      final fromSections = _extractTeamNameFromDetails(
        state.details,
        isHome: true,
      );
      if (fromOverview != null && fromOverview.isNotEmpty) {
        effectiveTeam1 = fromOverview;
      } else if (fromLineup != null && fromLineup.isNotEmpty) {
        effectiveTeam1 = fromLineup;
      } else if (fromSections != null && fromSections.isNotEmpty) {
        effectiveTeam1 = fromSections;
      }
    }

    // 2. Resolve Team 2 (Away)
    String effectiveTeam2 = fallbackMatch.team2;
    if (effectiveTeam2 == 'Away Team' ||
        effectiveTeam2.isEmpty ||
        effectiveTeam2 == 'الفريق الثاني') {
      final fromOverview = state.overview?.awayTeamName?.trim();
      final fromLineup = state.lineup?.away?.displayName.trim();
      final fromSections = _extractTeamNameFromDetails(
        state.details,
        isHome: false,
      );
      if (fromOverview != null && fromOverview.isNotEmpty) {
        effectiveTeam2 = fromOverview;
      } else if (fromLineup != null && fromLineup.isNotEmpty) {
        effectiveTeam2 = fromLineup;
      } else if (fromSections != null && fromSections.isNotEmpty) {
        effectiveTeam2 = fromSections;
      }
    }

    // 3. Resolve Team IDs
    final effectiveTeam1Id =
        fallbackMatch.team1Id ??
        state.overview?.homeTeamId ??
        state.lineup?.home?.teamId;
    final effectiveTeam2Id =
        fallbackMatch.team2Id ??
        state.overview?.awayTeamId ??
        state.lineup?.away?.teamId;

    // 4. Resolve Logos
    final effectiveLogo1 =
        fallbackMatch.team1Logo ??
        state.overview?.homeTeamLogo ??
        state.lineup?.home?.teamLogo ??
        (effectiveTeam1Id != null
            ? UrlHelper.resolveTeamLogo(effectiveTeam1Id)
            : null);

    final effectiveLogo2 =
        fallbackMatch.team2Logo ??
        state.overview?.awayTeamLogo ??
        state.lineup?.away?.teamLogo ??
        (effectiveTeam2Id != null
            ? UrlHelper.resolveTeamLogo(effectiveTeam2Id)
            : null);

    // 5. Resolve Scores
    String? effectiveScore1 =
        state.liveScore1 ??
        liveFromMatches?.score1 ??
        fallbackMatch.score1 ??
        state.overview?.score1;
    String? effectiveScore2 =
        state.liveScore2 ??
        liveFromMatches?.score2 ??
        fallbackMatch.score2 ??
        state.overview?.score2;

    if ((effectiveScore1 == null || effectiveScore2 == null) &&
        state.events.isNotEmpty) {
      int hGoals = 0;
      int aGoals = 0;
      bool hasGoals = false;
      for (final e in state.events) {
        final t = e.type.toLowerCase();
        if ((t == 'goal' || t.contains('goal')) &&
            !t.contains('disallow') &&
            !t.contains('miss')) {
          hasGoals = true;
          if (e.isHomeTeam) {
            hGoals++;
          } else {
            aGoals++;
          }
        }
      }
      if (hasGoals) {
        effectiveScore1 ??= hGoals.toString();
        effectiveScore2 ??= aGoals.toString();
      }
    }

    // 6. Resolve League Info
    final effectiveLeagueTitle =
        (fallbackMatch.leagueTitle != null &&
            fallbackMatch.leagueTitle!.isNotEmpty)
        ? fallbackMatch.leagueTitle
        : (state.overview?.championshipTitle ??
              _getEffectiveLeagueTitle(fallbackMatch, state));

    final effectiveLeagueId =
        state.championshipId ??
        state.overview?.championshipId ??
        fallbackMatch.leagueId ??
        LeagueResolver.resolveId(effectiveLeagueTitle ?? '');

    final effectiveLeagueLogo =
        fallbackMatch.leagueLogo ??
        state.overview?.championshipLogo ??
        UrlHelper.resolveChampionshipLogo(effectiveLeagueId);

    // 7. Status & Time & Date
    final bool isLiveFromFeed =
        (liveFromMatches != null &&
            (ScoreHelper.isLiveStatus(liveFromMatches.status) ||
                MatchStatusHelper.isLive(
                  MatchStatusHelper.parseMatch(liveFromMatches),
                ))) ||
        (widget.initialMatch != null &&
            (ScoreHelper.isLiveStatus(widget.initialMatch!.status) ||
                MatchStatusHelper.isLive(
                  MatchStatusHelper.parseMatch(widget.initialMatch!),
                )));

    String? effectiveStatus;
    String? effectiveStatusCode;

    final bool isCancelledOrPostponed =
        ScoreHelper.isCancelledOrPostponed(
          liveFromMatches?.status,
          liveFromMatches?.statusCode,
        ) ||
        ScoreHelper.isCancelledOrPostponed(
          fallbackMatch.status,
          fallbackMatch.statusCode,
        ) ||
        ScoreHelper.isCancelledOrPostponed(
          widget.initialMatch?.status,
          widget.initialMatch?.statusCode,
        ) ||
        ScoreHelper.isCancelledOrPostponed(state.overview?.status) ||
        ScoreHelper.isCancelledOrPostponed(
          state.liveStatus,
          state.liveStatusCode,
        );

    if (isCancelledOrPostponed) {
      effectiveStatus =
          (ScoreHelper.isCancelledOrPostponed(
                liveFromMatches?.status,
                liveFromMatches?.statusCode,
              )
              ? liveFromMatches?.status
              : null) ??
          (ScoreHelper.isCancelledOrPostponed(
                fallbackMatch.status,
                fallbackMatch.statusCode,
              )
              ? fallbackMatch.status
              : null) ??
          (ScoreHelper.isCancelledOrPostponed(
                widget.initialMatch?.status,
                widget.initialMatch?.statusCode,
              )
              ? widget.initialMatch?.status
              : null) ??
          (ScoreHelper.isCancelledOrPostponed(state.overview?.status)
              ? state.overview?.status
              : null) ??
          state.liveStatus;

      effectiveStatusCode =
          (ScoreHelper.isCancelledOrPostponed(
                liveFromMatches?.status,
                liveFromMatches?.statusCode,
              )
              ? liveFromMatches?.statusCode
              : null) ??
          (ScoreHelper.isCancelledOrPostponed(
                fallbackMatch.status,
                fallbackMatch.statusCode,
              )
              ? fallbackMatch.statusCode
              : null) ??
          (ScoreHelper.isCancelledOrPostponed(
                widget.initialMatch?.status,
                widget.initialMatch?.statusCode,
              )
              ? widget.initialMatch?.statusCode
              : null) ??
          state.liveStatusCode;
    } else if (isLiveFromFeed) {
      // Prioritize live values if the match is actively in-play
      effectiveStatus =
          (ScoreHelper.isLiveStatus(state.liveStatus)
              ? state.liveStatus
              : null) ??
          liveFromMatches?.status ??
          widget.initialMatch?.status ??
          state.overview?.status ??
          state.liveStatus;

      effectiveStatusCode =
          (state.liveStatusCode == 'LIVE' ||
                  state.liveStatusCode?.startsWith('IN_PLAY') == true
              ? state.liveStatusCode
              : null) ??
          liveFromMatches?.statusCode ??
          widget.initialMatch?.statusCode ??
          state.liveStatusCode;
    } else {
      effectiveStatus =
          state.liveStatus ??
          liveFromMatches?.status ??
          fallbackMatch.status ??
          state.overview?.status;

      effectiveStatusCode =
          state.liveStatusCode ??
          liveFromMatches?.statusCode ??
          fallbackMatch.statusCode;
    }

    final effectiveTime = fallbackMatch.time ?? state.overview?.time;
    final effectiveDate = fallbackMatch.date ?? state.overview?.date;
    final effectiveMinute =
        state.liveMinute ?? liveFromMatches?.minute ?? fallbackMatch.minute;
    final effectiveExtraTime =
        state.liveExtraTime ??
        liveFromMatches?.extraTime ??
        fallbackMatch.extraTime;
    final effectivePeriod =
        state.livePeriod ?? liveFromMatches?.period ?? fallbackMatch.period;

    // Guard: Check if timeline events or past match date indicate match has completed
    final hasFinishedEvent = state.events.any((e) {
      if (!e.isPeriodMarker) return false;
      final name = e.playerName.trim().toLowerCase();
      // Exclude first half, half time, or start markers
      if (name.contains('الأول') ||
          name.contains('اول') ||
          name.contains('1st') ||
          name.contains('half time') ||
          name.contains('halftime') ||
          name.contains('ht') ||
          name.contains('استراحة') ||
          name.contains('بداية')) {
        return false;
      }
      return name == 'نهاية المباراة' ||
          name == 'نهاية اللقاء' ||
          name.contains('نهاية المباراة') ||
          name.contains('نهاية اللقاء') ||
          name.contains('نهاية الوقت الأصلي واللقاء') ||
          name.contains('نهاية الشوط الإضافي الثاني') ||
          name == 'full time' ||
          name == 'ft' ||
          name.contains('full time') ||
          name.contains('full-time') ||
          name == 'match finished' ||
          name.contains('match finished');
    });

    final isPastMatch =
        effectiveDate != null &&
        DateTime.tryParse(effectiveDate)?.isBefore(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            ) ==
            true;

    if (!isLiveFromFeed &&
        !isCancelledOrPostponed &&
        !ScoreHelper.isLiveStatus(effectiveStatus)) {
      if (hasFinishedEvent ||
          (isPastMatch &&
              (effectiveScore1 != null || state.events.isNotEmpty))) {
        if (effectiveStatus == null ||
            effectiveStatus.isEmpty ||
            !ScoreHelper.isFinishedStatus(effectiveStatus)) {
          effectiveStatus = 'انتهت';
          effectiveStatusCode = 'FINISHED';
        }
      }
    }

    return fallbackMatch.copyWith(
      team1: effectiveTeam1,
      team2: effectiveTeam2,
      team1Logo: effectiveLogo1,
      team2Logo: effectiveLogo2,
      team1Id: effectiveTeam1Id,
      team2Id: effectiveTeam2Id,
      score1: effectiveScore1,
      score2: effectiveScore2,
      penaltyScore1:
          state.livePenaltyScore1 ??
          liveFromMatches?.penaltyScore1 ??
          fallbackMatch.penaltyScore1,
      penaltyScore2:
          state.livePenaltyScore2 ??
          liveFromMatches?.penaltyScore2 ??
          fallbackMatch.penaltyScore2,
      status: effectiveStatus,
      statusCode: effectiveStatusCode,
      time: effectiveTime,
      date: effectiveDate,
      minute: effectiveMinute,
      extraTime: effectiveExtraTime,
      period: effectivePeriod,
      leagueTitle: effectiveLeagueTitle,
      leagueId: effectiveLeagueId,
      leagueLogo: effectiveLeagueLogo,
    );
  }

  Future<void> _handleRefresh() async {
    final completer = Completer<void>();
    context.read<MatchDetailsBloc>().add(
      LoadMatchDetailsEvent(
        widget.matchId,
        isRefresh: true,
        completer: completer,
      ),
    );
    if (_leagueBloc != null && _currentLeagueId != null) {
      _leagueBloc!.add(
        LoadLeagueDetailsEvent(_currentLeagueId!, isRefresh: true),
      );
    }
    try {
      await completer.future.timeout(const Duration(seconds: 3));
    } catch (_) {}
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

    final effectiveLeagueId =
        state.championshipId ??
        match.leagueId ??
        LeagueResolver.resolveId(effectiveTitle);

    final effectiveLogo =
        match.leagueLogo ??
        UrlHelper.resolveChampionshipLogo(effectiveLeagueId);

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      onTap: () {
        final lId = effectiveLeagueId ?? LeagueResolver.resolveId(displayTitle);
        if (lId != null && lId.isNotEmpty) {
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
                style:
                    AppTypography.getBodyLarge(
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
    final initialIsCancelledOrPostponed = _computeIsCancelledOrPostponed(
      match: widget.initialMatch,
      state: null,
    );
    _currentTabs = _getTabsForStatus(
      isCancelledOrPostponed: initialIsCancelledOrPostponed,
    );
    context.read<MatchDetailsBloc>().add(
          LoadMatchDetailsEvent(
            widget.matchId,
            initialStatus: widget.initialMatch?.status,
            initialStatusCode: widget.initialMatch?.statusCode,
          ),
        );
  }

  @override
  void dispose() {
    _leagueBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    MatchEntity? liveFromMatches;
    try {
      final matchesBloc = context.watch<MatchesBloc>();
      final cleanId = widget.matchId.replaceAll('match:', '').trim();
      for (final league in matchesBloc.state.allLeagues) {
        for (final m in league.matches) {
          final mCleanId = m.id.replaceAll('match:', '').trim();
          final teamsMatch =
              (widget.initialMatch != null &&
              m.team1.toLowerCase().trim() ==
                  widget.initialMatch!.team1.toLowerCase().trim() &&
              m.team2.toLowerCase().trim() ==
                  widget.initialMatch!.team2.toLowerCase().trim());
          if (mCleanId == cleanId || teamsMatch) {
            liveFromMatches = m;
            break;
          }
        }
        if (liveFromMatches != null) break;
      }
    } catch (_) {}

    final fallbackMatch =
        liveFromMatches ??
        widget.initialMatch ??
        MatchEntity(id: widget.matchId, team1: 'Home Team', team2: 'Away Team');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
          builder: (context, state) {
            final activeMatch = _resolveActiveMatch(
              fallbackMatch: fallbackMatch,
              liveFromMatches: liveFromMatches,
              state: state,
            );
            return _buildAppBarLeagueBadge(
              context,
              activeMatch,
              state,
              isDark,
              isArabic,
            );
          },
        ),
        actions: [
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              return BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
                builder: (context, state) {
                  final activeMatch = _resolveActiveMatch(
                    fallbackMatch: fallbackMatch,
                    liveFromMatches: liveFromMatches,
                    state: state,
                  );
                  final isNotifActive = _isMatchNotificationActive(activeMatch, favState);
                  return IconButton(
                    icon: Icon(
                      isNotifActive
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: isNotifActive ? AppColors.primary : null,
                      size: 24,
                    ),
                    tooltip: isArabic
                        ? (isNotifActive
                            ? 'إيقاف إشعارات المباراة'
                            : 'تفعيل إشعارات المباراة')
                        : (isNotifActive
                            ? 'Mute match notifications'
                            : 'Enable match notifications'),
                    onPressed: () => _toggleMatchNotification(activeMatch, l10n),
                  );
                },
              );
            },
          ),
          BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
            builder: (context, state) {
              final activeMatch = _resolveActiveMatch(
                fallbackMatch: fallbackMatch,
                liveFromMatches: liveFromMatches,
                state: state,
              );
              return LiveActivityToggleButton(
                match: activeMatch,
                liveScore1: activeMatch.score1,
                liveScore2: activeMatch.score2,
                liveMinute: activeMatch.minute ??
                    state.liveMinute ??
                    liveFromMatches?.minute,
                liveStatus: activeMatch.status,
                liveStatusCode: activeMatch.statusCode,
                livePeriod: activeMatch.period ??
                    state.livePeriod ??
                    liveFromMatches?.period,
                compact: true,
              );
            },
          ),
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
              : BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
                  builder: (context, state) {
                    final activeMatch = _resolveActiveMatch(
                      fallbackMatch: fallbackMatch,
                      liveFromMatches: liveFromMatches,
                      state: state,
                    );
                    return IconButton(
                      icon: const Icon(Icons.share_rounded),
                      tooltip: isArabic ? 'مشاركة المباراة' : 'Share Match',
                      onPressed: () => _shareMatch(activeMatch, l10n),
                    );
                  },
                ),
          const SizedBox(width: 4),
        ],
      ),
      body: RepaintBoundary(
        key: _screenBoundaryKey,
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: BlocConsumer<MatchDetailsBloc, MatchDetailsState>(
            listener: (context, state) {
              final activeMatch = _resolveActiveMatch(
                fallbackMatch: fallbackMatch,
                liveFromMatches: liveFromMatches,
                state: state,
              );
              context.read<LiveActivityCubit>().updateTracking(
                match: activeMatch,
                liveScore1: activeMatch.score1,
                liveScore2: activeMatch.score2,
                liveMinute: activeMatch.minute ?? state.liveMinute,
                liveStatus: activeMatch.status,
                liveStatusCode: activeMatch.statusCode,
                livePeriod: activeMatch.period ?? state.livePeriod,
                penaltyScore1: activeMatch.penaltyScore1,
                penaltyScore2: activeMatch.penaltyScore2,
              );
            },
            builder: (context, state) {
              final activeMatch = _resolveActiveMatch(
                fallbackMatch: fallbackMatch,
                liveFromMatches: liveFromMatches,
                state: state,
              );

              final isCancelledOrPostponed = _computeIsCancelledOrPostponed(
                match: activeMatch,
                state: state,
              );
              final activeTabs = _getTabsForStatus(
                isCancelledOrPostponed: isCancelledOrPostponed,
              );
              _currentTabs = activeTabs;

              final effectiveLeagueId =
                  state.championshipId ??
                  state.overview?.championshipId ??
                  activeMatch.leagueId ??
                  LeagueResolver.resolveId(activeMatch.leagueTitle ?? '') ??
                  _resolveLeagueId(activeMatch);

              _ensureLeagueBloc(
                effectiveLeagueId,
                activeMatch.leagueTitle,
                activeMatch.leagueLogo,
              );

              return DefaultTabController(
                key: ValueKey(activeTabs.length),
                length: activeTabs.length,
                child: Builder(
                  builder: (tabContext) {
                    return Column(
                      children: [
                        // ── Top Score Hero Banner ──────────────────────────────────
                        Skeletonizer(
                          enabled:
                              widget.initialMatch == null &&
                              (state.status == MatchDetailsStatus.loading ||
                                  state.status == MatchDetailsStatus.initial),
                          effect: ShimmerEffect(
                            baseColor: isDark
                                ? const Color(0xFF1E2836)
                                : const Color(0xFFE2E8F0),
                            highlightColor: isDark
                                ? const Color(0xFF2E3D52)
                                : const Color(0xFFF1F5F9),
                            duration: const Duration(milliseconds: 1500),
                          ),
                          child: MatchHeaderBanner(
                            match: activeMatch,
                            liveScore1: activeMatch.score1,
                            liveScore2: activeMatch.score2,
                            liveStatus: activeMatch.status,
                            liveStatusCode: activeMatch.statusCode,
                            liveMinute:
                                activeMatch.minute ??
                                state.liveMinute ??
                                liveFromMatches?.minute,
                            liveExtraTime:
                                activeMatch.extraTime ??
                                state.liveExtraTime ??
                                liveFromMatches?.extraTime,
                            livePeriod:
                                activeMatch.period ??
                                state.livePeriod ??
                                liveFromMatches?.period,
                            penaltyScore1: activeMatch.penaltyScore1,
                            penaltyScore2: activeMatch.penaltyScore2,
                          ),
                        ),

                        // ── Lock Screen Live Activity Button ───────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Center(
                            child: LiveActivityToggleButton(
                              match: activeMatch,
                              liveScore1: activeMatch.score1,
                              liveScore2: activeMatch.score2,
                              liveMinute: activeMatch.minute ??
                                  state.liveMinute ??
                                  liveFromMatches?.minute,
                              liveStatus: activeMatch.status,
                              liveStatusCode: activeMatch.statusCode,
                              livePeriod: activeMatch.period ??
                                  state.livePeriod ??
                                  liveFromMatches?.period,
                              compact: false,
                            ),
                          ),
                        ),

                        // ── Main Horizontal Scrollable Tab Bar ─────────────────────
                        Container(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          child: TabBar(
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
                            tabs: activeTabs.map((tab) {
                              switch (tab) {
                                case _MatchTabType.events:
                                  return Tab(text: isArabic ? 'الأحداث' : 'Events');
                                case _MatchTabType.details:
                                  return Tab(text: isArabic ? 'التفاصيل' : 'Details');
                                case _MatchTabType.lineups:
                                  return Tab(text: isArabic ? 'التشكيلة' : 'Lineups');
                                case _MatchTabType.stats:
                                  return Tab(text: isArabic ? 'الإحصائيات' : 'Stats');
                                case _MatchTabType.standings:
                                  return Tab(text: isArabic ? 'الترتيب' : 'Standings');
                                case _MatchTabType.scorers:
                                  return Tab(text: isArabic ? 'الهدافون' : 'Scorers');
                                case _MatchTabType.assists:
                                  return Tab(text: isArabic ? 'الصناع' : 'Assists');
                                case _MatchTabType.news:
                                  return Tab(text: isArabic ? 'الأخبار' : 'News');
                              }
                            }).toList(),
                          ),
                        ),

                        const Divider(height: 1),

                        // ── Tab Content ────────────────────────────────────────────
                        Expanded(
                          child:
                              (state.status == MatchDetailsStatus.error &&
                                  state.details.isEmpty &&
                                  state.events.isEmpty)
                              ? ErrorView(
                                  message: state.errorMessage,
                                  onRetry: () => context.read<MatchDetailsBloc>().add(
                                    LoadMatchDetailsEvent(
                                      widget.matchId,
                                      initialStatus: widget.initialMatch?.status,
                                      initialStatusCode:
                                          widget.initialMatch?.statusCode,
                                    ),
                                  ),
                                )
                              : TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                            children: activeTabs.map((tab) {
                              switch (tab) {
                                case _MatchTabType.events:
                                  return _buildEventsTab(
                                    context,
                                    state,
                                    activeMatch,
                                    isDark,
                                    isArabic,
                                  );
                                case _MatchTabType.details:
                                  return _buildDetailsTab(
                                    context,
                                    state,
                                    activeMatch,
                                    isDark,
                                    isArabic,
                                  );
                                case _MatchTabType.lineups:
                                  return LineupTabView(matchId: widget.matchId);
                                case _MatchTabType.stats:
                                  return _buildStatsTab(
                                    context,
                                    state,
                                    activeMatch,
                                    isDark,
                                    isArabic,
                                  );
                                case _MatchTabType.standings:
                                  return _buildStandingsTab(
                                    context,
                                    state,
                                    activeMatch,
                                    isDark,
                                    isArabic,
                                  );
                                case _MatchTabType.scorers:
                                  return _buildScorersTab(
                                    context,
                                    effectiveLeagueId,
                                    isDark,
                                    isArabic,
                                  );
                                case _MatchTabType.assists:
                                  return _buildAssistsTab(
                                    context,
                                    effectiveLeagueId,
                                    isDark,
                                    isArabic,
                                  );
                                case _MatchTabType.news:
                                  return _buildNewsTab(
                                    context,
                                    state,
                                    isDark,
                                    isArabic,
                                  );
                              }
                            }).toList(),
                          ),
                  ),
                        ],
                      );
                    },
                  ),
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

    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      return _buildEventsSkeleton(context, isDark, isArabic);
    }

    final hasShootout =
        (state.penaltiesDetail != null && state.penaltiesDetail!.hasKicks) ||
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
      onRefresh: _handleRefresh,
      child: ListView(
        key: const PageStorageKey('events_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // ── Match Alert / Special Notice Card ─────────────────────────────
          if (alertText != null && alertText.trim().isNotEmpty) ...[
            _buildAlertCard(alertText, isDark: isDark),
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

  // ── Skeleton Loader for Events Tab (Matches Real UI Perfectly) ───────────
  Widget _buildEventsSkeleton(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    const dummyEvents = [
      MatchEventEntity(
        minute: "89'",
        playerName: 'بابلو مافيو',
        secondaryPlayerName: 'بطاقة صفراء',
        type: 'yellow_card',
        isHomeTeam: true,
      ),
      MatchEventEntity(
        minute: "84'",
        playerName: 'خوليو دياز',
        secondaryPlayerName: 'كوريا',
        type: 'substitution',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "83'",
        playerName: 'هوغو دورو',
        secondaryPlayerName: 'غيرا',
        type: 'substitution',
        isHomeTeam: true,
      ),
      MatchEventEntity(
        minute: "83'",
        playerName: 'خيسوس فاسكيز',
        secondaryPlayerName: 'غايا',
        type: 'substitution',
        isHomeTeam: true,
      ),
      MatchEventEntity(
        minute: "83'",
        playerName: 'جون غوريدي',
        secondaryPlayerName: 'ستاسين',
        type: 'substitution',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "81'",
        playerName: 'خوان إغليسياس',
        type: 'goal',
        score: '0 - 1',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "71'",
        playerName: 'جيورجي كوشوراشفيلي',
        secondaryPlayerName: 'فوفانا',
        type: 'substitution',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "67'",
        playerName: 'تشيديرا إيجوكي',
        secondaryPlayerName: 'بطاقة صفراء',
        type: 'yellow_card',
        isHomeTeam: true,
      ),
    ];

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: isDark ? const Color(0xFF1E2836) : const Color(0xFFE2E8F0),
        highlightColor: isDark
            ? const Color(0xFF2E3D52)
            : const Color(0xFFF1F5F9),
        duration: const Duration(milliseconds: 1500),
      ),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // 1. Video Highlights Summary Button Preview
          Align(
            alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'ملخص المباراة' : 'Match Highlights',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // 2. Section Header: "الأحداث" + [ الأبرز | كل الأحداث ]
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

          // 3. Events Timeline Container matching real UI
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
              children: dummyEvents
                  .map((e) => TimelineEventItem(event: e))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton Loader for Details Tab ───────────────────────────────────────
  Widget _buildDetailsSkeleton(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: isDark ? const Color(0xFF1E2836) : const Color(0xFFE2E8F0),
        highlightColor: isDark
            ? const Color(0xFF2E3D52)
            : const Color(0xFFF1F5F9),
        duration: const Duration(milliseconds: 1500),
      ),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // Section 1: Match Information Card
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'معلومات اللقاء' : 'Match Information',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...List.generate(
                  6,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isArabic ? 'وقت المباراة' : 'Match Time'),
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section 2: Channels & Commentators Card
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tv_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? 'القنوات الناقلة والمعلقين'
                          : 'Broadcast & Commentators',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('beIN Sports HD 1'),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightCardElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton Loader for Statistics Tab ────────────────────────────────────
  Widget _buildStatsSkeleton(BuildContext context, bool isDark, bool isArabic) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: isDark ? const Color(0xFF1E2836) : const Color(0xFFE2E8F0),
        highlightColor: isDark
            ? const Color(0xFF2E3D52)
            : const Color(0xFFF1F5F9),
        duration: const Duration(milliseconds: 1500),
      ),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: List.generate(
          7,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('55%'),
                    Text(
                      isArabic ? 'الاستحواذ على الكرة' : 'Ball Possession',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text('45%'),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCardElevated,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Skeleton Loader for News Tab ──────────────────────────────────────────
  Widget _buildNewsSkeleton(BuildContext context, bool isDark, bool isArabic) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: isDark ? const Color(0xFF1E2836) : const Color(0xFFE2E8F0),
        highlightColor: isDark
            ? const Color(0xFF2E3D52)
            : const Color(0xFFF1F5F9),
        duration: const Duration(milliseconds: 1500),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
              ),
              title: const Text('عنوان الخبر الرياضي التمهيدي للمباراة المهمة'),
              subtitle: const Text('منذ ساعتين • 154Score'),
            ),
          );
        },
      ),
    );
  }

  // ── Match Alert / Special Notice Card ───────────────────────────────────────
  Widget _buildAlertCard(String text, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.trim(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Video Highlights Summary Chips ─────────────────────────────────────────
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
          final isGoal =
              video.type == 'goals' ||
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
                  fallbackErrorMessage: isArabic
                      ? 'تعذر تشغيل الفيديو'
                      : 'Could not play video',
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
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
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
              // Animate to Statistics tab
              final statsIndex = _currentTabs.indexOf(_MatchTabType.stats);
              if (statsIndex != -1) {
                DefaultTabController.maybeOf(context)?.animateTo(statsIndex);
              }
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
    MatchEntity match,
    bool isDark,
    bool isArabic,
  ) {
    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      if ((match.team1.isEmpty || match.team1 == 'Home Team') &&
          widget.initialMatch == null) {
        return _buildDetailsSkeleton(context, isDark, isArabic);
      }
    }

    final overview = state.overview;
    final detailsList = List<MatchInfoSectionEntity>.from(state.details);

    final m = (match.team1 != 'Home Team' && match.team1.isNotEmpty)
        ? match
        : (widget.initialMatch ?? match);

    if (m.team1 != 'Home Team' || widget.initialMatch != null) {
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

    final homeTeamName = (match.team1.isNotEmpty && match.team1 != 'Home Team')
        ? match.team1
        : (widget.initialMatch?.team1 ??
              _extractTeamNameFromDetails(detailsList, isHome: true));
    final awayTeamName = (match.team2.isNotEmpty && match.team2 != 'Away Team')
        ? match.team2
        : (widget.initialMatch?.team2 ??
              _extractTeamNameFromDetails(detailsList, isHome: false));

    String? noticeText = state.alert ??
        overview?.note ??
        match.note ??
        widget.initialMatch?.note;
    if (noticeText == null || noticeText.trim().isEmpty) {
      for (final sec in detailsList) {
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
              noticeText = c;
              break;
            }
          }
        }
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _handleRefresh,
      child: ListView(
        key: const PageStorageKey('details_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 0. Cancellation / Postponement / Special Notice Card
          if (noticeText != null && noticeText.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _buildAlertCard(noticeText, isDark: isDark),
            ),

          // 1. First Leg / Return Leg
          if (overview?.returnLeg case final returnLeg?)
            MatchReturnLegCard(
              returnLeg: returnLeg,
              homeTeamFallback: homeTeamName,
              awayTeamFallback: awayTeamName,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 2. Head-to-Head Record
          if (overview?.h2hSummary case final h2hSummary?)
            MatchH2HCard(
              summary: h2hSummary,
              homeTeamFallback: homeTeamName,
              awayTeamFallback: awayTeamName,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 3. Recent Form (Last 5 matches)
          if (overview?.recentForm case final recentForm?)
            MatchFormCard(
              recentForm: recentForm,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 4. Quick Match Statistics
          if (overview?.quickStats case final quickStats?
              when !quickStats.isEmpty)
            MatchQuickStatsCard(
              stats: quickStats,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 5. Enriched Info Sections
          ...detailsList
              .where((sec) {
                if (overview != null) {
                  if (overview.h2hSummary != null &&
                      (sec.section.contains('المواجهات المباشرة') ||
                          sec.section.toLowerCase().contains('head-to-head'))) {
                    return false;
                  }
                  if (overview.recentForm != null &&
                      (sec.section.contains('آخر المباريات') ||
                          sec.section.toLowerCase().contains('recent form'))) {
                    return false;
                  }
                  if (overview.quickStats != null &&
                      (sec.section.contains('إحصائيات سريعة') ||
                          sec.section.toLowerCase().contains(
                            'quick statistics',
                          ))) {
                    return false;
                  }
                }
                final lowerTitle = sec.section.toLowerCase();
                if (lowerTitle.contains('alert') ||
                    lowerTitle.contains('notice') ||
                    lowerTitle.contains('hint') ||
                    lowerTitle.contains('تنبيه') ||
                    lowerTitle.contains('ملاحظة') ||
                    lowerTitle.contains('إلغاء') ||
                    lowerTitle.contains('تأجيل')) {
                  return false;
                }
                return true;
              })
              .map(
                (sec) => MatchInfoCard(
                  section: sec,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
        ],
      ),
    );
  }

  String? _extractTeamNameFromDetails(
    List<MatchInfoSectionEntity> sections, {
    required bool isHome,
  }) {
    for (final sec in sections) {
      for (final it in sec.items) {
        final t = it.title.trim().toLowerCase();
        if (isHome) {
          if (t.contains('صاحب الأرض') ||
              t.contains('صاحب الارض') ||
              t.contains('المضيف') ||
              t.contains('الفريق الأول') ||
              t.contains('home')) {
            final content = it.content.trim();
            if (content.isNotEmpty && content != '-' && content != 'المضيف') {
              return content;
            }
          }
        } else {
          if (t == 'الضيف' ||
              t.contains('الفريق الضيف') ||
              t.contains('الفريق الثاني') ||
              t.contains('away')) {
            final content = it.content.trim();
            if (content.isNotEmpty && content != '-' && content != 'الضيف') {
              return content;
            }
          }
        }
      }
    }
    return null;
  }

  // ── Tab 4: الإحصائيات (Full Statistics) ────────────────────────────────────
  Widget _buildStatsTab(
    BuildContext context,
    MatchDetailsState state,
    MatchEntity match,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      return _buildStatsSkeleton(context, isDark, isArabic);
    }

    final effectiveStats = state.stats.isNotEmpty
        ? state.stats
        : _buildStatsFromQuickStats(state.overview?.quickStats, isArabic);

    if (effectiveStats.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyView(titleKey: 'tab_stats', icon: Icons.bar_chart_rounded),
          ],
        ),
      );
    }

    final homeName = (match.team1.isNotEmpty && match.team1 != 'Home Team')
        ? match.team1
        : (widget.initialMatch?.team1 ?? (isArabic ? 'صاحب الأرض' : 'Home'));
    final awayName = (match.team2.isNotEmpty && match.team2 != 'Away Team')
        ? match.team2
        : (widget.initialMatch?.team2 ?? (isArabic ? 'الضيف' : 'Away'));
    final homeLogo = match.team1Logo ?? widget.initialMatch?.team1Logo;
    final awayLogo = match.team2Logo ?? widget.initialMatch?.team2Logo;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _handleRefresh,
      child: ListView(
        key: const PageStorageKey('stats_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // Team Comparison Header
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home Team
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (homeLogo != null && homeLogo.isNotEmpty) ...[
                        AppImage(
                          imageUrl: homeLogo,
                          width: 24,
                          height: 24,
                          placeholderIcon: Icons.shield_outlined,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          homeName,
                          style: AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center vs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isArabic ? 'الإحصائيات' : 'Stats',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Away Team
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          awayName,
                          style: AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (awayLogo != null && awayLogo.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        AppImage(
                          imageUrl: awayLogo,
                          width: 24,
                          height: 24,
                          placeholderIcon: Icons.shield_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Rows
          if (effectiveStats.any(
            (s) => s.category != null && s.category!.trim().isNotEmpty,
          )) ...[
            ..._buildCategorizedStatsWidgets(effectiveStats, isDark, isArabic),
          ] else ...[
            ...effectiveStats.map((stat) => StatComparisonBar(stat: stat)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedStatsWidgets(
    List<MatchStatItemEntity> stats,
    bool isDark,
    bool isArabic,
  ) {
    final Map<String, List<MatchStatItemEntity>> grouped = {};
    for (final s in stats) {
      final cat = (s.category != null && s.category!.trim().isNotEmpty)
          ? s.category!.trim()
          : (isArabic ? 'إحصائيات عامة' : 'General');
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      IconData icon = Icons.analytics_outlined;
      final lower = entry.key.toLowerCase();
      if (lower.contains('هجوم') || lower.contains('attack')) {
        icon = Icons.sports_soccer_rounded;
      } else if (lower.contains('تمرير') ||
          lower.contains('تحكم') ||
          lower.contains('pass') ||
          lower.contains('control')) {
        icon = Icons.swap_horiz_rounded;
      } else if (lower.contains('دفاع') ||
          lower.contains('انضباط') ||
          lower.contains('defen') ||
          lower.contains('discip')) {
        icon = Icons.shield_outlined;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(
            top: AppDimensions.md,
            bottom: AppDimensions.xs,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardElevated.withValues(alpha: 0.6)
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style:
                    AppTypography.getBodySmall(
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
      );

      widgets.addAll(entry.value.map((stat) => StatComparisonBar(stat: stat)));
    }
    return widgets;
  }

  List<MatchStatItemEntity> _buildStatsFromQuickStats(
    MatchQuickStatsEntity? qs,
    bool isArabic,
  ) {
    if (qs == null || qs.isEmpty) return [];
    final list = <MatchStatItemEntity>[];
    if (qs.homePossession != null || qs.awayPossession != null) {
      final hVal = double.tryParse(qs.homePossession ?? '50') ?? 50;
      final aVal = double.tryParse(qs.awayPossession ?? '50') ?? 50;
      final total = hVal + aVal;
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'الاستحواذ' : 'Ball Possession',
          homeValue: '${qs.homePossession ?? '50'}%',
          awayValue: '${qs.awayPossession ?? '50'}%',
          homePercentage: total > 0 ? (hVal / total) : 0.5,
        ),
      );
    }
    if (qs.homeShots != null || qs.awayShots != null) {
      final h = qs.homeShots ?? 0;
      final a = qs.awayShots ?? 0;
      final total = (h + a).toDouble();
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'إجمالي التسديدات' : 'Total Shots',
          homeValue: '$h',
          awayValue: '$a',
          homePercentage: total > 0 ? (h / total) : 0.5,
        ),
      );
    }
    if (qs.homeFouls != null || qs.awayFouls != null) {
      final h = qs.homeFouls ?? 0;
      final a = qs.awayFouls ?? 0;
      final total = (h + a).toDouble();
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'الأخطاء' : 'Fouls',
          homeValue: '$h',
          awayValue: '$a',
          homePercentage: total > 0 ? (h / total) : 0.5,
        ),
      );
    }
    if (qs.homeOffsides != null || qs.awayOffsides != null) {
      final h = qs.homeOffsides ?? 0;
      final a = qs.awayOffsides ?? 0;
      final total = (h + a).toDouble();
      list.add(
        MatchStatItemEntity(
          title: isArabic ? 'التسلل' : 'Offsides',
          homeValue: '$h',
          awayValue: '$a',
          homePercentage: total > 0 ? (h / total) : 0.5,
        ),
      );
    }
    return list;
  }

  String? _resolveLeagueId([MatchEntity? match]) {
    final rawId = match?.leagueId ?? widget.initialMatch?.leagueId;
    if (rawId != null && rawId.isNotEmpty && rawId != 'null') {
      return rawId;
    }
    final title = (match?.leagueTitle ?? widget.initialMatch?.leagueTitle ?? '')
        .toLowerCase();
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

  // ── Tab 5: الترتيب (Standings) ─────────────────────────────────────────────
  Widget _buildStandingsTab(
    BuildContext context,
    MatchDetailsState state,
    MatchEntity match,
    bool isDark,
    bool isArabic,
  ) {
    final leagueId =
        state.championshipId ?? match.leagueId ?? _resolveLeagueId(match);

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
            return Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: isDark
                    ? const Color(0xFF1E2836)
                    : const Color(0xFFE2E8F0),
                highlightColor: isDark
                    ? const Color(0xFF2E3D52)
                    : const Color(0xFFF1F5F9),
                duration: const Duration(milliseconds: 1500),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  8,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
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

          final t1Name = (match.team1.isNotEmpty
                  ? match.team1
                  : (widget.initialMatch?.team1 ?? ''))
              .trim();
          final t2Name = (match.team2.isNotEmpty
                  ? match.team2
                  : (widget.initialMatch?.team2 ?? ''))
              .trim();
          final t1Id = (match.team1Id?.isNotEmpty == true
                  ? match.team1Id
                  : widget.initialMatch?.team1Id)
              ?.trim();
          final t2Id = (match.team2Id?.isNotEmpty == true
                  ? match.team2Id
                  : widget.initialMatch?.team2Id)
              ?.trim();

          List<MapEntry<String, List<StandingRowEntity>>> sortedGroupEntries = [];
          if (hasGroups) {
            final rawEntries = standings.groups!.entries.toList();

            bool rowMatchesTeam(StandingRowEntity row) {
              final rName = row.teamName.trim().toLowerCase();
              final rId = row.teamId?.trim();

              if (t1Id != null && t1Id.isNotEmpty && rId == t1Id) return true;
              if (t2Id != null && t2Id.isNotEmpty && rId == t2Id) return true;

              if (t1Name.isNotEmpty) {
                final target = t1Name.toLowerCase();
                if (rName == target || rName.contains(target) || target.contains(rName)) {
                  return true;
                }
              }
              if (t2Name.isNotEmpty) {
                final target = t2Name.toLowerCase();
                if (rName == target || rName.contains(target) || target.contains(rName)) {
                  return true;
                }
              }
              return false;
            }

            int countMatchingTeams(MapEntry<String, List<StandingRowEntity>> entry) {
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
              context.read<StandingsBloc>().add(LoadStandingsEvent(leagueId));
              await _handleRefresh();
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
                                AppLocalizations.of(context).formatGroupName(groupEntry.key),
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
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? 'مجموعة المباراة' : 'Match Group',
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

  // ── Tab: الهدافون (Scorers) ────────────────────────────────────────────────
  Widget _buildScorersTab(
    BuildContext context,
    String? leagueId,
    bool isDark,
    bool isArabic,
  ) {
    if (leagueId == null || leagueId.isEmpty) {
      return _buildNoLeagueDataView(
        isDark: isDark,
        isArabic: isArabic,
        message: isArabic
            ? 'بيانات الهدافين غير متوفرة لهذه البطولة حالياً'
            : 'Top scorers not available for this competition',
      );
    }

    final bloc = _leagueBloc;
    if (bloc == null) {
      return _buildScorersSkeleton(isDark, isArabic);
    }

    return BlocBuilder<LeagueBloc, LeagueState>(
      bloc: bloc,
      builder: (context, state) {
        if (state.status == LeagueStatus.loading && state.topScorers.isEmpty) {
          return _buildScorersSkeleton(isDark, isArabic);
        }

        if (state.status == LeagueStatus.error && state.topScorers.isEmpty) {
          return ErrorView(
            message: state.errorMessage,
            onRetry: () => bloc.add(LoadLeagueDetailsEvent(leagueId, isRefresh: true)),
          );
        }

        if (state.topScorers.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              bloc.add(LoadLeagueDetailsEvent(leagueId, isRefresh: true));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyView(
                  titleKey: 'tab_overview',
                  customMessage: isArabic
                      ? 'لا توجد بيانات للهدافين حالياً'
                      : 'No top scorers available for this competition',
                  icon: Icons.emoji_events_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            bloc.add(LoadLeagueDetailsEvent(leagueId, isRefresh: true));
          },
          child: ListView(
            key: const PageStorageKey('match_scorers_tab_list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              TopScorersTable(scorers: state.topScorers, isAssists: false),
            ],
          ),
        );
      },
    );
  }

  // ── Tab: الصناع (Assists) ──────────────────────────────────────────────
  Widget _buildAssistsTab(
    BuildContext context,
    String? leagueId,
    bool isDark,
    bool isArabic,
  ) {
    if (leagueId == null || leagueId.isEmpty) {
      return _buildNoLeagueDataView(
        isDark: isDark,
        isArabic: isArabic,
        message: isArabic
            ? 'بيانات الصناع غير متوفرة لهذه البطولة حالياً'
            : 'Top assists not available for this competition',
      );
    }

    final bloc = _leagueBloc;
    if (bloc == null) {
      return _buildScorersSkeleton(isDark, isArabic);
    }

    return BlocBuilder<LeagueBloc, LeagueState>(
      bloc: bloc,
      builder: (context, state) {
        if (state.status == LeagueStatus.loading && state.topAssists.isEmpty) {
          return _buildScorersSkeleton(isDark, isArabic);
        }

        if (state.status == LeagueStatus.error && state.topAssists.isEmpty) {
          return ErrorView(
            message: state.errorMessage,
            onRetry: () => bloc.add(LoadLeagueDetailsEvent(leagueId, isRefresh: true)),
          );
        }

        if (state.topAssists.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              bloc.add(LoadLeagueDetailsEvent(leagueId, isRefresh: true));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyView(
                  titleKey: 'tab_overview',
                  customMessage: isArabic
                      ? 'لا توجد بيانات للصناع حالياً'
                      : 'No top assists available for this competition',
                  icon: Icons.emoji_events_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            bloc.add(LoadLeagueDetailsEvent(leagueId, isRefresh: true));
          },
          child: ListView(
            key: const PageStorageKey('match_assists_tab_list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              TopScorersTable(scorers: state.topAssists, isAssists: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScorersSkeleton(bool isDark, bool isArabic) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoLeagueDataView({
    required bool isDark,
    required bool isArabic,
    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
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
    );
  }

  // ── Tab: الأخبار (News) ────────────────────────────────────────────────────
  Widget _buildNewsTab(
    BuildContext context,
    MatchDetailsState state,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      return _buildNewsSkeleton(context, isDark, isArabic);
    }

    if (state.news.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyView(
              titleKey: 'tab_news',
              icon: Icons.article_rounded,
              customMessage: isArabic
                  ? 'لا توجد أخبار متعلقة بهذه المباراة حالياً'
                  : 'No news articles available for this match at the moment',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _handleRefresh,
      child: ListView.separated(
        key: const PageStorageKey('news_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        itemCount: state.news.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) {
          final item = state.news[index];
          final isItemArabic = TextDirectionHelper.isArabic(item.title) ||
              (item.description != null &&
                  TextDirectionHelper.isArabic(item.description!));
          final effectiveItemArabic = isItemArabic || isArabic;
          final itemDir = isItemArabic
              ? TextDirection.rtl
              : (isArabic ? TextDirection.rtl : TextDirection.ltr);

          return Card(
            elevation: 0,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                child: AppImage(
                  imageUrl: item.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.article_rounded,
                ),
              ),
              title: Directionality(
                textDirection: itemDir,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: itemDir,
                  textAlign: isItemArabic ? TextAlign.right : TextAlign.start,
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: effectiveItemArabic,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              subtitle:
                  (item.description != null && item.description!.isNotEmpty) ||
                      (item.date != null && item.date!.isNotEmpty)
                  ? Directionality(
                      textDirection: itemDir,
                      child: Column(
                        crossAxisAlignment: isItemArabic
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (item.description != null &&
                              item.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: itemDir,
                                textAlign: isItemArabic
                                    ? TextAlign.right
                                    : TextAlign.start,
                                style:
                                    AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: effectiveItemArabic,
                                    ).copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          if (item.date != null && item.date!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.date!,
                                style:
                                    AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: effectiveItemArabic,
                                    ).copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : null,
              onTap: () {
                final articleId =
                    item.articleId ?? UrlHelper.parseNewsUrl(item.link).id;
                final slug =
                    item.slug ?? UrlHelper.parseNewsUrl(item.link).slug;
                if (articleId != null && articleId.isNotEmpty) {
                  context.push('/news/$articleId', extra: {'slug': slug});
                } else if (item.link != null && item.link!.isNotEmpty) {
                  UrlHelper.launchExternalUrl(item.link, context: context);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
