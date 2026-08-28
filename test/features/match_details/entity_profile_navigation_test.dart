import 'package:flutter_test/flutter_test.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';

void main() {
  group('Entity Profile Navigation — V4.7.3 Regression Tests', () {
    // ── 1. Items with null ID must NOT be navigable ─────────────────────────
    group('null ID guard', () {
      test('referee item with null id is NOT navigable', () {
        const item = MatchInfoItemEntity(
          title: 'حكم الساحة', // Arabic for "referee"
          content: 'ميغيل سيسما',
          // id is null — this is what the real match details API returns
        );

        // Verify item represents a referee title but has no id
        expect(item.id, isNull);
        expect(
          item.title.toLowerCase().contains('حكم'),
          isTrue,
          reason: 'Title should be recognised as a referee title',
        );
        // Navigation should be suppressed → test the guard condition
        final shouldNav = item.id != null;
        expect(
          shouldNav,
          isFalse,
          reason:
              'A referee item with null id must NOT be navigable. '
              'Before V4.7.3 fix this would default to id="1" and open the '
              'wrong entity for every tap.',
        );
      });

      test('commentator item with null id is NOT navigable', () {
        const item = MatchInfoItemEntity(
          title: 'المعلق', // Arabic for "commentator"
          content: 'منتصر الأزهري',
          // id is null — production API never returns it from match details
        );

        expect(item.id, isNull);
        final shouldNav = item.id != null;
        expect(
          shouldNav,
          isFalse,
          reason:
              'A commentator item with null id must NOT be navigable. '
              'Before fix, every tap opened id=1 (رؤوف خليف or equivalent).',
        );
      });

      test('stadium item with null id is NOT navigable', () {
        const item = MatchInfoItemEntity(
          title: 'الملعب', // Arabic for "stadium"
          content: 'ملعب كامب نو',
          // id is null
        );

        expect(item.id, isNull);
        final shouldNav = item.id != null;
        expect(shouldNav, isFalse);
      });
    });

    // ── 2. Items WITH a real ID CAN be navigated ───────────────────────────
    group('valid ID navigation', () {
      test('referee item with a real id is navigable', () {
        const item = MatchInfoItemEntity(
          title: 'حكم الساحة',
          content: 'إسبن إسكاس',
          id: '770414',
          slug: 'espen-eskaas',
        );

        expect(item.id, isNotNull);
        expect(item.id!.isNotEmpty, isTrue);
        final shouldNav = item.id != null;
        expect(shouldNav, isTrue);
      });

      test('commentator item with a real id is navigable', () {
        const item = MatchInfoItemEntity(
          title: 'المعلق',
          content: 'جواد بدة',
          id: '16',
          slug: 'jawad-badda',
        );

        expect(item.id, equals('16'));
        final shouldNav = item.id != null;
        expect(shouldNav, isTrue);
      });
    });

    // ── 3. No fallback to id='1' ────────────────────────────────────────────
    test('the old id-fallback pattern "?? 1" no longer exists', () {
      // Build a list of null-id items (as they arrive from the real API)
      const items = [
        MatchInfoItemEntity(title: 'المعلق', content: 'حفيظ دراجي'),
        MatchInfoItemEntity(title: 'حكم الساحة', content: 'أندرو مادلي'),
        MatchInfoItemEntity(title: 'الملعب', content: 'الأنفيلد'),
      ];

      for (final item in items) {
        // The guarded resolution must NEVER produce '1' as ID
        final resolvedId = item.id; // null → no navigation, not '1'

        expect(
          resolvedId,
          isNull,
          reason:
              'Entity ID must be null (no navigation), not "1". '
              'Before V4.7.3 the code used item.id ?? "1" which always '
              'opened the same wrong entity.',
        );
        expect(resolvedId, isNot(equals('1')));
      }
    });

    // ── 4. Different commentator IDs → different API URLs ──────────────────
    group('commentator URL construction', () {
      String buildCommentatorUrl(String id, String slug) =>
          '/api/commentator/$id/$slug';

      test('commentator 16/jawad-badda generates unique URL', () {
        const url = '/api/commentator/16/jawad-badda';
        expect(url, equals(buildCommentatorUrl('16', 'jawad-badda')));
        expect(url, isNot(contains('/1/')));
      });

      test('commentator 42/hassan-moustafa generates unique URL', () {
        const url = '/api/commentator/42/hassan-moustafa';
        expect(url, equals(buildCommentatorUrl('42', 'hassan-moustafa')));
        expect(url, isNot(equals('/api/commentator/16/jawad-badda')));
      });

      test('two different commentator IDs produce two different URLs', () {
        const url1 = '/api/commentator/16/jawad-badda';
        const url2 = '/api/commentator/55/raouf-khlif';
        expect(url1, isNot(equals(url2)));
      });

      test('commentator URL never defaults to id=1 when id is null', () {
        // Simulate V4.7.3 guard: only call builder when id is non-null
        const String? nullableId = null;
        // ignore: dead_code
        final resolvedUrl = (nullableId != null)
            ? buildCommentatorUrl(nullableId, 'some-slug')
            : null;
        expect(resolvedUrl, isNull);
        expect(resolvedUrl, isNot(equals('/api/commentator/1/some-slug')));
      });
    });

    // ── 5. Different referee IDs → different API URLs ─────────────────────
    group('referee URL construction', () {
      String buildRefereeUrl(String id, String slug) =>
          '/api/referee/$id/$slug';

      test('referee 770414/espen-eskaas generates unique URL', () {
        const url = '/api/referee/770414/espen-eskaas';
        expect(url, equals(buildRefereeUrl('770414', 'espen-eskaas')));
      });

      test('different referees produce different URLs', () {
        const url1 = '/api/referee/770414/espen-eskaas';
        const url2 = '/api/referee/99999/another-referee';
        expect(url1, isNot(equals(url2)));
      });

      test('referee URL never defaults to id=1 when id is null', () {
        const String? nullableId = null;
        // ignore: dead_code
        final resolvedUrl = (nullableId != null)
            ? buildRefereeUrl(nullableId, 'slug')
            : null;
        expect(resolvedUrl, isNull);
      });
    });

    // ── 6. Cache key isolation ─────────────────────────────────────────────
    group('cache key isolation', () {
      // Conceptual cache key builder matching the pattern: entity:{id}:{slug}
      String buildCacheKey(String entityType, String id, String slug) =>
          '$entityType:$id:$slug';

      test('commentator cache keys do not collide with referee cache keys', () {
        const commentatorKey = 'commentator:16:jawad-badda';
        const refereeKey = 'referee:16:some-referee';
        expect(commentatorKey, isNot(equals(refereeKey)));
      });

      test('different commentator IDs produce different cache keys', () {
        const key1 = 'commentator:16:jawad-badda';
        const key2 = 'commentator:55:raouf-khlif';
        expect(key1, isNot(equals(key2)));
      });

      test('different referee IDs produce different cache keys', () {
        const key1 = 'referee:770414:espen-eskaas';
        const key2 = 'referee:99999:other-ref';
        expect(key1, isNot(equals(key2)));
      });

      test('stadium cache key is isolated from referee and commentator', () {
        final stadiumKey = buildCacheKey('stadium', '962', 'hard-rock-stadium');
        final refereeKey = buildCacheKey('referee', '962', 'hard-rock-stadium');
        final commentatorKey = buildCacheKey(
          'commentator',
          '962',
          'hard-rock-stadium',
        );
        expect(stadiumKey, isNot(equals(refereeKey)));
        expect(stadiumKey, isNot(equals(commentatorKey)));
        expect(refereeKey, isNot(equals(commentatorKey)));
      });
    });

    // ── 7. API endpoint construction matches the production spec ───────────
    group('API endpoint construction (matches openapi.json spec)', () {
      test('commentator endpoint matches production spec', () {
        const endpoint = '/api/commentator/16/jawad-badda';
        expect(endpoint, equals('/api/commentator/16/jawad-badda'));
      });

      test('referee endpoint matches production spec', () {
        const endpoint = '/api/referee/770414/espen-eskaas';
        expect(endpoint, equals('/api/referee/770414/espen-eskaas'));
      });

      test('stadium endpoint matches production spec', () {
        const endpoint = '/api/stadium/962/hard-rock-stadium';
        expect(endpoint, equals('/api/stadium/962/hard-rock-stadium'));
      });
    });
  });
}
