/// Contract for persisting whether the first-launch onboarding was completed.
abstract class OnboardingRepository {
  /// Whether the onboarding flow was already completed (or skipped).
  bool isCompleted();

  /// Marks the onboarding as completed so it is never shown again.
  Future<void> markCompleted();
}
