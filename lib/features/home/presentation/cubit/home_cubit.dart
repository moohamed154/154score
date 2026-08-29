import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/domain/repositories/matches_repository.dart';
import '../../../transfers/domain/entities/transfer_entity.dart';
import '../../../transfers/domain/repositories/transfers_repository.dart';
import '../../../videos/domain/entities/video_entity.dart';
import '../../../videos/domain/repositories/videos_repository.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<MatchEntity> liveMatches;
  final List<LeagueGroupEntity> todayLeagues;
  final List<VideoItemEntity> recentVideos;
  final List<TransferEntity> recentTransfers;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.liveMatches = const [],
    this.todayLeagues = const [],
    this.recentVideos = const [],
    this.recentTransfers = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<MatchEntity>? liveMatches,
    List<LeagueGroupEntity>? todayLeagues,
    List<VideoItemEntity>? recentVideos,
    List<TransferEntity>? recentTransfers,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      liveMatches: liveMatches ?? this.liveMatches,
      todayLeagues: todayLeagues ?? this.todayLeagues,
      recentVideos: recentVideos ?? this.recentVideos,
      recentTransfers: recentTransfers ?? this.recentTransfers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    liveMatches,
    todayLeagues,
    recentVideos,
    recentTransfers,
    errorMessage,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  final MatchesRepository _matchesRepository;
  final VideosRepository _videosRepository;
  final TransfersRepository _transfersRepository;
  final LocalStorageService _localStorageService;

  HomeCubit({
    required this._matchesRepository,
    required this._videosRepository,
    required this._transfersRepository,
    required this._localStorageService,
  }) : super(const HomeState());

  Future<void> loadHomeData({bool isRefresh = false}) async {
    if (!isRefresh) {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    final lang = _localStorageService.getLanguage();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final offset = _localStorageService.getTimezoneOffset();

    try {
      final results = await Future.wait([
        _matchesRepository.getMatchesByDate(
          date: dateStr,
          lang: lang,
          utcOffset: offset,
        ),
        _matchesRepository.getLiveMatchesFlat(lang: lang, utcOffset: offset),
        _videosRepository.getVideos(champId: 'all', lang: lang),
        _transfersRepository.getTransfers(lang: lang),
      ]);

      final leaguesRes =
          results[0].dataOrNull as List<LeagueGroupEntity>? ?? [];
      final liveRes = results[1].dataOrNull as List<MatchEntity>? ?? [];
      final videosRes = results[2].dataOrNull as List<VideoItemEntity>? ?? [];
      final transfersRes = results[3].dataOrNull as List<TransferEntity>? ?? [];

      emit(
        state.copyWith(
          status: HomeStatus.success,
          todayLeagues: leaguesRes,
          liveMatches: liveRes,
          recentVideos: videosRes,
          recentTransfers: transfersRes,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
