import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../domain/repositories/match_details_repository.dart';
import 'match_details_event.dart';
import 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  final MatchDetailsRepository _repository;
  final WebSocketService _webSocketService;
  final LocalStorageService _localStorageService;
  StreamSubscription? _wsSubscription;

  MatchDetailsBloc({
    required MatchDetailsRepository repository,
    required WebSocketService webSocketService,
    required LocalStorageService localStorageService,
    required String matchId,
  })  : _repository = repository,
        _webSocketService = webSocketService,
        _localStorageService = localStorageService,
        super(MatchDetailsState(matchId: matchId)) {
    on<LoadMatchDetailsEvent>(_onLoadMatchDetails);
    on<ChangeTabEvent>(_onChangeTab);
    on<LiveMatchDetailUpdateEvent>(_onLiveMatchDetailUpdate);

    _wsSubscription = _webSocketService.updatesStream.listen((update) {
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

    final lang = _localStorageService.getLanguage();
    final offset = _localStorageService.getTimezoneOffset();

    try {
      final results = await Future.wait([
        _repository.getEvents(event.matchId, lang: lang),
        _repository.getStats(event.matchId, lang: lang),
        _repository.getDetails(event.matchId, lang: lang, utcOffset: offset),
        _repository.getNews(event.matchId, lang: lang),
      ]);

      final eventsRes = results[0].dataOrNull ?? [];
      final statsRes = results[1].dataOrNull ?? [];
      final detailsRes = results[2].dataOrNull ?? [];
      final newsRes = results[3].dataOrNull ?? [];

      emit(state.copyWith(
        status: MatchDetailsStatus.success,
        events: eventsRes as dynamic,
        stats: statsRes as dynamic,
        details: detailsRes as dynamic,
        news: newsRes as dynamic,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchDetailsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onChangeTab(
    ChangeTabEvent event,
    Emitter<MatchDetailsState> emit,
  ) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  void _onLiveMatchDetailUpdate(
    LiveMatchDetailUpdateEvent event,
    Emitter<MatchDetailsState> emit,
  ) {
    final update = event.update;
    if (update.matchId != null && update.matchId == state.matchId) {
      emit(state.copyWith(
        liveScore1: update.score1 ?? state.liveScore1,
        liveScore2: update.score2 ?? state.liveScore2,
        liveStatus: update.status ?? state.liveStatus,
      ));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
