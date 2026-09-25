import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/repositories/teams_repository.dart';
import 'team_event.dart';
import 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamsRepository repository;
  final LocalStorageService localStorageService;

  TeamBloc({
    required this.repository,
    required this.localStorageService,
    required String teamId,
    String? initialName,
    String? initialLogo,
  }) : super(
         TeamState(
           teamId: teamId,
           teamName: initialName,
           teamLogo: initialLogo,
         ),
       ) {
    on<LoadTeamProfileEvent>(_onLoadTeamProfile);
    on<ChangeTeamTabEvent>(_onChangeTab);
    on<SelectChampionshipStandingsEvent>(_onSelectChampionshipStandings);
  }

  Future<void> _onLoadTeamProfile(
    LoadTeamProfileEvent event,
    Emitter<TeamState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: TeamStatus.loading));
    }

    final lang = localStorageService.getLanguage();

    try {
      final result = await repository.getTeamProfile(
        event.teamId,
        teamName: event.teamName ?? state.teamName,
        leagueId: event.leagueId,
        lang: lang,
      );

      await result.fold(
        onSuccess: (profile) async {
          if (profile.teamId.isNotEmpty && profile.teamName.isNotEmpty) {
            unawaited(
              localStorageService.registerTeamTitles({
                profile.teamId: profile.teamName,
              }),
            );
          }
          final initialChampId =
              profile.leagueId ??
              (profile.championships.isNotEmpty
                  ? (profile.championships.first.urlId ??
                        profile.championships.first.id)
                  : null);

          LeagueStandingsEntity? initialStandings;
          if (initialChampId != null && initialChampId.isNotEmpty) {
            final stResult = await repository.getChampionshipStandings(
              initialChampId,
              lang: lang,
            );
            stResult.fold(
              onSuccess: (st) => initialStandings = st,
              onFailure: (_) {},
            );
          }

          emit(
            state.copyWith(
              status: TeamStatus.success,
              teamId: profile.teamId,
              teamName: profile.teamName,
              teamLogo: profile.teamLogo ?? state.teamLogo,
              profile: profile,
              selectedChampionshipId: initialChampId,
              currentStandings: initialStandings,
              errorMessage: null,
            ),
          );
        },
        onFailure: (f) async {
          emit(
            state.copyWith(status: TeamStatus.error, errorMessage: f.message),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(status: TeamStatus.error, errorMessage: e.toString()),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  void _onChangeTab(ChangeTeamTabEvent event, Emitter<TeamState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  Future<void> _onSelectChampionshipStandings(
    SelectChampionshipStandingsEvent event,
    Emitter<TeamState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedChampionshipId: event.championshipId,
        isStandingsLoading: true,
      ),
    );

    final lang = localStorageService.getLanguage();
    final result = await repository.getChampionshipStandings(
      event.championshipId,
      lang: lang,
    );

    result.fold(
      onSuccess: (standings) {
        emit(
          state.copyWith(
            currentStandings: standings,
            isStandingsLoading: false,
          ),
        );
      },
      onFailure: (_) {
        emit(state.copyWith(isStandingsLoading: false));
      },
    );
  }
}
