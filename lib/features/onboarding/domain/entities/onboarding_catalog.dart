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
    OnboardingItem(ar: 'الأهلي', en: 'Al Ahly'),
    OnboardingItem(ar: 'الزمالك', en: 'Zamalek'),
    OnboardingItem(ar: 'مصر', en: 'Egypt'),
    OnboardingItem(ar: 'ريال مدريد', en: 'Real Madrid'),
    OnboardingItem(ar: 'برشلونة', en: 'Barcelona'),
    OnboardingItem(ar: 'أتلتيكو مدريد', en: 'Atletico Madrid'),
    OnboardingItem(ar: 'مانشستر سيتي', en: 'Manchester City'),
    OnboardingItem(ar: 'مانشستر يونايتد', en: 'Manchester United'),
    OnboardingItem(ar: 'ليفربول', en: 'Liverpool'),
    OnboardingItem(ar: 'أرسنال', en: 'Arsenal'),
    OnboardingItem(ar: 'تشيلسي', en: 'Chelsea'),
    OnboardingItem(ar: 'توتنهام', en: 'Tottenham'),
    OnboardingItem(ar: 'بايرن ميونخ', en: 'Bayern Munich'),
    OnboardingItem(ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund'),
    OnboardingItem(ar: 'يوفنتوس', en: 'Juventus'),
    OnboardingItem(ar: 'ميلان', en: 'AC Milan'),
    OnboardingItem(ar: 'إنتر ميلان', en: 'Inter Milan'),
    OnboardingItem(ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),
    OnboardingItem(ar: 'الهلال', en: 'Al Hilal'),
    OnboardingItem(ar: 'النصر', en: 'Al Nassr'),
    OnboardingItem(ar: 'الاتحاد', en: 'Al Ittihad'),
    OnboardingItem(ar: 'السعودية', en: 'Saudi Arabia'),
    OnboardingItem(ar: 'البرازيل', en: 'Brazil'),
    OnboardingItem(ar: 'الأرجنتين', en: 'Argentina'),
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
