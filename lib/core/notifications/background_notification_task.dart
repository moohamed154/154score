import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/api_endpoints.dart';
import '../notifications/notification_service.dart';

// ── Constants ──────────────────────────────────────────────────────────────
const _taskName = 'notifPollTask';
const _taskTag = '154score_notif_poll';

/// Keys used in SharedPreferences to prevent duplicate notifications.
const _prefSeenIds = '154score_seen_notif_ids';
const _prefLastLang = '154score_notif_lang';
const _prefNewsEnabled = 'notif_news_enabled';
const _prefLineupEnabled = 'notif_lineup_enabled';
const _prefGoalsEnabled = 'notif_goals_enabled';
const _prefStartEndEnabled = 'notif_start_end_enabled';

// ── Top-level Workmanager callback ─────────────────────────────────────────
// MUST be a top-level function (not inside a class).
@pragma('vm:entry-point')
void workmanagerCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskName) {
      await _runNotificationPoll();
    }
    return Future.value(true);
  });
}

/// Performs the actual HTTP poll and fires OS notifications for new items.
Future<void> _runNotificationPoll() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_prefLastLang) ?? 'ar';

    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    final response = await dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'lang': lang},
    );

    if (response.statusCode != 200 || response.data == null) return;

    // Parse notifications
    final body = response.data;
    List<dynamic> items = [];
    if (body is Map && body['data'] != null) {
      final inner = body['data'];
      if (inner is Map && inner['notifications'] is List) {
        items = inner['notifications'] as List;
      } else if (inner is List) {
        items = inner;
      }
    } else if (body is List) {
      items = body;
    }

    if (items.isEmpty) return;

    // Read user preferences
    final newsEnabled = prefs.getBool(_prefNewsEnabled) ?? true;
    final lineupEnabled = prefs.getBool(_prefLineupEnabled) ?? true;
    final goalsEnabled = prefs.getBool(_prefGoalsEnabled) ?? true;
    final startEndEnabled = prefs.getBool(_prefStartEndEnabled) ?? true;
    final matchScope = prefs.getString('app_notif_match_scope') ?? 'starred_only';

    // Read already-seen notification IDs (persist cross-session)
    final seenSet = (prefs.getStringList(_prefSeenIds) ?? []).toSet();
    final List<String> newlySeenIds = [];

    final notifService = NotificationService.instance;
    // Ensure channels are created (lightweight if already done)
    await notifService.initialize();

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id']?.toString() ?? '';
      if (id.isEmpty || seenSet.contains(id)) continue;

      final type = raw['type']?.toString() ?? '';
      final title = raw['title']?.toString() ?? '';
      final notifBody = raw['body']?.toString() ?? '';
      final matchId = raw['match_id']?.toString() ?? '';
      final articleId = (raw['data'] as Map?)
              ?['article_id']
              ?.toString() ??
          '';

      // Sanitize – should already be done by the API, but double-check
      if (_containsBrandWord(title) || _containsBrandWord(notifBody)) {
        newlySeenIds.add(id);
        continue;
      }

      // Check match notification scope (starred vs all)
      if (type != 'news' && matchScope == 'starred_only') {
        final matchesStarred = _isStarredMatchEvent(
          prefs: prefs,
          title: title,
          body: notifBody,
          matchId: matchId,
          data: raw['data'] as Map?,
        );
        if (!matchesStarred) {
          newlySeenIds.add(id);
          continue;
        }
      }

      final payload = jsonEncode({
        'type': type == 'news' ? 'news' : 'match',
        if (matchId.isNotEmpty) 'match_id': matchId,
        if (articleId.isNotEmpty) 'article_id': articleId,
      });

      switch (type) {
        case 'news':
          if (newsEnabled) {
            await notifService.showNewsNotification(
              articleId: articleId.isNotEmpty ? articleId : id,
              title: title,
              body: notifBody,
              payload: payload,
            );
          }
        case 'goal':
          if (goalsEnabled) {
            await notifService.showGoalNotification(
              matchId: matchId.isNotEmpty ? matchId : id,
              title: title,
              body: notifBody,
              payload: payload,
            );
          }
        case 'lineup':
          if (lineupEnabled) {
            await notifService.showLineupNotification(
              matchId: matchId.isNotEmpty ? matchId : id,
              title: title,
              body: notifBody,
              payload: payload,
            );
          }
        case 'match_start':
          if (startEndEnabled) {
            await notifService.showMatchStartNotification(
              matchId: matchId.isNotEmpty ? matchId : id,
              title: title,
              body: notifBody,
              payload: payload,
            );
          }
        case 'match_end':
          if (startEndEnabled) {
            await notifService.showMatchEndNotification(
              matchId: matchId.isNotEmpty ? matchId : id,
              title: title,
              body: notifBody,
              payload: payload,
            );
          }
      }
      newlySeenIds.add(id);
    }

    if (newlySeenIds.isNotEmpty) {
      seenSet.addAll(newlySeenIds);
      // Keep only the last 500 IDs to prevent unbounded growth
      final trimmed = seenSet.toList();
      if (trimmed.length > 500) {
        trimmed.removeRange(0, trimmed.length - 500);
      }
      await prefs.setStringList(_prefSeenIds, trimmed);
    }
  } catch (e) {
    // Swallow errors in background – never crash the task worker
    // ignore: avoid_print
    print('[BackgroundNotifTask] error: $e');
  }
}

bool _containsBrandWord(String text) {
  final lower = text.toLowerCase();
  return lower.contains('yallashoot') ||
      lower.contains('yalla shoot') ||
      lower.contains('يلا شوت') ||
      lower.contains('يلاشوت') ||
      lower.contains('ysscores');
}

bool _isStarredMatchEvent({
  required SharedPreferences prefs,
  required String title,
  required String body,
  required String matchId,
  Map? data,
}) {
  if (matchId.isNotEmpty) {
    final favMatches = prefs.getStringList('app_favorite_matches') ?? [];
    final matchNotifs = prefs.getStringList('match_notifications') ?? [];
    if (favMatches.contains(matchId) || matchNotifs.contains(matchId)) return true;
  }

  final favTeams = prefs.getStringList('app_favorite_teams') ?? [];
  final teamNotifs = prefs.getStringList('team_notifications') ?? [];
  final mutedTeams = (prefs.getStringList('team_notifications_muted') ?? []).toSet();

  final Set<String> targetNames = {};
  final rawTitles = prefs.getString('app_favorite_team_titles');
  if (rawTitles != null && rawTitles.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawTitles);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final k = entry.key.toString().trim().toLowerCase();
          final v = entry.value.toString().trim().toLowerCase();
          if (k.isNotEmpty && !mutedTeams.contains(k)) targetNames.add(k);
          if (v.isNotEmpty && !mutedTeams.contains(v)) targetNames.add(v);
        }
      }
    } catch (_) {}
  }

  for (final t in teamNotifs) {
    final trimmed = t.trim().toLowerCase();
    if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed)) targetNames.add(trimmed);
  }

  final Set<String> targetIds = {};
  for (final id in favTeams) {
    final trimmed = id.trim();
    if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed.toLowerCase())) targetIds.add(trimmed);
  }
  for (final id in teamNotifs) {
    final trimmed = id.trim();
    if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed.toLowerCase())) targetIds.add(trimmed);
  }

  if (targetNames.isEmpty && targetIds.isEmpty) {
    return false;
  }

  if (data != null) {
    final homeId = data['home_team_id']?.toString() ?? data['home_id']?.toString();
    final awayId = data['away_team_id']?.toString() ?? data['away_id']?.toString();
    final teamId = data['team_id']?.toString();
    if ((homeId != null && targetIds.contains(homeId)) ||
        (awayId != null && targetIds.contains(awayId)) ||
        (teamId != null && targetIds.contains(teamId))) {
      return true;
    }

    final homeName = data['home_team']?.toString().toLowerCase();
    final awayName = data['away_team']?.toString().toLowerCase();
    if (homeName != null && targetNames.any((n) => homeName.contains(n) || n.contains(homeName))) {
      return true;
    }
    if (awayName != null && targetNames.any((n) => awayName.contains(n) || n.contains(awayName))) {
      return true;
    }
  }

  final lowerTitle = title.toLowerCase();
  final lowerBody = body.toLowerCase();
  for (final name in targetNames) {
    if (lowerTitle.contains(name) || lowerBody.contains(name)) {
      return true;
    }
  }

  return false;
}

// ── Service Registration ───────────────────────────────────────────────────

/// Call once in [main] after [WidgetsFlutterBinding.ensureInitialized].
Future<void> initBackgroundNotifications() async {
  await Workmanager().initialize(
    workmanagerCallback,
  );

  // Register a periodic poll every 15 minutes (minimum on Android)
  await Workmanager().registerPeriodicTask(
    _taskTag,
    _taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 5),
  );
}

/// Persists the current language so the background task uses the right locale.
Future<void> saveNotificationLang(String lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefLastLang, lang);
}
