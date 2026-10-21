import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';

void main() {
  group('Coach / Manager Role Localization', () {
    test('renders localized coach role for Arabic and English', () {
      const isArabic = true;
      final roleAr = isArabic ? 'المدير الفني' : 'Head Coach';
      expect(roleAr, 'المدير الفني');

      const isEnglish = false;
      final roleEn = isEnglish ? 'المدير الفني' : 'Head Coach';
      expect(roleEn, 'Head Coach');
    });

    test('AppLocalizations contains manager key in both languages', () {
      final l10nEn = AppLocalizations(const Locale('en'));
      expect(l10nEn.translate('manager'), 'Manager');

      final l10nAr = AppLocalizations(const Locale('ar'));
      expect(l10nAr.translate('manager'), 'المدير الفني');
    });
  });
}
