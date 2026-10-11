import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/live_activity/domain/entities/live_activity_entity.dart';
import 'package:score154/features/live_activity/domain/repositories/live_activity_repository.dart';
import 'package:score154/features/live_activity/data/datasources/live_activity_platform_datasource.dart';
import 'package:score154/features/live_activity/data/datasources/live_activity_remote_datasource.dart';
import 'package:score154/features/live_activity/data/repositories/live_activity_repository_impl.dart';
import 'package:score154/features/live_activity/presentation/cubit/live_activity_cubit.dart';
import 'package:score154/features/live_activity/presentation/cubit/live_activity_state.dart';

class MockLiveActivityPlatformDataSource extends Mock
    implements LiveActivityPlatformDataSource {}

class MockLiveActivityRemoteDataSource extends Mock
    implements LiveActivityRemoteDataSource {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockLiveActivityRepository extends Mock
    implements LiveActivityRepository {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LiveActivityEntity & LiveActivityState Tests', () {
    test('LiveActivityEntity equality and copyWith', () {
      const entity1 = LiveActivityEntity(
        activityId: 'act_123',
        matchId: '1001',
        pushToken: 'token_abc',
        isTracking: true,
      );

      final entity2 = entity1.copyWith(pushToken: 'token_xyz');

      expect(entity1.activityId, 'act_123');
      expect(entity1.matchId, '1001');
      expect(entity2.pushToken, 'token_xyz');
      expect(entity1 == entity2, false);
    });

    test('LiveActivityState tracks active match correctly', () {
      const state = LiveActivityState(
        trackedMatchIds: {'1001', '1002'},
        isSupported: true,
      );

      expect(state.isTracking('1001'), true);
      expect(state.isTracking('match:1001'), true);
      expect(state.isTracking('1003'), false);
    });
  });

  group('LiveActivityCubit Tests', () {
    late MockLiveActivityRepository mockRepo;
    late StreamController<String> trackingStoppedController;

    setUp(() {
      mockRepo = MockLiveActivityRepository();
      trackingStoppedController = StreamController<String>.broadcast();
      when(() => mockRepo.areActivitiesSupported())
          .thenAnswer((_) async => true);
      when(() => mockRepo.getActiveTrackedMatchIds())
          .thenAnswer((_) async => ['1001']);
      when(() => mockRepo.onTrackingStoppedStream)
          .thenAnswer((_) => trackingStoppedController.stream);
    });

    tearDown(() {
      trackingStoppedController.close();
    });

    test('Initializes with supported status and active matches', () async {
      final cubit = LiveActivityCubit(repository: mockRepo);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.isSupported, true);
      expect(cubit.state.isTracking('1001'), true);
      await cubit.close();
    });

    test('startTracking adds matchId to trackedMatchIds', () async {
      final cubit = LiveActivityCubit(repository: mockRepo);
      await Future.delayed(const Duration(milliseconds: 20));

      const match = MatchEntity(
        id: '2002',
        team1: 'Real Madrid',
        team2: 'Barcelona',
        score1: '2',
        score2: '1',
      );

      when(() => mockRepo.startTrackingMatch(
            match: match,
            liveScore1: any(named: 'liveScore1'),
            liveScore2: any(named: 'liveScore2'),
            liveMinute: any(named: 'liveMinute'),
            liveStatus: any(named: 'liveStatus'),
            liveStatusCode: any(named: 'liveStatusCode'),
            livePeriod: any(named: 'livePeriod'),
          )).thenAnswer((_) async => const ApiSuccess(LiveActivityEntity(
            activityId: 'act_2002',
            matchId: '2002',
          )));

      final res = await cubit.startTracking(match: match);
      expect(res, true);
      expect(cubit.state.isTracking('2002'), true);

      await cubit.close();
    });

    test('stopTracking removes matchId from trackedMatchIds', () async {
      final cubit = LiveActivityCubit(repository: mockRepo);
      await Future.delayed(const Duration(milliseconds: 20));

      when(() => mockRepo.stopTrackingMatch('1001'))
          .thenAnswer((_) async => const ApiSuccess(true));

      final res = await cubit.stopTracking('1001');
      expect(res, true);
      expect(cubit.state.isTracking('1001'), false);

      await cubit.close();
    });
  });

  group('LiveActivityRepositoryImpl Tests', () {
    late MockLiveActivityPlatformDataSource mockPlatform;
    late MockLiveActivityRemoteDataSource mockRemote;
    late MockLocalStorageService mockStorage;
    late StreamController<Map<String, dynamic>> tokenRotatedController;
    late StreamController<String> trackingStoppedController;

    setUp(() {
      mockPlatform = MockLiveActivityPlatformDataSource();
      mockRemote = MockLiveActivityRemoteDataSource();
      mockStorage = MockLocalStorageService();
      tokenRotatedController =
          StreamController<Map<String, dynamic>>.broadcast();
      trackingStoppedController = StreamController<String>.broadcast();

      when(() => mockPlatform.onPushTokenRotatedStream)
          .thenAnswer((_) => tokenRotatedController.stream);
      when(() => mockPlatform.onTrackingStoppedStream)
          .thenAnswer((_) => trackingStoppedController.stream);
    });

    tearDown(() {
      tokenRotatedController.close();
      trackingStoppedController.close();
    });

    test('startTrackingMatch formats payload and registers with platform',
        () async {
      final repo = LiveActivityRepositoryImpl(
        platformDataSource: mockPlatform,
        remoteDataSource: mockRemote,
        localStorage: mockStorage,
      );

      const match = MatchEntity(
        id: '3003',
        team1: 'Arsenal',
        team2: 'Chelsea',
        score1: '1',
        score2: '0',
        status: 'مباشر',
        statusCode: 'LIVE',
        minute: "45'",
      );

      when(() => mockPlatform.startLiveActivity(any())).thenAnswer((_) async => {
            'activityId': 'act_3003',
            'pushToken': 'push_token_sample',
          });

      when(() => mockRemote.registerActivity(
            activityId: any(named: 'activityId'),
            matchId: any(named: 'matchId'),
            pushToken: any(named: 'pushToken'),
            platform: any(named: 'platform'),
          )).thenAnswer((_) async => true);

      final result = await repo.startTrackingMatch(match: match);
      expect(result is ApiSuccess, true);

      final entity = (result as ApiSuccess).data as LiveActivityEntity;
      expect(entity.activityId, 'act_3003');
      expect(entity.matchId, '3003');

      verify(() => mockPlatform.startLiveActivity(any())).called(1);
      repo.dispose();
    });
  });
}
