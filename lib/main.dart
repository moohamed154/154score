import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/background_notification_task.dart';
import 'core/notifications/notification_service.dart';
import 'app/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 3. Register Workmanager background poll (every 15 min, survives app kill)
  await initBackgroundNotifications();

  runApp(const App());
}
