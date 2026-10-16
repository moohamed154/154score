import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/core/utils/url_helper.dart';
import 'package:score154/features/profiles/data/datasources/profiles_remote_datasource.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late ProfilesRemoteDataSourceImpl dataSource;

  setUp(() {
    client = MockApiClient();
    dataSource = ProfilesRemoteDataSourceImpl(client);
  });

  group('Stadium Profile & Image URL Normalization Tests', () {
    test(
        'UrlHelper rewrites /stadium/820/ and /stadium/800/ to canonical 600px CDN URL',
        () {
      const url820 = 'https://imgs.ysscores.com/stadium/820/1461724761244.jpg';
      final normalized820 = UrlHelper.normalizeImageUrl(url820);
      expect(
        normalized820,
        equals('https://imgs.ysscores.com/stadium/600/1461724761244.jpg'),
      );

      const url800 = 'https://imgs.ysscores.com/stadium/800/1461724761244.jpg';
      final normalized800 = UrlHelper.normalizeImageUrl(url800);
      expect(
        normalized800,
        equals('https://imgs.ysscores.com/stadium/600/1461724761244.jpg'),
      );
    });

    test(
        'UrlHelper.normalizeStadiumImageUrl maps bare filenames to canonical 600px CDN URL',
        () {
      const bareFilename = '1461724761244.jpg';
      final res = UrlHelper.normalizeStadiumImageUrl(bareFilename);
      expect(
        res,
        equals('https://imgs.ysscores.com/stadium/600/1461724761244.jpg'),
      );
    });

    test(
      'UrlHelper.isValidImageUrl accepts 600px stadium URL and normalized URLs',
      () {
        expect(
          UrlHelper.isValidImageUrl(
            'https://imgs.ysscores.com/stadium/600/1461724761244.jpg',
          ),
          isTrue,
        );
        expect(
          UrlHelper.isValidImageUrl(
            'https://imgs.ysscores.com/stadium/820/1461724761244.jpg',
          ),
          isTrue,
        );
      },
    );

    test(
        'ProfilesRemoteDataSourceImpl parses stadium response and normalizes image to 600px CDN',
        () async {
      final mockJson = {
        'status': 'success',
        'data': {
          'id': '2',
          'name': 'رامون سانشيز بيزخوان',
          'name_en': 'Estadio R. Sanchez Pizjuan',
          'image': 'https://imgs.ysscores.com/stadium/820/1461724761244.jpg',
          'capacity': '42,714',
          'seats': '42,714',
          'built_date': '1958-09-07',
          'country': 'إسبانيا',
          'teams': [
            {
              'id': '8633',
              'name': 'إشبيلية',
              'logo': 'https://imgs.ysscores.com/teams/64/1871690196746.png',
            },
          ],
        },
      };

      when(
        () => client.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => mockJson);

      final profile = await dataSource.getProfile(
        '/api/stadium/2',
        '2',
        'ramon-sanchez-pizjuan',
        lang: 'ar',
      );

      expect(profile.name, equals('رامون سانشيز بيزخوان'));
      expect(
        profile.image,
        equals('https://imgs.ysscores.com/stadium/600/1461724761244.jpg'),
      );
      expect(profile.capacity, equals('42,714'));
      expect(profile.residentTeams.length, equals(1));
      expect(profile.residentTeams.first.name, equals('إشبيلية'));
    });
  });
}
