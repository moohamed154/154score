import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/domain/repositories/matches_repository.dart';
import 'package:score154/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:score154/features/matches/presentation/bloc/matches_event.dart';
import 'package:score154/features/matches/presentation/bloc/matches_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMatchesRepository extends Mock implements MatchesRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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
    when(() => mockStorage.getTimeFormat()).thenReturn('24h');
    when(() => mockStorage.getFavoriteMatches()).thenReturn([]);
    when(() => mockStorage.getFavoriteCompetitions()).thenReturn([]);
    when(() => mockStorage.getFavoriteTeams()).thenReturn([]);
    when(() => mockStorage.getMatchesFilter()).thenReturn(null);
    when(() => mockStorage.getMatchesSortOrder()).thenReturn(null);
    when(() => mockStorage.getHideFavorites()).thenReturn(false);
    when(
      () => mockStorage.isFavoriteCompetition(
        compName: any(named: 'compName'),
        id: any(named: 'id'),
        name: any(named: 'name'),
        slug: any(named: 'slug'),
      ),
    ).thenReturn(false);
    when(() => mockStorage.setMatchesFilter(any()))
        .thenAnswer((_) async => true);
    when(() => mockStorage.setMatchesSortOrder(any()))
        .thenAnswer((_) async => true);
    when(() => mockStorage.setHideFavorites(any()))
        .thenAnswer((_) async => true);
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
        when(
          () => mockRepository.getMatchesByDate(
            date: any(named: 'date'),
            lang: any(named: 'lang'),
            utcOffset: any(named: 'utcOffset'),
            status: any(named: 'status'),
            leagueId: any(named: 'leagueId'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => const ApiSuccess(testLeagues));

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

    blocTest<MatchesBloc, MatchesState>(
      'filters matches correctly when MatchFilterType.favorites is chosen',
      build: () {
        when(() => mockStorage.getFavoriteMatches()).thenReturn(['1']);
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
      act: (bloc) =>
          bloc.add(const ChangeFilterEvent(MatchFilterType.favorites)),
      expect: () => [
        isA<MatchesState>()
            .having(
              (s) => s.activeFilter,
              'activeFilter',
              MatchFilterType.favorites,
            )
            .having((s) => s.filteredLeagues.length, 'filtered length', 1)
            .having(
              (s) => s.filteredLeagues.first.matches.first.isFavorite,
              'isFavorite',
              true,
            ),
      ],
    );

    blocTest<MatchesBloc, MatchesState>(
      'updates filtered leagues on RefreshFavoritesEvent',
      build: () {
        when(() => mockStorage.getFavoriteMatches()).thenReturn(['1']);
        return MatchesBloc(
          repository: mockRepository,
          webSocketService: mockWebSocketService,
          localStorageService: mockStorage,
        );
      },
      seed: () => MatchesState(
        selectedDate: testDate,
        status: MatchesStatus.success,
        activeFilter: MatchFilterType.favorites,
        allLeagues: testLeagues,
        filteredLeagues: const [],
      ),
      act: (bloc) => bloc.add(const RefreshFavoritesEvent()),
      expect: () => [
        isA<MatchesState>()
            .having((s) => s.filteredLeagues.length, 'filtered length', 1)
            .having(
              (s) => s.filteredLeagues.first.matches.first.isFavorite,
              'isFavorite',
              true,
            ),
      ],
    );
  });
}
