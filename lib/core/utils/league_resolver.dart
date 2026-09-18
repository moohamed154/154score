class LeagueResolver {
  LeagueResolver._();

  static const Map<String, String> _nameToId = {
    // English Competitions
    'الدوري الإنجليزي الممتاز': '937599',
    'الدوري الإنجليزي': '937599',
    'البريميرليج': '937599',
    'premier league': '937599',
    'epl': '937599',
    'كأس الرابطة الإنجليزية': '937600',
    'كأس رابطة المحترفين الإنجليزية': '937600',
    'كأس كاراباو': '937600',
    'carabao cup': '937600',
    'efl cup': '937600',
    'كأس الاتحاد الإنجليزي': '937601',
    'fa cup': '937601',
    'درع المجتمع الإنجليزي': '937602',
    'community shield': '937602',

    // Spanish Competitions
    'الدوري الإسباني': '938652',
    'الدوري الإسباني - الدرجة الأولى': '938652',
    'لا ليغا': '938652',
    'laliga': '938652',
    'la liga': '938652',
    'كأس ملك إسبانيا': '938653',
    'copa del rey': '938653',
    'كأس السوبر الإسباني': '88013',
    'supercopa de espana': '88013',

    // Italian Competitions
    'الدوري الإيطالي': '936357',
    'الدوري الإيطالي الدرجة الأولى': '936357',
    'الكالتشيو': '936357',
    'serie a': '936357',
    'كأس إيطاليا': '936358',
    'coppa italia': '936358',
    'كأس السوبر الإيطالي': '936359',
    'supercoppa italiana': '936359',

    // German Competitions
    'الدوري الألماني': '938769',
    'البوندسليجا': '938769',
    'bundesliga': '938769',
    'كأس ألمانيا': '938770',
    'dfb pokal': '938770',
    'كأس السوبر الألماني': '938771',
    'dfb supercup': '938771',

    // French Competitions
    'الدوري الفرنسي': '937873',
    'ليج 1': '937873',
    'ligue 1': '937873',
    'كأس فرنسا': '937874',
    'coupe de france': '937874',
    'كأس السوبر الفرنسي': '937875',

    // European Competitions
    'دوري أبطال أوروبا': '904988',
    'champions league': '904988',
    'ucl': '904988',
    'الدوري الأوروبي': '937603',
    'europa league': '937603',
    'دوري المؤتمر الأوروبي': '937604',
    'conference league': '937604',
    'كأس السوبر الأوروبي': '937605',
    'uefa super cup': '937605',

    // Arab & Asian Competitions
    'دوري روشن السعودي': '941825',
    'الدوري السعودي للمحترفين': '941825',
    'الدوري السعودي': '941825',
    'saudi pro league': '941825',
    'roshn': '941825',
    'كأس خادم الحرمين الشريفين': '941826',
    'كأس الملك': '941826',
    'كأس السوبر السعودي': '941827',
    'الدوري المصري الممتاز': '943009',
    'الدوري المصري': '943009',
    'egyptian premier league': '943009',
    'كأس مصر': '943010',
    'كأس رابطة الأندية المصرية': '943011',
    'كأس السوبر المصري': '943012',
    'دوري أبطال آسيا للنخبة': '943501',
    'دوري أبطال آسيا': '943501',
    'afc champions league': '943501',
    'دوري أبطال إفريقيا': '943601',
    'caf champions league': '943601',
    'كأس الكونفيدرالية الإفريقية': '943602',
    'caf confederation cup': '943602',

    // South American Competitions
    'الدوري البرازيلي': '916145',
    'الدوري البرازيلي الممتاز': '916145',
    'البرازيل': '916145',
    'brazil': '916145',
    'brasileirao': '916145',
    'serie a brazil': '916145',
    'الدوري الأرجنتيني': '905256',
    'دوري الدرجة الأولى الأرجنتيني': '905256',
    'الأرجنتين': '905256',
    'argentina': '905256',
    'كأس الأرجنتين': '917618',
    'كوبا ليبرتادوريس': '924592',
    'copa libertadores': '924592',
    'كوبا سودا أمريكانا': '924591',
    'copa sudamericana': '924591',

    // Other Arab Competitions
    'البطولة الوطنية المغربية': '34872360',
    'الدوري المغربي': '34872360',
    'botola': '34872360',
    'الرابطة المحترفة الجزائرية': '942806',
    'الرابطة المحترفة الجزائرية الأولى': '942806',
    'الدوري الجزائري': '942806',
    'الرابطة التونسية لكرة القدم': '97887515',
    'الدوري التونسي': '97887515',
    'دوري نجوم قطر': '941155',
    'دوري نجوم بنك الدوحه': '941155',
    'الدوري القطري': '941155',
    'كأس قطر': '76943325',
    'دوري أدنوك للمحترفين': '939531',
    'الدوري الإماراتي للمحترفين': '939531',
    'الدوري الإماراتي': '939531',
    'دوري زين الكويتي': '943480',
    'الدوري الكويتي': '943480',
    'الدوري الأردني': '82075541',
    'الدوري الأردني للمحترفين': '82075541',
    'دوري المحترفين العماني': '943388',
    'الدوري العماني': '943388',
    'دوري ناصر بن حمد الممتاز': '942854',
    'الدوري البحريني الممتاز': '942854',
    'الدوري البحريني': '942854',
    'الدوري العراقي الممتاز': '73242049',
    'الدوري العراقي': '73242049',
    'دوري نجوم العراق': '73242049',
    'الدوري السوري الممتاز': '59013714',
    'الدوري السوري': '59013714',
    'دوري برايم': '59013714',
    'الدوري السوداني الممتاز': '24554571',
    'الدوري السوداني': '24554571',
    'الدوري الليبي': '915871',
    'الدوري اليمني': '30130539',

    // Other International Competitions
    'كأس العالم': '900001',
    'world cup': '900001',
    'كأس الأمم الأوروبية': '900002',
    'euro': '900002',
    'كوبا أمريكا': '900003',
    'copa america': '900003',
    'كأس الأمم الإفريقية': '900004',
    'afcon': '900004',
    'كأس آسيا': '900005',
    'asian cup': '900005',

    // Other European Competitions
    'الدوري الإسكتلندي الممتاز': '937650',
    'الدوري الإسكتلندي': '937650',
    'دوري السوبر السويسري': '937880',
    'الدوري اليوناني': '941071',
    'الدوري السويدي': '916322',
    'الدوري السويدي الممتاز': '916322',
    'الدوري الهولندي': '937877',
    'الدوري البرتغالي': '937878',
    'الدوري التركي': '937881',
    'الدوري البلجيكي': '937882',
    'الدوري الروسي': '938370',
    'الدوري الروسي الممتاز': '938370',
    'الدوري المكسيكي': '938179',
    'الدوري المكسيكي الممتاز': '938179',
    'الدوري النمساوي': '938366',
    'الدوري التشيكي': '938182',
    'الدوري البولندي': '937879',
    'الدوري الكرواتي': '936758',
    'الدوري النرويجي': '916225',
    'الدوري الصيني': '920266',
    'الدوري الياباني': '937875',
  };

  /// Normalizes Arabic text for tolerant matching (removes accents, standardizes letters).
  static String normalize(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\-_/\\]'), ' ');
    s = s.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    s = s.replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627');
    s = s.replaceAll('\u0629', '\u0647');
    s = s.replaceAll('\u0649', '\u064A');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Resolves a league ID from name, title, or slug.
  static String? resolveId(String? nameOrSlug) {
    if (nameOrSlug == null || nameOrSlug.trim().isEmpty) return null;
    final trimmed = nameOrSlug.trim();

    if (RegExp(r'^[0-9]+$').hasMatch(trimmed) && trimmed != '0') {
      return trimmed;
    }

    final lower = trimmed.toLowerCase();
    if (_nameToId.containsKey(lower)) {
      return _nameToId[lower];
    }

    final normInput = normalize(trimmed);
    for (final entry in _nameToId.entries) {
      if (normalize(entry.key) == normInput) {
        return entry.value;
      }
    }

    for (final entry in _nameToId.entries) {
      final normKey = normalize(entry.key);
      if (normInput.contains(normKey) || normKey.contains(normInput)) {
        if (normKey.length >= 4 || normInput.length >= 4) {
          return entry.value;
        }
      }
    }

    // Specific keyword fuzzy matching
    if (normInput.contains('برازيل') || normInput.contains('brazil')) {
      return '916145';
    }
    if (normInput.contains('ارجنتين') || normInput.contains('argentin')) {
      return '905256';
    }
    if (normInput.contains('مغرب') || normInput.contains('botola')) {
      return '34872360';
    }
    if (normInput.contains('جزائر')) {
      return '942806';
    }
    if (normInput.contains('تونس')) {
      return '97887515';
    }
    if (normInput.contains('قطر')) {
      return '941155';
    }
    if (normInput.contains('امارات') || normInput.contains('ادنوك')) {
      return '939531';
    }
    if (normInput.contains('كويت') || normInput.contains('زين')) {
      return '943480';
    }
    if (normInput.contains('عراق')) {
      return '73242049';
    }
    if (normInput.contains('اردن')) {
      return '82075541';
    }
    if (normInput.contains('عمان')) {
      return '943388';
    }
    if (normInput.contains('بحرين')) {
      return '942854';
    }
    if (normInput.contains('سودان')) {
      return '24554571';
    }
    if (normInput.contains('ليبيا') || normInput.contains('ليبي')) {
      return '915871';
    }
    if (normInput.contains('يمن')) {
      return '30130539';
    }
    if (normInput.contains('روسي') || normInput.contains('russian') || normInput.contains('russia')) {
      return '938370';
    }
    if (normInput.contains('كاراباو') ||
        normInput.contains('carabao') ||
        (normInput.contains('رابطه') && normInput.contains('انجليز'))) {
      return '937600';
    }
    if (normInput.contains('انجليز') || normInput.contains('premier')) {
      return '937599';
    }
    if (normInput.contains('اسبان') || normInput.contains('laliga')) {
      return '938652';
    }
    if (normInput.contains('ايطال') || normInput.contains('serie')) {
      return '936357';
    }
    if (normInput.contains('المان') || normInput.contains('bundesliga')) {
      return '938769';
    }
    if (normInput.contains('فرنس') || normInput.contains('ligue')) {
      return '937873';
    }
    if (normInput.contains('ابطال اوروبا') || normInput.contains('champions')) {
      return '904988';
    }
    if (normInput.contains('سعود') || normInput.contains('roshn')) {
      return '941825';
    }
    if (normInput.contains('مصر') || normInput.contains('egypt')) {
      return '943009';
    }

    return null;
  }
}
