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

// ── Service Registration ───────────────────────────────────────────────────

/// Call once in [main] after [WidgetsFlutterBinding.ensureInitialized].
Future<void> initBackgroundNotifications() async {
  await Workmanager().initialize(
    workmanagerCallback,
    isInDebugMode: false,
  );

  // Register a periodic poll every 15 minutes (minimum on Android)
  await Workmanager().registerPeriodicTask(
    _taskTag,
    _taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 5),
  );
}

/// Persists the current language so the background task uses the right locale.
Future<void> saveNotificationLang(String lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefLastLang, lang);
}
