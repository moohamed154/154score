import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/bloc/match_details_state.dart';
import 'package:score154/features/match_details/presentation/widgets/match_info_card.dart';
import 'package:score154/features/match_details/presentation/widgets/tabs/match_info_tab.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

void main() {
  Widget wrapWidget(Widget child, {Locale locale = const Locale('ar')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('MatchInfoCard Sanitization', () {
    testWidgets('filters out [object Object] items completely', (tester) async {
      const section = MatchInfoSectionEntity(
        section: 'معلومات اللقاء',
        items: [
          MatchInfoItemEntity(title: 'البطولة', content: 'دوري أبطال أفريقيا'),
          MatchInfoItemEntity(
            title: 'ركلات الترجيح',
            content:
                '[object Object],[object Object] - [object Object],[object Object]',
          ),
          MatchInfoItemEntity(title: 'الملعب', content: 'ملعب القاهرة'),
        ],
      );

      await tester.pumpWidget(wrapWidget(const MatchInfoCard(section: section)));
      await tester.pumpAndSettle();

      expect(find.text('دوري أبطال أفريقيا'), findsOneWidget);
      expect(find.text('ملعب القاهرة'), findsOneWidget);
      expect(find.textContaining('[object'), findsNothing);
      expect(find.textContaining('Object]'), findsNothing);
    });

    testWidgets('renders valid penalty shootout score correctly', (tester) async {
      const section = MatchInfoSectionEntity(
        section: 'معلومات اللقاء',
        items: [
          MatchInfoItemEntity(title: 'ركلات الترجيح', content: '2 - 3'),
        ],
      );

      await tester.pumpWidget(wrapWidget(const MatchInfoCard(section: section)));
      await tester.pumpAndSettle();

      expect(find.text('ركلات الترجيح'), findsOneWidget);
      expect(find.text('2 - 3'), findsOneWidget);
    });
  });

  group('MatchInfoTab Penalties Substitution', () {
    testWidgets('substitutes corrupted shootout item with clean score from penaltiesDetail', (tester) async {
      const corruptedSection = MatchInfoSectionEntity(
        section: 'معلومات اللقاء',
        items: [
          MatchInfoItemEntity(title: 'صاحب الأرض', content: 'كايزر تشيفز'),
          MatchInfoItemEntity(title: 'الضيف', content: 'ريد أروز'),
          MatchInfoItemEntity(
            title: 'ركلات الترجيح',
            content: '[object Object],[object Object],[object Object]',
          ),
        ],
      );

      const state = MatchDetailsState(
        matchId: '41871791',
        status: MatchDetailsStatus.success,
        details: [corruptedSection],
        penaltiesDetail: PenaltyShootoutDetailEntity(
          homeScore: '2',
          awayScore: '3',
        ),
      );

      const match = MatchEntity(
        id: '41871791',
        team1: 'كايزر تشيفز',
        team2: 'ريد أروز',
        penaltyScore1: '2',
        penaltyScore2: '3',
      );

      await tester.pumpWidget(
        wrapWidget(
          MatchInfoTab(
            state: state,
            match: match,
            isDark: true,
            isArabic: true,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('[object'), findsNothing);
      expect(find.text('ركلات الترجيح'), findsOneWidget);
      expect(find.text('2 - 3'), findsOneWidget);
    });

    testWidgets('inserts clean penalty shootout if absent from backend items but present in match state', (tester) async {
      const normalSection = MatchInfoSectionEntity(
        section: 'معلومات اللقاء',
        items: [
          MatchInfoItemEntity(title: 'صاحب الأرض', content: 'الأهلي'),
          MatchInfoItemEntity(title: 'الضيف', content: 'الزمالك'),
          MatchInfoItemEntity(title: 'النتيجة الإجمالية', content: '1 - 1'),
        ],
      );

      const state = MatchDetailsState(
        matchId: '12345',
        status: MatchDetailsStatus.success,
        details: [normalSection],
      );

      const match = MatchEntity(
        id: '12345',
        team1: 'الأهلي',
        team2: 'الزمالك',
        penaltyScore1: '4',
        penaltyScore2: '2',
      );

      await tester.pumpWidget(
        wrapWidget(
          MatchInfoTab(
            state: state,
            match: match,
            isDark: true,
            isArabic: true,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ركلات الترجيح'), findsOneWidget);
      expect(find.text('4 - 2'), findsOneWidget);
    });
  });
}
