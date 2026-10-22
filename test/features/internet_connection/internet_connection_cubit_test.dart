import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/features/internet_connection/domain/entities/internet_connection_status.dart';
import 'package:score154/features/internet_connection/domain/repositories/internet_connection_repository.dart';
import 'package:score154/features/internet_connection/presentation/cubit/internet_connection_cubit.dart';
import 'package:score154/features/internet_connection/presentation/cubit/internet_connection_state.dart';

class MockInternetConnectionRepository extends Mock
    implements InternetConnectionRepository {}

void main() {
  late MockInternetConnectionRepository mockRepository;
  late StreamController<InternetConnectionStatus> statusStreamController;

  setUp(() {
    mockRepository = MockInternetConnectionRepository();
    statusStreamController =
        StreamController<InternetConnectionStatus>.broadcast();

    when(() => mockRepository.onStatusChanged)
        .thenAnswer((_) => statusStreamController.stream);
    when(() => mockRepository.dispose()).thenReturn(null);
  });

  tearDown(() {
    statusStreamController.close();
  });

  group('InternetConnectionCubit Unit Tests', () {
    test('initially online device transitions to connected state', () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.connected);

      final cubit = InternetConnectionCubit(repository: mockRepository);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isConnected, isTrue);
      expect(cubit.state.isDisconnected, isFalse);
      expect(cubit.state.status, equals(InternetConnectionStatus.connected));

      await cubit.close();
    });

    test('initially offline device transitions to disconnected state',
        () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isDisconnected, isTrue);
      expect(cubit.state.isConnected, isFalse);
      expect(cubit.state.status, equals(InternetConnectionStatus.disconnected));

      await cubit.close();
    });

    test('internet lost while app is open triggers disconnected after debounce',
        () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.connected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isConnected, isTrue);

      // Now connection drops
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      statusStreamController.add(InternetConnectionStatus.disconnected);

      // Before debounce settles (<350ms), state should still remain connected
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.isConnected, isTrue);

      // After debounce and re-verification, state becomes disconnected
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(cubit.state.isDisconnected, isTrue);

      await cubit.close();
    });

    test('internet restored while app is open triggers connected immediately',
        () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isDisconnected, isTrue);

      // Connection restored
      statusStreamController.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.isConnected, isTrue);
      expect(cubit.state.hasRecovered, isTrue);

      await cubit.close();
    });

    test('manual retry succeeds when internet has been restored', () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isDisconnected, isTrue);

      // Network becomes available
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.connected);

      final retryFuture = cubit.retryConnection();
      expect(cubit.state.isRetrying, isTrue);

      final success = await retryFuture;
      expect(success, isTrue);
      expect(cubit.state.isRetrying, isFalse);
      expect(cubit.state.isConnected, isTrue);
      expect(cubit.state.hasRecovered, isTrue);

      await cubit.close();
    });

    test('manual retry fails when still offline', () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final retryFuture = cubit.retryConnection();
      expect(cubit.state.isRetrying, isTrue);

      final success = await retryFuture;
      expect(success, isFalse);
      expect(cubit.state.isRetrying, isFalse);
      expect(cubit.state.isDisconnected, isTrue);
      expect(cubit.state.hasRecovered, isFalse);

      await cubit.close();
    });

    test('onAppResumed re-checks connection actively', () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isDisconnected, isTrue);

      // User turned Wi-Fi on in Android quick settings and resumed
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.connected);

      cubit.onAppResumed();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.isConnected, isTrue);

      await cubit.close();
    });

    test('does not duplicate state emissions for identical status', () async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.connected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stateList = <InternetConnectionState>[];
      final sub = cubit.stream.listen(stateList.add);

      // Emitting connected again when already connected
      statusStreamController.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(stateList.isEmpty, isTrue);

      await sub.cancel();
      await cubit.close();
    });
  });
}
