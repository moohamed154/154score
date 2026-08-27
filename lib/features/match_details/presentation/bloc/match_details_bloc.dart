import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../domain/repositories/match_details_repository.dart';
import 'match_details_event.dart';
import 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  final MatchDetailsRepository repository;
  final WebSocketService webSocketService;
  final LocalStorageService localStorageService;
  StreamSubscription? _wsSubscription;

  MatchDetailsBloc({
    required this.repository,
    required this.webSocketService,
    required this.localStorageService,
    required String matchId,
  }) : super(MatchDetailsState(matchId: matchId)) {
    on<LoadMatchDetailsEvent>(_onLoadMatchDetails);
    on<ChangeTabEvent>(_onChangeTab);
    on<LiveMatchDetailUpdateEvent>(_onLiveMatchDetailUpdate);

    webSocketService.joinMatchRoom(matchId);

    _wsSubscription = webSocketService.updatesStream.listen((update) {
      add(LiveMatchDetailUpdateEvent(update));
    });
  }

  Future<void> _onLoadMatchDetails(
    LoadMatchDetailsEvent event,
    Emitter<MatchDetailsState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: MatchDetailsStatus.loading));
    }

    final lang = localStorageService.getLanguage();
    final offset = localStorageService.getTimezoneOffset();

    try {
      final eventsFuture = repository.getEvents(event.matchId, lang: lang);
      final statsFuture = repository.getStats(event.matchId, lang: lang);
      final detailsFuture = repository.getDetails(
        event.matchId,
        lang: lang,
        utcOffset: offset,
      );
      final newsFuture = repository.getNews(event.matchId, lang: lang);

      final eventsRes = (await eventsFuture).dataOrNull ?? [];
      final statsRes = (await statsFuture).dataOrNull ?? [];
      final detailsRes = (await detailsFuture).dataOrNull ?? [];
      final newsRes = (await newsFuture).dataOrNull ?? [];

      emit(
        state.copyWith(
          status: MatchDetailsStatus.success,
          events: eventsRes,
          stats: statsRes,
          details: detailsRes,
          news: newsRes,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MatchDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<MatchDetailsState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  void _onLiveMatchDetailUpdate(
    LiveMatchDetailUpdateEvent event,
    Emitter<MatchDetailsState> emit,
  ) {
    final update = event.update;
    if (update.matchId != null && update.matchId == state.matchId) {
      emit(
        state.copyWith(
          liveScore1: update.score1 ?? state.liveScore1,
          liveScore2: update.score2 ?? state.liveScore2,
          liveStatus: update.status ?? state.liveStatus,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    webSocketService.leaveMatchRoom(state.matchId);
    _wsSubscription?.cancel();
    return super.close();
  }
}
