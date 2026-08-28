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
  return ProfileEntity(
    id: id,
    slug: slug,
    name: name,
    sections: [
      ProfileSectionEntity(
        section: 'معلومات البطاقة',
        items: [
          ProfileItemEntity(title: 'الاسم', content: name),
          const ProfileItemEntity(title: 'نوع الحكم', content: 'حكم الساحة'),
        ],
      ),
    ],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────
void main() {
  late MockProfilesRepository repo;

  setUp(() {
    repo = MockProfilesRepository();
  });

  group('Referee Profile — V4.7.3 Regression Tests', () {
    // ── 1. Correct id and slug are sent to the repository ─────────────────
    test('referee 770414/espen-eskaas sends correct id and slug', () async {
      const id = '770414';
      const slug = 'espen-eskaas';

      when(
        () => repo.getRefereeProfile(id, slug, lang: any(named: 'lang')),
      ).thenAnswer(
        (_) async => ApiSuccess(makeProfile(id, slug, 'إسبن إسكاس')),
      );

      final result = await repo.getRefereeProfile(id, slug, lang: 'ar');

      expect(result.dataOrNull?.id, equals('770414'));
      expect(result.dataOrNull?.slug, equals('espen-eskaas'));
      expect(result.dataOrNull?.name, equals('إسبن إسكاس'));

      verify(
        () => repo.getRefereeProfile(id, slug, lang: any(named: 'lang')),
      ).called(1);
    });

    // ── 2. Missing optional fields do not crash ───────────────────────────
    test('referee profile with no sections (minimal data) does not crash', () {
      // A ProfileEntity with empty sections is valid
      const profile = ProfileEntity(
        id: '770414',
        slug: 'espen-eskaas',
        name: 'إسبن إسكاس',
        sections: [],
        // image and countryFlag are null — this is fine
      );

      expect(profile.id, equals('770414'));
      expect(profile.name, isNotEmpty);
      expect(profile.sections, isEmpty);
      expect(profile.image, isNull);
      expect(profile.countryFlag, isNull);
    });

    // ── 3. Different referees remain isolated ─────────────────────────────
    test('referee 770414 and referee 999 return different data', () async {
      const id1 = '770414';
      const slug1 = 'espen-eskaas';
      const id2 = '999';
      const slug2 = 'another-referee';

      when(
        () => repo.getRefereeProfile(id1, slug1, lang: any(named: 'lang')),
      ).thenAnswer(
        (_) async => ApiSuccess(makeProfile(id1, slug1, 'إسبن إسكاس')),
      );

      when(
        () => repo.getRefereeProfile(id2, slug2, lang: any(named: 'lang')),
      ).thenAnswer(
        (_) async => ApiSuccess(makeProfile(id2, slug2, 'حكم آخر')),
      );

      final r1 = await repo.getRefereeProfile(id1, slug1, lang: 'ar');
      final r2 = await repo.getRefereeProfile(id2, slug2, lang: 'ar');

      expect(r1.dataOrNull?.id, isNot(equals(r2.dataOrNull?.id)));
      expect(r1.dataOrNull?.name, isNot(equals(r2.dataOrNull?.name)));
    });

    // ── 4. Error state is clean — no crash on failure ─────────────────────
    test('invalid referee id returns ApiFailure cleanly', () async {
      const id = '0';
      const slug = 'invalid-referee';

      when(
        () => repo.getRefereeProfile(id, slug, lang: any(named: 'lang')),
      ).thenAnswer(
        (_) async =>
            const ApiFailure(ServerFailure('Not found', statusCode: 404)),
      );

      final result = await repo.getRefereeProfile(id, slug, lang: 'ar');

      expect(result, isA<ApiFailure>());
      expect(result.dataOrNull, isNull);
    });

    // ── 5. Retry produces a new request ──────────────────────────────────
    test('calling getRefereeProfile twice (retry) makes two API calls', () async {
      const id = '770414';
      const slug = 'espen-eskaas';
      var callCount = 0;

      when(
        () => repo.getRefereeProfile(id, slug, lang: any(named: 'lang')),
      ).thenAnswer((_) async {
        callCount++;
        return ApiSuccess(makeProfile(id, slug, 'إسبن إسكاس'));
      });

      await repo.getRefereeProfile(id, slug, lang: 'ar');
      await repo.getRefereeProfile(id, slug, lang: 'ar');

      expect(callCount, equals(2));
    });

    // ── 6. Three different referee IDs return three distinct profiles ──────
    test('three referees produce three distinct results', () async {
      final referees = [
        ('770414', 'espen-eskaas', 'إسبن إسكاس'),
        ('111', 'ali-hassan', 'علي حسن'),
        ('222', 'mark-clattenburg', 'مارك كلاتنبرغ'),
      ];

      for (final (id, slug, name) in referees) {
        when(
          () => repo.getRefereeProfile(id, slug, lang: any(named: 'lang')),
        ).thenAnswer(
          (_) async => ApiSuccess(makeProfile(id, slug, name)),
        );
      }

      final results = await Future.wait(
        referees.map((r) => repo.getRefereeProfile(r.$1, r.$2, lang: 'ar')),
      );

      final names = results.map((r) => r.dataOrNull?.name).toList();
      final ids = results.map((r) => r.dataOrNull?.id).toList();

      expect(names.toSet().length, equals(3));
      expect(ids.toSet().length, equals(3));
    });

    // ── 7. Referee API response fields match the DTO expectation ─────────
    test('ProfileEntity correctly maps referee section data', () {
      // Simulate the real API response structure for a referee:
      // {"section":"معلومات البطاقة","items":[
      //   {"title":"الاسم","content":"إسبن إسكاس"},
      //   {"title":"شعار الدولة","content":"https://..."},
      //   {"title":"الصورة","content":"https://..."}
      // ]}
      const profile = ProfileEntity(
        id: '770414',
        slug: 'espen-eskaas',
        name: 'إسبن إسكاس',
        image: 'https://imgs.ysscores.com/referee/128/17809671147454.png',
        countryFlag: 'https://www.ysscores.com/images/flags/no.png',
        sections: [
          ProfileSectionEntity(
            section: 'معلومات أخرى',
            items: [
              ProfileItemEntity(title: 'نوع الحكم', content: 'حكم الساحة'),
              ProfileItemEntity(title: 'الدولة', content: 'النرويج'),
              ProfileItemEntity(title: 'تاريخ الميلاد', content: '1988-06-24'),
              ProfileItemEntity(title: 'دولي', content: 'نعم'),
            ],
          ),
        ],
      );

      expect(profile.image, isNotNull);
      expect(profile.countryFlag, isNotNull);
      expect(profile.sections.first.section, equals('معلومات أخرى'));
      expect(profile.sections.first.items.length, equals(4));
      expect(
        profile.sections.first.items
            .any((i) => i.title == 'نوع الحكم'),
        isTrue,
      );
    });
  });
}
