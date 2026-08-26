import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/network/api_result.dart';
import 'package:ysscores/core/storage/local_storage_service.dart';
import 'package:ysscores/features/standings/domain/entities/standings_entity.dart';
import 'package:ysscores/features/standings/domain/repositories/standings_repository.dart';
import 'package:ysscores/features/standings/presentation/bloc/standings_bloc.dart';

class MockStandingsRepository extends Mock implements StandingsRepository {}
class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockStandingsRepository mockRepository;
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockRepository = MockStandingsRepository();
    mockStorage = MockLocalStorageService();
    when(() => mockStorage.getLanguage()).thenReturn('en');
  });

  const testStandings = LeagueStandingsEntity(
    leagueId: '937599',
    leagueTitle: 'Premier League',
    rows: [
      StandingRowEntity(
        position: 1,
        teamName: 'Arsenal',
        played: 10,
        wins: 8,
        draws: 1,
        losses: 1,
        goalsFor: 24,
        goalsAgainst: 8,
        goalDiff: 16,
        points: 25,
      ),
    ],
  );

  group('StandingsBloc Tests', () {
    blocTest<StandingsBloc, StandingsState>(
      'emits [loading, success] when LoadStandingsEvent succeeds',
      build: () {
        when(() => mockRepository.getStandings(any(), lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess(testStandings));

        return StandingsBloc(
          repository: mockRepository,
          localStorageService: mockStorage,
        );
      },
      act: (bloc) => bloc.add(const LoadStandingsEvent('937599')),
      expect: () => [
        isA<StandingsState>().having((s) => s.status, 'status', StandingsStatus.loading),
        isA<StandingsState>()
            .having((s) => s.status, 'status', StandingsStatus.success)
            .having((s) => s.standings?.rows.length, 'rows length', 1),
      ],
    );
  });
}
