import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/match_details/domain/repositories/match_details_repository.dart';
import 'package:score154/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:score154/features/match_details/presentation/bloc/match_details_event.dart';

class MockMatchDetailsRepository extends Mock
    implements MatchDetailsRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockMatchDetailsRepository mockRepository;
  late MockWebSocketService mockWebSocketService;
  late MockLocalStorageService mockLocalStorageService;
  late StreamController<MatchDetailRealtimeUpdate> matchDetailController;
  late StreamController<LiveMatchUpdate> liveMatchController;

  setUp(() {
    mockRepository = MockMatchDetailsRepository();
    mockWebSocketService = MockWebSocketService();
    mockLocalStorageService = MockLocalStorageService();
    matchDetailController =
        StreamController<MatchDetailRealtimeUpdate>.broadcast();
    liveMatchController = StreamController<LiveMatchUpdate>.broadcast();

    when(() => mockLocalStorageService.getLanguage()).thenReturn('ar');
    when(() => mockLocalStorageService.getTimezoneOffset()).thenReturn(3);

    when(() => mockWebSocketService.connect()).thenReturn(null);
    when(() => mockWebSocketService.joinMatchRoom(any())).thenReturn(null);
    when(() => mockWebSocketService.leaveMatchRoom(any())).thenReturn(null);
    when(() => mockWebSocketService.matchUpdatesStream(any()))
        .thenAnswer((_) => matchDetailController.stream);
    when(() => mockWebSocketService.updatesStream)
        .thenAnswer((_) => liveMatchController.stream);

    when(() => mockRepository.getEvents(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(() => mockRepository.getStats(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(
      () => mockRepository.getDetails(
        any(),
        lang: any(named: 'lang'),
        utcOffset: any(named: 'utcOffset'),
      ),
    ).thenAnswer((_) async => const ApiSuccess([]));
    when(() => mockRepository.getNews(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(() => mockRepository.getLineups(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess(null));
  });

  tearDown(() {
    matchDetailController.close();
    liveMatchController.close();
  });

  group('MatchDetails WebSocket Real-Time Propagation Tests', () {
    test('MatchDetailRealtimeUpdate.fromJson preserves match_id when event has own id', () {
      final payload = {
        'id': 99999, // Event ID
        'match_id': 1080351, // Match ID
        'score_1': '2',
        'score_2': '1',
        'minute': '90',
        'extra_time': '6',
        'period': '2',
        'status': 'live',
      };

      final update = MatchDetailRealtimeUpdate.fromJson(
        payload,
        fallbackMatchId: '1080351',
      );

      expect(update.matchId, '1080351');
      expect(update.score1, '2');
      expect(update.score2, '1');
      expect(update.minute, '90');
      expect(update.extraTime, '6');
      expect(update.period, '2');
      expect(update.status, 'live');
    });

    test('MatchDetailsBloc emits liveMinute, liveExtraTime, livePeriod from general LiveMatchUpdate', () async {
      final bloc = MatchDetailsBloc(
        repository: mockRepository,
        webSocketService: mockWebSocketService,
        localStorageService: mockLocalStorageService,
        matchId: '1080351',
      );

      const liveUpdate = LiveMatchUpdate(
        matchId: '1080351',
        score1: '3',
        score2: '1',
        minute: '90',
        extraTime: '6',
        period: '2',
        status: 'live',
      );

      bloc.add(const LiveMatchDetailUpdateEvent(liveUpdate));
      await pumpEventQueue();

      expect(bloc.state.liveScore1, '3');
      expect(bloc.state.liveScore2, '1');
      expect(bloc.state.liveMinute, '90');
      expect(bloc.state.liveExtraTime, '6');
      expect(bloc.state.livePeriod, '2');
      expect(bloc.state.liveStatus, 'live');

      await bloc.close();
    });

    test('MatchDetailsBloc emits liveMinute, liveExtraTime, livePeriod from match:{id} room socket update', () async {
      final bloc = MatchDetailsBloc(
        repository: mockRepository,
        webSocketService: mockWebSocketService,
        localStorageService: mockLocalStorageService,
        matchId: '1080351',
      );

      const roomUpdate = MatchDetailRealtimeUpdate(
        matchId: '1080351',
        score1: '2',
        score2: '2',
        minute: '90',
        extraTime: '5',
        period: '2',
        status: 'live',
        eventType: 'goal',
        eventPlayer: 'Player X',
        isHomeTeam: false,
      );

      bloc.add(const MatchDetailSocketUpdateEvent(roomUpdate));
      await pumpEventQueue();

      expect(bloc.state.liveScore1, '2');
      expect(bloc.state.liveScore2, '2');
      expect(bloc.state.liveMinute, '90');
      expect(bloc.state.liveExtraTime, '5');
      expect(bloc.state.livePeriod, '2');
      expect(bloc.state.liveStatus, 'live');
      expect(bloc.state.events.isNotEmpty, isTrue);

      await bloc.close();
    });

    test(
      'MatchDetailsBloc correctly matches room when ID has match: prefix',
      () async {
        final bloc = MatchDetailsBloc(
          repository: mockRepository,
          webSocketService: mockWebSocketService,
          localStorageService: mockLocalStorageService,
          matchId: 'match:1080351',
        );

        expect(bloc.state.matchId, '1080351');

        const roomUpdate = MatchDetailRealtimeUpdate(
          matchId: '1080351',
          score1: '1',
          score2: '0',
          minute: '15',
          status: 'live',
        );

        bloc.add(const MatchDetailSocketUpdateEvent(roomUpdate));
        await pumpEventQueue();

        expect(bloc.state.liveScore1, '1');
        expect(bloc.state.liveScore2, '0');
        expect(bloc.state.liveMinute, '15');

        await bloc.close();
      },
    );

    test('MatchDetailsBloc emits livePenaltyScore1 and livePenaltyScore2 from LiveMatchUpdate and room update', () async {
      final bloc = MatchDetailsBloc(
        repository: mockRepository,
        webSocketService: mockWebSocketService,
        localStorageService: mockLocalStorageService,
        matchId: '1080351',
      );

      const liveUpdate = LiveMatchUpdate(
        matchId: '1080351',
        score1: '1',
        score2: '1',
        penaltyScore1: '4',
        penaltyScore2: '5',
        minute: '120',
        period: 'penalties',
        status: 'ركلات الترجيح',
        statusCode: 'PENALTIES',
      );

      liveMatchController.add(liveUpdate);
      await pumpEventQueue();

      expect(bloc.state.livePenaltyScore1, '4');
      expect(bloc.state.livePenaltyScore2, '5');
      expect(bloc.state.liveStatusCode, 'PENALTIES');

      await bloc.close();
    });
  });
}
