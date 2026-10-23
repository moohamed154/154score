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
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../bloc/match_details_bloc.dart';
import '../bloc/match_details_event.dart';
import '../bloc/match_details_state.dart';
import '../widgets/lineup/lineup_tab_view.dart';
import '../widgets/match_header_banner.dart';
import '../widgets/tabs/match_events_tab.dart';
import '../widgets/tabs/match_info_tab.dart';
import '../widgets/tabs/match_news_tab.dart';
import '../widgets/tabs/match_scorers_tab.dart';
import '../widgets/tabs/match_standings_tab.dart';
import '../widgets/tabs/match_stats_tab.dart';

import '../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../leagues/presentation/bloc/league_event.dart';
import '../../../live_activity/presentation/cubit/live_activity_cubit.dart';
import '../../../live_activity/presentation/widgets/live_activity_toggle_button.dart';

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

  bool _computeIsUpcoming({
    MatchEntity? match,
    MatchDetailsState? state,
  }) {
    if (_computeIsCancelledOrPostponed(match: match, state: state)) {
      return false;
    }

    final effectiveStatus = state?.liveStatus ??
        state?.overview?.status ??
        match?.status ??
        widget.initialMatch?.status;
    final effectiveStatusCode = state?.liveStatusCode ??
        match?.statusCode ??
        widget.initialMatch?.statusCode;

    final effectiveMatch = match ?? widget.initialMatch;

    if (effectiveStatus == null && effectiveMatch == null) {
      return false;
    }

    if (ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode) ||
        ScoreHelper.isFinishedStatus(effectiveStatus, effectiveStatusCode)) {
      return false;
    }

    if (effectiveMatch != null) {
      final phase = MatchStatusHelper.parseMatch(effectiveMatch);
      if (MatchStatusHelper.isLive(phase) ||
          MatchStatusHelper.isFinished(phase)) {
        return false;
      }
      if (MatchStatusHelper.isUpcoming(phase)) {
        return true;
      }
    }

    if (effectiveStatus != null && effectiveStatus.trim().isNotEmpty) {
      return ScoreHelper.isUpcomingStatus(effectiveStatus, effectiveStatusCode);
    }

    return false;
  }

  List<_MatchTabType> _getTabsForStatus({
    required bool isCancelledOrPostponed,
    bool isUpcoming = false,
  }) {
    if (isCancelledOrPostponed || isUpcoming) {
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

  bool _isSharing = false;
  final GlobalKey _screenBoundaryKey = GlobalKey();

  Future<void> _shareMatch(MatchEntity match, AppLocalizations l10n) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final boundary = _screenBoundaryKey.currentContext?.findRenderObject()
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
          ? '⚽ تابع مباراة ${match.team1} ضد ${match.team2} وتغطية المباريات والتشكيلات لحظة بلحظة عبر تطبيق 154Score!\n\n📲 حمّل التطبيق الآن واستمتع بتغطية المباريات المباشرة:\nhttps://154score-api.medohs770.workers.dev/'
          : '⚽ Follow ${match.team1} vs ${match.team2} live scores, events, and lineups with 154Score app!\n\n📲 Download the app now:\nhttps://154score-api.medohs770.workers.dev/';

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
          ? '⚽ تابع مباراة ${match.team1} ضد ${match.team2} عبر تطبيق 154Score!\nhttps://154score-api.medohs770.workers.dev/'
          : '⚽ Follow ${match.team1} vs ${match.team2} on 154Score!\nhttps://154score-api.medohs770.workers.dev/';
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

  bool _isMatchNotificationActive(MatchEntity match,
      [FavoritesState? favState]) {
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
    final key =
        (id != null && id.trim().isNotEmpty) ? id.trim() : (name?.trim() ?? '');
    if (key.isEmpty) return false;
    if (storage.isTeamNotificationMuted(key)) return false;
    if (storage.isTeamNotificationEnabled(key)) return true;
    final isFav = favState != null
        ? favState.isFavoriteTeam(id: id, name: name)
        : storage.isFavoriteTeam(name ?? '', id: id);
    return isFav;
  }

  Future<void> _toggleMatchNotification(
      MatchEntity match, AppLocalizations l10n) async {
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
                  const Icon(Icons.notifications_off_rounded,
                      color: Color(0xFFF59E0B), size: 20),
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
                  nextStatus
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color:
                      nextStatus ? AppColors.primary : const Color(0xFF94A3B8),
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
    bool isDark = true,
  }) {
    final bool hasDuplicateFallbackNames =
        fallbackMatch.team1.trim().isNotEmpty &&
            fallbackMatch.team1.trim().toLowerCase() ==
                fallbackMatch.team2.trim().toLowerCase();

    // 1. Resolve Team 1 (Home)
    String effectiveTeam1 = fallbackMatch.team1;
    if (effectiveTeam1 == 'Home Team' ||
        effectiveTeam1.isEmpty ||
        effectiveTeam1 == 'الفريق الأول' ||
        hasDuplicateFallbackNames) {
      final fromOverview = state.overview?.homeTeamName?.trim();
      final fromLineup = state.lineup?.home?.displayName.trim();
      final fromSections = MatchInfoTab.extractTeamNameFromDetails(
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
        effectiveTeam2 == 'الفريق الثاني' ||
        hasDuplicateFallbackNames) {
      final fromOverview = state.overview?.awayTeamName?.trim();
      final fromLineup = state.lineup?.away?.displayName.trim();
      final fromSections = MatchInfoTab.extractTeamNameFromDetails(
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
    final effectiveTeam1Id = fallbackMatch.team1Id ??
        state.overview?.homeTeamId ??
        state.lineup?.home?.teamId;
    final effectiveTeam2Id = fallbackMatch.team2Id ??
        state.overview?.awayTeamId ??
        state.lineup?.away?.teamId;

    // 4. Resolve Logos
    final effectiveLogo1 = fallbackMatch.team1Logo ??
        state.overview?.homeTeamLogo ??
        state.lineup?.home?.teamLogo ??
        (effectiveTeam1Id != null
            ? UrlHelper.resolveTeamLogo(effectiveTeam1Id)
            : null);

    final effectiveLogo2 = fallbackMatch.team2Logo ??
        state.overview?.awayTeamLogo ??
        state.lineup?.away?.teamLogo ??
        (effectiveTeam2Id != null
            ? UrlHelper.resolveTeamLogo(effectiveTeam2Id)
            : null);

    // 5. Resolve Scores
    String? effectiveScore1 = state.liveScore1 ??
        liveFromMatches?.score1 ??
        fallbackMatch.score1 ??
        state.overview?.score1;
    String? effectiveScore2 = state.liveScore2 ??
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
    final effectiveLeagueTitle = (fallbackMatch.leagueTitle != null &&
            fallbackMatch.leagueTitle!.isNotEmpty)
        ? fallbackMatch.leagueTitle
        : (state.overview?.championshipTitle ??
            _getEffectiveLeagueTitle(fallbackMatch, state));

    final effectiveLeagueId = state.championshipId ??
        state.overview?.championshipId ??
        fallbackMatch.leagueId ??
        LeagueResolver.resolveId(effectiveLeagueTitle ?? '');

    final rawLeagueLogo = (fallbackMatch.leagueLogo != null &&
            fallbackMatch.leagueLogo!.isNotEmpty)
        ? fallbackMatch.leagueLogo
        : state.overview?.championshipLogo;

    final effectiveLeagueLogo = UrlHelper.resolveChampionshipLogo(
      effectiveLeagueId ?? effectiveLeagueTitle,
      currentLogo: rawLeagueLogo,
      isDark: isDark,
    );

    // 7. Status & Time & Date
    final bool isLiveFromFeed = (liveFromMatches != null &&
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

    final bool isCancelledOrPostponed = ScoreHelper.isCancelledOrPostponed(
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
      effectiveStatus = (ScoreHelper.isCancelledOrPostponed(
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

      effectiveStatusCode = (ScoreHelper.isCancelledOrPostponed(
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
      effectiveStatus = (ScoreHelper.isLiveStatus(state.liveStatus)
              ? state.liveStatus
              : null) ??
          liveFromMatches?.status ??
          widget.initialMatch?.status ??
          state.overview?.status ??
          state.liveStatus;

      effectiveStatusCode = (state.liveStatusCode == 'LIVE' ||
                  state.liveStatusCode?.startsWith('IN_PLAY') == true
              ? state.liveStatusCode
              : null) ??
          liveFromMatches?.statusCode ??
          widget.initialMatch?.statusCode ??
          state.liveStatusCode;
    } else {
      effectiveStatus = state.liveStatus ??
          liveFromMatches?.status ??
          fallbackMatch.status ??
          state.overview?.status;

      effectiveStatusCode = state.liveStatusCode ??
          liveFromMatches?.statusCode ??
          fallbackMatch.statusCode;
    }

    final effectiveTime = fallbackMatch.time ?? state.overview?.time;
    final effectiveDate = fallbackMatch.date ?? state.overview?.date;
    final effectiveMinute =
        state.liveMinute ?? liveFromMatches?.minute ?? fallbackMatch.minute;
    final effectiveExtraTime = state.liveExtraTime ??
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

    final isPastMatch = effectiveDate != null &&
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
      penaltyScore1: state.livePenaltyScore1 ??
          liveFromMatches?.penaltyScore1 ??
          fallbackMatch.penaltyScore1,
      penaltyScore2: state.livePenaltyScore2 ??
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
    Completer<void>? leagueCompleter;
    if (_leagueBloc != null && _currentLeagueId != null) {
      leagueCompleter = Completer<void>();
      _leagueBloc!.add(
        LoadLeagueDetailsEvent(
          _currentLeagueId!,
          isRefresh: true,
          completer: leagueCompleter,
        ),
      );
    }
    try {
      if (leagueCompleter != null) {
        await Future.wait([
          completer.future,
          leagueCompleter.future,
        ]).timeout(const Duration(seconds: 4));
      } else {
        await completer.future.timeout(const Duration(seconds: 4));
      }
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

    final effectiveLeagueId = state.championshipId ??
        state.overview?.championshipId ??
        match.leagueId ??
        LeagueResolver.resolveId(effectiveTitle);

    final rawLogo = (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
        ? match.leagueLogo
        : state.overview?.championshipLogo;

    final effectiveLogo = UrlHelper.resolveChampionshipLogo(
      effectiveLeagueId ?? displayTitle,
      currentLogo: rawLogo,
      isDark: isDark,
    );

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
              Container(
                width: 26,
                height: 26,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3447)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: AppImage(
                  imageUrl: effectiveLogo,
                  fit: BoxFit.contain,
                  placeholderIcon: Icons.emoji_events_outlined,
                ),
              ),
              const SizedBox(width: 8),
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
    final initialIsCancelledOrPostponed = _computeIsCancelledOrPostponed(
      match: widget.initialMatch,
      state: null,
    );
    final initialIsUpcoming = _computeIsUpcoming(
      match: widget.initialMatch,
      state: null,
    );
    _currentTabs = _getTabsForStatus(
      isCancelledOrPostponed: initialIsCancelledOrPostponed,
      isUpcoming: initialIsUpcoming,
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
      final cleanId = widget.matchId.replaceAll('match:', '').trim();
      final initTeam1 = widget.initialMatch?.team1.toLowerCase().trim();
      final initTeam2 = widget.initialMatch?.team2.toLowerCase().trim();
      liveFromMatches = context.select<MatchesBloc, MatchEntity?>((matchesBloc) {
        for (final league in matchesBloc.state.allLeagues) {
          for (final m in league.matches) {
            final mCleanId = m.id.replaceAll('match:', '').trim();
            final teamsMatch = (initTeam1 != null &&
                initTeam2 != null &&
                m.team1.toLowerCase().trim() == initTeam1 &&
                m.team2.toLowerCase().trim() == initTeam2);
            if (mCleanId == cleanId || teamsMatch) {
              return m;
            }
          }
        }
        return null;
      });
    } catch (_) {}

    final fallbackMatch = liveFromMatches ??
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
              isDark: isDark,
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
                    isDark: isDark,
                  );
                  final isNotifActive =
                      _isMatchNotificationActive(activeMatch, favState);
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
                    onPressed: () =>
                        _toggleMatchNotification(activeMatch, l10n),
                  );
                },
              );
            },
          ),
          if (sl.isRegistered<LocalStorageService>() &&
              sl<LocalStorageService>().isLiveActivityFeatureEnabled())
            BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
              builder: (context, state) {
                final activeMatch = _resolveActiveMatch(
                  fallbackMatch: fallbackMatch,
                  liveFromMatches: liveFromMatches,
                  state: state,
                  isDark: isDark,
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
                      isDark: isDark,
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
                isDark: isDark,
              );
              if (sl.isRegistered<LocalStorageService>() &&
                  sl<LocalStorageService>().isLiveActivityFeatureEnabled()) {
                try {
                  final liveCubit = context.read<LiveActivityCubit>();
                  if (liveCubit.state.isFeatureEnabled) {
                    liveCubit.updateTracking(
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
                  }
                } catch (_) {}
              }
            },
            builder: (context, state) {
              final activeMatch = _resolveActiveMatch(
                fallbackMatch: fallbackMatch,
                liveFromMatches: liveFromMatches,
                state: state,
                isDark: isDark,
              );

              final isCancelledOrPostponed = _computeIsCancelledOrPostponed(
                match: activeMatch,
                state: state,
              );
              final isUpcoming = _computeIsUpcoming(
                match: activeMatch,
                state: state,
              );
              final activeTabs = _getTabsForStatus(
                isCancelledOrPostponed: isCancelledOrPostponed,
                isUpcoming: isUpcoming,
              );
              _currentTabs = activeTabs;

              final effectiveLeagueId = state.championshipId ??
                  state.overview?.championshipId ??
                  activeMatch.leagueId ??
                  LeagueResolver.resolveId(activeMatch.leagueTitle ?? '') ??
                  MatchStandingsTab.resolveLeagueId(
                    match: activeMatch,
                    initialMatch: widget.initialMatch,
                  );

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
                          enabled: widget.initialMatch == null &&
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
                            liveMinute: activeMatch.minute ??
                                state.liveMinute ??
                                liveFromMatches?.minute,
                            liveExtraTime: activeMatch.extraTime ??
                                state.liveExtraTime ??
                                liveFromMatches?.extraTime,
                            livePeriod: activeMatch.period ??
                                state.livePeriod ??
                                liveFromMatches?.period,
                            penaltyScore1: activeMatch.penaltyScore1,
                            penaltyScore2: activeMatch.penaltyScore2,
                          ),
                        ),

                        // ── Lock Screen Live Activity Button ───────────────────────
                        if (sl.isRegistered<LocalStorageService>() &&
                            sl<LocalStorageService>()
                                .isLiveActivityFeatureEnabled())
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
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
                                  return Tab(
                                      text: isArabic ? 'الأحداث' : 'Events');
                                case _MatchTabType.details:
                                  return Tab(
                                      text: isArabic ? 'التفاصيل' : 'Details');
                                case _MatchTabType.lineups:
                                  return Tab(
                                      text: isArabic ? 'التشكيلة' : 'Lineups');
                                case _MatchTabType.stats:
                                  return Tab(
                                      text: isArabic ? 'الإحصائيات' : 'Stats');
                                case _MatchTabType.standings:
                                  return Tab(
                                      text: isArabic ? 'الترتيب' : 'Standings');
                                case _MatchTabType.scorers:
                                  return Tab(
                                      text: isArabic ? 'الهدافون' : 'Scorers');
                                case _MatchTabType.assists:
                                  return Tab(
                                      text: isArabic ? 'الصناع' : 'Assists');
                                case _MatchTabType.news:
                                  return Tab(
                                      text: isArabic ? 'الأخبار' : 'News');
                              }
                            }).toList(),
                          ),
                        ),

                        const Divider(height: 1),

                        // ── Tab Content ────────────────────────────────────────────
                        Expanded(
                          child: (state.status == MatchDetailsStatus.error &&
                                  state.details.isEmpty &&
                                  state.events.isEmpty)
                              ? ErrorView(
                                  message: state.errorMessage,
                                  onRetry: () =>
                                      context.read<MatchDetailsBloc>().add(
                                            LoadMatchDetailsEvent(
                                              widget.matchId,
                                              initialStatus:
                                                  widget.initialMatch?.status,
                                              initialStatusCode: widget
                                                  .initialMatch?.statusCode,
                                            ),
                                          ),
                                )
                              : TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: activeTabs.map((tab) {
                                    switch (tab) {
                                      case _MatchTabType.events:
                                        return MatchEventsTab(
                                          state: state,
                                          match: activeMatch,
                                          initialMatch: widget.initialMatch,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                          onRefresh: _handleRefresh,
                                          onShowMoreStats: () {
                                            final statsIndex = _currentTabs
                                                .indexOf(_MatchTabType.stats);
                                            if (statsIndex != -1) {
                                              DefaultTabController.maybeOf(
                                                tabContext,
                                              )?.animateTo(statsIndex);
                                            }
                                          },
                                        );
                                      case _MatchTabType.details:
                                        return MatchInfoTab(
                                          state: state,
                                          match: activeMatch,
                                          initialMatch: widget.initialMatch,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                          onRefresh: _handleRefresh,
                                        );
                                      case _MatchTabType.lineups:
                                        return LineupTabView(
                                            matchId: widget.matchId);
                                      case _MatchTabType.stats:
                                        return MatchStatsTab(
                                          state: state,
                                          match: activeMatch,
                                          initialMatch: widget.initialMatch,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                          onRefresh: _handleRefresh,
                                        );
                                      case _MatchTabType.standings:
                                        return MatchStandingsTab(
                                          state: state,
                                          match: activeMatch,
                                          initialMatch: widget.initialMatch,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                          onRefresh: _handleRefresh,
                                        );
                                      case _MatchTabType.scorers:
                                        return MatchScorersTab(
                                          leagueId: effectiveLeagueId,
                                          leagueBloc: _leagueBloc,
                                          isAssists: false,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        );
                                      case _MatchTabType.assists:
                                        return MatchScorersTab(
                                          leagueId: effectiveLeagueId,
                                          leagueBloc: _leagueBloc,
                                          isAssists: true,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        );
                                      case _MatchTabType.news:
                                        return MatchNewsTab(
                                          state: state,
                                          isDark: isDark,
                                          isArabic: isArabic,
                                          onRefresh: _handleRefresh,
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
}
