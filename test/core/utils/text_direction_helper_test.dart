import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/text_direction_helper.dart';

void main() {
  group('TextDirectionHelper', () {
    test('correctly identifies Arabic text', () {
      expect(TextDirectionHelper.isArabic('ريال مدريد يفوز باللقب'), isTrue);
      expect(TextDirectionHelper.isArabic('أحدث الأخبار'), isTrue);
      expect(TextDirectionHelper.isArabic('English title'), isFalse);
      expect(TextDirectionHelper.isArabic(''), isFalse);
      expect(TextDirectionHelper.isArabic(null), isFalse);
    });

    test('returns correct TextDirection', () {
      expect(
        TextDirectionHelper.getDirection('أحدث الأخبار'),
        equals(TextDirection.rtl),
      );
      expect(
        TextDirectionHelper.getDirection('Latest News'),
        equals(TextDirection.ltr),
      );
    });

    test('returns correct TextAlign', () {
      expect(
        TextDirectionHelper.getTextAlign('أحدث الأخبار'),
        equals(TextAlign.right),
      );
      expect(
        TextDirectionHelper.getTextAlign('Latest News'),
        equals(TextAlign.start),
      );
    });
  });
}
