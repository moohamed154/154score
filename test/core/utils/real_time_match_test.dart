import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/storage/local_storage_service.dart';
import 'package:ysscores/core/utils/match_status_helper.dart';
import 'package:ysscores/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:ysscores/features/matches/data/models/match_dto.dart';
import 'package:ysscores/features/matches/data/repositories/matches_repository_impl.dart';
import 'package:ysscores/features/matches/domain/entities/match_entity.dart';
import 'package:ysscores/features/matches/presentation/widgets/match_card.dart';

class MockMatchesRemoteDataSource extends Mock
    implements MatchesRemoteDataSource {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  group('Real-Time Match Time Calculation Tests', () {
    test('parseTimeToMinutes parses various time formats correctly', () {
      expect(MatchStatusHelper.parseTimeToMinutes('20:00'), 20 * 60);
      expect(MatchStatusHelper.parseTimeToMinutes('20:30'), 20 * 60 + 30);
      expect(MatchStatusHelper.parseTimeToMinutes('08:00 PM'), 20 * 60);
      expect(MatchStatusHelper.parseTimeToMinutes('08:00 ص'), 8 * 60);
      expect(MatchStatusHelper.parseTimeToMinutes('08:00 م'), 20 * 60);
      expect(MatchStatusHelper.parseTimeToMinutes('null'), isNull);
      expect(MatchStatusHelper.parseTimeToMinutes(null), isNull);
      expect(MatchStatusHelper.parseTimeToMinutes('-'), isNull);
    });

    test('estimateMinuteNumber and estimateMinuteFromKickoff for 1st half', () {
      // Match started at 20:00, now is 20:25 (25 mins in)
      const kickOff = '20:00';
      final now = DateTime(2026, 9, 9, 20, 25);

      final minNum = MatchStatusHelper.estimateMinuteNumber(
        time: kickOff,
        status: 'الشوط الأول',
        period: '1st_half',
        now: now,
      );
      expect(minNum, 25);

      final label = MatchStatusHelper.estimateMinuteFromKickoff(
        time: kickOff,
        status: 'الشوط الأول',
        period: '1st_half',
        now: now,
      );
      expect(label, "25'");
    });

    test('estimateMinuteFromKickoff for 1st half extra time', () {
      // Match started at 20:00, now is 20:48 (48 mins in)
      const kickOff = '20:00';
      final now = DateTime(2026, 9, 9, 20, 48);

      final label = MatchStatusHelper.estimateMinuteFromKickoff(
        time: kickOff,
        status: 'الشوط الأول',
        period: '1st_half',
        now: now,
      );
      expect(label, "45' +3'");
    });

    test('estimateMinuteFromKickoff for half-time', () {
      const kickOff = '20:00';
      final now = DateTime(2026, 9, 9, 20, 52);

      final labelAr = MatchStatusHelper.estimateMinuteFromKickoff(
        time: kickOff,
        status: 'استراحة',
        period: 'ht',
        isArabic: true,
        now: now,
      );
      expect(labelAr, 'استراحة');

      final labelEn = MatchStatusHelper.estimateMinuteFromKickoff(
        time: kickOff,
        status: 'HT',
        period: 'ht',
        isArabic: false,
        now: now,
      );
      expect(labelEn, 'HT');
    });

    test('estimateMinuteFromKickoff for 2nd half', () {
      // Match started at 20:00, now is 21:35 (95 mins elapsed, ~35 mins in 2nd half -> 80')
      const kickOff = '20:00';
      final now = DateTime(2026, 9, 9, 21, 35);

      final minNum = MatchStatusHelper.estimateMinuteNumber(
        time: kickOff,
        status: 'الشوط الثاني',
        period: '2nd_half',
        now: now,
      );
      expect(minNum, 80);

      final label = MatchStatusHelper.estimateMinuteFromKickoff(
        time: kickOff,
        status: 'الشوط الثاني',
        period: '2nd_half',
        now: now,
      );
      expect(label, "80'");
    });

    test('getDisplayLabel uses estimated real time when minute is null', () {
      final phase = MatchStatusHelper.parseStatus('الشوط الثاني');
      expect(phase, MatchPhase.live);

      // Suppose kickoff was 20:00 and now is 21:35 (80')
      final now = DateTime.now();
      // Use a time that started 25 minutes ago
      final twentyFiveMinsAgo = now.subtract(const Duration(minutes: 25));
      final timeStr =
          '${twentyFiveMinsAgo.hour.toString().padLeft(2, '0')}:${twentyFiveMinsAgo.minute.toString().padLeft(2, '0')}';

      final label = MatchStatusHelper.getDisplayLabel(
        phase,
        'الشوط الأول',
        time: timeStr,
        period: '1st_half',
        isArabic: true,
      );
      expect(label, isNot('مباشر'));
      expect(label.contains("'"), isTrue);
    });
  });

  group('MatchCard Real-Time Clock Widget Test', () {
    testWidgets('MatchCard displays calculated minute when minute is null', (
      tester,
    ) async {
      final now = DateTime.now();
      final thirtyMinsAgo = now.subtract(const Duration(minutes: 30));
      final timeStr =
          '${thirtyMinsAgo.hour.toString().padLeft(2, '0')}:${thirtyMinsAgo.minute.toString().padLeft(2, '0')}';

      final match = MatchEntity(
        id: '123',
        team1: 'المقاولون العرب',
        team2: 'الأهلي',
        score1: '1',
        score2: '1',
        time: timeStr,
        status: 'الشوط الأول',
        statusCode: 'LIVE',
        period: '1st_half',
        minute: null, // Null in response!
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const [Locale('ar')],
          locale: const Locale('ar'),
          home: Scaffold(body: MatchCard(match: match)),
        ),
      );

      await tester.pump();

      // Expect team names and scores
      expect(find.text('المقاولون العرب'), findsOneWidget);
      expect(find.text('الأهلي'), findsOneWidget);

      // Crucial: It should display real time minute like "30'" rather than generic "مباشر"
      expect(find.text('مباشر'), findsNothing);
      expect(find.textContaining("'"), findsOneWidget);
    });
  });

  group('MatchesRepositoryImpl Live Reconciliation Test', () {
    late MockMatchesRemoteDataSource mockRemoteDataSource;
    late MockLocalStorageService mockLocalStorage;
    late MatchesRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = MockMatchesRemoteDataSource();
      mockLocalStorage = MockLocalStorageService();
      repository = MatchesRepositoryImpl(mockRemoteDataSource, mockLocalStorage);
      when(() => mockLocalStorage.getFavoriteMatches()).thenReturn([]);
    });

    test('reconciles live match minute into today matches', () async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final dateMatches = [
        const LeagueGroupDto(
          leagueTitle: 'دوري ORA',
          matches: [
            MatchDto(
              id: '5996720',
              team1: 'المقاولون العرب',
              team2: 'الأهلي',
              score1: '1',
              score2: '1',
              time: '20:00',
              status: 'الشوط الثاني',
              statusCode: 'LIVE',
              minute: null, // date endpoint has null minute!
            ),
          ],
        ),
      ];

      final liveMatches = [
        const LeagueGroupDto(
          leagueTitle: 'دوري ORA',
          matches: [
            MatchDto(
              id: '5996720',
              team1: 'المقاولون العرب',
              team2: 'الأهلي',
              score1: '1',
              score2: '1',
              time: '20:00',
              status: 'الشوط الثاني',
              statusCode: 'LIVE',
              minute: '81', // live endpoint has official 81' minute!
              period: '2nd_half',
            ),
          ],
        ),
      ];

      when(
        () => mockRemoteDataSource.getMatchesByDate(
          date: todayStr,
          lang: any(named: 'lang'),
          utcOffset: any(named: 'utcOffset'),
          status: any(named: 'status'),
          leagueId: any(named: 'leagueId'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => dateMatches);

      when(
        () => mockRemoteDataSource.getLiveMatches(
          lang: any(named: 'lang'),
          utcOffset: any(named: 'utcOffset'),
          date: any(named: 'date'),
          leagueId: any(named: 'leagueId'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => liveMatches);

      final res = await repository.getMatchesByDate(
        date: todayStr,
        lang: 'ar',
      );

      expect(res.isSuccess, isTrue);
      final leagues = res.dataOrNull!;
      expect(leagues.length, 1);
      final match = leagues.first.matches.first;

      // The live minute must be reconciled!
      expect(match.minute, '81');
      expect(match.period, '2nd_half');
    });
  });
}
