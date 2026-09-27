import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/apns_notification_service.dart';
import 'core/notifications/background_notification_task.dart';
import 'core/notifications/live_match_foreground_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Initialize foreground task communication port (Android/iOS)
  FlutterForegroundTask.initCommunicationPort();

  // 1. DI
  await initDependencies();

  // 2. Local notifications (foreground + background taps)
  await NotificationService.instance.initialize(
    onNotificationTap: (payload) {
      // Parse payload and navigate using the router
      if (payload != null && payload.isNotEmpty) {
        AppRouter.handleNotificationPayload(payload);
      }
    },
  );

  // 3. Android Zero-Delay Live Match Foreground Service
  try {
    await LiveMatchForegroundService.init();
    final storage = sl<LocalStorageService>();
    if (storage.isLiveMatchModeEnabled()) {
      await LiveMatchForegroundService.startService();
    }
  } catch (e) {
    debugPrint('[main] LiveMatchForegroundService.init/start error: $e');
  }

  // 4. iOS Direct APNs registration (without Firebase)
  try {
    await ApnsNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('[main] ApnsNotificationService.initialize error: $e');
  }

  // 5. Register Workmanager background poll (survives app kill)
  try {
    await initBackgroundNotifications();
  } catch (e) {
    debugPrint('[main] initBackgroundNotifications error: $e');
  }

  runApp(const App());
}
