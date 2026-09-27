import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/matches/domain/entities/match_entity.dart';
import '../di/injection_container.dart';
import '../storage/local_storage_service.dart';
import '../utils/match_status_helper.dart';
import 'notification_service.dart';

/// Tracks real-time match scores and status transitions in foreground and background.
/// Fires OS push notifications immediately when a goal is scored, a match kicks off,
/// or a match concludes for any favorited team, favorited match, or notification-enabled match.
class MatchNotificationTracker {
  MatchNotificationTracker._();
  static final MatchNotificationTracker instance = MatchNotificationTracker._();

  final Map<String, ({int score1, int score2, String status, int timestamp})>
      _matchStates = {};
  final Set<String> _sentAlertKeys = {};
  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Processes leagues from MatchesBloc
  Future<void> processLeagues(List<LeagueGroupEntity> leagues) async {
    for (final league in leagues) {
      await processMatches(league.matches);
    }
  }

  /// Processes multiple matches
  Future<void> processMatches(List<MatchEntity> matches) async {
    for (final match in matches) {
      await processMatchUpdate(match);
    }
  }

  /// Processes a single match update
  Future<void> processMatchUpdate(MatchEntity match) async {
    final cleanId = match.id.replaceAll('match:', '').trim();
    if (cleanId.isEmpty) return;

    final s1 = int.tryParse(match.score1 ?? '');
    final s2 = int.tryParse(match.score2 ?? '');
    final status = match.status ?? '';

    await _ensurePrefs();
    final prefScoreKey = '154score_last_score_$cleanId';
    final prefStatusKey = '154score_last_status_$cleanId';

    // 1. Get previous state from memory or prefs
    ({int score1, int score2, String status, int timestamp})? previous =
        _matchStates[cleanId];

    if (previous == null) {
      final savedScoreStr = _prefs?.getString(prefScoreKey);
      final savedStatusStr = _prefs?.getString(prefStatusKey);
      if (savedScoreStr != null) {
        final parts = savedScoreStr.split('-');
        final p1 = int.tryParse(parts.first.trim()) ?? 0;
        final p2 = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
        previous = (
          score1: p1,
          score2: p2,
          status: savedStatusStr ?? '',
          timestamp: 0,
        );
        _matchStates[cleanId] = previous;
      }
    }

    // 2. If no previous state, this is the first time seeing this match.
    // Record baseline without firing notification (prevents spam on app start).
    if (previous == null) {
      if (s1 != null || s2 != null || status.isNotEmpty) {
        final initialScore1 = s1 ?? 0;
        final initialScore2 = s2 ?? 0;
        _matchStates[cleanId] = (
          score1: initialScore1,
          score2: initialScore2,
          status: status,
          timestamp: match.timestamp ?? 0,
        );
        await _prefs?.setString(prefScoreKey, '$initialScore1-$initialScore2');
        await _prefs?.setString(prefStatusKey, status);
      }
      return;
    }

    // 3. Check if this match is tracked for notifications
    final isTracked = isMatchTracked(match);

    if (isTracked) {
      final storage = sl.isRegistered<LocalStorageService>()
          ? sl<LocalStorageService>()
          : null;

      // ── A. Goal Event Detection ───────────────────────────────────────────
      final goalsEnabled = storage?.isMatchGoalsNotificationEnabled() ??
          (_prefs?.getBool('notif_goals_enabled') ?? true);

      if (goalsEnabled) {
        if (s1 != null && s1 > previous.score1) {
          // Team 1 scored!
          final alertKey = 'goal_${cleanId}_1_$s1';
          if (!_sentAlertKeys.contains(alertKey)) {
            _sentAlertKeys.add(alertKey);
            await _sendGoalNotification(
              match: match,
              scoringTeam: match.team1,
              s1: s1,
              s2: s2 ?? previous.score2,
            );
          }
        }
        if (s2 != null && s2 > previous.score2) {
          // Team 2 scored!
          final alertKey = 'goal_${cleanId}_2_$s2';
          if (!_sentAlertKeys.contains(alertKey)) {
            _sentAlertKeys.add(alertKey);
            await _sendGoalNotification(
              match: match,
              scoringTeam: match.team2,
              s1: s1 ?? previous.score1,
              s2: s2,
            );
          }
        }
      }

      // ── B. Match Start Detection ──────────────────────────────────────────
      final startEndEnabled = storage?.isMatchStartEndNotificationEnabled() ??
          (_prefs?.getBool('notif_start_end_enabled') ?? true);

      if (startEndEnabled) {
        final wasUpcoming = MatchStatusHelper.isUpcoming(
          MatchStatusHelper.parseStatus(previous.status),
        );
        final isLiveNow = MatchStatusHelper.isLive(
          MatchStatusHelper.parseStatus(status),
        );
        if (wasUpcoming && isLiveNow) {
          final alertKey = 'start_$cleanId';
          if (!_sentAlertKeys.contains(alertKey)) {
            _sentAlertKeys.add(alertKey);
            await _sendMatchStartNotification(match);
          }
        }
      }

      // ── C. Match End Detection ────────────────────────────────────────────
      if (startEndEnabled) {
        final wasLive = MatchStatusHelper.isLive(
          MatchStatusHelper.parseStatus(previous.status),
        );
        final isFinishedNow = MatchStatusHelper.isFinished(
          MatchStatusHelper.parseStatus(status),
        );
        if (wasLive && isFinishedNow) {
          final alertKey = 'end_$cleanId';
          if (!_sentAlertKeys.contains(alertKey)) {
            _sentAlertKeys.add(alertKey);
            await _sendMatchEndNotification(
              match: match,
              s1: s1 ?? previous.score1,
              s2: s2 ?? previous.score2,
            );
          }
        }
      }
    }

    // 4. Update memory & persistence
    final updatedScore1 = s1 ?? previous.score1;
    final updatedScore2 = s2 ?? previous.score2;
    final updatedStatus = status.isNotEmpty ? status : previous.status;

    _matchStates[cleanId] = (
      score1: updatedScore1,
      score2: updatedScore2,
      status: updatedStatus,
      timestamp: match.timestamp ?? previous.timestamp,
    );
    await _prefs?.setString(prefScoreKey, '$updatedScore1-$updatedScore2');
    await _prefs?.setString(prefStatusKey, updatedStatus);
  }

  /// Checks if notifications should be fired for this match based on
  /// user's favorited teams, favorited matches, and single-match notifications.
  bool isMatchTracked(MatchEntity match) {
    try {
      final storage = sl.isRegistered<LocalStorageService>()
          ? sl<LocalStorageService>()
          : null;
      if (storage != null) {
        // 1. Single match notification or favorited match
        if (match.id.isNotEmpty) {
          if (storage.isMatchNotificationEnabled(match.id)) return true;
          if (storage.isFavoriteMatch(match.id)) return true;
        }

        // 2. Global match notification scope
        if (storage.getMatchNotificationScope() ==
            LocalStorageService.matchNotifScopeAll) {
          return true;
        }

        // 3. Team 1
        if (_isTeamTracked(storage, match.team1Id, match.team1)) return true;

        // 4. Team 2
        if (_isTeamTracked(storage, match.team2Id, match.team2)) return true;
      } else if (_prefs != null) {
        // Fallback using SharedPreferences directly (e.g. background task)
        return _isMatchTrackedFromPrefs(match);
      }
    } catch (_) {}
    return false;
  }

  bool _isTeamTracked(LocalStorageService storage, String? id, String? name) {
    final cleanId = id?.trim();
    final cleanName = name?.trim();

    // Muted check
    if (cleanId != null &&
        cleanId.isNotEmpty &&
        storage.isTeamNotificationMuted(cleanId)) {
      return false;
    }
    if (cleanName != null &&
        cleanName.isNotEmpty &&
        storage.isTeamNotificationMuted(cleanName)) {
      return false;
    }

    // Explicit team notification
    if (cleanId != null &&
        cleanId.isNotEmpty &&
        storage.isTeamNotificationEnabled(cleanId)) {
      return true;
    }
    if (cleanName != null &&
        cleanName.isNotEmpty &&
        storage.isTeamNotificationEnabled(cleanName)) {
      return true;
    }

    // Starred / Favorite team
    if (cleanName != null &&
        cleanName.isNotEmpty &&
        storage.isFavoriteTeam(cleanName, id: cleanId)) {
      return true;
    }
    if (cleanId != null &&
        cleanId.isNotEmpty &&
        storage.isFavoriteTeam(cleanId, id: cleanId)) {
      return true;
    }

    // Check favorite team title aliases (e.g. Arabic vs English)
    final favTitles = storage.getFavoriteTeamTitles();
    if (cleanName != null && cleanName.isNotEmpty) {
      final lower = cleanName.toLowerCase();
      for (final entry in favTitles.entries) {
        final k = entry.key.toLowerCase();
        final v = entry.value.toLowerCase();
        if (lower == k ||
            lower == v ||
            lower.contains(v) ||
            v.contains(lower) ||
            lower.contains(k) ||
            k.contains(lower)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isMatchTrackedFromPrefs(MatchEntity match) {
    if (_prefs == null) return false;
    final cleanId = match.id.replaceAll('match:', '').trim();

    final favMatches = (_prefs!.getStringList('app_favorite_matches') ??
        _prefs!.getStringList('favorite_matches') ??
        []).map((s) => s.replaceAll('match:', '').trim()).toSet();
    final matchNotifs = (_prefs!.getStringList('match_notifications') ?? [])
        .map((s) => s.replaceAll('match:', '').trim()).toSet();
    if (favMatches.contains(cleanId) || matchNotifs.contains(cleanId)) return true;

    final mutedTeams = (_prefs!.getStringList('team_notifications_muted') ?? [])
        .map((s) => s.toLowerCase().trim())
        .toSet();
    final favTeams = (_prefs!.getStringList('app_favorite_teams') ??
        _prefs!.getStringList('favorite_teams') ??
        []);
    final teamNotifs = _prefs!.getStringList('team_notifications') ?? [];

    final targetNames = <String>{};
    final rawTitles = _prefs!.getString('app_favorite_team_titles') ??
        _prefs!.getString('favorite_team_titles');
    if (rawTitles != null && rawTitles.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTitles);
        if (decoded is Map) {
          for (final e in decoded.entries) {
            targetNames.add(e.key.toString().toLowerCase().trim());
            targetNames.add(e.value.toString().toLowerCase().trim());
          }
        }
      } catch (_) {}
    }
    for (final t in favTeams) {
      targetNames.add(t.toLowerCase().trim());
    }
    for (final t in teamNotifs) {
      targetNames.add(t.toLowerCase().trim());
    }

    targetNames.removeAll(mutedTeams);

    final t1 = match.team1.toLowerCase().trim();
    final t2 = match.team2.toLowerCase().trim();
    final t1Id = match.team1Id?.toLowerCase().trim();
    final t2Id = match.team2Id?.toLowerCase().trim();

    for (final name in targetNames) {
      if (name.isEmpty) continue;
      if (t1 == name || t1.contains(name) || name.contains(t1)) return true;
      if (t2 == name || t2.contains(name) || name.contains(t2)) return true;
      if (t1Id != null && t1Id == name) return true;
      if (t2Id != null && t2Id == name) return true;
    }

    return false;
  }

  Future<void> _sendGoalNotification({
    required MatchEntity match,
    required String scoringTeam,
    required int s1,
    required int s2,
  }) async {
    final lang = _prefs?.getString('154score_notif_lang') ?? 'ar';
    final isArabic = lang == 'ar';

    final title = isArabic
        ? '⚽ هدف! [$scoringTeam] $s1 - $s2 ${scoringTeam == match.team1 ? match.team2 : match.team1}'
        : '⚽ Goal! [$scoringTeam] $s1 - $s2 ${scoringTeam == match.team1 ? match.team2 : match.team1}';

    final min = (match.minute != null && match.minute!.trim().isNotEmpty)
        ? (isArabic ? 'الدقيقة ${match.minute}\' | ' : 'Minute ${match.minute}\' | ')
        : '';
    final body = '$min${match.team1} ضد ${match.team2}';

    final payload = jsonEncode({
      'type': 'match',
      'match_id': match.id,
    });

    final notifId = NotificationService.stableId('goal_${match.id}_${s1}_$s2');

    await NotificationService.instance.showGoalNotification(
      matchId: match.id,
      title: title,
      body: body,
      payload: payload,
      notificationId: notifId,
    );
  }

  Future<void> _sendMatchStartNotification(MatchEntity match) async {
    final lang = _prefs?.getString('154score_notif_lang') ?? 'ar';
    final isArabic = lang == 'ar';

    final title = isArabic
        ? 'صافرة البداية ⏱️ ${match.team1} ضد ${match.team2}'
        : 'Kick-off ⏱️ ${match.team1} vs ${match.team2}';
    final body = isArabic
        ? 'بدأت الآن مباراة ${match.team1} و ${match.team2}'
        : '${match.team1} vs ${match.team2} has just kicked off!';

    final payload = jsonEncode({
      'type': 'match',
      'match_id': match.id,
    });

    await NotificationService.instance.showMatchStartNotification(
      matchId: match.id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _sendMatchEndNotification({
    required MatchEntity match,
    required int s1,
    required int s2,
  }) async {
    final lang = _prefs?.getString('154score_notif_lang') ?? 'ar';
    final isArabic = lang == 'ar';

    final title = isArabic
        ? 'نهاية المباراة 🏁 ${match.team1} $s1 - $s2 ${match.team2}'
        : 'Full Time 🏁 ${match.team1} $s1 - $s2 ${match.team2}';
    final body = isArabic
        ? 'انتهت مباراة ${match.team1} ضد ${match.team2} بالنتيجة $s1 - $s2'
        : 'Match ended between ${match.team1} and ${match.team2} ($s1 - $s2)';

    final payload = jsonEncode({
      'type': 'match',
      'match_id': match.id,
    });

    await NotificationService.instance.showMatchEndNotification(
      matchId: match.id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
