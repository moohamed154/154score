import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/utils/url_helper.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';
import 'package:ysscores/features/match_details/presentation/widgets/match_header_banner.dart';
import 'package:ysscores/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:ysscores/features/matches/domain/entities/match_entity.dart';
import 'package:ysscores/features/matches/presentation/widgets/horizontal_date_selector.dart';
import 'package:ysscores/features/matches/presentation/widgets/match_card.dart';
import 'package:ysscores/features/standings/domain/entities/standings_entity.dart';
import 'package:ysscores/features/standings/presentation/widgets/standings_table.dart';
import 'package:ysscores/features/transfers/domain/entities/transfer_entity.dart';
import 'package:ysscores/features/transfers/presentation/widgets/transfer_card.dart';
import 'package:ysscores/features/videos/domain/entities/video_entity.dart';
import 'package:ysscores/features/videos/presentation/widgets/video_card.dart';

Widget createTestApp(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('154Score V4.7 — Video URL Normalization & Validation Tests', () {
    test('1. Normalize standard HTTPS and HTTP video URLs', () {
      expect(
        UrlHelper.normalizeVideoUrl(
          'https://www.youtube.com/watch?v=h_ZGy005uHY',
        ),
        equals('https://www.youtube.com/watch?v=h_ZGy005uHY'),
      );
      expect(
        UrlHelper.normalizeVideoUrl('http://youtu.be/h_ZGy005uHY'),
        equals('http://youtu.be/h_ZGy005uHY'),
      );
    });

    test('2. Normalize protocol-relative and relative video URLs', () {
      expect(
        UrlHelper.normalizeVideoUrl('//www.youtube.com/embed/12345'),
        equals('https://www.youtube.com/embed/12345'),
      );
      expect(
        UrlHelper.normalizeVideoUrl('/video/352801'),
        equals('https://www.ysscores.com/video/352801'),
      );
    });

    test('3. Extract YouTube watch URL from thumbnail fallback', () {
      const thumb = 'https://i3.ytimg.com/vi/h_ZGy005uHY/hqdefault.jpg';
      final resolved = UrlHelper.normalizeVideoUrl(null, thumbnail: thumb);
      expect(resolved, equals('https://www.youtube.com/watch?v=h_ZGy005uHY'));
    });

    test('4. Reject null, empty, and invalid video URLs safely', () {
      expect(UrlHelper.normalizeVideoUrl(null), isNull);
      expect(UrlHelper.normalizeVideoUrl(''), isNull);
      expect(UrlHelper.normalizeVideoUrl('   '), isNull);
      expect(UrlHelper.normalizeVideoUrl('null'), isNull);
      expect(UrlHelper.normalizeVideoUrl('undefined'), isNull);

      expect(UrlHelper.isValidVideoUrl(null), isFalse);
      expect(UrlHelper.isValidVideoUrl('not-a-url'), isFalse);
      expect(
        UrlHelper.isValidVideoUrl(
          'https://www.youtube.com/watch?v=h_ZGy005uHY',
        ),
        isTrue,
      );
    });
  });

  group('154Score V4.7 — Standings Table & Multi-Group Tests', () {
    testWidgets('5. StandingsTable renders columns and points cleanly', (
      tester,
    ) async {
      const rows = [
        StandingRowEntity(
          position: 1,
          teamName: 'ريال مدريد الملكي',
          played: 38,
          wins: 29,
          draws: 8,
          losses: 1,
          goalsFor: 87,
          goalsAgainst: 26,
          goalDiff: 61,
          points: 95,
          groupName: 'المجموعة A',
        ),
        StandingRowEntity(
          position: 2,
          teamName: 'برشلونة الكتالوني',
          played: 38,
          wins: 26,
          draws: 7,
          losses: 5,
          goalsFor: 79,
          goalsAgainst: 44,
          goalDiff: 35,
          points: 85,
          groupName: 'المجموعة A',
        ),
      ];

      await tester.pumpWidget(
        createTestApp(
          const SingleChildScrollView(child: StandingsTable(rows: rows)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ريال مدريد الملكي'), findsOneWidget);
      expect(find.text('برشلونة الكتالوني'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('+61'), findsOneWidget);
      expect(find.text('+35'), findsOneWidget);
    });

    testWidgets('6. StandingsTable handles empty rows gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const StandingsTable(rows: [])));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('154Score V4.7 — Zero-Overflow Responsive Matrix Tests', () {
    testWidgets('7. Responsive Viewports 320px to 1024px zero-overflow audit', (
      tester,
    ) async {
      final widths = [
        320.0,
        360.0,
        375.0,
        390.0,
        412.0,
        480.0,
        600.0,
        768.0,
        1024.0,
      ];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;

        // 1. Match Card with Live Score & Penalties
        const testMatch = MatchEntity(
          id: '1001',
          team1: 'ريال مدريد الإسباني العريق',
          team2: 'مانشستر سيتي الإنجليزي المتصدر',
          score1: '3',
          score2: '3',
          penaltyScore1: '5',
          penaltyScore2: '4',
          status: 'ركلات الترجيح',
          minute: '120',
          leagueTitle: 'دوري أبطال أوروبا الأدوار الإقصائية',
        );

        // 2. Standings Table with Long Names & Negative GD
        const testRows = [
          StandingRowEntity(
            position: 1,
            teamName: 'نادي بايرن ميونخ الألماني البافاري',
            played: 34,
            wins: 28,
            draws: 4,
            losses: 2,
            goalsFor: 98,
            goalsAgainst: 22,
            goalDiff: 76,
            points: 88,
          ),
          StandingRowEntity(
            position: 18,
            teamName: 'نادي دارمشتات متذيل الترتيب العام',
            played: 34,
            wins: 3,
            draws: 8,
            losses: 23,
            goalsFor: 30,
            goalsAgainst: 86,
            goalDiff: -56,
            points: 17,
          ),
        ];

        // 3. Match Header Banner
        const testHeaderBanner = MatchHeaderBanner(
          match: testMatch,
          liveScore1: '3',
          liveScore2: '3',
          liveStatus: 'مباشر',
          penaltyScore1: '5',
          penaltyScore2: '4',
        );

        // 4. Timeline Event Item (Substitution with long names)
        const testEvent = MatchEventEntity(
          minute: '88+4',
          type: 'substitution',
          playerName: 'فينيسيوس خوسيه بايكساو دي أوليفيرا جونيور',
          secondaryPlayerName: 'لوكا مودريتش أسطورة خط الوسط الكرواتي',
          isHomeTeam: true,
        );

        // 5. Transfer Card with Long Names
        const testTransfer = TransferEntity(
          id: 't1',
          playerName: 'كيليان مبابي لوتين الفرنسي الدولي',
          playerPosition: 'مهاجم صريح / جناح أيسر متقدم',
          fromTeamName: 'نادي باريس سان جيرمان الفرنسي',
          toTeamName: 'نادي ريال مدريد الإسباني الملكي',
          transferPrice: '150,000,000 €',
          transferType: 'انتقال نهائي حر مع مكافأة توقيع قياسية',
          date: '28 أغسطس 2026',
        );

        // 6. Video Card
        const testVideo = VideoItemEntity(
          id: '352801',
          title: 'ملخص وأهداف مباراة ريال مدريد ومانشستر سيتي مع ركلات الترجيح',
          image: 'https://i3.ytimg.com/vi/h_ZGy005uHY/hqdefault.jpg',
          date: '28 أغسطس 2026',
        );

        await tester.pumpWidget(
          createTestApp(
            SingleChildScrollView(
              child: Column(
                children: [
                  HorizontalDateSelector(
                    selectedDate: DateTime.now(),
                    onDateSelected: (_) {},
                  ),
                  const MatchCard(match: testMatch),
                  testHeaderBanner,
                  const StandingsTable(rows: testRows),
                  const TimelineEventItem(event: testEvent),
                  const TransferCard(transfer: testTransfer),
                  const VideoCard(video: testVideo),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on viewport $width px',
        );
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets(
      '8. HorizontalDateSelector zero-overflow at large font scales',
      (tester) async {
        for (final scale in [1.0, 1.25, 1.5, 1.75, 2.0]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: createTestApp(
                HorizontalDateSelector(
                  selectedDate: DateTime.now(),
                  onDateSelected: (_) {},
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            tester.takeException(),
            isNull,
            reason: 'HorizontalDateSelector overflow at font scale $scale',
          );
        }
      },
    );
  });
}
