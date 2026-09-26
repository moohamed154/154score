import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import 'notification_service.dart';

const _prefSeenIds = '154score_seen_notif_ids';

/// Listens to [NotificationsBloc] and fires OS-level local notifications
/// for any items that haven't been shown before.
///
/// Add this widget near the top of the widget tree (inside [MultiBlocProvider])
/// and it will handle foreground notification display automatically.
class ForegroundNotificationListener extends StatefulWidget {
  final Widget child;
  const ForegroundNotificationListener({super.key, required this.child});

  @override
  State<ForegroundNotificationListener> createState() =>
      _ForegroundNotificationListenerState();
}

class _ForegroundNotificationListenerState
    extends State<ForegroundNotificationListener> {
  final Set<String> _shownIds = {};
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadSeenIds();
  }

  Future<void> _loadSeenIds() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getStringList(_prefSeenIds) ?? [];
    _shownIds.addAll(saved);
  }

  Future<void> _persistSeenId(String id) async {
    _shownIds.add(id);
    final list = _shownIds.toList();
    if (list.length > 500) {
      list.removeRange(0, list.length - 500);
    }
    await _prefs?.setStringList(_prefSeenIds, list);
  }

  Future<void> _handleNewNotifications(
    List<AppNotificationEntity> items,
  ) async {
    final service = NotificationService.instance;

    for (final notif in items) {
      if (_shownIds.contains(notif.id)) continue;

      // Brand-word safety
      if (_containsBrandWord(notif.title) || _containsBrandWord(notif.body)) {
        await _persistSeenId(notif.id);
        continue;
      }

      final matchId = notif.data['match_id']?.toString() ?? '';
      final articleId = notif.data['article_id']?.toString() ?? '';

      switch (notif.type) {
        case NotificationType.news:
          await service.showNewsNotification(
            articleId: articleId.isNotEmpty ? articleId : notif.id,
            title: notif.title,
            body: notif.body,
          );
        case NotificationType.goal:
          await service.showGoalNotification(
            matchId: matchId.isNotEmpty ? matchId : notif.id,
            title: notif.title,
            body: notif.body,
          );
        case NotificationType.lineup:
          await service.showLineupNotification(
            matchId: matchId.isNotEmpty ? matchId : notif.id,
            title: notif.title,
            body: notif.body,
          );
        case NotificationType.matchStart:
          await service.showMatchStartNotification(
            matchId: matchId.isNotEmpty ? matchId : notif.id,
            title: notif.title,
            body: notif.body,
          );
        case NotificationType.matchEnd:
          await service.showMatchEndNotification(
            matchId: matchId.isNotEmpty ? matchId : notif.id,
            title: notif.title,
            body: notif.body,
          );
        default:
          break;
      }

      await _persistSeenId(notif.id);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (prev, curr) =>
          curr.status == NotificationsStatus.success &&
          curr.notifications != prev.notifications,
      listener: (context, state) {
        // Only show OS notifications for unread items.
        final unread = state.notifications.where((n) => !n.isRead).toList();
        if (unread.isNotEmpty) {
          _handleNewNotifications(unread);
        }
      },
      child: widget.child,
    );
  }
}
