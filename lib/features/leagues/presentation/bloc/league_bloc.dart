import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../domain/repositories/leagues_repository.dart';
import 'league_event.dart';
import 'league_state.dart';

class LeagueBloc extends Bloc<LeagueEvent, LeagueState> {
  final LeaguesRepository repository;
  final LocalStorageService localStorageService;
  final WebSocketService? webSocketService;

  StreamSubscription? _wsSubscription;

  LeagueBloc({
    required this.repository,
    required this.localStorageService,
    this.webSocketService,
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
    on<LeagueLiveMatchReceivedEvent>(_onLiveMatchReceived);

    if (webSocketService != null) {
      try {
        _wsSubscription = webSocketService!.liveMatchesStream.listen((update) {
          add(LeagueLiveMatchReceivedEvent(update));
        });
      } catch (_) {}
    }
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
      final result = await repository.getLeagueFullDetails(
        event.leagueId,
        lang: lang,
        forceRefresh: event.isRefresh,
      );

      result.fold(
        onSuccess: (details) {
          final effectiveTitle =
              details.name.isNotEmpty && details.name != 'League'
              ? details.name
              : (details.standings?.leagueTitle.isNotEmpty == true &&
                        details.standings?.leagueTitle != 'League Standings'
                    ? details.standings!.leagueTitle
                    : (state.leagueTitle ?? 'League'));

          emit(
            state.copyWith(
              status: LeagueStatus.success,
              leagueTitle: effectiveTitle,
              leagueLogo: details.logo ?? state.leagueLogo,
              country: details.country ?? state.country,
              season: details.season ?? state.season,
              standings: details.standings,
              topScorers: details.topScorers,
              topAssists: details.topAssists,
              matches: details.matches,
              errorMessage: null,
            ),
          );
        },
        onFailure: (failure) {
          if (state.matches.isEmpty && state.standings == null) {
            emit(
              state.copyWith(
                status: LeagueStatus.error,
                errorMessage: failure.message,
              ),
            );
          } else {
            emit(state.copyWith(status: LeagueStatus.success));
          }
        },
      );
    } catch (e) {
      if (state.matches.isEmpty && state.standings == null) {
        emit(
          state.copyWith(
            status: LeagueStatus.error,
            errorMessage: e.toString(),
          ),
        );
      } else {
        emit(state.copyWith(status: LeagueStatus.success));
      }
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  void _onChangeTab(ChangeLeagueTabEvent event, Emitter<LeagueState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  void _onLiveMatchReceived(
    LeagueLiveMatchReceivedEvent event,
    Emitter<LeagueState> emit,
  ) {
    final update = event.update;
    if (update is! LiveMatchUpdate || state.matches.isEmpty) return;

    bool matchFound = false;
    final updatedMatches = state.matches.map((m) {
      final matchesId = update.matchId != null && m.id == update.matchId;
      final matchesTeams =
          (update.team1 != null &&
          update.team2 != null &&
          update.team1!.isNotEmpty &&
          update.team2!.isNotEmpty &&
          m.team1.toLowerCase().contains(update.team1!.toLowerCase()) &&
          m.team2.toLowerCase().contains(update.team2!.toLowerCase()));

      if (matchesId || matchesTeams) {
        matchFound = true;
        return m.copyWith(
          score1: (update.score1 != null && update.score1!.isNotEmpty)
              ? update.score1
              : m.score1,
          score2: (update.score2 != null && update.score2!.isNotEmpty)
              ? update.score2
              : m.score2,
          status: (update.status != null && update.status!.isNotEmpty)
              ? update.status
              : m.status,
          statusCode:
              (update.statusCode != null && update.statusCode!.isNotEmpty)
              ? update.statusCode
              : m.statusCode,
          minute: (update.minute != null && update.minute!.isNotEmpty)
              ? update.minute
              : m.minute,
          period: (update.period != null && update.period!.isNotEmpty)
              ? update.period
              : m.period,
          extraTime: (update.extraTime != null && update.extraTime!.isNotEmpty)
              ? update.extraTime
              : m.extraTime,
        );
      }
      return m;
    }).toList();

    if (matchFound) {
      emit(state.copyWith(matches: updatedMatches));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
