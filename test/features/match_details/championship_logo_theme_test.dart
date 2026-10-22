import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/url_helper.dart';

void main() {
  group('Championship Logo Dark and Light Theme Adaptation Tests', () {
    test('UCL swaps reciprocal variants between dark and light mode', () {
      final darkLogo = UrlHelper.resolveChampionshipLogo('904988', isDark: true);
      final lightLogo =
          UrlHelper.resolveChampionshipLogo('904988', isDark: false);

      expect(darkLogo, contains('3141696514284'));
      expect(lightLogo, contains('5171696546919'));

      // Flips when currentLogo has the opposite theme URL
      final flippedToLight = UrlHelper.resolveChampionshipLogo(
        '904988',
        currentLogo: darkLogo,
        isDark: false,
      );
      expect(flippedToLight, contains('5171696546919'));

      final flippedToDark = UrlHelper.resolveChampionshipLogo(
        '904988',
        currentLogo: lightLogo,
        isDark: true,
      );
      expect(flippedToDark, contains('3141696514284'));
    });

    test('Egyptian League (دوري ORA) swaps reciprocal variants', () {
      final darkLogo = UrlHelper.resolveChampionshipLogo('943009', isDark: true);
      final lightLogo =
          UrlHelper.resolveChampionshipLogo('943009', isDark: false);

      expect(darkLogo, contains('17882926672499'));
      expect(lightLogo, contains('17882925978755'));

      final flippedToLight = UrlHelper.resolveChampionshipLogo(
        '943009',
        currentLogo: darkLogo,
        isDark: false,
      );
      expect(flippedToLight, contains('17882925978755'));
    });

    test('Saudi Pro League swaps reciprocal variants', () {
      final darkLogo = UrlHelper.resolveChampionshipLogo('941825', isDark: true);
      final lightLogo =
          UrlHelper.resolveChampionshipLogo('941825', isDark: false);

      expect(darkLogo, contains('5111703719091'));
      expect(lightLogo, contains('3421703719071'));

      final flippedToLight = UrlHelper.resolveChampionshipLogo(
        '941825',
        currentLogo: darkLogo,
        isDark: false,
      );
      expect(flippedToLight, contains('3421703719071'));
    });

    test('German Bundesliga resolves to official red logo and swaps legacy Austrian shield', () {
      final darkLogo = UrlHelper.resolveChampionshipLogo('2606', isDark: true);
      final lightLogo = UrlHelper.resolveChampionshipLogo('2606', isDark: false);
      expect(darkLogo, contains('6171690288722'));
      expect(lightLogo, contains('6171690288722'));

      // Also resolves by title
      final byTitle = UrlHelper.resolveChampionshipLogo('الدوري الألماني');
      expect(byTitle, contains('6171690288722'));

      // Replaces legacy Austrian shield
      final replaced = UrlHelper.resolveChampionshipLogo(
        '2606',
        currentLogo: 'https://imgs.ysscores.com/championship/128/17883477127566.png',
      );
      expect(replaced, contains('6171690288722'));
    });

    test('Resolves championship logo by competition name in Arabic', () {
      final uclByTitleLight = UrlHelper.resolveChampionshipLogo(
        'دوري أبطال أوروبا',
        isDark: false,
      );
      expect(uclByTitleLight, contains('5171696546919'));
    });

    test('Prints onboarding catalog league logos', () {
      final ids = [
        '12048', // UCL
        '6811', // PL
        '1933', // LaLiga
        '3734', // Serie A
        '2606', // Bundesliga
        '1985', // Ligue 1
        '7167', // Saudi Pro League
        '943487', // CAF Champions League
        '937603', // Europa League
        '894789', // World Cup
      ];
      for (final id in ids) {
        final dark = UrlHelper.resolveChampionshipLogo(id, isDark: true);
        final light = UrlHelper.resolveChampionshipLogo(id, isDark: false);
        print('ID $id => dark: $dark | light: $light');
      }
    });
  });
}
