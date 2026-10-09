import 'package:equatable/equatable.dart';

/// A selectable item (team or league) with bilingual names.
class OnboardingItem extends Equatable {
  const OnboardingItem({required this.ar, required this.en, this.id});

  final String ar;
  final String en;
  final String? id;

  String nameFor({required bool isArabic}) => isArabic ? ar : en;

  @override
  List<Object?> get props => [ar, en, id];
}

/// Curated suggestions shown during onboarding.
class OnboardingCatalog {
  OnboardingCatalog._();

  static const List<OnboardingItem> teams = [
    OnboardingItem(ar: 'الأهلي', en: 'Al Ahly', id: '101745'),
    OnboardingItem(ar: 'الزمالك', en: 'Zamalek', id: '80591'),
    OnboardingItem(ar: 'مصر', en: 'Egypt', id: '10255'),
    OnboardingItem(ar: 'ريال مدريد', en: 'Real Madrid', id: '8633'),
    OnboardingItem(ar: 'برشلونة', en: 'Barcelona', id: '8634'),
    OnboardingItem(ar: 'أتلتيكو مدريد', en: 'Atletico Madrid', id: '9906'),
    OnboardingItem(ar: 'مانشستر سيتي', en: 'Manchester City', id: '8456'),
    OnboardingItem(ar: 'مانشستر يونايتد', en: 'Manchester United', id: '10260'),
    OnboardingItem(ar: 'ليفربول', en: 'Liverpool', id: '8650'),
    OnboardingItem(ar: 'أرسنال', en: 'Arsenal', id: '9825'),
    OnboardingItem(ar: 'تشيلسي', en: 'Chelsea', id: '8455'),
    OnboardingItem(ar: 'توتنهام', en: 'Tottenham', id: '8586'),
    OnboardingItem(ar: 'بايرن ميونخ', en: 'Bayern Munich', id: '9823'),
    OnboardingItem(ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund', id: '9789'),
    OnboardingItem(ar: 'يوفنتوس', en: 'Juventus', id: '9885'),
    OnboardingItem(ar: 'ميلان', en: 'AC Milan', id: '8564'),
    OnboardingItem(ar: 'إنتر ميلان', en: 'Inter Milan', id: '8636'),
    OnboardingItem(ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain', id: '9847'),
    OnboardingItem(ar: 'الهلال', en: 'Al Hilal', id: '2529'),
    OnboardingItem(ar: 'النصر', en: 'Al Nassr', id: '101918'),
    OnboardingItem(ar: 'الاتحاد', en: 'Al Ittihad', id: '8577'),
    OnboardingItem(ar: 'السعودية', en: 'Saudi Arabia', id: '7795'),
    OnboardingItem(ar: 'البرازيل', en: 'Brazil', id: '8256'),
    OnboardingItem(ar: 'الأرجنتين', en: 'Argentina', id: '6706'),
  ];

  /// Arabic names intentionally match `LocalStorageServiceImpl` canonical keys.
  static const List<OnboardingItem> leagues = [
    OnboardingItem(
      ar: 'دوري أبطال أوروبا',
      en: 'UEFA Champions League',
      id: '12048',
    ),
    OnboardingItem(
      ar: 'الدوري الإنجليزي الممتاز',
      en: 'Premier League',
      id: '6811',
    ),
    OnboardingItem(ar: 'الدوري الإسباني', en: 'LaLiga', id: '1933'),
    OnboardingItem(ar: 'الدوري الإيطالي', en: 'Serie A', id: '3734'),
    OnboardingItem(ar: 'الدوري الألماني', en: 'Bundesliga', id: '2606'),
    OnboardingItem(ar: 'الدوري الفرنسي', en: 'Ligue 1', id: '1985'),
    OnboardingItem(
      ar: 'الدوري السعودي للمحترفين',
      en: 'Saudi Pro League',
      id: '7167',
    ),
    OnboardingItem(
      ar: 'دوري أبطال أفريقيا',
      en: 'CAF Champions League',
      id: '943487',
    ),
    OnboardingItem(ar: 'الدوري الأوروبي', en: 'Europa League', id: '937603'),
    OnboardingItem(ar: 'كأس العالم', en: 'FIFA World Cup', id: '894789'),
  ];
}
