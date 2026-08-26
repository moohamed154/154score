import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/network/api_result.dart';
import 'package:ysscores/core/storage/local_storage_service.dart';
import 'package:ysscores/core/websocket/websocket_event.dart';
import 'package:ysscores/core/websocket/websocket_service.dart';
import 'package:ysscores/features/matches/domain/entities/match_entity.dart';
import 'package:ysscores/features/matches/domain/repositories/matches_repository.dart';
import 'package:ysscores/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:ysscores/features/matches/presentation/bloc/matches_event.dart';
import 'package:ysscores/features/matches/presentation/bloc/matches_state.dart';

class MockMatchesRepository extends Mock implements MatchesRepository {}
class MockWebSocketService extends Mock implements WebSocketService {}
class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockMatchesRepository mockRepository;
  late MockWebSocketService mockWebSocketService;
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockRepository = MockMatchesRepository();
    mockWebSocketService = MockWebSocketService();
    mockStorage = MockLocalStorageService();

    when(() => mockWebSocketService.updatesStream)
        .thenAnswer((_) => const Stream<LiveMatchUpdate>.empty());
    when(() => mockStorage.getLanguage()).thenReturn('en');
    when(() => mockStorage.getTimezoneOffset()).thenReturn(3);
    when(() => mockStorage.getFavoriteMatches()).thenReturn([]);
  });

  final testDate = DateTime(2026, 8, 27);
  const testLeagues = [
    LeagueGroupEntity(
      leagueTitle: 'Premier League',
      matches: [
        MatchEntity(
          id: '1',
          team1: 'Arsenal',
          team2: 'Chelsea',
          score1: '2',
          score2: '1',
          status: 'Live',
        ),
      ],
    ),
  ];

  group('MatchesBloc Tests', () {
    blocTest<MatchesBloc, MatchesState>(
      'emits [loading, success] when LoadMatchesEvent succeeds',
      build: () {
        when(() => mockRepository.getMatches(
              date: any(named: 'date'),
              lang: any(named: 'lang'),
              utcOffset: any(named: 'utcOffset'),
            )).thenAnswer((_) async => const ApiSuccess(testLeagues));

        return MatchesBloc(
          repository: mockRepository,
          webSocketService: mockWebSocketService,
          localStorageService: mockStorage,
        );
      },
      act: (bloc) => bloc.add(LoadMatchesEvent(date: testDate)),
      expect: () => [
        isA<MatchesState>()
            .having((s) => s.status, 'status', MatchesStatus.loading)
            .having((s) => s.selectedDate, 'date', testDate),
        isA<MatchesState>()
            .having((s) => s.status, 'status', MatchesStatus.success)
            .having((s) => s.allLeagues.length, 'leagues count', 1)
            .having((s) => s.liveMatchesCount, 'live count', 1),
      ],
    );

    blocTest<MatchesBloc, MatchesState>(
      'filters matches correctly on ChangeFilterEvent',
      build: () {
        return MatchesBloc(
          repository: mockRepository,
          webSocketService: mockWebSocketService,
          localStorageService: mockStorage,
        );
      },
      seed: () => MatchesState(
        selectedDate: testDate,
        status: MatchesStatus.success,
        allLeagues: testLeagues,
        filteredLeagues: testLeagues,
      ),
      act: (bloc) => bloc.add(const ChangeFilterEvent(MatchFilterType.live)),
      expect: () => [
        isA<MatchesState>()
            .having((s) => s.activeFilter, 'activeFilter', MatchFilterType.live)
            .having((s) => s.filteredLeagues.length, 'filtered length', 1),
      ],
    );
  });
}
