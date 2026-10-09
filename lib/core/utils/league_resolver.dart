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
    'دوري ora': '943009',
    'دوري أورا': '943009',
    'دوري اورا': '943009',
    'ora': '943009',
    'egyptian premier league': '943009',
    'كأس مصر': '943010',
    'كأس رابطة الأندية المصرية': '943011',
    'كأس السوبر المصري': '943012',
    'دوري أبطال آسيا للنخبة': '943501',
    'دوري أبطال آسيا': '943501',
    'afc champions league': '943501',
    'دوري أبطال أفريقيا': '943601',
    'دوري أبطال إفريقيا': '943601',
    'caf champions league': '943601',
    'كأس الكونفيدرالية': '943602',
    'كأس الكونفيدرالية الإفريقية': '943602',
    'كأس الكونفدرالية': '943602',
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
    'كأس القارات للأندية': '77059',
    'كأس القارات': '77059',
    'كأس الإنتركونتيننتال': '77059',
    'كأس الانتركونتيننتال': '77059',
    'كأس انتركونتيننتال': '77059',
    'fifa intercontinental cup': '77059',
    'intercontinental cup': '77059',

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
    'الدوري النمساوي': '544491',
    'الدوري النمساوي الممتاز': '544491',
    'austrian bundesliga': '544491',
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
    if (normInput.contains('روسي') ||
        normInput.contains('russian') ||
        normInput.contains('russia')) {
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

  static const Map<String, ({String ar, String en})> _idToTitles = {
    '943876': (
      ar: 'تصفيات كأس أمم أفريقيا',
      en: 'Africa Cup of Nations Qualification',
    ),
    '937599': (ar: 'الدوري الإنجليزي الممتاز', en: 'Premier League'),
    '6811': (ar: 'الدوري الإنجليزي الممتاز', en: 'Premier League'),
    '938652': (ar: 'الدوري الإسباني', en: 'LaLiga'),
    '1933': (ar: 'الدوري الإسباني', en: 'LaLiga'),
    '936357': (ar: 'الدوري الإيطالي', en: 'Serie A'),
    '3734': (ar: 'الدوري الإيطالي', en: 'Serie A'),
    '938769': (ar: 'الدوري الألماني', en: 'Bundesliga'),
    '2606': (ar: 'الدوري الألماني', en: 'Bundesliga'),
    '937873': (ar: 'الدوري الفرنسي', en: 'Ligue 1'),
    '1985': (ar: 'الدوري الفرنسي', en: 'Ligue 1'),
    '904988': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '12048': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '943230': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '937603': (ar: 'الدوري الأوروبي', en: 'UEFA Europa League'),
    '943229': (ar: 'الدوري الأوروبي', en: 'UEFA Europa League'),
    '89249': (ar: 'الدوري الأوروبي', en: 'UEFA Europa League'),
    '937604': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '943231': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '31250': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '941825': (ar: 'دوري روشن السعودي', en: 'Saudi Pro League'),
    '7167': (ar: 'دوري روشن السعودي', en: 'Saudi Pro League'),
    '943009': (ar: 'الدوري المصري الممتاز', en: 'Egyptian Premier League'),
    '58553': (ar: 'الدوري المصري الممتاز', en: 'Egyptian Premier League'),
    '894789': (ar: 'كأس العالم', en: 'FIFA World Cup'),
    '900001': (ar: 'كأس العالم', en: 'FIFA World Cup'),
    '97533': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '943487': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '911131': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '77783': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '943601': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '41791876': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '943602': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '911121': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '76684': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '88013': (ar: 'كأس السوبر الإسباني', en: 'Spanish Super Cup'),
    '59771441': (ar: 'كأس السوبر الإسباني', en: 'Spanish Super Cup'),
    '943488': (ar: 'كأس السوبر الإسباني', en: 'Spanish Super Cup'),
    '938653': (ar: 'كأس ملك إسبانيا', en: 'Copa del Rey'),
    '938426': (ar: 'كأس خادم الحرمين الشريفين', en: 'King Cup'),
    '9609': (ar: 'كأس خادم الحرمين الشريفين', en: 'King Cup'),
    '26995682': (ar: 'كأس القارات للأندية', en: 'FIFA Intercontinental Cup'),
    '77059': (ar: 'كأس القارات للأندية', en: 'FIFA Intercontinental Cup'),
    '842143': (ar: 'كأس القارات للأندية', en: 'FIFA Intercontinental Cup'),
    '544491': (ar: 'الدوري النمساوي', en: 'Austrian Bundesliga'),
    '938366': (ar: 'الدوري النمساوي', en: 'Austrian Bundesliga'),
  };

  static const Map<String, String> _arToEn = {
    // African & International
    'تصفيات كأس أمم إفريقيا': 'Africa Cup of Nations Qualification',
    'تصفيات كأس أمم أفريقيا': 'Africa Cup of Nations Qualification',
    'كأس أمم إفريقيا': 'Africa Cup of Nations',
    'كأس أمم أفريقيا': 'Africa Cup of Nations',
    'كأس الأمم الإفريقية': 'Africa Cup of Nations',
    'كأس الأمم الأفريقية': 'Africa Cup of Nations',
    'دوري أبطال أفريقيا': 'CAF Champions League',
    'دوري أبطال إفريقيا': 'CAF Champions League',
    'كأس الكونفيدرالية الإفريقية': 'CAF Confederation Cup',
    'كأس الكونفدرالية الإفريقية': 'CAF Confederation Cup',
    'كأس السوبر الأفريقي': 'CAF Super Cup',
    'كأس السوبر الإفريقي': 'CAF Super Cup',
    'كأس العرب': 'Arab Cup',
    'تصفيات كأس العالم': 'World Cup Qualification',
    'تصفيات كأس العالم - أفريقيا': 'World Cup Qualification - Africa',
    'تصفيات كأس العالم - أوروبا': 'World Cup Qualification - Europe',
    'تصفيات كأس العالم - آسيا': 'World Cup Qualification - Asia',
    'كأس العالم': 'FIFA World Cup',
    'دوري أبطال أوروبا': 'UEFA Champions League',
    'الدوري الأوروبي': 'UEFA Europa League',
    'دوري المؤتمر الأوروبي': 'UEFA Conference League',
    'كأس السوبر الأوروبي': 'UEFA Super Cup',
    'دوري الأمم الأوروبية': 'UEFA Nations League',
    'كأس أمم أوروبا': 'UEFA Euro',
    'يورو': 'UEFA Euro',

    // Domestic Leagues
    'الدوري الإنجليزي الممتاز': 'Premier League',
    'الدوري الإنجليزي': 'Premier League',
    'البريميرليج': 'Premier League',
    'كأس الاتحاد الإنجليزي': 'FA Cup',
    'كأس الرابطة الإنجليزية': 'Carabao Cup',
    'كأس كاراباو': 'Carabao Cup',
    'درع المجتمع الإنجليزي': 'Community Shield',

    'الدوري الإسباني': 'LaLiga',
    'الدوري الإسباني - الدرجة الأولى': 'LaLiga',
    'لا ليغا': 'LaLiga',
    'كأس ملك إسبانيا': 'Copa del Rey',
    'كأس السوبر الإسباني': 'Spanish Super Cup',

    'الدوري الإيطالي': 'Serie A',
    'الدوري الإيطالي الدرجة الأولى': 'Serie A',
    'الكالتشيو': 'Serie A',
    'كأس إيطاليا': 'Coppa Italia',
    'كأس السوبر الإيطالي': 'Italian Super Cup',

    'الدوري الألماني': 'Bundesliga',
    'البوندسليجا': 'Bundesliga',
    'كأس ألمانيا': 'DFB Pokal',
    'كأس السوبر الألماني': 'DFB Supercup',

    'الدوري الفرنسي': 'Ligue 1',
    'ليج 1': 'Ligue 1',
    'كأس فرنسا': 'Coupe de France',
    'كأس السوبر الفرنسي': 'Trophée des Champions',

    'دوري روشن السعودي': 'Saudi Pro League',
    'الدوري السعودي للمحترفين': 'Saudi Pro League',
    'الدوري السعودي': 'Saudi Pro League',
    'كأس خادم الحرمين الشريفين': 'King Cup',
    'كأس الملك': 'King Cup',
    'كأس السوبر السعودي': 'Saudi Super Cup',

    'الدوري المصري الممتاز': 'Egyptian Premier League',
    'الدوري المصري': 'Egyptian Premier League',
    'كأس مصر': 'Egypt Cup',
    'كأس رابطة الأندية المصرية': 'Egyptian League Cup',
    'كأس السوبر المصري': 'Egyptian Super Cup',
  };

  static final Map<String, String> _enToAr = {
    for (final entry in _arToEn.entries) entry.value.toLowerCase(): entry.key,
  };

  static String resolveTitle(
    String? titleOrId, {
    required bool isArabic,
    String? id,
  }) {
    if (titleOrId == null || titleOrId.trim().isEmpty) {
      if (id != null && _idToTitles.containsKey(id.trim())) {
        final pair = _idToTitles[id.trim()]!;
        return isArabic ? pair.ar : pair.en;
      }
      return '';
    }

    final trimmed = titleOrId.trim();

    // 1. Check if titleOrId is an ID
    if (_idToTitles.containsKey(trimmed)) {
      final pair = _idToTitles[trimmed]!;
      return isArabic ? pair.ar : pair.en;
    }

    if (id != null && _idToTitles.containsKey(id.trim())) {
      final pair = _idToTitles[id.trim()]!;
      return isArabic ? pair.ar : pair.en;
    }

    // 2. Localization from Arabic to English
    if (!isArabic) {
      if (_arToEn.containsKey(trimmed)) {
        return _arToEn[trimmed]!;
      }
      final normInput = normalize(trimmed);
      for (final entry in _arToEn.entries) {
        if (normalize(entry.key) == normInput) {
          return entry.value;
        }
      }
      if (!RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) {
        return trimmed;
      }
      for (final entry in _arToEn.entries) {
        final normKey = normalize(entry.key);
        if (normInput.contains(normKey) || normKey.contains(normInput)) {
          return entry.value;
        }
      }
    } else {
      final lower = trimmed.toLowerCase();
      if (_enToAr.containsKey(lower)) {
        return _enToAr[lower]!;
      }
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) {
        return trimmed;
      }
      for (final entry in _enToAr.entries) {
        if (lower.contains(entry.key) || entry.key.contains(lower)) {
          return entry.value;
        }
      }
    }

    return trimmed;
  }

  /// Returns a canonical identifier for a competition given its name or ID.
  static String? getCanonicalId(String? nameOrId) {
    if (nameOrId == null || nameOrId.trim().isEmpty) return null;
    return resolveId(nameOrId);
  }

  /// Determines if two competition names, slugs, or identifiers refer to the same competition.
  /// Handles:
  /// - Exact match (case insensitive)
  /// - Normalized Arabic text (alif, hamza, taa marbuta, etc.)
  /// - Cross-API IDs (e.g. '1933' vs '938652' for LaLiga, '6811' vs '937599' for Premier League)
  /// - Arabic <-> English translations (e.g. 'Premier League' vs 'الدوري الإنجليزي الممتاز')
  /// - Known aliases and title variations
  static bool areSameCompetition(
    String? a,
    String? b, {
    String? idA,
    String? idB,
  }) {
    final cleanA = a?.trim() ?? '';
    final cleanB = b?.trim() ?? '';
    final cleanIdA = idA?.trim() ?? '';
    final cleanIdB = idB?.trim() ?? '';

    final hasA = cleanA.isNotEmpty || cleanIdA.isNotEmpty;
    final hasB = cleanB.isNotEmpty || cleanIdB.isNotEmpty;
    if (!hasA || !hasB) return false;

    // 1. Direct ID match
    if (cleanIdA.isNotEmpty && cleanIdB.isNotEmpty && cleanIdA == cleanIdB) {
      return true;
    }

    // 2. Direct name match (case-insensitive)
    if (cleanA.isNotEmpty && cleanB.isNotEmpty &&
        cleanA.toLowerCase() == cleanB.toLowerCase()) {
      return true;
    }

    // 3. Normalized Arabic match
    if (cleanA.isNotEmpty && cleanB.isNotEmpty) {
      final normA = normalize(cleanA);
      final normB = normalize(cleanB);
      if (normA == normB) return true;
    }

    // 3b. Stage-tolerant base name match (e.g. "دوري أبطال أفريقيا | الأدوار الإقصائية")
    final baseA = cleanA.contains('|') ? cleanA.split('|').first.trim() : cleanA;
    final baseB = cleanB.contains('|') ? cleanB.split('|').first.trim() : cleanB;
    if (baseA.isNotEmpty && baseB.isNotEmpty && (baseA != cleanA || baseB != cleanB)) {
      if (baseA.toLowerCase() == baseB.toLowerCase() ||
          normalize(baseA) == normalize(baseB)) {
        return true;
      }
    }

    // 4. Resolve IDs from names or IDs
    final resIdA = cleanIdA.isNotEmpty
        ? (resolveId(cleanIdA) ?? cleanIdA)
        : (cleanA.isNotEmpty ? resolveId(cleanA) : null);

    final resIdB = cleanIdB.isNotEmpty
        ? (resolveId(cleanIdB) ?? cleanIdB)
        : (cleanB.isNotEmpty ? resolveId(cleanB) : null);

    if (resIdA != null && resIdB != null && resIdA == resIdB) {
      return true;
    }

    // 5. Cross-check with _idToTitles (which maps duplicate API IDs to canonical names)
    // E.g., '1933' and '938652' both have ar: 'الدوري الإسباني', en: 'LaLiga'
    final pairA = (resIdA != null && _idToTitles.containsKey(resIdA))
        ? _idToTitles[resIdA]
        : ((cleanIdA.isNotEmpty && _idToTitles.containsKey(cleanIdA))
            ? _idToTitles[cleanIdA]
            : null);

    final pairB = (resIdB != null && _idToTitles.containsKey(resIdB))
        ? _idToTitles[resIdB]
        : ((cleanIdB.isNotEmpty && _idToTitles.containsKey(cleanIdB))
            ? _idToTitles[cleanIdB]
            : null);

    if (pairA != null && pairB != null) {
      if (pairA.ar == pairB.ar ||
          pairA.en.toLowerCase() == pairB.en.toLowerCase()) {
        return true;
      }
    }

    // Check if name A matches title pair of B
    if (pairB != null && cleanA.isNotEmpty) {
      if (cleanA.toLowerCase() == pairB.en.toLowerCase() ||
          cleanA == pairB.ar ||
          normalize(cleanA) == normalize(pairB.ar)) {
        return true;
      }
    }

    // Check if name B matches title pair of A
    if (pairA != null && cleanB.isNotEmpty) {
      if (cleanB.toLowerCase() == pairA.en.toLowerCase() ||
          cleanB == pairA.ar ||
          normalize(cleanB) == normalize(pairA.ar)) {
        return true;
      }
    }

    // 6. Cross-language mapping (_arToEn and _enToAr)
    if (cleanA.isNotEmpty && cleanB.isNotEmpty) {
      final normA = normalize(cleanA);
      final normB = normalize(cleanB);

      final enFromA = _arToEn[cleanA] ?? _arToEn[normA];
      if (enFromA != null && enFromA.toLowerCase() == cleanB.toLowerCase()) {
        return true;
      }

      final enFromB = _arToEn[cleanB] ?? _arToEn[normB];
      if (enFromB != null && enFromB.toLowerCase() == cleanA.toLowerCase()) {
        return true;
      }

      final arFromA = _enToAr[cleanA.toLowerCase()];
      if (arFromA != null &&
          (arFromA == cleanB || normalize(arFromA) == normB)) {
        return true;
      }

      final arFromB = _enToAr[cleanB.toLowerCase()];
      if (arFromB != null &&
          (arFromB == cleanA || normalize(arFromB) == normA)) {
        return true;
      }

      // Check resolved titles
      final titleArA = resolveTitle(cleanA, isArabic: true, id: resIdA);
      final titleArB = resolveTitle(cleanB, isArabic: true, id: resIdB);
      if (titleArA.isNotEmpty && titleArA == titleArB) {
        return true;
      }
      if (titleArA.isNotEmpty && normalize(titleArA) == normalize(titleArB)) {
        return true;
      }

      final titleEnA = resolveTitle(cleanA, isArabic: false, id: resIdA);
      final titleEnB = resolveTitle(cleanB, isArabic: false, id: resIdB);
      if (titleEnA.isNotEmpty &&
          titleEnA.toLowerCase() == titleEnB.toLowerCase()) {
        return true;
      }
    }

    return false;
  }
}

