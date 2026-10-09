import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../matches/domain/entities/match_entity.dart';
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
  final VideosRepository _videosRepository;
  final TransfersRepository _transfersRepository;
  final LocalStorageService _localStorageService;

  DateTime? _lastLoadedTime;
  static const _homeDataTtl = Duration(minutes: 5);

  HomeCubit({
    required VideosRepository videosRepository,
    required TransfersRepository transfersRepository,
    required LocalStorageService localStorageService,
  })  : _videosRepository = videosRepository,
        _transfersRepository = transfersRepository,
        _localStorageService = localStorageService,
        super(const HomeState());

  Future<void> loadHomeData({bool isRefresh = false}) async {
    final hasExistingData =
        state.recentVideos.isNotEmpty || state.recentTransfers.isNotEmpty;

    if (!isRefresh &&
        hasExistingData &&
        _lastLoadedTime != null &&
        DateTime.now().difference(_lastLoadedTime!) < _homeDataTtl) {
      return;
    }

    if (!isRefresh && !hasExistingData) {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    final lang = _localStorageService.getLanguage();

    try {
      final results = await Future.wait([
        _videosRepository.getVideos(champId: 'all', lang: lang),
        _transfersRepository.getTransfers(lang: lang),
      ]).timeout(const Duration(milliseconds: 3500));

      final videosRes = results[0].dataOrNull as List<VideoItemEntity>? ?? [];
      final transfersRes = results[1].dataOrNull as List<TransferEntity>? ?? [];

      _lastLoadedTime = DateTime.now();

      emit(
        state.copyWith(
          status: HomeStatus.success,
          recentVideos: videosRes.isNotEmpty ? videosRes : state.recentVideos,
          recentTransfers: transfersRes.isNotEmpty
              ? transfersRes
              : state.recentTransfers,
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (!hasExistingData) {
        emit(
          state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
        );
      }
    }
  }

  Future<void> changeLanguage(
    String targetLang, {
    Completer<void>? completer,
  }) async {
    try {
      final results = await Future.wait([
        _videosRepository.getVideos(champId: 'all', lang: targetLang),
        _transfersRepository.getTransfers(lang: targetLang),
      ]).timeout(const Duration(milliseconds: 3500));

      final currentLang = _localStorageService.getLanguage();
      if (currentLang != targetLang) return;

      final videosRes = results[0].dataOrNull as List<VideoItemEntity>? ?? [];
      final transfersRes = results[1].dataOrNull as List<TransferEntity>? ?? [];

      _lastLoadedTime = DateTime.now();

      emit(
        state.copyWith(
          status: HomeStatus.success,
          recentVideos: videosRes.isNotEmpty ? videosRes : state.recentVideos,
          recentTransfers: transfersRes.isNotEmpty
              ? transfersRes
              : state.recentTransfers,
          errorMessage: null,
        ),
      );
    } catch (_) {
      // Keep existing visible data
    } finally {
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }
}
