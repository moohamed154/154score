import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:score154/features/onboarding/presentation/viewmodels/onboarding_cubit.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository mockRepo;
  late OnboardingCubit cubit;

  setUp(() {
    mockRepo = MockOnboardingRepository();
    cubit = OnboardingCubit(mockRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('OnboardingCubit with 5 pages', () {
    test('initial state starts at page 0 with pageCount 5', () {
      expect(cubit.state.page, 0);
      expect(OnboardingState.pageCount, 5);
      expect(cubit.state.isLastPage, false);
      expect(cubit.state.status, OnboardingStatus.inProgress);
    });

    test('next() increments page sequentially through all 5 pages', () {
      // 0: Language
      expect(cubit.state.page, 0);
      expect(cubit.state.isLastPage, false);

      // 1: Theme
      cubit.next();
      expect(cubit.state.page, 1);
      expect(cubit.state.isLastPage, false);

      // 2: Font Size (NEW)
      cubit.next();
      expect(cubit.state.page, 2);
      expect(cubit.state.isLastPage, false);

      // 3: Teams
      cubit.next();
      expect(cubit.state.page, 3);
      expect(cubit.state.isLastPage, false);

      // 4: Leagues (Final Page)
      cubit.next();
      expect(cubit.state.page, 4);
      expect(cubit.state.isLastPage, true);

      // Calling next() on last page does not overshoot
      cubit.next();
      expect(cubit.state.page, 4);
      expect(cubit.state.isLastPage, true);
    });

    test('back() decrements page and does not go below 0', () {
      cubit.goTo(2); // Jump to Font Size
      expect(cubit.state.page, 2);

      cubit.back(); // Back to Theme
      expect(cubit.state.page, 1);

      cubit.back(); // Back to Language
      expect(cubit.state.page, 0);

      cubit.back(); // Boundary check
      expect(cubit.state.page, 0);
    });

    test('goTo(validPage) updates page and ignores out-of-bounds', () {
      cubit.goTo(2);
      expect(cubit.state.page, 2);

      cubit.goTo(-1);
      expect(cubit.state.page, 2);

      cubit.goTo(5); // >= pageCount
      expect(cubit.state.page, 2);
    });

    test('complete() marks repository and emits completed status', () async {
      when(() => mockRepo.markCompleted()).thenAnswer((_) async {});

      await cubit.complete();

      verify(() => mockRepo.markCompleted()).called(1);
      expect(cubit.state.status, OnboardingStatus.completed);
    });
  });
}
