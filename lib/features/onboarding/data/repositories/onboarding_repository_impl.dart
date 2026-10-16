import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyCompleted = 'app_onboarding_completed';

  @override
  bool isCompleted() {
    return _prefs.getBool(_keyCompleted) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    await _prefs.setBool(_keyCompleted, true);
  }

  @override
  Future<void> resetOnboarding() async {
    await _prefs.remove(_keyCompleted);
  }
}
