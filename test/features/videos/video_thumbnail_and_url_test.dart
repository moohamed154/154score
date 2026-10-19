import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/url_helper.dart';
import 'package:score154/features/videos/data/models/video_dto.dart';

void main() {
  group('UrlHelper - Video Thumbnail and Placeholder Filtering', () {
    test('filters out Yalla Shoot default video logo and placeholder URLs', () {
      expect(
        UrlHelper.normalizeImageUrl('https://www.ysscores.com/../../images/video_default.png'),
        isNull,
      );
      expect(
        UrlHelper.normalizeImageUrl('/../../images/video_default.png'),
        isNull,
      );
      expect(
        UrlHelper.normalizeImageUrl('https://www.ysscores.com/images/video_default.png'),
        isNull,
      );
      expect(
        UrlHelper.normalizeImageUrl('https://imgs.ysscores.com/placeholder.png'),
        isNull,
      );
      expect(
        UrlHelper.normalizeImageUrl('https://www.ysscores.com/images/default.png'),
        isNull,
      );
    });

    test('validates that Yalla Shoot default placeholders are invalid web images', () {
      expect(
        UrlHelper.isValidImageUrl('https://www.ysscores.com/../../images/video_default.png'),
        isFalse,
      );
      expect(
        UrlHelper.isValidImageUrl('https://www.ysscores.com/images/video_default.png'),
        isFalse,
      );
    });

    test('preserves genuine image URLs', () {
      expect(
        UrlHelper.normalizeImageUrl('https://imgs.ysscores.com/video_img/680/291786824017.jpg'),
        equals('https://imgs.ysscores.com/video_img/680/291786824017.jpg'),
      );
      expect(
        UrlHelper.isValidImageUrl('https://imgs.ysscores.com/video_img/680/291786824017.jpg'),
        isTrue,
      );
    });
  });

  group('VideoDto - parsing & Yalla Shoot logo sanitization', () {
    test('extracts clean ID from external links with trailing slashes and nullifies default logo', () {
      final json = {
        'link_detail': 'https://www.facebook.com/reel/1008503335539340/',
        'title': 'ملخص المباراة كربلاء - أربيل',
        'link': 'https://www.facebook.com/reel/1008503335539340/',
        'v_image': '/../../images/video_default.png',
        'created_at': '2026-09-18T19:45:08.000000Z',
      };

      final dto = VideoDto.fromJson(json);
      expect(dto.id, equals('1008503335539340'));
      expect(dto.title, equals('ملخص المباراة كربلاء - أربيل'));
      expect(dto.image, isNull);

      final entity = dto.toEntity(championship: 'Iraq Stars League');
      expect(entity.id, equals('1008503335539340'));
      expect(entity.image, isNull);
      expect(entity.link, equals('https://www.facebook.com/reel/1008503335539340/'));
      expect(entity.championship, equals('Iraq Stars League'));
    });
  });
}
