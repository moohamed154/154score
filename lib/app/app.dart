import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection_container.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/matches/presentation/bloc/matches_bloc.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    sl<WebSocketService>().handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        BlocProvider<MatchesBloc>(create: (_) => sl<MatchesBloc>()),
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()),
        BlocProvider<StandingsBloc>(create: (_) => sl<StandingsBloc>()),
        BlocProvider<TransfersBloc>(create: (_) => sl<TransfersBloc>()),
        BlocProvider<VideosBloc>(create: (_) => sl<VideosBloc>()),
        BlocProvider<FavoritesCubit>(create: (_) => sl<FavoritesCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, currentLocale) {
              return MaterialApp.router(
                title: '154 SCORE',
                debugShowCheckedModeBanner: false,
                routerConfig: AppRouter.router,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: currentLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
