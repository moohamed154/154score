import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/repositories/leagues_repository.dart';
import 'league_event.dart';
import 'league_state.dart';

class LeagueBloc extends Bloc<LeagueEvent, LeagueState> {
  final LeaguesRepository repository;
  final LocalStorageService localStorageService;

  LeagueBloc({
    required this.repository,
    required this.localStorageService,
    required String leagueId,
    String? initialTitle,
    String? initialLogo,
  }) : super(
         LeagueState(
           leagueId: leagueId,
           leagueTitle: initialTitle,
           leagueLogo: initialLogo,
         ),
       ) {
    on<LoadLeagueDetailsEvent>(_onLoadLeagueDetails);
    on<ChangeLeagueTabEvent>(_onChangeTab);
  }

  Future<void> _onLoadLeagueDetails(
    LoadLeagueDetailsEvent event,
    Emitter<LeagueState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: LeagueStatus.loading));
    }

    final lang = localStorageService.getLanguage();

    try {
      final standingsFuture = repository.getLeagueStandings(
        event.leagueId,
        lang: lang,
      );
      final scorersFuture = repository.getLeagueTopScorers(
        event.leagueId,
        lang: lang,
      );
      final matchesFuture = repository.getLeagueMatches(
        event.leagueId,
        lang: lang,
      );

      final standingsRes = await standingsFuture;
      final scorersRes = await scorersFuture;
      final matchesRes = await matchesFuture;

      final standings = standingsRes.dataOrNull;
      final scorers = scorersRes.dataOrNull ?? [];
      final matches = matchesRes.dataOrNull ?? [];

      final effectiveTitle =
          standings?.leagueTitle.isNotEmpty == true &&
              standings?.leagueTitle != 'League Standings'
          ? standings!.leagueTitle
          : (state.leagueTitle ?? 'League');

      emit(
        state.copyWith(
          status: LeagueStatus.success,
          leagueTitle: effectiveTitle,
          standings: standings,
          topScorers: scorers,
          matches: matches,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: LeagueStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onChangeTab(ChangeLeagueTabEvent event, Emitter<LeagueState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }
}
