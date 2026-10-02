import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/apns_notification_service.dart';
import 'core/notifications/background_notification_task.dart';
import 'core/notifications/live_match_foreground_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_sync_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 0. Initialize Android foreground task communication port
    if (Platform.isAndroid) {
      try {
        FlutterForegroundTask.initCommunicationPort();
      } catch (e) {
        debugPrint('[main] FlutterForegroundTask.initCommunicationPort error: $e');
      }
    }

    // 1. Dependency Injection
    await initDependencies();

    // 2. OS-level Local notifications initialization
    try {
      await NotificationService.instance.initialize(
        onNotificationTap: (payload) {
          if (payload != null && payload.isNotEmpty) {
            AppRouter.handleNotificationPayload(payload);
          }
        },
      );
    } catch (e) {
      debugPrint('[main] NotificationService.initialize error: $e');
    }

    runApp(const App());

    // 3. Platform Push Architecture:
    // iOS: Native APNs (MethodChannel + Section 4.7 endpoints)
    if (Platform.isIOS) {
      unawaited(
        ApnsNotificationService.instance.initialize().catchError((e) {
          debugPrint('[main] ApnsNotificationService.initialize error: $e');
        }),
      );
    }

    // Push token registration & foreground handling
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

    // 5. Android-only background tasks (Foreground Service & Workmanager)
    if (Platform.isAndroid) {
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
    }
  }, (error, stack) {
    debugPrint('[main] Uncaught launch error: $error\n$stack');
  });
}
