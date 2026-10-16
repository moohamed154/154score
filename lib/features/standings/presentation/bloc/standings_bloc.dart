import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
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

  const LoadStandingsEvent(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
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
    emit(
      state.copyWith(
        status: StandingsStatus.loading,
        selectedLeagueId: event.leagueId,
      ),
    );

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
  }

  Future<void> _onChangeStandingsLanguage(
    ChangeStandingsLanguageEvent event,
    Emitter<StandingsState> emit,
  ) async {
    final targetLang = event.languageCode;
    try {
      // 1. Prefetch rankings directory for targetLang in background so cache is warm for StandingsView
      try {
        if (GetIt.instance.isRegistered<ApiClient>()) {
          final apiClient = GetIt.instance<ApiClient>();
          final dynamic response = await apiClient.get(
            ApiEndpoints.rank,
            queryParameters: {'lang': targetLang},
          );
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
