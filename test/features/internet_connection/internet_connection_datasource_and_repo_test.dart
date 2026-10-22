import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:score154/features/internet_connection/data/datasources/internet_connection_remote_datasource.dart';
import 'package:score154/features/internet_connection/data/repositories/internet_connection_repository_impl.dart';
import 'package:score154/features/internet_connection/domain/entities/internet_connection_status.dart';

class MockInternetConnection extends Mock implements InternetConnection {}

void main() {
  late MockInternetConnection mockInternetConnection;
  late StreamController<InternetStatus> statusStreamController;

  setUp(() {
    mockInternetConnection = MockInternetConnection();
    statusStreamController = StreamController<InternetStatus>.broadcast();
    when(() => mockInternetConnection.onStatusChange)
        .thenAnswer((_) => statusStreamController.stream);
  });

  tearDown(() {
    statusStreamController.close();
  });

  group('InternetConnectionRemoteDataSource', () {
    test('reports true when real external reachability check succeeds',
        () async {
      when(() => mockInternetConnection.hasInternetAccess)
          .thenAnswer((_) async => true);

      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );

      final hasAccess = await dataSource.hasInternetAccess();
      expect(hasAccess, isTrue);
      dataSource.dispose();
    });

    test(
        'reports false when Wi-Fi/Mobile data is connected but has no real internet',
        () async {
      // Simulates Wi-Fi connected to router with no WAN access or captive portal
      when(() => mockInternetConnection.hasInternetAccess)
          .thenAnswer((_) async => false);

      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );

      final hasAccess = await dataSource.hasInternetAccess();
      expect(hasAccess, isFalse);
      dataSource.dispose();
    });

    test('handles exceptions safely without crashing', () async {
      when(() => mockInternetConnection.hasInternetAccess)
          .thenThrow(Exception('Socket timeout or DNS error'));

      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );

      final hasAccess = await dataSource.hasInternetAccess();
      expect(hasAccess, isFalse);
      dataSource.dispose();
    });

    test('streams reachability changes accurately', () async {
      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );

      final events = <bool>[];
      final sub = dataSource.onInternetAccessChanged.listen(events.add);

      statusStreamController.add(InternetStatus.connected);
      statusStreamController.add(InternetStatus.disconnected);
      statusStreamController.add(InternetStatus.connected);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, equals([true, false, true]));

      await sub.cancel();
      dataSource.dispose();
    });
  });

  group('InternetConnectionRepositoryImpl', () {
    test('maps boolean access to InternetConnectionStatus entities correctly',
        () async {
      when(() => mockInternetConnection.hasInternetAccess)
          .thenAnswer((_) async => true);

      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );
      final repo = InternetConnectionRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final status = await repo.checkInternetAccess();
      expect(status, equals(InternetConnectionStatus.connected));
      expect(status.isConnected, isTrue);
      expect(status.isDisconnected, isFalse);

      final isConnected = await repo.isConnected;
      expect(isConnected, isTrue);

      repo.dispose();
    });

    test('maps disconnected reachability correctly', () async {
      when(() => mockInternetConnection.hasInternetAccess)
          .thenAnswer((_) async => false);

      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );
      final repo = InternetConnectionRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final status = await repo.checkInternetAccess();
      expect(status, equals(InternetConnectionStatus.disconnected));
      expect(status.isDisconnected, isTrue);

      repo.dispose();
    });

    test('propagates status changes through domain stream', () async {
      final dataSource = InternetConnectionRemoteDataSourceImpl(
        internetConnection: mockInternetConnection,
      );
      final repo = InternetConnectionRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final streamStatuses = <InternetConnectionStatus>[];
      final sub = repo.onStatusChanged.listen(streamStatuses.add);

      statusStreamController.add(InternetStatus.connected);
      statusStreamController.add(InternetStatus.disconnected);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        streamStatuses,
        equals([
          InternetConnectionStatus.connected,
          InternetConnectionStatus.disconnected,
        ]),
      );

      await sub.cancel();
      repo.dispose();
    });
  });
}
