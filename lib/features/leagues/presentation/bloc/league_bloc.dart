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
      final profileFuture = repository.getLeagueProfile(
        event.leagueId,
        lang: lang,
      );
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

      final results = await Future.wait([
        profileFuture,
        standingsFuture,
        scorersFuture,
        matchesFuture,
      ]);

      final profileRes = results[0] as dynamic;
      final standingsRes = results[1] as dynamic;
      final scorersRes = results[2] as dynamic;
      final matchesRes = results[3] as dynamic;

      final profileMap = profileRes?.dataOrNull as Map<String, dynamic>?;
      final standings = standingsRes?.dataOrNull as dynamic;
      final scorers = (scorersRes?.dataOrNull ?? []) as List<dynamic>;
      final matches = (matchesRes?.dataOrNull ?? []) as List<dynamic>;

      final profileCountry = profileMap?['country']?.toString();
      String? profileSeason;
      if (profileMap?['current_season'] is Map) {
        profileSeason =
            profileMap!['current_season']['season_name']?.toString() ??
            profileMap['current_season']['name']?.toString();
      }
      final profileLogo = profileMap?['logo']?.toString();
      final profileName = profileMap?['name']?.toString();

      final effectiveTitle =
          profileName?.isNotEmpty == true
              ? profileName!
              : (standings?.leagueTitle.isNotEmpty == true &&
                      standings?.leagueTitle != 'League Standings'
                  ? standings!.leagueTitle
                  : (state.leagueTitle ?? 'League'));

      emit(
        state.copyWith(
          status: LeagueStatus.success,
          leagueTitle: effectiveTitle,
          leagueLogo: profileLogo ?? state.leagueLogo,
          country: profileCountry ?? state.country,
          season: profileSeason ?? state.season,
          standings: standings,
          topScorers: scorers.cast(),
          matches: matches.cast(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: LeagueStatus.error, errorMessage: e.toString()),
      );
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
          statusCode: (update.statusCode != null && update.statusCode!.isNotEmpty)
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
