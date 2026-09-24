import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/utils/match_event_helper.dart';
import 'package:score154/core/utils/match_status_helper.dart';
import 'package:score154/core/utils/score_helper.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/lineup/pitch_player_node.dart';
import 'package:score154/features/match_details/presentation/widgets/match_header_banner.dart';
import 'package:score154/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

void main() {
  group('Live vs Finished Match Status & Banner Tests', () {
    test('ScoreHelper.isFinishedStatus returns false for live matches and half-time', () {
      expect(ScoreHelper.isFinishedStatus('مباشر'), isFalse);
      expect(ScoreHelper.isFinishedStatus('الشوط الثاني'), isFalse);
      expect(ScoreHelper.isFinishedStatus('الشوط الأول'), isFalse);
      expect(ScoreHelper.isFinishedStatus('live'), isFalse);
      expect(ScoreHelper.isFinishedStatus('نهاية الشوط الأول'), isFalse);
      expect(ScoreHelper.isFinishedStatus('انتهت'), isTrue);
      expect(ScoreHelper.isFinishedStatus('FT'), isTrue);
      expect(ScoreHelper.isFinishedStatus('ended'), isTrue);
    });

    test('MatchStatusHelper.parseStatus correctly distinguishes half-time and live from finished', () {
      // 1. Half-time variations
      expect(
        MatchStatusHelper.parseStatus('نهاية الشوط الأول'),
        equals(MatchPhase.halfTime),
      );
      expect(
        MatchStatusHelper.parseStatus('نهاية الشوط'),
        equals(MatchPhase.halfTime),
      );
      expect(
        MatchStatusHelper.parseStatus('استراحة'),
        equals(MatchPhase.halfTime),
      );

      // 2. Live match variations
      expect(
        MatchStatusHelper.parseStatus(
          'الشوط الثاني',
          minute: '62',
          statusCode: 'LIVE',
          period: '2nd_half',
        ),
        equals(MatchPhase.live),
      );
      expect(
        MatchStatusHelper.parseStatus('مباشر', minute: '62'),
        equals(MatchPhase.live),
      );

      // 3. Truly finished match
      expect(
        MatchStatusHelper.parseStatus('انتهت', statusCode: 'FINISHED'),
        equals(MatchPhase.finished),
      );
      expect(
        MatchStatusHelper.parseStatus('نهاية المباراة'),
        equals(MatchPhase.finished),
      );
    });

    testWidgets(
      'Live match with 1st half end event in timeline does NOT show "انتهت"',
      (tester) async {
        const liveMatch = MatchEntity(
          id: '12345',
          team1: 'هوفنهايم',
          team2: 'بادربورن',
          score1: '1',
          score2: '2',
          status: 'الشوط الثاني',
          statusCode: 'LIVE',
          minute: '62',
          period: '2nd_half',
          time: '20:30',
          date: '2026-09-20',
        );

        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Scaffold(
              body: MatchHeaderBanner(
                match: liveMatch,
                liveScore1: '1',
                liveScore2: '2',
                liveStatus: 'الشوط الثاني',
                liveStatusCode: 'LIVE',
                liveMinute: '62',
                livePeriod: '2nd_half',
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Ensure "انتهت" is NOT displayed anywhere in the banner for this live match
        expect(find.text('انتهت'), findsNothing);
      },
    );

    testWidgets('Finished match correctly displays "انتهت" center pill', (
      tester,
    ) async {
      const finishedMatch = MatchEntity(
        id: '67890',
        team1: 'هوفنهايم',
        team2: 'بادربورن',
        score1: '1',
        score2: '2',
        status: 'انتهت',
        statusCode: 'FINISHED',
        time: '20:30',
        date: '2026-09-20',
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: MatchHeaderBanner(
              match: finishedMatch,
              liveScore1: '1',
              liveScore2: '2',
              liveStatus: 'انتهت',
              liveStatusCode: 'FINISHED',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Ensure "انتهت" IS displayed for truly finished match
      expect(find.text('انتهت'), findsOneWidget);
    });

    test('MatchEventHelper normalizes minute 120 to 90 for 90-minute matches without extra time', () {
      final rawEvents = [
        const MatchEventEntity(
          minute: '0',
          playerName: 'بداية الشوط الأول',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '45',
          playerName: 'نهاية الشوط الأول',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '45',
          playerName: 'بداية الشوط الثاني',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '80',
          playerName: 'محمد صلاح',
          type: 'goal',
          isHomeTeam: true,
        ),
        const MatchEventEntity(
          minute: '90+4',
          playerName: 'ليروي سانيه',
          type: 'yellow_card',
          isHomeTeam: true,
        ),
        const MatchEventEntity(
          minute: '120',
          playerName: 'نهاية المباراة',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
      ];

      expect(MatchEventHelper.detectExtraTime(rawEvents), isFalse);

      final normalized = MatchEventHelper.normalizeEvents(rawEvents);
      final ftEvent = normalized.firstWhere(
        (e) => e.playerName == 'نهاية المباراة',
      );

      expect(ftEvent.minute, equals('90'));

      // Check sorting weight preserves end of match placement after 90+4
      final merged = MatchEventHelper.mergeEvents(
        existingEvents: normalized,
        incomingEvents: [],
      );
      expect(merged.last.playerName, equals('نهاية المباراة'));
      expect(merged.last.minute, equals('90'));
    });

    test('MatchEventHelper preserves minute 120 when match actually played extra time', () {
      final extraTimeEvents = [
        const MatchEventEntity(
          minute: '0',
          playerName: 'بداية الشوط الأول',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '90',
          playerName: 'نهاية الوقت الأصلي',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '90',
          playerName: 'بداية الشوط الإضافي الأول',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '105',
          playerName: 'نهاية الشوط الإضافي الأول',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
        const MatchEventEntity(
          minute: '112',
          playerName: 'هدف في الوقت الإضافي',
          type: 'goal',
          isHomeTeam: false,
        ),
        const MatchEventEntity(
          minute: '120',
          playerName: 'نهاية المباراة',
          type: 'start-end-match',
          isPeriodMarker: true,
        ),
      ];

      expect(MatchEventHelper.detectExtraTime(extraTimeEvents), isTrue);

      final normalized = MatchEventHelper.normalizeEvents(extraTimeEvents);
      final ftEvent = normalized.firstWhere(
        (e) => e.playerName == 'نهاية المباراة',
      );

      expect(ftEvent.minute, equals('120'));
    });

    testWidgets(
      'TimelineEventItem renders 90 for normalized full-time marker instead of 120',
      (tester) async {
        const event90 = MatchEventEntity(
          minute: '90',
          playerName: 'نهاية المباراة',
          type: 'start-end-match',
          isPeriodMarker: true,
        );

        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Scaffold(body: TimelineEventItem(event: event90)),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('نهاية المباراة'), findsOneWidget);
        expect(find.text('(90\')'), findsOneWidget);
        expect(find.text('(120\')'), findsNothing);
      },
    );

    testWidgets('TimelineEventItem renders 120 when match had extra time', (
      tester,
    ) async {
      const event120 = MatchEventEntity(
        minute: '120',
        playerName: 'نهاية المباراة',
        type: 'start-end-match',
        isPeriodMarker: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: TimelineEventItem(event: event120)),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('نهاية المباراة'), findsOneWidget);
      expect(find.text('(120\')'), findsOneWidget);
    });

    testWidgets(
      'Starter subbed out displays "تم استبداله" and NEVER "شارك كبديل"',
      (tester) async {
        const starterSalah = LineupPlayerEntity(
          playerId: '10',
          name: 'محمد صلاح',
          shortName: 'صلاح',
          number: 10,
          position: 'مهاجم',
          positionCode: 'F',
          isStarter: true,
          isSubstitute: false,
          substituteOut: true,
          substituteIn: false,
          substituteTime: 89,
          subbedForName: 'أرال سيمسير',
        );

        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Scaffold(
              body: Center(
                child: PitchPlayerNode(player: starterSalah, isHome: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on player to open bottom sheet
        await tester.tap(find.byType(PitchPlayerNode));
        await tester.pumpAndSettle();

        // Verify "تم استبداله" badge is displayed with subbed time
        expect(find.textContaining('تم استبداله'), findsOneWidget);

        // Verify "شارك كبديل" badge is NEVER displayed for starter
        expect(find.textContaining('شارك كبديل'), findsNothing);
      },
    );

    testWidgets(
      'Bench substitute subbed in displays "شارك كبديل" and NEVER "تم استبداله"',
      (tester) async {
        const subSimsir = LineupPlayerEntity(
          playerId: '19',
          name: 'أرال سيمسير',
          shortName: 'سيمسير',
          number: 19,
          position: 'مهاجم',
          positionCode: 'SUB',
          isStarter: false,
          isSubstitute: true,
          substituteIn: true,
          substituteOut: false,
          substituteTime: 89,
          subbedForName: 'محمد صلاح',
        );

        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Scaffold(
              body: Center(
                child: PitchPlayerNode(player: subSimsir, isHome: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on player to open bottom sheet
        await tester.tap(find.byType(PitchPlayerNode));
        await tester.pumpAndSettle();

        // Verify "شارك كبديل" badge is displayed
        expect(find.textContaining('شارك كبديل'), findsOneWidget);

        // Verify "تم استبداله" badge is NOT displayed
        expect(find.textContaining('تم استبداله'), findsNothing);
      },
    );
  });
}
