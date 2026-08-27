import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
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

      result.fold(
        onSuccess: (profile) {
          emit(
            state.copyWith(
              status: TeamStatus.success,
              teamName: profile.teamName,
              teamLogo: profile.teamLogo ?? state.teamLogo,
              profile: profile,
              errorMessage: null,
            ),
          );
        },
        onFailure: (f) {
          emit(
            state.copyWith(status: TeamStatus.error, errorMessage: f.message),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(status: TeamStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onChangeTab(ChangeTeamTabEvent event, Emitter<TeamState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }
}
