import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/transfers/domain/entities/transfer_entity.dart';
import 'package:score154/features/transfers/domain/repositories/transfers_repository.dart';
import 'package:score154/features/transfers/presentation/bloc/transfers_bloc.dart';

class MockTransfersRepository extends Mock implements TransfersRepository {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockTransfersRepository mockRepository;
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockRepository = MockTransfersRepository();
    mockStorage = MockLocalStorageService();
    when(() => mockStorage.getLanguage()).thenReturn('en');
  });

  const testTransfersPage1 = [
    TransferEntity(
      id: '1',
      playerName: 'Kylian Mbappe',
      fromTeamName: 'PSG',
      toTeamName: 'Real Madrid',
      transferPrice: 'Free',
    ),
  ];

  const testTransfersPage2 = [
    TransferEntity(
      id: '2',
      playerName: 'Erling Haaland',
      fromTeamName: 'Dortmund',
      toTeamName: 'Man City',
      transferPrice: '€60M',
    ),
  ];

  group('TransfersBloc Tests', () {
    blocTest<TransfersBloc, TransfersState>(
      'emits [loading, success] when LoadTransfersEvent succeeds',
      build: () {
        when(
          () => mockRepository.getTransfers(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            loadedIds: any(named: 'loadedIds'),
          ),
        ).thenAnswer((_) async => const ApiSuccess(testTransfersPage1));

        return TransfersBloc(
          repository: mockRepository,
          localStorageService: mockStorage,
        );
      },
      act: (bloc) => bloc.add(const LoadTransfersEvent()),
      expect: () => [
        isA<TransfersState>().having(
          (s) => s.status,
          'status',
          TransfersStatus.loading,
        ),
        isA<TransfersState>()
            .having((s) => s.status, 'status', TransfersStatus.success)
            .having((s) => s.allTransfers.length, 'transfers length', 1)
            .having((s) => s.currentPage, 'current page', 1)
            .having((s) => s.hasReachedMax, 'hasReachedMax', false),
      ],
    );

    blocTest<TransfersBloc, TransfersState>(
      'emits updated transfers when LoadMoreTransfersEvent succeeds',
      build: () {
        when(
          () => mockRepository.getTransfers(
            lang: any(named: 'lang'),
            page: 1,
            loadedIds: any(named: 'loadedIds'),
          ),
        ).thenAnswer((_) async => const ApiSuccess(testTransfersPage1));

        when(
          () => mockRepository.getTransfers(
            lang: any(named: 'lang'),
            page: 2,
            loadedIds: any(named: 'loadedIds'),
          ),
        ).thenAnswer((_) async => const ApiSuccess(testTransfersPage2));

        return TransfersBloc(
          repository: mockRepository,
          localStorageService: mockStorage,
        );
      },
      seed: () => const TransfersState(
        status: TransfersStatus.success,
        allTransfers: testTransfersPage1,
        filteredTransfers: testTransfersPage1,
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreTransfersEvent()),
      expect: () => [
        isA<TransfersState>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<TransfersState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.allTransfers.length, 'allTransfers length', 2)
            .having((s) => s.currentPage, 'currentPage', 2),
      ],
    );
  });
}
