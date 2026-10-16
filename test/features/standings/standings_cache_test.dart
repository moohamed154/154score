import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/errors/exceptions.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/standings/data/datasources/standings_remote_datasource.dart';
import 'package:score154/features/standings/data/repositories/standings_repository_impl.dart';
import 'package:score154/features/standings/domain/entities/standings_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Standings Caching Unit & Integration Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;
    late MockApiClient mockApiClient;
    late StandingsRemoteDataSource remoteDataSource;
    late StandingsRepositoryImpl repository;

    final dummyStandingsJson = {
      'data': {
        'league_name': 'Premier League',
        'table': [
          {
            'position': 1,
            'team_name': 'Arsenal',
            'team_id': '1234',
            'played': 10,
            'wins': 8,
            'draws': 1,
            'losses': 1,
            'goals_for': 24,
            'goals_against': 8,
            'goal_difference': 16,
            'points': 25,
          },
          {
            'position': 2,
            'team_name': 'Manchester City',
            'team_id': '5678',
            'played': 10,
            'wins': 7,
            'draws': 2,
            'losses': 1,
            'goals_for': 22,
            'goals_against': 9,
            'goal_difference': 13,
            'points': 23,
          }
        ]
      }
    };

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageServiceImpl(prefs);
      mockApiClient = MockApiClient();
      remoteDataSource = StandingsRemoteDataSourceImpl(mockApiClient, storage);
      repository = StandingsRepositoryImpl(remoteDataSource, storage);
    });

    test(
        '1. LocalStorageService persists and retrieves league standings cache per language',
        () async {
      const leagueId = '937599';
      final jsonStr = jsonEncode(dummyStandingsJson);

      expect(storage.getCachedLeagueStandings(leagueId, lang: 'ar'), isNull);

      final saved =
          await storage.setCachedLeagueStandings(leagueId, jsonStr, lang: 'ar');
      expect(saved, isTrue);

      final retrieved = storage.getCachedLeagueStandings(leagueId, lang: 'ar');
      expect(retrieved, equals(jsonStr));

      // Separate language isolation
      expect(storage.getCachedLeagueStandings(leagueId, lang: 'en'), isNull);
    });

    test(
        '2. StandingsRemoteDataSource caches response and recovers from cache on network failure',
        () async {
      const leagueId = '937599';

      when(() => mockApiClient.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => dummyStandingsJson);

      final result = await remoteDataSource.getStandings(leagueId, lang: 'ar');
      expect(result.rows.length, equals(2));
      expect(result.rows.first.teamName, equals('Arsenal'));

      // Verify that cache was populated in storage
      final cached = storage.getCachedLeagueStandings(leagueId, lang: 'ar');
      expect(cached, isNotNull);

      // Now simulate network failure
      when(() => mockApiClient.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(const NetworkException('No internet connection'));

      // Remote data source gracefully recovers from cache
      final offlineResult =
          await remoteDataSource.getStandings(leagueId, lang: 'ar');
      expect(offlineResult.rows.length, equals(2));
      expect(offlineResult.rows[1].teamName, equals('Manchester City'));
    });

    test(
        '3. StandingsRepositoryImpl returns cached entity and recovers offline with ApiSuccess',
        () async {
      const leagueId = '937599';

      // Pre-seed storage cache
      await storage.setCachedLeagueStandings(
          leagueId, jsonEncode(dummyStandingsJson),
          lang: 'ar');

      // Make network throw ServerException
      when(() => mockApiClient.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(const ServerException('Upstream 503', statusCode: 503));

      final repoResult = await repository.getStandings(leagueId, lang: 'ar');
      expect(repoResult, isA<ApiSuccess<LeagueStandingsEntity>>());

      final entity = (repoResult as ApiSuccess<LeagueStandingsEntity>).data;
      expect(entity.rows.length, equals(2));
      expect(entity.rows.first.teamName, equals('Arsenal'));
      expect(entity.rows.first.points, equals(25));
    });

    test(
        '4. StandingsRepositoryImpl serves in-memory cache on subsequent requests within 5 minutes',
        () async {
      const leagueId = '937599';

      when(() => mockApiClient.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => dummyStandingsJson);

      final firstCall = await repository.getStandings(leagueId, lang: 'ar');
      expect(firstCall, isA<ApiSuccess<LeagueStandingsEntity>>());

      // Verify client was called once
      verify(() => mockApiClient.get(any(),
          queryParameters: any(named: 'queryParameters'))).called(1);

      // Second call should hit memory cache immediately without calling API client again
      final secondCall = await repository.getStandings(leagueId, lang: 'ar');
      expect(secondCall, isA<ApiSuccess<LeagueStandingsEntity>>());
      verifyNever(() => mockApiClient.get(any(),
          queryParameters: any(named: 'queryParameters')));
    });
  });
}
