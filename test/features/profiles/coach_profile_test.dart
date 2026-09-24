import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/features/profiles/data/datasources/profiles_remote_datasource.dart';
import 'package:score154/features/profiles/domain/entities/profile_entity.dart';
import 'package:score154/features/profiles/domain/repositories/profiles_repository.dart';

class MockProfilesRepository extends Mock implements ProfilesRepository {}

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('Coach Profile Tests', () {
    late MockProfilesRepository repo;
    late MockApiClient apiClient;
    late ProfilesRemoteDataSourceImpl dataSource;

    setUp(() {
      repo = MockProfilesRepository();
      apiClient = MockApiClient();
      dataSource = ProfilesRemoteDataSourceImpl(apiClient);
    });

    test('Coach Profile entity supports currentTeam and career timeline', () {
      const coach = ProfileEntity(
        id: '862633',
        slug: 'pepe-bordalas',
        name: 'بيبي بوردالاس',
        englishName: 'Pepe Bordalas',
        image: 'https://imgs.ysscores.com/coach/150/17866245312173.png',
        country: 'إسبانيا',
        birthDate: '1964-03-05',
        role: 'المدير الفني',
        currentTeam: ProfileTeamEntity(
          id: '8305',
          name: 'خيتافي',
          role: 'المدير الفني',
          from: '2023-04-29',
          to: '2028-06-30',
          duration: '2023 - الآن',
          isCurrent: true,
        ),
        career: [
          ProfileTeamEntity(
            id: '8305',
            name: 'خيتافي',
            role: 'المدير الفني',
            duration: '2023 - الآن',
            isCurrent: true,
          ),
          ProfileTeamEntity(
            id: '10267',
            name: 'فالنسيا',
            role: 'المدير الفني',
            duration: '2021 - 2022',
            isCurrent: false,
          ),
        ],
        sections: [],
      );

      expect(coach.name, equals('بيبي بوردالاس'));
      expect(coach.currentTeam?.name, equals('خيتافي'));
      expect(coach.career.length, equals(2));
      expect(coach.career.first.isCurrent, isTrue);
      expect(coach.career.last.isCurrent, isFalse);
    });

    test('ProfilesRemoteDataSource parses coach payload with career and current team', () async {
      final mockResponse = {
        'status': true,
        'data': {
          'id': '862633',
          'name': 'بيبي بوردالاس',
          'name_en': 'Pepe Bordalas',
          'image': 'https://imgs.ysscores.com/coach/150/17866245312173.png',
          'country': 'إسبانيا',
          'birth_date': '1964-03-05',
          'role': 'المدير الفني',
          'current_team': {
            'team_id': '8305',
            'team_name': 'خيتافي',
            'team_logo': 'https://imgs.ysscores.com/teams/64/3451691957863.png',
            'role': 'المدير الفني',
            'from': '2023-04-29',
            'to': '2028-06-30',
          },
          'career': [
            {
              'team_id': '8305',
              'team_name': 'خيتافي',
              'team_logo':
                  'https://imgs.ysscores.com/teams/64/3451691957863.png',
              'role': 'المدير الفني',
              'from': '2023-04-29',
              'to': '2028-06-30',
              'duration': '2023 - الآن',
              'is_current': true,
            },
            {
              'team_id': '10267',
              'team_name': 'فالنسيا',
              'team_logo':
                  'https://imgs.ysscores.com/teams/64/7881690196747.png',
              'role': 'المدير الفني',
              'from': '2021-07-01',
              'to': '2022-06-03',
              'duration': '2021 - 2022',
              'is_current': false,
            },
          ],
          'metadata': [
            {'title': 'الدولة / الجنسية', 'content': 'إسبانيا'},
            {'title': 'العمر والميلاد', 'content': '1964-03-05 - (62 عام)'},
          ],
        },
      };

      when(
        () => apiClient.get(
          '/api/coach/862633/pepe-bordalas',
          queryParameters: {'lang': 'ar'},
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await dataSource.getProfile(
        '/api/coach/862633/pepe-bordalas',
        '862633',
        'pepe-bordalas',
        lang: 'ar',
      );

      expect(result.id, equals('862633'));
      expect(result.name, equals('بيبي بوردالاس'));
      expect(result.englishName, equals('Pepe Bordalas'));
      expect(result.currentTeam?.name, equals('خيتافي'));
      expect(result.career.length, equals(2));
      expect(result.career[0].duration, equals('2023 - الآن'));
      expect(result.career[0].isCurrent, isTrue);
      expect(result.career[1].duration, equals('2021 - 2022'));
      expect(result.career[1].isCurrent, isFalse);
    });

    test('getCoachProfile returns ApiSuccess on repository call', () async {
      const id = '862633';
      const slug = 'pepe-bordalas';
      const profile = ProfileEntity(
        id: id,
        slug: slug,
        name: 'بيبي بوردالاس',
        sections: [],
      );

      when(() => repo.getCoachProfile(id, slug, lang: any(named: 'lang')))
          .thenAnswer((_) async => const ApiSuccess(profile));

      final res = await repo.getCoachProfile(id, slug, lang: 'ar');

      expect(res.dataOrNull?.id, equals('862633'));
      expect(res.dataOrNull?.name, equals('بيبي بوردالاس'));
    });
  });
}
