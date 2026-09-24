import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/utils/match_status_helper.dart';
import 'package:score154/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:score154/features/matches/data/models/match_dto.dart';
import 'package:score154/features/matches/data/repositories/matches_repository_impl.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';

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

    test(
      'estimateMatchMinutes returns minute and extraMinute for stoppage time',
      () {
        const kickOff = '20:00';
        // 1st half stoppage (48 mins in -> minute: 45, extra: 3)
        final now1st = DateTime(2026, 9, 9, 20, 48);
        final est1st = MatchStatusHelper.estimateMatchMinutes(
          time: kickOff,
          status: 'الشوط الأول',
          period: '1st_half',
          now: now1st,
        );
        expect(est1st.minute, 45);
        expect(est1st.extraMinute, 3);

        // 2nd half stoppage (108 mins in -> 48 mins into 2nd half -> minute: 90, extra: 3)
        final now2nd = DateTime(2026, 9, 9, 21, 48);
        final est2nd = MatchStatusHelper.estimateMatchMinutes(
          time: kickOff,
          status: 'الشوط الثاني',
          period: '2nd_half',
          now: now2nd,
        );
        expect(est2nd.minute, 90);
        expect(est2nd.extraMinute, 3);
      },
    );

    test('formatExtraTime correctly formats extra time strings', () {
      expect(
        MatchStatusHelper.formatExtraTime('02:00 / 5', minute: 90),
        '02:00  / 5',
      );
      expect(
        MatchStatusHelper.formatExtraTime('5', minute: 90, elapsedSeconds: 120),
        '02:00  / 5',
      );
      expect(
        MatchStatusHelper.formatExtraTime('+00:00 / 5', minute: 90),
        '00:00  / 5',
      );
      expect(MatchStatusHelper.formatExtraTime('0', minute: 90), isNull);
      expect(MatchStatusHelper.formatExtraTime('+00:00', minute: 90), isNull);
    });

    test('getDisplayLabel uses estimated real time when minute is null', () {
      final phase = MatchStatusHelper.parseStatus('الشوط الثاني');
      expect(phase, MatchPhase.live);

      final now = DateTime.now();
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
        minute: null,
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

      expect(find.text('المقاولون العرب'), findsOneWidget);
      expect(find.text('الأهلي'), findsOneWidget);
      expect(find.text('مباشر'), findsNothing);
      expect(find.text("30'"), findsOneWidget);
    });

    testWidgets(
      'MatchCard displays 90 in circular live clock for stoppage time',
      (tester) async {
        const match = MatchEntity(
          id: '124',
          team1: 'كرالوفه',
          team2: 'فيكتوريا بيلزن',
          score1: '0',
          score2: '0',
          status: 'الشوط الثاني',
          statusCode: 'LIVE',
          period: '2nd_half',
          minute: '90',
          extraTime: '02:00 / 5',
        );

        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: [Locale('ar')],
            locale: Locale('ar'),
            home: Scaffold(body: MatchCard(match: match)),
          ),
        );

        await tester.pump();

        expect(find.text('كرالوفه'), findsOneWidget);
        expect(find.text('فيكتوريا بيلزن'), findsOneWidget);
        expect(find.text("90'"), findsOneWidget);
      },
    );

    testWidgets(
      'MatchCard displays calculated 1st half extra time in circular live clock',
      (tester) async {
        // Started 48 minutes ago in 1st half
        final now = DateTime.now();
        final fortyEightMinsAgo = now.subtract(const Duration(minutes: 48));
        final timeStr =
            '${fortyEightMinsAgo.hour.toString().padLeft(2, '0')}:${fortyEightMinsAgo.minute.toString().padLeft(2, '0')}';

        final match = MatchEntity(
          id: '125',
          team1: 'المقاولون العرب',
          team2: 'الأهلي',
          score1: '1',
          score2: '1',
          time: timeStr,
          status: 'الشوط الأول',
          statusCode: 'LIVE',
          period: '1st_half',
          minute: null,
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

        expect(find.text('المقاولون العرب'), findsOneWidget);
        expect(find.text('الأهلي'), findsOneWidget);
        expect(find.textContaining('45'), findsOneWidget);
      },
    );

    testWidgets(
      'MatchCard displays live minute when status is لم تبدأ but kickoff has arrived',
      (tester) async {
        final now = DateTime.now();
        final twentyTwoMinsAgo = now.subtract(const Duration(minutes: 22));
        final timeStr =
            '${twentyTwoMinsAgo.hour.toString().padLeft(2, '0')}:${twentyTwoMinsAgo.minute.toString().padLeft(2, '0')}';

        final match = MatchEntity(
          id: '126',
          team1: 'باريس',
          team2: 'براتيسلافا',
          score1: '1',
          score2: '0',
          time: timeStr,
          status: 'لم تبدأ',
          statusCode: 'UPCOMING',
          minute: null,
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

        // Must display live calculated minute e.g. 22' instead of static kick-off time
        expect(find.text(timeStr), findsNothing);
        expect(find.text("22'"), findsOneWidget);
      },
    );
  });

  group('MatchesRepositoryImpl Live Reconciliation Test', () {
    late MockMatchesRemoteDataSource mockRemoteDataSource;
    late MockLocalStorageService mockLocalStorage;
    late MatchesRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = MockMatchesRemoteDataSource();
      mockLocalStorage = MockLocalStorageService();
      repository = MatchesRepositoryImpl(
        mockRemoteDataSource,
        mockLocalStorage,
      );
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

      final res = await repository.getMatchesByDate(date: todayStr, lang: 'ar');

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
