import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/errors/failures.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/utils/match_event_helper.dart';
import 'package:score154/core/utils/match_status_helper.dart';
import 'package:score154/core/widgets/animated_score_text.dart';
import 'package:score154/core/widgets/live_match_clock.dart';
import 'package:score154/core/widgets/penalty_shootout_widget.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/league_section_widget.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';

class _MockStorageForLiveScore implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  Future<bool> registerTeamTitles(Map<String, String> titles) async => true;
  @override
  String resolveTeamTitle(String teamOrId, {bool? isArabic}) => teamOrId;
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
  bool hasCustomFavoriteCompetitions() => false;
  @override
  bool isTeamNotificationEnabled(String teamIdOrName) => false;
  @override
  Future<bool> toggleTeamNotification(String teamIdOrName) async => true;
}

Widget createTestApp(Widget child, {Locale locale = const Locale('ar')}) {
  return BlocProvider<FavoritesCubit>(
    create: (_) => FavoritesCubit(_MockStorageForLiveScore()),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('154Score V4.6 — Live Score Engine & Status Helper Tests', () {
    test('1. MatchStatusHelper correctly identifies all match phases', () {
      expect(
        MatchStatusHelper.parseStatus('مباشر', minute: '67'),
        equals(MatchPhase.live),
      );
      expect(MatchStatusHelper.parseStatus('67\''), equals(MatchPhase.live));
      expect(
        MatchStatusHelper.parseStatus('استراحة'),
        equals(MatchPhase.halfTime),
      );
      expect(MatchStatusHelper.parseStatus('HT'), equals(MatchPhase.halfTime));
      expect(
        MatchStatusHelper.parseStatus('وقت إضافي'),
        equals(MatchPhase.extraTime),
      );
      expect(
        MatchStatusHelper.parseStatus('ركلات الترجيح'),
        equals(MatchPhase.penalties),
      );
      expect(
        MatchStatusHelper.parseStatus('انتهت'),
        equals(MatchPhase.finished),
      );
      expect(MatchStatusHelper.parseStatus('FT'), equals(MatchPhase.finished));
      expect(
        MatchStatusHelper.parseStatus('لم تبدأ', time: '21:00'),
        equals(MatchPhase.upcoming),
      );
      expect(
        MatchStatusHelper.parseStatus('مؤجلة'),
        equals(MatchPhase.postponed),
      );
      expect(
        MatchStatusHelper.parseStatus('ملغاة'),
        equals(MatchPhase.cancelled),
      );
    });

    test(
      '2. MatchStatusHelper correctly prioritizes Live > Upcoming > Finished',
      () {
        final livePri = MatchStatusHelper.getPriority(MatchPhase.live);
        final htPri = MatchStatusHelper.getPriority(MatchPhase.halfTime);
        final upPri = MatchStatusHelper.getPriority(MatchPhase.upcoming);
        final finPri = MatchStatusHelper.getPriority(MatchPhase.finished);

        expect(livePri, equals(0));
        expect(htPri, equals(0));
        expect(upPri, equals(1));
        expect(finPri, equals(2));
        expect(livePri < upPri && upPri < finPri, isTrue);
      },
    );
  });

  group('154Score V4.6 — Event Diff & Deduplication Engine Tests', () {
    test('3. MatchEventHelper merges and sorts events chronologically without duplicates', () {
      final existingEvents = [
        const MatchEventEntity(
          minute: '23',
          type: 'goal',
          playerName: 'فيني جونيور',
          score: '1 - 0',
          isHomeTeam: true,
        ),
        const MatchEventEntity(
          minute: '45+1',
          type: 'yellow_card',
          playerName: 'كارفخال',
          isHomeTeam: true,
        ),
      ];

      final incomingEvents = [
        // Duplicate of event 1
        const MatchEventEntity(
          minute: '23',
          type: 'goal',
          playerName: 'فيني جونيور',
          score: '1 - 0',
          isHomeTeam: true,
        ),
        // New live event
        const MatchEventEntity(
          minute: '67',
          type: 'goal',
          playerName: 'مبابي',
          score: '2 - 0',
          isHomeTeam: true,
        ),
        // Duplicate by minute_type_player
        const MatchEventEntity(
          minute: '23',
          type: 'goal',
          playerName: 'فيني جونيور',
          score: '1 - 0',
          isHomeTeam: true,
        ),
      ];

      final merged = MatchEventHelper.mergeEvents(
        existingEvents: existingEvents,
        incomingEvents: incomingEvents,
      );

      // Should have exactly 3 events (1, 2, 3)
      expect(merged.length, equals(3));
      expect(merged[0].minute, equals('23'));
      expect(merged[1].minute, equals('45+1'));
      expect(merged[2].minute, equals('67'));
      expect(merged[2].playerName, equals('مبابي'));
    });
  });

  group('154Score V4.6 — Live UI Component Widget Tests', () {
    testWidgets('4. LiveMatchClock displays live minute and pulse indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const LiveMatchClock(
            status: 'مباشر',
            minute: '67',
            showLiveDot: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('67:00'), findsOneWidget);
    });

    testWidgets('5. AnimatedScoreText transitions score without layout jump', (
      tester,
    ) async {
      String currentScore = '1';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return createTestApp(
              Column(
                children: [
                  AnimatedScoreText(
                    score: currentScore,
                    isLive: true,
                    isLarge: true,
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => currentScore = '2'),
                    child: const Text('Update'),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
      '6. PenaltyShootoutWidget handles detailed dots and compact mode',
      (tester) async {
        // 1. Detailed Shootout
        await tester.pumpWidget(
          createTestApp(
            const PenaltyShootoutWidget(
              penaltyScore1: '5',
              penaltyScore2: '4',
              attempts1: [true, true, true, true, true],
              attempts2: [true, true, true, true, false],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('5 : 4'), findsOneWidget);
        expect(find.text('ركلات الترجيح'), findsOneWidget);

        // 2. Compact Shootout
        await tester.pumpWidget(
          createTestApp(
            const PenaltyShootoutWidget(
              penaltyScore1: '4',
              penaltyScore2: '3',
              isCompact: true,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('4 - 3'), findsOneWidget);
        expect(find.text('ر.ت '), findsOneWidget);
      },
    );

    testWidgets(
      '7. MatchCard renders live match with live clock and animated score',
      (tester) async {
        const liveMatch = MatchEntity(
          id: '101',
          team1: 'ريال مدريد',
          team2: 'برشلونة',
          score1: '2',
          score2: '1',
          status: 'مباشر',
          minute: '78',
          leagueTitle: 'الدوري الإسباني',
        );

        await tester.pumpWidget(
          createTestApp(const MatchCard(match: liveMatch)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('ريال مدريد'), findsOneWidget);
        expect(find.text('برشلونة'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('78:00'), findsOneWidget);
      },
    );

    testWidgets(
      '8. TimelineEventItem renders goals, cards, and substitutions cleanly',
      (tester) async {
        const subEvent = MatchEventEntity(
          minute: '60',
          type: 'substitution',
          playerName: 'لوكا مودريتش',
          secondaryPlayerName: 'توني كروس',
          isHomeTeam: true,
        );

        await tester.pumpWidget(
          createTestApp(const TimelineEventItem(event: subEvent)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('لوكا مودريتش'), findsOneWidget);
        expect(find.text('توني كروس'), findsOneWidget);
        expect(find.text("60'"), findsOneWidget);
      },
    );
  });

  group('154Score V4.6 — Responsive Validation & Error State Tests', () {
    testWidgets('9. Responsive Breakpoint Validation across 320px to 1024px', (
      tester,
    ) async {
      final widths = [320.0, 360.0, 375.0, 390.0, 412.0, 600.0, 768.0, 1024.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;

        const league = LeagueGroupEntity(
          leagueTitle: 'دوري أبطال أوروبا الممتاز للأندية النخبة',
          matches: [
            MatchEntity(
              id: '1',
              team1: 'ريال مدريد الإسباني الملكي',
              team2: 'مانشستر سيتي الإنجليزي السماوي',
              score1: '3',
              score2: '3',
              penaltyScore1: '4',
              penaltyScore2: '3',
              status: 'مباشر',
              minute: '88',
            ),
          ],
        );

        await tester.pumpWidget(
          createTestApp(
            const SingleChildScrollView(
              child: LeagueSectionWidget(league: league),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
    });

    test(
      '10. Semantic API Failure mappings verify 429, 503, timeout, and network',
      () {
        const rateLimit = RateLimitFailure('Too many requests');
        const upstream = UpstreamUnavailableFailure('Service busy');
        const timeout = TimeoutFailure('Connection timed out');
        const network = NetworkFailure('No internet connection');

        expect(rateLimit.statusCode, equals(429));
        expect(upstream.statusCode, equals(503));
        expect(timeout.message, contains('timed out'));
        expect(network.message, contains('internet'));
      },
    );
  });
}
