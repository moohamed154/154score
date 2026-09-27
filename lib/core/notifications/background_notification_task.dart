import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/matches/data/models/match_dto.dart';
import '../../features/matches/domain/entities/match_entity.dart';
import '../constants/api_endpoints.dart';
import '../notifications/notification_service.dart';
import 'match_notification_tracker.dart';

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
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    try {
      if (task == _taskName ||
          task == _taskTag ||
          task == Workmanager.iOSBackgroundTask ||
          task.contains('notif') ||
          task == 'iOSBackgroundTask') {
        await _runNotificationPoll();
      }
    } catch (e) {
      debugPrint('[workmanagerCallback] error executing $task: $e');
    }
    return Future.value(true);
  });
}

/// Performs the actual HTTP poll and fires OS notifications for new items.
Future<void> _runNotificationPoll() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {}
    final lang = prefs.getString(_prefLastLang) ?? 'ar';

    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'User-Agent': '154Score-Flutter/1.0',
      },
    ));

    final notifService = NotificationService.instance;
    await notifService.initialize();

    // 1. Poll live match events (goals, start, end) for tracked/starred matches & teams
    await _pollLiveMatches(dio, prefs, lang, notifService);

    // 2. Poll news / article notifications feed
    Response? response;
    try {
      response = await dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'lang': lang},
      );
    } catch (_) {}

    if (response == null || response.statusCode != 200 || response.data == null) return;

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
    final isFirstRun = !prefs.containsKey(_prefSeenIds);
    if (isFirstRun) {
      final initialIds = items
          .map((r) => r is Map ? r['id']?.toString() ?? '' : '')
          .where((id) => id.isNotEmpty)
          .toList();
      await prefs.setStringList(_prefSeenIds, initialIds);
      return;
    }
    final List<String> newlySeenIds = [];

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

Future<void> _pollLiveMatches(
  Dio dio,
  SharedPreferences prefs,
  String lang,
  NotificationService notifService,
) async {
  try {
    dynamic matchesData;
    try {
      final liveRes = await dio.get(
        ApiEndpoints.matchesLive,
        queryParameters: {'lang': lang},
      );
      if (liveRes.statusCode == 200 && liveRes.data != null) {
        matchesData = liveRes.data;
      }
    } catch (_) {}

    if (matchesData == null) {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      try {
        final res = await dio.get(
          ApiEndpoints.matchesByDate(dateStr),
          queryParameters: {'lang': lang},
        );
        if (res.statusCode == 200 && res.data != null) {
          matchesData = res.data;
        }
      } catch (_) {}
    }

    if (matchesData == null) return;

    final matches = _extractMatchesFromPayload(matchesData);
    if (matches.isNotEmpty) {
      await MatchNotificationTracker.instance.processMatches(matches);
    }
  } catch (e) {
    debugPrint('[background_notification_task] _pollLiveMatches error: $e');
  }
}

List<MatchEntity> _extractMatchesFromPayload(dynamic data) {
  final result = <MatchEntity>[];
  if (data is Map && data['data'] != null) {
    final inner = data['data'];
    if (inner is List) {
      for (final item in inner) {
        if (item is Map) {
          if (item['matches'] is List) {
            for (final m in item['matches']) {
              if (m is Map) {
                try {
                  result.add(
                    MatchDto.fromJson(Map<String, dynamic>.from(m)).toEntity(),
                  );
                } catch (_) {}
              }
            }
          } else {
            try {
              result.add(
                MatchDto.fromJson(Map<String, dynamic>.from(item)).toEntity(),
              );
            } catch (_) {}
          }
        }
      }
    }
  }
  return result;
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
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 5),
  );
}

/// Schedules an immediate one-off background task to poll notifications
/// as a safety net when the app is backgrounded or closed.
Future<void> scheduleBackupNotificationPoll() async {
  try {
    await Workmanager().registerOneOffTask(
      'notif_oneoff_${DateTime.now().millisecondsSinceEpoch}',
      _taskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: const Duration(seconds: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  } catch (e) {
    debugPrint('[BackgroundNotifTask] scheduleBackupNotificationPoll error: $e');
  }
}

/// Persists the current language so the background task uses the right locale.
Future<void> saveNotificationLang(String lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefLastLang, lang);
}
