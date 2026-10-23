import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/league_resolver.dart';
import 'package:score154/core/utils/url_helper.dart';

void main() {
  group('UrlHelper Championship and Team Logo Resolution Tests', () {
    test('resolves CAF Confederation Cup themed logo for id 73510208 and 44444', () {
      final darkLogo = UrlHelper.resolveChampionshipLogo('73510208', isDark: true);
      expect(darkLogo, 'https://imgs.ysscores.com/championship/128/17638085863023.png');

      final lightLogo = UrlHelper.resolveChampionshipLogo('73510208', isDark: false);
      expect(lightLogo, 'https://imgs.ysscores.com/championship/128/17638085806160.png');

      final darkAlias = UrlHelper.resolveChampionshipLogo('CAF Confederation Cup', isDark: true);
      expect(darkAlias, 'https://imgs.ysscores.com/championship/128/17638085863023.png');
    });

    test('rejects numeric dummy IDs and avoids falling back to Yalla Shoot placeholder', () {
      final dummyLogo = UrlHelper.resolveChampionshipLogo(
        '12345',
        currentLogo: 'https://imgs.ysscores.com/championship/128/12345.png',
        isDark: true,
      );
      expect(dummyLogo, isNull);

      final dummyNoLogo = UrlHelper.resolveChampionshipLogo('9999999', isDark: true);
      expect(dummyNoLogo, isNull);
    });

    test('normalizes championship image URL when incorrectly requested under /teams/', () {
      final normalized = UrlHelper.normalizeChampionshipImageUrl('https://imgs.ysscores.com/teams/64/17638085863023.png');
      expect(normalized, 'https://imgs.ysscores.com/championship/128/17638085863023.png');
    });

    test('resolves Egyptian League Cup with dedicated trophy logo', () {
      final cupLogo = UrlHelper.resolveChampionshipLogo('560100', isDark: true);
      expect(cupLogo, 'https://imgs.ysscores.com/championship/128/2751704301232.png');

      final seasonCupLogo = UrlHelper.resolveChampionshipLogo('1254598', isDark: false);
      expect(seasonCupLogo, 'https://imgs.ysscores.com/championship/128/2751704301232.png');
    });

    test('resolves FIFA World Cup logo distinct from FA Cup and Intercontinental Cup', () {
      final worldCupLogo = UrlHelper.resolveChampionshipLogo('77059', isDark: true);
      expect(worldCupLogo, 'https://imgs.ysscores.com/championship/128/17813924887417.png');

      final faCupLogo = UrlHelper.resolveChampionshipLogo('89492', isDark: true);
      expect(faCupLogo, 'https://imgs.ysscores.com/championship/128/1231702394244.png');

      final intercontinentalLogo = UrlHelper.resolveChampionshipLogo('842143', isDark: true);
      expect(intercontinentalLogo, 'https://imgs.ysscores.com/championship/128/2121751062605.png');
    });
  });

  group('LeagueResolver Discrimination and Accurate Catalog Mapping Tests', () {
    test('accurately resolves Egyptian domestic competitions without collapsing into Egyptian Premier League', () {
      // Egyptian League Cup
      expect(
        LeagueResolver.resolveTitle('كأس الرابطة المصرية', isArabic: false, id: '560100'),
        equals('Egyptian League Cup'),
      );
      expect(
        LeagueResolver.resolveTitle('Egyptian League Cup', isArabic: true, id: '1254598'),
        equals('كأس الرابطة المصرية'),
      );

      // Egypt Cup
      expect(
        LeagueResolver.resolveTitle('كأس مصر', isArabic: false, id: '58881'),
        equals('Egypt Cup'),
      );
      expect(
        LeagueResolver.resolveTitle('Egypt Cup', isArabic: true, id: '3746233'),
        equals('كأس مصر'),
      );

      // Egyptian Second Division
      expect(
        LeagueResolver.resolveTitle('الدوري المصري - القسم الثاني', isArabic: false, id: '38371'),
        equals('Egyptian Second Division'),
      );
      expect(
        LeagueResolver.resolveTitle('Egyptian Second Division', isArabic: true, id: '941513'),
        equals('الدوري المصري - القسم الثاني'),
      );

      // Egyptian Premier League
      expect(
        LeagueResolver.resolveTitle('الدوري المصري الممتاز', isArabic: false, id: '943009'),
        equals('Egyptian Premier League'),
      );
      expect(
        LeagueResolver.resolveTitle('Egyptian Premier League', isArabic: true, id: '58553'),
        equals('الدوري المصري الممتاز'),
      );
    });

    test('discriminates Asian and Gulf competitions from UEFA Champions League', () {
      expect(
        LeagueResolver.resolveTitle('AFC Champions League Elite', isArabic: true, id: '855126'),
        equals('دوري أبطال آسيا للنخبة'),
      );
      expect(
        LeagueResolver.resolveTitle('AFC Champions League Two', isArabic: true, id: '854128'),
        equals('دوري أبطال آسيا 2'),
      );
      expect(
        LeagueResolver.resolveTitle('Gulf Club Champions League', isArabic: true, id: '596133'),
        equals('دوري أبطال الخليج'),
      );
    });

    test('discriminates other countries premier leagues from English Premier League', () {
      expect(
        LeagueResolver.resolveTitle('Kuwait Premier League', isArabic: true, id: '41480'),
        equals('الدوري الكويتي'),
      );
      expect(
        LeagueResolver.resolveTitle('Bahraini Premier League', isArabic: true, id: '26232'),
        equals('الدوري البحريني الممتاز'),
      );
      expect(
        LeagueResolver.resolveTitle('Sudan Premier League', isArabic: true, id: '537188'),
        equals('الدوري السوداني الممتاز'),
      );
      expect(
        LeagueResolver.resolveTitle('Libyan Premier League', isArabic: true, id: '784120'),
        equals('الدوري الليبي'),
      );
      expect(
        LeagueResolver.resolveTitle('Premier Liga', isArabic: true, id: '505443'),
        equals('الدوري الروسي الممتاز'),
      );
    });

    test('discriminates Saudi First Division League from Saudi Pro League', () {
      expect(
        LeagueResolver.resolveTitle('First Division League', isArabic: true, id: '89554'),
        equals('دوري الدرجة الأولى السعودي'),
      );
      expect(
        LeagueResolver.resolveTitle('Saudi Pro League', isArabic: true, id: '7167'),
        equals('دوري روشن السعودي'),
      );
    });

    test('discriminates FIFA World Cup from FIFA Intercontinental Cup', () {
      expect(
        LeagueResolver.resolveTitle(null, isArabic: false, id: '77059'),
        equals('FIFA World Cup'),
      );
      expect(
        LeagueResolver.resolveTitle(null, isArabic: false, id: '842143'),
        equals('FIFA Intercontinental Cup'),
      );
      expect(
        LeagueResolver.resolveTitle(null, isArabic: true, id: '26995682'),
        equals('كأس الإنتركونتيننتال للأندية'),
      );
    });

    test('discriminates Iraqi domestic leagues', () {
      expect(
        LeagueResolver.resolveTitle('الدوري العراقي', isArabic: false, id: '99376'),
        equals('Iraq Stars League'),
      );
      expect(
        LeagueResolver.resolveTitle('الدوري العراقي الدرجة الأولى', isArabic: false, id: '364189'),
        equals('Iraqi First Division'),
      );
    });
  });
}
