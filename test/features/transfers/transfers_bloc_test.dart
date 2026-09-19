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

  const testTransfers = [
    TransferEntity(
      id: '1',
      playerName: 'Kylian Mbappe',
      fromTeamName: 'PSG',
      toTeamName: 'Real Madrid',
      transferPrice: 'Free',
    ),
  ];

  group('TransfersBloc Tests', () {
    blocTest<TransfersBloc, TransfersState>(
      'emits [loading, success] when LoadTransfersEvent succeeds',
      build: () {
        when(() => mockRepository.getTransfers(lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess(testTransfers));

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
            .having((s) => s.allTransfers.length, 'transfers length', 1),
      ],
    );
  });
}
