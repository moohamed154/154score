import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/background_notification_task.dart';
import 'core/notifications/live_match_foreground_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_sync_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 0. Initialize foreground task communication port (Android/iOS)
    FlutterForegroundTask.initCommunicationPort();

    // 1. Dependency Injection
    await initDependencies();

    // 2. OS-level Local notifications initialization
    await NotificationService.instance.initialize(
      onNotificationTap: (payload) {
        if (payload != null && payload.isNotEmpty) {
          AppRouter.handleNotificationPayload(payload);
        }
      },
    );

    runApp(const App());

    // 3. Primary Remote Push Architecture: Firebase Cloud Messaging (FCM & APNs)
    // Initializes Firebase, registers token with POST /notifications/push_notifications_providers,
    // and hooks foreground, background, and terminated tap handlers.
    unawaited(
      PushNotificationService.instance.initialize().catchError((e) {
        debugPrint('[main] PushNotificationService.initialize error: $e');
      }),
    );

    // 4. Synchronize user's subscribed teams/matches with backend server
    // POST /notifications/notification_post_service
    unawaited(
      NotificationSyncService.instance.syncAllSubscriptions().catchError((e) {
        debugPrint('[main] NotificationSyncService.syncAllSubscriptions error: $e');
        return false;
      }),
    );

    // 5. Optional secondary fallback services (Android Foreground Service & Workmanager)
    try {
      await LiveMatchForegroundService.init();
      final storage = sl<LocalStorageService>();
      if (storage.isLiveMatchModeEnabled()) {
        await LiveMatchForegroundService.startService();
      }
    } catch (e) {
      debugPrint('[main] LiveMatchForegroundService error: $e');
    }

    try {
      await initBackgroundNotifications();
    } catch (e) {
      debugPrint('[main] initBackgroundNotifications error: $e');
    }
  }, (error, stack) {
    debugPrint('[main] Uncaught launch error: $error\n$stack');
  });
}

