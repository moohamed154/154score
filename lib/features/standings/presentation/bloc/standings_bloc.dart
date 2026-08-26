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

  const LoadStandingsEvent(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
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
  List<Object?> get props => [status, selectedLeagueId, standings, errorMessage];
}

class StandingsBloc extends Bloc<StandingsEvent, StandingsState> {
  final StandingsRepository _repository;
  final LocalStorageService _localStorageService;

  StandingsBloc({
    required StandingsRepository repository,
    required LocalStorageService localStorageService,
  })  : _repository = repository,
        _localStorageService = localStorageService,
        super(const StandingsState()) {
    on<LoadStandingsEvent>(_onLoadStandings);
  }

  Future<void> _onLoadStandings(
    LoadStandingsEvent event,
    Emitter<StandingsState> emit,
  ) async {
    emit(state.copyWith(
      status: StandingsStatus.loading,
      selectedLeagueId: event.leagueId,
    ));

    final lang = _localStorageService.getLanguage();
    final result = await _repository.getStandings(event.leagueId, lang: lang);

    result.fold(
      onSuccess: (data) {
        emit(state.copyWith(
          status: data.rows.isEmpty ? StandingsStatus.empty : StandingsStatus.success,
          standings: data,
          errorMessage: null,
        ));
      },
      onFailure: (failure) {
        emit(state.copyWith(
          status: StandingsStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }
}
