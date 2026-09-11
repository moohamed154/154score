import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/network/api_client.dart';
import 'package:ysscores/features/match_details/data/datasources/match_details_remote_datasource.dart';

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
                  }
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
                    }
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
                    }
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
      expect(payload.events[0].videoUrl,
          'https://x.com/beINSPORTS/status/2098108413574004793');

      expect(payload.videos.hasVideo, isTrue);
      expect(payload.videos.summary?.title, 'ملخص إضافي');
      expect(payload.videos.summary?.url,
          'https://www.youtube.com/watch?v=uBkxy7BTsZs');

      expect(payload.videos.goalClips.length, 2);
      expect(payload.videos.goalClips[0].playerName, 'سيرجينيو ديست');
      expect(payload.videos.goalClips[0].url,
          'https://x.com/beINSPORTS/status/2098108413574004793');

      final chips = payload.videos.allChips;
      expect(chips.length, 3);
      expect(chips[0].title, 'ملخص إضافي');
      expect(chips[1].title, contains('سيرجينيو ديست'));
      expect(chips[2].title, contains('جليكير ميندوزا'));
    });
  });
}
