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

import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubits.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. External / Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(sl()),
  );

  sl.registerLazySingleton<WebSocketService>(() {
    final service = WebSocketServiceImpl();
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
  sl.registerLazySingleton<TransfersRemoteDataSource>(
    () => TransfersRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<VideosRemoteDataSource>(
    () => VideosRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfilesRemoteDataSource>(
    () => ProfilesRemoteDataSourceImpl(sl()),
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
  sl.registerLazySingleton<TransfersRepository>(
    () => TransfersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<VideosRepository>(() => VideosRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfilesRepository>(
    () => ProfilesRepositoryImpl(sl()),
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

  sl.registerFactory<StandingsBloc>(
    () => StandingsBloc(repository: sl(), localStorageService: sl()),
  );

  sl.registerFactory<TransfersBloc>(
    () => TransfersBloc(repository: sl(), localStorageService: sl()),
  );

  sl.registerFactory<VideosBloc>(
    () => VideosBloc(repository: sl(), localStorageService: sl()),
  );

  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      matchesRepository: sl(),
      videosRepository: sl(),
      transfersRepository: sl(),
      localStorageService: sl(),
    ),
  );

  sl.registerFactory<FavoritesCubit>(() => FavoritesCubit(sl()));

  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));

  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(sl(), sl()));
}
