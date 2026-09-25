import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/constants/api_endpoints.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/leagues/data/datasources/leagues_remote_datasource.dart';
import 'package:score154/features/leagues/data/repositories/leagues_repository_impl.dart';
import 'package:score154/features/leagues/presentation/bloc/league_bloc.dart';
import 'package:score154/features/leagues/presentation/bloc/league_state.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/standings/data/datasources/standings_remote_datasource.dart';

class MockLocalStorageService implements LocalStorageService {
  @override
  Future<void> init() async {}
  @override
  String getLanguage() => 'ar';
  @override
  Future<bool> setLanguage(String langCode) async => true;
  @override
  String getThemeMode() => 'dark';
  @override
  Future<bool> setThemeMode(String themeMode) async => true;
  @override
  String getTimeFormat() => '24h';
  @override
  Future<bool> setTimeFormat(String format) async => true;
  @override
  int getTimezoneOffset() => 0;
  @override
  Future<bool> setTimezoneOffset(int offset) async => true;
  @override
  bool isTimezoneAuto() => true;
  @override
  Future<bool> setTimezoneAuto(bool isAuto) async => true;
  @override
  int getDeviceTimezoneOffset() => 3;
  @override
  List<String> getFavoriteTeams() => [];
  @override
  Future<bool> toggleFavoriteTeam(String teamName, {String? id}) async => true;
  @override
  bool isFavoriteTeam(String teamName, {String? id}) => false;
  @override
  Map<String, String> getFavoriteTeamTitles() => {};
  @override
  Future<bool> registerTeamTitles(Map<String, String> idToTitle) async => true;
  @override
  String resolveTeamTitle(String teamId, {bool? isArabic}) => teamId;
  @override
  List<String> getFavoriteCompetitions() => [];
  @override
  Future<bool> toggleFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) async => true;
  @override
  bool isFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) => false;
  @override
  Map<String, String> getFavoriteCompetitionTitles() => {};
  @override
  Future<bool> registerCompetitionTitles(Map<String, String> titles) async =>
      true;
  @override
  String resolveCompetitionTitle(String compOrId) => compOrId;
  @override
  List<String> getFavoriteMatches() => [];
  @override
  Future<bool> toggleFavoriteMatch(String matchId) async => true;
  @override
  bool isFavoriteMatch(String matchId) => false;
  @override
  Future<bool> setFavoriteCompetitions(List<String> list) async => true;
  @override
  String? getCachedRankings({String? lang}) => null;
  @override
  Future<bool> setCachedRankings(String json, {String? lang}) async => true;
  @override
  bool isReorderTipDismissed() => true;
  @override
  bool hasCustomFavoriteCompetitions() => false;
  @override
  Future<bool> setReorderTipDismissed(bool dismissed) async => true;
  @override
  String? getMatchesFilter() => null;
  @override
  Future<bool> setMatchesFilter(String filter) async => true;
  @override
  String? getMatchesSortOrder() => null;
  @override
  Future<bool> setMatchesSortOrder(String sortOrder) async => true;
  @override
  bool isTeamNotificationEnabled(String teamIdOrName) => false;
  @override
  Future<bool> toggleTeamNotification(String teamIdOrName) async => true;
}

class FakeWebSocketService extends Mock implements WebSocketService {
  final _controller = StreamController<LiveMatchUpdate>.broadcast();

  void emitUpdate(LiveMatchUpdate update) {
    _controller.add(update);
  }

  @override
  Stream<LiveMatchUpdate> get liveMatchesStream => _controller.stream;
  @override
  Stream<LiveMatchUpdate> get updatesStream => _controller.stream;
  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  late ApiClient apiClient;
  late StandingsRemoteDataSource standingsDataSource;
  late LeaguesRemoteDataSource leaguesDataSource;
  late LeaguesRepositoryImpl repository;
  late MockLocalStorageService storageService;

  setUpAll(() {
    apiClient = ApiClient();
    standingsDataSource = StandingsRemoteDataSourceImpl(apiClient);
    leaguesDataSource = LeaguesRemoteDataSourceImpl(
      apiClient,
      standingsDataSource,
    );
    repository = LeaguesRepositoryImpl(leaguesDataSource);
    storageService = MockLocalStorageService();
  });

  group('154Score Leagues API & Realtime WebSocket Tests', () {
    test('1. Verify League Endpoints URLs', () {
      expect(ApiEndpoints.rank, '/api/rank');
      expect(ApiEndpoints.leagues, '/api/leagues');
      expect(ApiEndpoints.leagueProfile('938652'), '/api/leagues/938652');
      expect(
        ApiEndpoints.leagueStandings('938652'),
        '/api/leagues/938652/standings',
      );
      expect(
        ApiEndpoints.leagueTopScorers('938652'),
        '/api/leagues/938652/top-scorers',
      );
      expect(
        ApiEndpoints.leagueMatches('938652'),
        '/api/leagues/938652/matches',
      );
    });

    test('1.1. Live API: GET /api/rank (getRankingsList)', () async {
      final res = await apiClient.get(
        ApiEndpoints.rank,
        queryParameters: {'lang': 'ar'},
      );
      expect(res, isNotNull);
      final map = res as Map<String, dynamic>;
      expect(map['success'], isTrue);
      final data = map['data'] as Map<String, dynamic>;
      expect(data['featured'], isA<List>());
      expect(data['leagues'], isA<List>());
      expect((data['featured'] as List).isNotEmpty, isTrue);
    });

    test('2. Live API: GET /api/leagues/{id} (Profile Overview)', () async {
      final res = await repository.getLeagueProfile('938652', lang: 'ar');
      expect(res.isSuccess, isTrue);
      if (res.dataOrNull != null) {
        expect(res.dataOrNull, isA<Map>());
      }
    });

    test('3. Live API: GET /api/leagues/{id}/standings', () async {
      final res = await repository.getLeagueStandings('938652', lang: 'ar');
      expect(res.isSuccess, isTrue);
      final standings = res.dataOrNull!;
      expect(standings.leagueId, '938652');
      expect(standings.rows, isNotEmpty);
      expect(standings.rows.first.teamName, isNotEmpty);
      expect(standings.rows.first.position, 1);
    });

    test('4. Live API: GET /api/leagues/{id}/top-scorers', () async {
      final res = await repository.getLeagueTopScorers('938652', lang: 'ar');
      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull, isA<List>());
    });

    test('5. Live API: GET /api/matches with league_id filter', () async {
      final res = await repository.getLeagueMatches('938652', lang: 'ar');
      expect(res.isSuccess, isTrue);
      final matches = res.dataOrNull!;
      expect(matches, isA<List>());
      if (matches.isNotEmpty) {
        expect(matches.first.team1, isNotEmpty);
        expect(matches.first.team2, isNotEmpty);
      }
    });

    test(
      '5. Real-Time WebSocket: LeagueBloc updates live match in real time',
      () async {
        final fakeWs = FakeWebSocketService();
        final bloc = LeagueBloc(
          repository: repository,
          localStorageService: storageService,
          webSocketService: fakeWs,
          leagueId: '938652',
        );

        // Seed with sample initial match
        bloc.emit(
          const LeagueState(
            leagueId: '938652',
            status: LeagueStatus.success,
            matches: [
              MatchEntity(
                id: '5868040',
                team1: 'إشبيلية',
                team2: 'أتلتيكو مدريد',
                score1: '0',
                score2: '0',
                status: 'مباشر',
                statusCode: 'LIVE',
                minute: '10',
              ),
            ],
          ),
        );

        // Emit real-time WebSocket goal update
        fakeWs.emitUpdate(
          const LiveMatchUpdate(
            matchId: '5868040',
            team1: 'إشبيلية',
            team2: 'أتلتيكو مدريد',
            score1: '1',
            score2: '3',
            status: 'الشوط الثاني',
            statusCode: 'LIVE',
            minute: '69',
            period: '2nd_half',
            extraTime: '+00:00',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.matches.first.score1, '1');
        expect(bloc.state.matches.first.score2, '3');
        expect(bloc.state.matches.first.status, 'الشوط الثاني');
        expect(bloc.state.matches.first.minute, '69');
        expect(bloc.state.matches.first.period, '2nd_half');

        await bloc.close();
        fakeWs.dispose();
      },
    );
  });
}
