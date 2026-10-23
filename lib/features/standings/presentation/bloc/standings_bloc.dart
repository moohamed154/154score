import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/standings_entity.dart';
import '../../domain/repositories/standings_repository.dart';

abstract class StandingsEvent extends Equatable {
  const StandingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStandingsEvent extends StandingsEvent {
  final String leagueId;
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadStandingsEvent(
    this.leagueId, {
    this.isRefresh = false,
    this.completer,
  });

  @override
  List<Object?> get props => [leagueId, isRefresh];
}

class ChangeStandingsLanguageEvent extends StandingsEvent {
  final String languageCode;
  final Completer<void>? completer;

  const ChangeStandingsLanguageEvent(this.languageCode, {this.completer});

  @override
  List<Object?> get props => [languageCode];
}

enum StandingsStatus { initial, loading, success, empty, error }

class StandingsState extends Equatable {
  final StandingsStatus status;
  final String selectedLeagueId;
  final LeagueStandingsEntity? standings;
  final String? errorMessage;

  const StandingsState({
    this.status = StandingsStatus.initial,
    this.selectedLeagueId = '937599', // Default: Premier League
    this.standings,
    this.errorMessage,
  });

  StandingsState copyWith({
    StandingsStatus? status,
    String? selectedLeagueId,
    LeagueStandingsEntity? standings,
    String? errorMessage,
  }) {
    return StandingsState(
      status: status ?? this.status,
      selectedLeagueId: selectedLeagueId ?? this.selectedLeagueId,
      standings: standings ?? this.standings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedLeagueId,
        standings,
        errorMessage,
      ];
}

class StandingsBloc extends Bloc<StandingsEvent, StandingsState> {
  final StandingsRepository repository;
  final LocalStorageService localStorageService;

  StandingsBloc({required this.repository, required this.localStorageService})
      : super(const StandingsState()) {
    on<LoadStandingsEvent>(_onLoadStandings);
    on<ChangeStandingsLanguageEvent>(_onChangeStandingsLanguage);
  }

  Future<void> _onLoadStandings(
    LoadStandingsEvent event,
    Emitter<StandingsState> emit,
  ) async {
    if (event.isRefresh) {
      repository.clearCache(event.leagueId);
    } else {
      emit(
        state.copyWith(
          status: StandingsStatus.loading,
          selectedLeagueId: event.leagueId,
        ),
      );
    }

    try {
      final lang = localStorageService.getLanguage();
      final result = await repository.getStandings(event.leagueId, lang: lang);

      result.fold(
        onSuccess: (data) {
          emit(
            state.copyWith(
              status: data.rows.isEmpty
                  ? StandingsStatus.empty
                  : StandingsStatus.success,
              standings: data,
              errorMessage: null,
            ),
          );
        },
        onFailure: (failure) {
          emit(
            state.copyWith(
              status: StandingsStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<dynamic> fetchRankings({
    String search = '',
    String? lang,
  }) async {
    final effectiveLang = lang ?? localStorageService.getLanguage();
    final res = await repository.getRankings(
      lang: effectiveLang,
      search: search,
    );
    if (res.isFailure) {
      throw Exception(res.failureOrNull?.message ?? 'Failed to load rankings');
    }
    return res.dataOrNull;
  }

  Future<void> _onChangeStandingsLanguage(
    ChangeStandingsLanguageEvent event,
    Emitter<StandingsState> emit,
  ) async {
    final targetLang = event.languageCode;
    try {
      // 1. Prefetch rankings directory for targetLang in background so cache is warm for StandingsView
      try {
        final rankResult = await repository.getRankings(lang: targetLang);
        final dynamic response = rankResult.dataOrNull;
        if (response is Map && response['data'] is Map) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          final featuredRaw =
              data['favorites'] as List? ?? (data['featured'] as List? ?? []);
          final leaguesRaw =
              data['all'] as List? ?? (data['leagues'] as List? ?? []);
          if (featuredRaw.isNotEmpty || leaguesRaw.isNotEmpty) {
            await localStorageService.setCachedRankings(
              jsonEncode({'featured': featuredRaw, 'leagues': leaguesRaw}),
              lang: targetLang,
            );
          }
        }
      } catch (_) {}

      final result = await repository.getStandings(
        state.selectedLeagueId,
        lang: targetLang,
      );

      final currentLang = localStorageService.getLanguage();
      if (currentLang != targetLang) return;

      result.fold(
        onSuccess: (data) {
          emit(
            state.copyWith(
              status: data.rows.isEmpty
                  ? StandingsStatus.empty
                  : StandingsStatus.success,
              standings: data,
              errorMessage: null,
            ),
          );
        },
        onFailure: (failure) {
          // Keep existing visible standings
        },
      );
    } catch (_) {
      // Keep existing visible standings
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }
}
