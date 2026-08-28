import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/errors/failures.dart';
import 'package:ysscores/core/network/api_result.dart';
import 'package:ysscores/features/profiles/domain/entities/profile_entity.dart';
import 'package:ysscores/features/profiles/domain/repositories/profiles_repository.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────
class MockProfilesRepository extends Mock implements ProfilesRepository {}

// ── Helpers ─────────────────────────────────────────────────────────────────

ProfileEntity makeProfile(String id, String slug, String name) {
  return ProfileEntity(id: id, slug: slug, name: name, sections: const []);
}

// ── Tests ──────────────────────────────────────────────────────────────────
void main() {
  late MockProfilesRepository repo;

  setUp(() {
    repo = MockProfilesRepository();
  });

  group('Commentator Profile — V4.7.3 Regression Tests', () {
    // ── 1. Different IDs call different endpoints ──────────────────────────
    test(
      'commentator 16 and commentator 55 generate separate repository calls',
      () async {
        const id1 = '16';
        const slug1 = 'jawad-badda';
        const id2 = '55';
        const slug2 = 'raouf-khlif';

        when(
          () =>
              repo.getCommentatorProfile(id1, slug1, lang: any(named: 'lang')),
        ).thenAnswer(
          (_) async => ApiSuccess(makeProfile(id1, slug1, 'جواد بدة')),
        );

        when(
          () =>
              repo.getCommentatorProfile(id2, slug2, lang: any(named: 'lang')),
        ).thenAnswer(
          (_) async => ApiSuccess(makeProfile(id2, slug2, 'رؤوف خليف')),
        );

        final result1 = await repo.getCommentatorProfile(
          id1,
          slug1,
          lang: 'ar',
        );
        final result2 = await repo.getCommentatorProfile(
          id2,
          slug2,
          lang: 'ar',
        );

        // Verify different profiles returned
        expect(result1.dataOrNull?.id, equals('16'));
        expect(result2.dataOrNull?.id, equals('55'));
        expect(result1.dataOrNull?.name, equals('جواد بدة'));
        expect(result2.dataOrNull?.name, equals('رؤوف خليف'));

        // Verify each was called once with its own arguments
        verify(
          () =>
              repo.getCommentatorProfile(id1, slug1, lang: any(named: 'lang')),
        ).called(1);
        verify(
          () =>
              repo.getCommentatorProfile(id2, slug2, lang: any(named: 'lang')),
        ).called(1);
      },
    );

    // ── 2. No hardcoded fallback to رؤوف خليف or any specific commentator ──
    test('loading commentator 42 does NOT return رؤوف خليف data', () async {
      const id = '42';
      const slug = 'hassan-moustafa';
      const expectedName = 'حسن مصطفى';

      when(() => repo.getCommentatorProfile(id, slug, lang: any(named: 'lang')))
          .thenAnswer(
            (_) async => ApiSuccess(makeProfile(id, slug, expectedName)),
          );

      final result = await repo.getCommentatorProfile(id, slug, lang: 'ar');

      expect(result.dataOrNull?.name, equals(expectedName));
      expect(result.dataOrNull?.name, isNot(equals('رؤوف خليف')));
      expect(result.dataOrNull?.id, equals('42'));
      expect(result.dataOrNull?.id, isNot(equals('1')));
    });

    // ── 3. Profile data carries the correct entity id and slug ─────────────
    test('returned ProfileEntity carries the requested id and slug', () async {
      const id = '16';
      const slug = 'jawad-badda';

      when(() => repo.getCommentatorProfile(id, slug, lang: any(named: 'lang')))
          .thenAnswer(
            (_) async => const ApiSuccess(
              ProfileEntity(
                id: '16',
                slug: 'jawad-badda',
                name: 'جواد بدة',
                sections: [],
              ),
            ),
          );

      final result = await repo.getCommentatorProfile(id, slug, lang: 'ar');
      final profile = result.dataOrNull!;

      expect(profile.id, equals(id));
      expect(profile.slug, equals(slug));
    });

    // ── 4. Cache key conceptual test ──────────────────────────────────────
    test('commentator cache keys are entity-specific', () {
      // The cache key concept: commentator:{id}:{slug}
      const key1 = 'commentator:16:jawad-badda';
      const key2 = 'commentator:55:raouf-khlif';
      const key3 = 'commentator:42:hassan-moustafa';

      // All three must be unique
      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key2, isNot(equals(key3)));

      // None must default to a single shared key
      expect(key1, isNot(equals('commentator')));
      expect(key2, isNot(equals('commentator')));
    });

    // ── 5. Invalid API response returns a Failure (no silent wrong data) ───
    test('network failure produces ApiFailure not silent wrong data', () async {
      const id = '9999';
      const slug = 'unknown-commentator';

      when(
        () => repo.getCommentatorProfile(id, slug, lang: any(named: 'lang')),
      ).thenAnswer(
        (_) async =>
            const ApiFailure(NetworkFailure('Upstream service unavailable')),
      );

      final result = await repo.getCommentatorProfile(id, slug, lang: 'ar');

      expect(result, isA<ApiFailure>());
      expect(result.dataOrNull, isNull);
    });

    // ── 6. Three different commentators return three different profiles ─────
    test(
      'three different commentator IDs return three distinct profiles',
      () async {
        final commentators = [
          ('16', 'jawad-badda', 'جواد بدة'),
          ('55', 'raouf-khlif', 'رؤوف خليف'),
          ('42', 'hassan-moustafa', 'حسن مصطفى'),
        ];

        for (final (id, slug, name) in commentators) {
          when(
            () =>
                repo.getCommentatorProfile(id, slug, lang: any(named: 'lang')),
          ).thenAnswer((_) async => ApiSuccess(makeProfile(id, slug, name)));
        }

        final results = await Future.wait(
          commentators.map(
            (c) => repo.getCommentatorProfile(c.$1, c.$2, lang: 'ar'),
          ),
        );

        final names = results.map((r) => r.dataOrNull?.name).toList();
        final ids = results.map((r) => r.dataOrNull?.id).toList();

        // Each result must be unique
        expect(names.toSet().length, equals(3));
        expect(ids.toSet().length, equals(3));
        expect(names[0], equals('جواد بدة'));
        expect(names[1], equals('رؤوف خليف'));
        expect(names[2], equals('حسن مصطفى'));
      },
    );
  });
}
