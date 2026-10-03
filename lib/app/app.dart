import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/di/injection_container.dart';
import '../core/localization/app_localizations.dart';
import '../core/notifications/background_notification_task.dart';
import '../core/notifications/foreground_notification_listener.dart';
import '../core/notifications/live_match_foreground_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/local_storage_service.dart';
import '../core/theme/app_theme.dart';
import '../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/matches/presentation/bloc/matches_bloc.dart';
import '../features/news/presentation/bloc/news_bloc.dart';
import '../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../features/settings/presentation/cubit/settings_cubits.dart';
import '../features/standings/presentation/bloc/standings_bloc.dart';
import '../features/transfers/presentation/bloc/transfers_bloc.dart';
import '../features/videos/presentation/bloc/videos_bloc.dart';
import 'router/app_router.dart';

import '../core/websocket/websocket_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      sl<WebSocketService>().connect();
    } catch (_) {}
    // Handle notification permissions and launch payload on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await NotificationService.instance.requestPermissions();
      } catch (e) {
        debugPrint('[App] requestPermissions error: $e');
      }

      // Always-on zero-delay foreground service for matches & news on Android
      try {
        final storage = sl<LocalStorageService>();
        if (storage.isLiveMatchModeEnabled()) {
          await LiveMatchForegroundService.startService();
        }
      } catch (e) {
        debugPrint('[App] LiveMatchForegroundService start error: $e');
      }

      final payload = await NotificationService.instance.getLaunchPayload();
      if (payload != null && payload.isNotEmpty) {
        AppRouter.handleNotificationPayload(payload);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    sl<WebSocketService>().handleAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (Platform.isAndroid) {
        try {
          final storage = sl<LocalStorageService>();
          if (storage.isLiveMatchModeEnabled()) {
            LiveMatchForegroundService.isRunning().then((running) {
              if (!running) {
                LiveMatchForegroundService.startService();
              }
            });
          }
        } catch (_) {}
      }
      try {
        if (Platform.isAndroid) {
          scheduleBackupNotificationPoll();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        BlocProvider<MatchesBloc>(create: (_) => sl<MatchesBloc>()),
        BlocProvider<NewsBloc>(create: (_) => sl<NewsBloc>()),
        BlocProvider<NotificationsBloc>(
          create: (_) => sl<NotificationsBloc>()..add(const LoadNotificationsEvent()),
        ),
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()),
        BlocProvider<StandingsBloc>(create: (_) => sl<StandingsBloc>()),
        BlocProvider<TransfersBloc>(create: (_) => sl<TransfersBloc>()),
        BlocProvider<VideosBloc>(create: (_) => sl<VideosBloc>()),
        BlocProvider<FavoritesCubit>(create: (_) => sl<FavoritesCubit>()),
        BlocProvider<TimezoneCubit>(create: (_) => sl<TimezoneCubit>()),
        BlocProvider<NewsLanguageCubit>(create: (_) => sl<NewsLanguageCubit>()),
      ],
      child: ForegroundNotificationListener(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return BlocBuilder<LocaleCubit, LocaleState>(
              buildWhen: (prev, curr) => prev.locale != curr.locale,
              builder: (context, localeState) {
                return SkeletonizerConfig(
                  data: SkeletonizerConfigData(
                    effectResolver: (brightness) {
                      final isDarkBrightness =
                          themeMode == ThemeMode.dark ||
                          (themeMode == ThemeMode.system &&
                              brightness == Brightness.dark);
                      return isDarkBrightness
                          ? const ShimmerEffect(
                              baseColor: Color(0xFF243242),
                              highlightColor: Color(0xFF3B4E68),
                              duration: Duration(milliseconds: 1400),
                            )
                          : const ShimmerEffect(
                              baseColor: Color(0xFFE2E8F0),
                              highlightColor: Color(0xFFF1F5F9),
                              duration: Duration(milliseconds: 1400),
                            );
                    },
                  ),
                  child: MaterialApp.router(
                    title: '154 SCORE',
                    debugShowCheckedModeBanner: false,
                    routerConfig: AppRouter.router,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    locale: localeState.locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      ...GlobalMaterialLocalizations.delegates,
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
