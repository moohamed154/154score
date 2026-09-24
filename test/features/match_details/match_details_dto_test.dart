import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/features/match_details/data/datasources/match_details_remote_datasource.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late MatchDetailsRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = MatchDetailsRemoteDataSourceImpl(mockApiClient);
  });

  group('MatchDetailsRemoteDataSource V4.2 Parsing Tests', () {
    test('getEvents parses V4.2 events correctly (team-a/b, text, subtitle, minute)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'section': 'الأحداث',
              'items': {
                'all_events': [
                  {
                    'is_start_end': false,
                    'team': 'team-a',
                    'time': '14’',
                    'minute': 14,
                    'text': 'اياغو أسباس',
                    'subtitle': 'ميغيل رومان',
                    'type': 'goal',
                  },
                  {
                    'is_start_end': false,
                    'team': 'team-b',
                    'time': '64’',
                    'minute': 64,
                    'text': 'أنتي بوديمير',
                    'subtitle': 'ضربة جزاء',
                    'type': 'goal',
                  },
                ],
              },
            },
          ],
        },
      );

      final events = await dataSource.getEvents('5868013', lang: 'ar');

      expect(events.length, 2);
      expect(events[0].playerName, 'اياغو أسباس');
      expect(events[0].secondaryPlayerName, 'ميغيل رومان');
      expect(events[0].isHomeTeam, isTrue);
      expect(events[0].minute, '14');
      expect(events[0].type, 'goal');

      expect(events[1].playerName, 'أنتي بوديمير');
      expect(events[1].secondaryPlayerName, 'ضربة جزاء');
      expect(events[1].isHomeTeam, isFalse);
    });

    test('getStats parses V4.2 sectioned statistics with accurate percentage and no NaN', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'section': 'الهجوم',
              'items': [
                {
                  'title': 'الاستحواذ',
                  'team_a': '54 %',
                  'team_b': '46 %',
                  'team_a_val': 54,
                  'team_b_val': 46,
                },
                {
                  'title': 'التسديدات',
                  'team_a': '1',
                  'team_b': '10',
                  'team_a_val': 1,
                  'team_b_val': 10,
                },
              ],
            },
          ],
        },
      );

      final stats = await dataSource.getStats('5868013', lang: 'ar');

      expect(stats.length, 2);
      expect(stats[0].title, 'الاستحواذ');
      expect(stats[0].homeValue, '54 %');
      expect(stats[0].awayValue, '46 %');
      expect(stats[0].homePercentage, closeTo(0.54, 0.01));
      expect(stats[0].homePercentage.isNaN, isFalse);

      expect(stats[1].title, 'التسديدات');
      expect(stats[1].homeValue, '1');
      expect(stats[1].awayValue, '10');
      expect(stats[1].homePercentage, closeTo(0.09, 0.01));
    });

    test('getDetails parses section items safely', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'section': 'معلومات اللقاء',
              'items': [
                {'title': 'القناة', 'content': 'بي إن سبورت 8'},
                {'title': 'المعلق', 'content': 'منتصر الأزهري'},
              ],
            },
          ],
        },
      );

      final details = await dataSource.getDetails('5868013', lang: 'ar');

      expect(details.length, 1);
      expect(details[0].section, 'معلومات اللقاء');
      expect(details[0].items.length, 2);
      expect(details[0].items[0].title, 'القناة');
      expect(details[0].items[0].content, 'بي إن سبورت 8');
    });

    test('getEventsPayload parses match summary, goals, and goal clips accurately', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'section': 'الأحداث',
              'items': {
                'has_video': true,
                'match_summary': {
                  'type': 14,
                  'category': 'alternative_summary',
                  'title': 'ملخص إضافي',
                  'url': 'https://www.youtube.com/watch?v=uBkxy7BTsZs',
                },
                'match_goals': null,
                'video_links': [
                  {
                    'type': 14,
                    'category': 'alternative_summary',
                    'title': 'ملخص إضافي',
                    'url': 'https://www.youtube.com/watch?v=uBkxy7BTsZs',
                  },
                ],
                'videos': {
                  'has_video': true,
                  'summary': {
                    'type': 14,
                    'category': 'alternative_summary',
                    'title': 'ملخص إضافي',
                    'url': 'https://www.youtube.com/watch?v=uBkxy7BTsZs',
                  },
                  'goals': null,
                  'full_match': null,
                  'all': [
                    {
                      'type': 14,
                      'category': 'alternative_summary',
                      'title': 'ملخص إضافي',
                      'url': 'https://www.youtube.com/watch?v=uBkxy7BTsZs',
                    },
                  ],
                  'goal_clips': [
                    {
                      'event_id': '72147417',
                      'player_name': 'سيرجينيو ديست',
                      'team': 'team-a',
                      'time': "48'",
                      'minute': 48,
                      'type': 'goal',
                      'video_url':
                          'https://x.com/beINSPORTS/status/2098108413574004793',
                    },
                    {
                      'event_id': '72147394',
                      'player_name': 'جليكير ميندوزا',
                      'team': 'team-b',
                      'time': "45+1'",
                      'minute': 45,
                      'type': 'goal',
                      'video_url':
                          'https://x.com/beINSPORTS/status/2098107791181304245',
                    },
                  ],
                },
                'all_events': [
                  {
                    'is_start_end': false,
                    'team': 'team-a',
                    'time': "48'",
                    'minute': 48,
                    'text': 'سيرجينيو ديست',
                    'type': 'goal',
                    'video_url':
                        'https://x.com/beINSPORTS/status/2098108413574004793',
                  },
                ],
              },
            },
          ],
        },
      );

      final payload = await dataSource.getEventsPayload('6106304', lang: 'ar');

      expect(payload.events.length, 1);
      expect(payload.events[0].playerName, 'سيرجينيو ديست');
      expect(
        payload.events[0].videoUrl,
        'https://x.com/beINSPORTS/status/2098108413574004793',
      );

      expect(payload.videos.hasVideo, isTrue);
      expect(payload.videos.summary?.title, 'ملخص إضافي');
      expect(
        payload.videos.summary?.url,
        'https://www.youtube.com/watch?v=uBkxy7BTsZs',
      );

      expect(payload.videos.goalClips.length, 2);
      expect(payload.videos.goalClips[0].playerName, 'سيرجينيو ديست');
      expect(
        payload.videos.goalClips[0].url,
        'https://x.com/beINSPORTS/status/2098108413574004793',
      );

      final chips = payload.videos.allChips;
      expect(chips.length, 3);
      expect(chips[0].title, 'ملخص إضافي');
      expect(chips[1].title, contains('سيرجينيو ديست'));
      expect(chips[2].title, contains('جليكير ميندوزا'));
    });

    test('when has_video is false, MatchVideosEntity hasVideo is false and allChips is empty', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'section': 'الأحداث',
              'items': {
                'has_video': false,
                'match_summary': null,
                'match_goals': null,
                'video_links': [],
                'videos': {
                  'has_video': false,
                  'summary': null,
                  'goals': null,
                  'full_match': null,
                  'all': [],
                  'goal_clips': [],
                },
                'all_events': [],
              },
            },
          ],
        },
      );

      final payload = await dataSource.getEventsPayload('123456', lang: 'ar');

      expect(payload.videos.hasVideo, isFalse);
      expect(payload.videos.allChips, isEmpty);
      expect(payload.videos.isEmpty, isTrue);
      expect(payload.videos.isNotEmpty, isFalse);
    });

    test(
      'news parsing drops items with تحميل تطبيق يلا شووت and download links',
      () async {
        when(
          () => mockApiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'data': [
              {
                'section': 'الأخبار',
                'items': [
                  {
                    'title': 'تحميل تطبيق يلا شووت للهواتف الذكية',
                    'url':
                        'https://www.ysscores.com/ar/Download-Yalla-Shoot-App',
                  },
                  {
                    'title': 'ريال مدريد يحقق فوزا مثيرا في الدوري',
                    'url': 'https://www.ysscores.com/ar/news/12345',
                  },
                ],
              },
            ],
          },
        );

        final news = await dataSource.getNews('123456', lang: 'ar');

        expect(news.length, 1);
        expect(news.first.title, 'ريال مدريد يحقق فوزا مثيرا في الدوري');
        expect(news.any((n) => n.title.contains('تحميل تطبيق')), isFalse);
      },
    );

    test('news parsing drops items with Download Yalla Shoot App and download links in English too', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'section': 'News',
              'items': [
                {
                  'title': 'Download Yalla Shoot App for Android and iOS',
                  'url': 'https://www.ysscores.com/en/Download-Yalla-Shoot-App',
                },
                {
                  'title': 'Real Madrid achieves an exciting league victory',
                  'url': 'https://www.ysscores.com/en/news/12345',
                },
              ],
            },
          ],
        },
      );

      final news = await dataSource.getNews('123456', lang: 'en');

      expect(news.length, 1);
      expect(
        news.first.title,
        'Real Madrid achieves an exciting league victory',
      );
      expect(
        news.any((n) => n.title.toLowerCase().contains('download yalla shoot')),
        isFalse,
      );
    });

    test('getDetailsPayload parses rich overview and sections from YallaShoot parity API', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'overview': {
            'team_wins': {
              'team1_wins': 5,
              'team2_wins': 3,
              'draws': 2,
              'team1_name': 'ليفربول',
              'team2_name': 'ريال مدريد',
            },
            'played_result': {
              'home': {
                'team_name': 'ليفربول',
                'matches': [
                  {
                    'id': '101',
                    'match_id': '101',
                    'opponent_name': 'مانشستر سيتي',
                    'score': '2 - 1',
                    'result': 'win',
                  },
                ],
              },
              'away': {
                'team_name': 'ريال مدريد',
                'matches': [
                  {
                    'id': '102',
                    'match_id': '102',
                    'opponent_name': 'برشلونة',
                    'score': '1 - 2',
                    'result': 'loss',
                  },
                ],
              },
            },
            'return_match': {
              'id': '99',
              'match_id': '99',
              'home_team': 'ريال مدريد',
              'away_team': 'ليفربول',
              'result': '1 - 1',
              'agg_result': '3 - 2',
              'penalties': '4 - 2',
            },
            'quick_stats': {
              'possession_home': '58',
              'possession_away': '42',
              'shots_home': 15,
              'shots_away': 8,
              'fouls_home': 10,
              'fouls_away': 12,
              'offsides_home': 2,
              'offsides_away': 1,
            },
            'referees': [
              {'id': '501', 'name': 'أنتوني تايلور', 'role': 'حكم ساحة'},
            ],
          },
          'data': [
            {
              'section': 'معلومات اللقاء',
              'items': [
                {
                  'title': 'الملعب',
                  'value': 'أنفيلد',
                  'id': '300',
                  'type': 'stadium',
                },
              ],
            },
          ],
        },
      );

      final payload = await dataSource.getDetailsPayload('5868013', lang: 'ar');

      expect(payload.sections.length, 1);
      expect(payload.sections.first.section, 'معلومات اللقاء');
      expect(payload.sections.first.items.first.content, 'أنفيلد');
      expect(payload.sections.first.items.first.entityId, '300');
      expect(payload.sections.first.items.first.entityType, 'stadium');

      expect(payload.overview, isNotNull);
      final overview = payload.overview!;

      // H2H
      expect(overview.h2hSummary, isNotNull);
      expect(overview.h2hSummary!.homeWins, 5);
      expect(overview.h2hSummary!.awayWins, 3);
      expect(overview.h2hSummary!.draws, 2);
      expect(overview.h2hSummary!.totalMatches, 10);

      // Form
      expect(overview.recentForm, isNotNull);
      expect(overview.recentForm!.homeMatches.length, 1);
      expect(overview.recentForm!.homeMatches.first.isWin, isTrue);
      expect(overview.recentForm!.awayMatches.length, 1);
      expect(overview.recentForm!.awayMatches.first.isLoss, isTrue);

      // Return leg
      expect(overview.returnLeg, isNotNull);
      expect(overview.returnLeg!.matchId, '99');
      expect(overview.returnLeg!.aggResult, '3 - 2');
      expect(overview.returnLeg!.penalties, '4 - 2');

      // Quick stats
      expect(overview.quickStats, isNotNull);
      expect(overview.quickStats!.homePossession, '58');
      expect(overview.quickStats!.awayPossession, '42');
      expect(overview.quickStats!.homeShots, 15);

      // Referees
      expect(overview.referees.length, 1);
      expect(overview.referees.first.name, 'أنتوني تايلور');
      expect(overview.referees.first.id, '501');
    });
  });
}
