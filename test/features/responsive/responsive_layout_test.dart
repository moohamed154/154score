import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/core/widgets/error_view.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/live_match_card.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/match_header_banner.dart';
import 'package:score154/features/match_details/presentation/widgets/match_info_card.dart';
import 'package:score154/features/match_details/presentation/widgets/stat_comparison_bar.dart';
import 'package:score154/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:score154/features/standings/domain/entities/standings_entity.dart';
import 'package:score154/features/standings/presentation/widgets/standings_table.dart';
import 'package:score154/features/transfers/domain/entities/transfer_entity.dart';
import 'package:score154/features/transfers/presentation/widgets/transfer_card.dart';
import 'package:score154/features/videos/domain/entities/video_entity.dart';
import 'package:score154/features/videos/presentation/widgets/video_card.dart';

Widget createTestableWidget(
  Widget child, {
  double width = 360.0,
  double height = 800.0,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.dark,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  const screenWidths = [
    320.0,
    360.0,
    375.0,
    390.0,
    414.0,
    600.0,
    768.0,
    1024.0,
  ];

  const sampleMatch = MatchEntity(
    id: '5868013',
    team1: 'سيلتا فيغو دي فيغو الملكي الطويل',
    team2: 'أوساسونا كاسل فالي الرياضي',
    team1Logo: 'https://imgs.ysscores.com/teams/64/9611690196747.png',
    team2Logo: 'https://imgs.ysscores.com/teams/64/7961690196745.png',
    score1: '2',
    score2: '1',
    status: 'الشوط الثاني',
    minute: '68',
    leagueTitle: 'الدوري الإسباني الدرجة الأولى الممتاز',
    isFavorite: true,
  );

  final sampleRows = [
    const StandingRowEntity(
      position: 1,
      teamName: 'مانشستر سيتي الرياضي لكرة القدم',
      teamLogo: 'https://imgs.ysscores.com/teams/64/1.png',
      played: 28,
      wins: 20,
      draws: 5,
      losses: 3,
      goalsFor: 62,
      goalsAgainst: 25,
      goalDiff: 37,
      points: 65,
    ),
    const StandingRowEntity(
      position: 18,
      teamName: 'شيفيلد يونايتد كلوب',
      played: 28,
      wins: 3,
      draws: 5,
      losses: 20,
      goalsFor: 20,
      goalsAgainst: 65,
      goalDiff: -45,
      points: 14,
    ),
  ];

  const sampleTransfer = TransferEntity(
    id: '1',
    playerName: 'كيليان مبابي لوتين دي باريس',
    playerPosition: 'مهاجم صريح / جناح أيسر',
    fromTeamName: 'باريس سان جيرمان الفرنسي',
    toTeamName: 'ريال مدريد الإسباني الملكي',
    fromTeamImage: 'https://imgs.ysscores.com/teams/64/1.png',
    toTeamImage: 'https://imgs.ysscores.com/teams/64/2.png',
    transferPrice: '€180M',
    transferType: 'انتقال حر نهائي',
    date: '2026-07-01',
  );

  group('Responsive Layout Tests across Screen Widths (320px to 1024px)', () {
    for (final width in screenWidths) {
      testWidgets(
        'MatchCard renders without overflow at ${width}px (Arabic & English)',
        (tester) async {
          await tester.pumpWidget(
            createTestableWidget(
              MatchCard(match: sampleMatch, onFavoriteTap: () {}),
              width: width,
              locale: const Locale('ar'),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            createTestableWidget(
              MatchCard(match: sampleMatch, onFavoriteTap: () {}),
              width: width,
              locale: const Locale('en'),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('LiveMatchCard renders without overflow at ${width}px', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestableWidget(
            LiveMatchCard(
              match: sampleMatch,
              width: width > 360 ? 280.0 : width - 32,
            ),
            width: width,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('MatchHeaderBanner renders without overflow at ${width}px', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestableWidget(
            const MatchHeaderBanner(
              match: sampleMatch,
              liveScore1: '2',
              liveScore2: '1',
            ),
            width: width,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('StandingsTable renders without overflow at ${width}px', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestableWidget(StandingsTable(rows: sampleRows), width: width),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'TransferCard renders without overflow at ${width}px (RTL arrow check)',
        (tester) async {
          await tester.pumpWidget(
            createTestableWidget(
              const TransferCard(transfer: sampleTransfer),
              width: width,
              locale: const Locale('ar'),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'TimelineEventItem renders home and away events without overflow',
      (tester) async {
        const homeEvent = MatchEventEntity(
          playerName: 'إيرلينغ براوت هالاند النرويجي',
          secondaryPlayerName: 'تمريرة حاسمة: كيفين دي بروين صانع الألعاب',
          minute: '45+2’',
          type: 'goal',
          isHomeTeam: true,
        );

        const awayEvent = MatchEventEntity(
          playerName: 'فينيسيوس خوسيه بايكساو دي أوليفيرا جونيور',
          minute: '88’',
          type: 'yellow-card',
          isHomeTeam: false,
        );

        await tester.pumpWidget(
          createTestableWidget(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TimelineEventItem(event: homeEvent),
                TimelineEventItem(event: awayEvent),
              ],
            ),
            width: 320.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('StatComparisonBar renders clamped flex percentages safely', (
      tester,
    ) async {
      const stat1 = MatchStatItemEntity(
        title: 'الاستحواذ على الكرة',
        homeValue: '68%',
        awayValue: '32%',
        homePercentage: 0.68,
      );

      const statZero = MatchStatItemEntity(
        title: 'البطاقات الحمراء',
        homeValue: '0',
        awayValue: '0',
        homePercentage: 0.5,
      );

      await tester.pumpWidget(
        createTestableWidget(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatComparisonBar(stat: stat1),
              StatComparisonBar(stat: statZero),
            ],
          ),
          width: 320.0,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'MatchInfoCard renders long descriptions with safe wrapping and RTL chevron',
      (tester) async {
        const section = MatchInfoSectionEntity(
          section: 'معلومات وتفاصيل اللقاء',
          items: [
            MatchInfoItemEntity(
              title: 'الملعب المستضيف',
              content: 'استاد لوسيل الدولي المونديالي الجديد في الدوحة',
            ),
            MatchInfoItemEntity(
              title: 'حكم الساحة',
              content: 'سيمون مارتشينياك البولندي',
            ),
          ],
        );

        await tester.pumpWidget(
          createTestableWidget(
            const MatchInfoCard(section: section),
            width: 320.0,
            locale: const Locale('ar'),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'VideoCard renders both horizontal and vertical without overflow',
      (tester) async {
        const video = VideoItemEntity(
          id: '352509',
          title: 'أهداف وملخص مباراة القمة الكروية المثيرة بالتفصيل الكامل',
          image: 'https://imgs.ysscores.com/news/123.jpg',
          date: 'منذ ساعتين',
        );

        await tester.pumpWidget(
          createTestableWidget(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VideoCard(video: video, isHorizontal: true),
                VideoCard(video: video, isHorizontal: false),
              ],
            ),
            width: 320.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ErrorView gracefully sanitizes 503 upstream errors to Arabic friendly state',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const ErrorView(
              message: 'DioException [bad response]: 503 Service Unavailable',
            ),
            width: 320.0,
            locale: const Locale('ar'),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          find.text('البيانات غير متاحة مؤقتًا، حاول مرة أخرى.'),
          findsOneWidget,
        );
      },
    );
  });
}
