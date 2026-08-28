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
  });
}
