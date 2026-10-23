import 'package:flutter_test/flutter_test.dart';
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
  });
}
