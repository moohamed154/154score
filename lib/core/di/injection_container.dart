import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../storage/local_storage_service.dart';
import '../websocket/websocket_service.dart';

import '../../features/matches/data/datasources/matches_remote_datasource.dart';
import '../../features/matches/data/repositories/matches_repository_impl.dart';
import '../../features/matches/domain/repositories/matches_repository.dart';
import '../../features/matches/presentation/bloc/matches_bloc.dart';

import '../../features/match_details/data/datasources/match_details_remote_datasource.dart';
import '../../features/match_details/data/repositories/match_details_repository_impl.dart';
import '../../features/match_details/domain/repositories/match_details_repository.dart';
import '../../features/match_details/presentation/bloc/match_details_bloc.dart';

import '../../features/standings/data/datasources/standings_remote_datasource.dart';
import '../../features/standings/data/repositories/standings_repository_impl.dart';
import '../../features/standings/domain/repositories/standings_repository.dart';
import '../../features/standings/presentation/bloc/standings_bloc.dart';

import '../../features/leagues/data/datasources/leagues_remote_datasource.dart';
import '../../features/leagues/data/repositories/leagues_repository_impl.dart';
import '../../features/leagues/domain/repositories/leagues_repository.dart';
import '../../features/leagues/presentation/bloc/league_bloc.dart';

import '../../features/teams/data/datasources/teams_remote_datasource.dart';
import '../../features/teams/data/repositories/teams_repository_impl.dart';
import '../../features/teams/domain/repositories/teams_repository.dart';
import '../../features/teams/presentation/bloc/team_bloc.dart';

import '../../features/transfers/data/datasources/transfers_remote_datasource.dart';
import '../../features/transfers/data/repositories/transfers_repository_impl.dart';
import '../../features/transfers/domain/repositories/transfers_repository.dart';
import '../../features/transfers/presentation/bloc/transfers_bloc.dart';

import '../../features/videos/data/datasources/videos_remote_datasource.dart';
import '../../features/videos/data/repositories/videos_repository_impl.dart';
import '../../features/videos/domain/repositories/videos_repository.dart';
import '../../features/videos/presentation/bloc/videos_bloc.dart';

import '../../features/profiles/data/datasources/profiles_remote_datasource.dart';
import '../../features/profiles/data/repositories/profiles_repository_impl.dart';
import '../../features/profiles/domain/repositories/profiles_repository.dart';

import '../../features/players/data/datasources/player_remote_datasource.dart';
import '../../features/players/data/repositories/player_repository_impl.dart';
import '../../features/players/domain/repositories/player_repository.dart';
import '../../features/players/presentation/bloc/player_bloc.dart';

import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubits.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/presentation/viewmodels/onboarding_cubit.dart';
import '../../features/search/data/repositories/search_repository.dart';
import '../../features/search/presentation/cubit/search_cubit.dart';

import '../../features/news/data/datasources/news_remote_datasource.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';

import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

import '../../features/maintenance/data/repositories/maintenance_repository_impl.dart';
import '../../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../../features/maintenance/presentation/viewmodels/maintenance_cubit.dart';

import '../../features/app_update/data/datasources/app_update_remote_datasource.dart';
import '../../features/app_update/data/repositories/app_update_repository_impl.dart';
import '../../features/app_update/domain/repositories/app_update_repository.dart';
import '../../features/app_update/presentation/viewmodels/app_update_cubit.dart';

import '../../features/live_activity/data/datasources/live_activity_platform_datasource.dart';
import '../../features/live_activity/data/datasources/live_activity_remote_datasource.dart';
import '../../features/live_activity/data/repositories/live_activity_repository_impl.dart';
import '../../features/live_activity/domain/repositories/live_activity_repository.dart';
import '../../features/live_activity/presentation/cubit/live_activity_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. External / Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(sl()),
  );
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(localStorageService: sl<LocalStorageService>()),
  );

  sl.registerLazySingleton<WebSocketService>(() {
    final service = WebSocketServiceImpl(networkInfo: sl());
    service.initialize();
    return service;
  });

  // 2. DataSources
  sl.registerLazySingleton<MatchesRemoteDataSource>(
    () => MatchesRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<MatchDetailsRemoteDataSource>(
    () => MatchDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<StandingsRemoteDataSource>(
    () => StandingsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LeaguesRemoteDataSource>(
    () => LeaguesRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<TeamsRemoteDataSource>(
    () => TeamsRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<TransfersRemoteDataSource>(
    () => TransfersRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<VideosRemoteDataSource>(
    () => VideosRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NewsRemoteDataSource>(
    () => NewsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfilesRemoteDataSource>(
    () => ProfilesRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PlayerRemoteDataSource>(
    () => PlayerRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AppUpdateRemoteDataSource>(
    () => AppUpdateRemoteDataSourceImpl(apiClient: sl()),
  );

  // 3. Repositories
  sl.registerLazySingleton<MatchesRepository>(
    () => MatchesRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<MatchDetailsRepository>(
    () => MatchDetailsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<StandingsRepository>(
    () => StandingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<LeaguesRepository>(
    () => LeaguesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TeamsRepository>(() => TeamsRepositoryImpl(sl()));
  sl.registerLazySingleton<TransfersRepository>(
    () => TransfersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<VideosRepository>(() => VideosRepositoryImpl(sl()));
  sl.registerLazySingleton<NewsRepository>(() => NewsRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfilesRepository>(
    () => ProfilesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PlayerRepository>(() => PlayerRepositoryImpl(sl()));
  sl.registerLazySingleton<SearchRepository>(() => SearchRepository(sl()));
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(apiClient: sl(), localStorage: sl()),
  );
  sl.registerLazySingleton<AppUpdateRepository>(
    () => AppUpdateRepositoryImpl(remoteDataSource: sl()),
  );

  // 4. ViewModels / Blocs / Cubits
  sl.registerFactory<MatchesBloc>(
    () => MatchesBloc(
      repository: sl(),
      webSocketService: sl(),
      localStorageService: sl(),
    ),
  );

  sl.registerFactoryParam<MatchDetailsBloc, String, void>(
    (matchId, _) => MatchDetailsBloc(
      repository: sl(),
      webSocketService: sl(),
      localStorageService: sl(),
      matchId: matchId,
    ),
  );

  sl.registerFactoryParam<LeagueBloc, String, Map<String, dynamic>?>(
    (leagueId, extra) => LeagueBloc(
      repository: sl(),
      localStorageService: sl(),
      webSocketService: sl(),
      leagueId: leagueId,
      initialTitle: extra?['title']?.toString(),
      initialLogo: extra?['logo']?.toString(),
    ),
  );

  sl.registerFactoryParam<TeamBloc, String, Map<String, dynamic>?>(
    (teamId, extra) => TeamBloc(
      repository: sl(),
      localStorageService: sl(),
      teamId: teamId,
      initialName: extra?['name']?.toString(),
      initialLogo: extra?['logo']?.toString(),
    ),
  );

  sl.registerFactoryParam<PlayerBloc, String, Map<String, dynamic>?>(
    (playerId, extra) => PlayerBloc(
      repository: sl(),
      localStorageService: sl(),
      initialId: playerId,
      initialName: extra?['name']?.toString(),
      initialPhoto: extra?['photo']?.toString(),
      initialSlug: extra?['slug']?.toString(),
    ),
  );

  sl.registerFactory<StandingsBloc>(
    () => StandingsBloc(repository: sl(), localStorageService: sl()),
  );

  sl.registerFactory<TransfersBloc>(
    () => TransfersBloc(
      repository: sl(),
      localStorageService: sl(),
      webSocketService: sl(),
    ),
  );

  sl.registerFactory<VideosBloc>(
    () => VideosBloc(repository: sl(), localStorageService: sl()),
  );

  sl.registerFactory<NewsBloc>(
    () => NewsBloc(repository: sl(), localStorageService: sl()),
  );

  sl.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(repository: sl()),
  );

  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      videosRepository: sl(),
      transfersRepository: sl(),
      localStorageService: sl(),
    ),
  );

  sl.registerFactory<FavoritesCubit>(() => FavoritesCubit(sl()));

  sl.registerFactory<SearchCubit>(() => SearchCubit(sl()));

  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerFactory<OnboardingCubit>(() => OnboardingCubit(sl()));

  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(sl(), sl()));

  sl.registerLazySingleton<TimezoneCubit>(() => TimezoneCubit(sl()));

  sl.registerLazySingleton<NewsLanguageCubit>(() => NewsLanguageCubit(sl()));

  sl.registerLazySingleton<MaintenanceRepository>(
    () => MaintenanceRepositoryImpl(sl()),
  );
  sl.registerFactory<MaintenanceCubit>(() => MaintenanceCubit(sl()));

  sl.registerFactory<AppUpdateCubit>(
    () => AppUpdateCubit(
      appUpdateRepository: sl(),
      dio: sl<ApiClient>().dio,
    ),
  );

  // Live Activities & Lock Screen Score Tracking
  sl.registerLazySingleton<LiveActivityPlatformDataSource>(
    () => LiveActivityPlatformDataSourceImpl(),
  );
  sl.registerLazySingleton<LiveActivityRemoteDataSource>(
    () => LiveActivityRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<LiveActivityRepository>(
    () => LiveActivityRepositoryImpl(
      platformDataSource: sl(),
      remoteDataSource: sl(),
      localStorage: sl(),
    ),
  );
  sl.registerLazySingleton<LiveActivityCubit>(
    () => LiveActivityCubit(repository: sl()),
  );
}
