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
    'دوري البطولة الإنجليزية': '938218',
    'efl championship': '938218',

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
    'supercopa de españa': '88013',
    'spanish super cup': '88013',

    // Italian Competitions
    'الدوري الإيطالي': '936357',
    'الدوري الإيطالي الدرجة الأولى': '936357',
    'الكالتشيو': '936357',
    'serie a': '936357',
    'كأس إيطاليا': '936358',
    'coppa italia': '936358',
    'كأس السوبر الإيطالي': '936359',
    'supercoppa italiana': '936359',
    'italian super cup': '936359',

    // German Competitions
    'الدوري الألماني': '938769',
    'البوندسليجا': '938769',
    'bundesliga': '938769',
    'كأس ألمانيا': '938770',
    'dfb pokal': '938770',
    'dfb-pokal': '938770',
    'كأس السوبر الألماني': '938771',
    'dfb supercup': '938771',

    // French Competitions
    'الدوري الفرنسي': '937873',
    'ليج 1': '937873',
    'ligue 1': '937873',
    'كأس فرنسا': '937874',
    'coupe de france': '937874',
    'كأس السوبر الفرنسي': '937876',
    'trophee des champions': '937876',
    'trophée des champions': '937876',

    // European Competitions
    'دوري أبطال أوروبا': '904988',
    'uefa champions league': '904988',
    'champions league': '904988',
    'ucl': '904988',
    'الدوري الأوروبي': '937603',
    'اليوروباليج': '937603',
    'uefa europa league': '937603',
    'europa league': '937603',
    'دوري المؤتمر الأوروبي': '937604',
    'دوري المؤتمر الاوروبي': '937604',
    'دوري المؤتمر': '937604',
    'uefa conference league': '937604',
    'uefa europa conference league': '937604',
    'conference league': '937604',
    'europa conference league': '937604',
    '31250': '937604',
    '943231': '937604',
    '937351': '937604',
    'كأس السوبر الأوروبي': '937605',
    'uefa super cup': '937605',
    'دوري الأمم الأوروبية': '920741',
    'uefa nations league': '920741',

    // Saudi Competitions
    'دوري روشن السعودي': '941825',
    'دوري روشن للمحترفين': '941825',
    'الدوري السعودي للمحترفين': '941825',
    'الدوري السعودي': '941825',
    'saudi pro league': '941825',
    'roshn saudi league': '941825',
    'كأس خادم الحرمين الشريفين': '938426',
    'كأس الملك': '938426',
    'king cup': '938426',
    "king's cup": '938426',
    'كأس السوبر السعودي': '97986963',
    'saudi super cup': '97986963',
    'دوري الدرجة الأولى السعودي': '91937926',
    'دوري يلو': '91937926',
    'first division league': '91937926',
    'saudi first division league': '91937926',

    // Egyptian Competitions
    'الدوري المصري الممتاز': '943009',
    'الدوري المصري': '943009',
    'دوري ora': '943009',
    'دوري أورا': '943009',
    'دوري اورا': '943009',
    'ora': '943009',
    'egyptian premier league': '943009',
    'egyptian league': '943009',
    'كأس مصر': '3746233',
    'egypt cup': '3746233',
    'كأس الرابطة المصرية': '1254598',
    'كأس رابطة الأندية المصرية': '1254598',
    'كأس عاصمة مصر': '1254598',
    'egyptian league cup': '1254598',
    'cairo capital cup': '1254598',
    'كأس السوبر المصري': '943012',
    'egyptian super cup': '943012',
    'الدوري المصري - القسم الثاني': '941513',
    'دوري المحترفين المصري': '941513',
    'egyptian second division': '941513',

    // Asian & Gulf Competitions
    'دوري أبطال آسيا للنخبة': '943983',
    'دوري أبطال آسيا': '943983',
    'afc champions league elite': '943983',
    'afc champions league': '943983',
    'دوري أبطال آسيا 2': '944055',
    'afc champions league two': '944055',
    'afc champions league 2': '944055',
    'دوري التحدي الآسيوي': '944396',
    'afc challenge league': '944396',
    'دوري أبطال الخليج': '57789573',
    'gulf club champions league': '57789573',
    'كأس الخليج العربي': '15949033',
    'خليجي': '15949033',
    'arabian gulf cup': '15949033',
    'gulf cup': '15949033',
    'كأس الخليج تحت 17 سنة': '98026338',
    'gulf cup u-17': '98026338',
    'gulf cup u17': '98026338',
    'بطولة إتحاد غرب آسيا للناشئين': '52732116',
    'بطولة اتحاد غرب آسيا للناشئين': '52732116',
    'waff u-16 championship': '52732116',

    // African Competitions
    'دوري أبطال أفريقيا': '943601',
    'دوري أبطال إفريقيا': '943601',
    'caf champions league': '943601',
    'دوري أبطال أفريقيا | الأدوار الإقصائية': '97533',
    'دوري أبطال إفريقيا | الأدوار الإقصائية': '97533',
    'تصفيات دوري أبطال أفريقيا': '97533',
    'تصفيات دوري أبطال إفريقيا': '97533',
    'caf champions league | qualification': '97533',
    'كأس الكونفيدرالية': '943602',
    'كأس الكونفيدرالية الإفريقية': '943602',
    'كأس الكونفدرالية': '943602',
    'كأس الكونفدرالية الإفريقية': '943602',
    'caf confederation cup': '943602',
    'caf confederation': '943602',
    'الكونفيدرالية': '943602',
    '73510208': '943602',
    '41791876': '943602',
    'كأس الكونفيدرالية | الأدوار الإقصائية': '44444',
    'كأس الكونفيدرالية الإفريقية | الأدوار الإقصائية': '44444',
    'تصفيات كأس الكونفيدرالية': '44444',
    'تصفيات كأس الكونفدرالية': '44444',
    'caf confederation cup | qualification': '44444',
    '44444': '44444',
    'كأس السوبر الأفريقي': '17324407',
    'كأس السوبر الإفريقي': '17324407',
    'caf super cup': '17324407',
    'تصفيات كأس أمم أفريقيا': '943876',
    'تصفيات كأس أمم إفريقيا': '943876',
    'africa cup of nations qualification': '943876',

    // South & North American Competitions
    'الدوري البرازيلي': '916145',
    'الدوري البرازيلي الممتاز': '916145',
    'brasileirao': '916145',
    'serie a brazil': '916145',
    'campeonato brasileiro serie a': '916145',
    'campeonato brasileiro série a': '916145',
    'الدوري الأرجنتيني': '905256',
    'دوري الدرجة الأولى الأرجنتيني': '905256',
    'argentine primera division': '905256',
    'argentine primera división': '905256',
    'كأس الأرجنتين': '917618',
    'copa argentina': '917618',
    'كوبا ليبرتادوريس': '924592',
    'copa libertadores': '924592',
    'كوبا سودا أمريكانا': '924591',
    'copa sudamericana': '924591',
    'conmebol sudamericana': '924591',
    'الدوري الأمريكي لكرة القدم': '913550',
    'الدوري الأمريكي': '913550',
    'major league soccer': '913550',
    'mls': '913550',
    'كأس الدوريات': '938331',
    'leagues cup': '938331',
    'كأس الكونكاكاف أمريكا الوسطى': '938385',
    'concacaf central american': '938385',
    'concacaf central american cup': '938385',
    'دوري أمم الكونكاكاف': '941120',
    'concacaf nations league': '941120',
    'الدوري المكسيكي': '938179',
    'الدوري المكسيكي الممتاز': '938179',
    'liga mx': '938179',

    // Arab Domestic Leagues & Cups
    'البطولة الوطنية المغربية': '34872360',
    'الدوري المغربي': '34872360',
    'botola': '34872360',
    'botola pro': '34872360',
    'الرابطة المحترفة الجزائرية': '942806',
    'الرابطة المحترفة الجزائرية الأولى': '942806',
    'الدوري الجزائري': '942806',
    'algerian professional league 1': '942806',
    'الرابطة التونسية لكرة القدم': '97887515',
    'الدوري التونسي': '97887515',
    'tunisian professional league 1': '97887515',
    'دوري نجوم قطر': '941155',
    'دوري نجوم بنك الدوحه': '941155',
    'الدوري القطري': '941155',
    'qatar stars league': '941155',
    'كأس قطر': '76943325',
    'qatar cup': '76943325',
    'كأس نجوم قطر': '1610546',
    'qsl cup': '1610546',
    'دوري أدنوك للمحترفين': '939531',
    'الدوري الإماراتي للمحترفين': '939531',
    'الدوري الإماراتي': '939531',
    'uae pro league': '939531',
    'كأس السوبر الإماراتي': '59592212',
    'uae super cup': '59592212',
    'كأس مصرف أبوظبي الإسلامي': '67197392',
    'adib cup': '67197392',
    'دوري زين الكويتي': '943480',
    'الدوري الكويتي': '943480',
    'kuwait premier league': '943480',
    'الدوري الأردني': '82075541',
    'الدوري الأردني للمحترفين': '82075541',
    'jordanian pro league': '82075541',
    'دوري المحترفين العماني': '943388',
    'الدوري العماني': '943388',
    'oman professional league': '943388',
    'دوري ناصر بن حمد الممتاز': '942854',
    'الدوري البحريني الممتاز': '942854',
    'الدوري البحريني': '942854',
    'bahraini premier league': '942854',
    'الدوري العراقي الممتاز': '3680601',
    'الدوري العراقي': '3680601',
    'دوري نجوم العراق': '3680601',
    'iraq stars league': '3680601',
    'الدوري العراقي الدرجة الأولى': '73242049',
    'iraqi first division': '73242049',
    'الدوري السوري الممتاز': '59013714',
    'الدوري السوري': '59013714',
    'دوري برايم': '59013714',
    'syrian premier league': '59013714',
    'كأس السوبر السوري': '59814632',
    'syrian super cup': '59814632',
    'الدوري السوداني الممتاز': '24554571',
    'الدوري السوداني': '24554571',
    'sudan premier league': '24554571',
    'الدوري الليبي': '69555066',
    'الدوري الليبي الممتاز': '69555066',
    'libyan premier league': '69555066',
    'الدوري اليمني': '30130539',
    'yemeni league': '30130539',
    'كأس الجمهورية اليمنية': '24483495',
    'yemen republic cup': '24483495',

    // International Competitions
    'كأس العالم': '894789',
    'fifa world cup': '894789',
    'world cup': '894789',
    'كأس العالم تحت 17 سنة': '945377',
    'fifa u-17 world cup': '945377',
    'fifa u17 world cup': '945377',
    'كأس الأمم الأوروبية': '900002',
    'كأس أمم أوروبا': '900002',
    'uefa euro': '900002',
    'euro': '900002',
    'كوبا أمريكا': '900003',
    'copa america': '900003',
    'كأس الأمم الإفريقية': '900004',
    'كأس الأمم الأفريقية': '900004',
    'كأس أمم أفريقيا': '900004',
    'كأس أمم إفريقيا': '900004',
    'africa cup of nations': '900004',
    'afcon': '900004',
    'كأس آسيا': '930140',
    'afc asian cup': '930140',
    'asian cup': '930140',
    'كأس الإنتركونتيننتال للأندية': '26995682',
    'كأس القارات للأندية': '26995682',
    'كأس القارات': '26995682',
    'كأس الإنتركونتيننتال': '26995682',
    'كأس الانتركونتيننتال': '26995682',
    'كأس انتركونتيننتال': '26995682',
    'fifa intercontinental cup': '26995682',
    'intercontinental cup': '26995682',
    'مباراة ودية - أندية': '915708',
    'مباريات ودية - أندية': '915708',
    'club friendlies': '915708',
    'مباراة ودية': '914609',
    'مباريات ودية': '914609',
    'friendlies': '914609',

    // Other European & Global Leagues
    'الدوري الإسكتلندي الممتاز': '937650',
    'الدوري الإسكتلندي': '937650',
    'scottish premiership': '937650',
    'دوري السوبر السويسري': '937880',
    'swiss super league': '937880',
    'الدوري اليوناني': '941071',
    'super league greece': '941071',
    'الدوري السويدي': '916322',
    'الدوري السويدي الممتاز': '916322',
    'sweden league': '916322',
    'allsvenskan': '916322',
    'الدوري الهولندي': '937276',
    'الدوري الهولندي الممتاز': '937276',
    'eredivisie': '937276',
    'الدوري البرتغالي': '938823',
    'الدوري البرتغالي الممتاز': '938823',
    'liga portugal': '938823',
    'primeira liga': '938823',
    'كأس البرتغال': '903290',
    'portugal cup': '903290',
    'taca de portugal': '903290',
    'الدوري التركي': '939779',
    'الدوري التركي الممتاز': '939779',
    'super lig': '939779',
    'süper lig': '939779',
    'الدوري البلجيكي': '937988',
    'الدوري البلجيكي الممتاز': '937988',
    'belgian pro league': '937988',
    'كأس السوبر البلجيكي': '937891',
    'pro league super cup': '937891',
    'دوري السوبر الدنماركي': '935487',
    'الدوري الدنماركي': '935487',
    'danish superliga': '935487',
    'الدوري الروسي': '938370',
    'الدوري الروسي الممتاز': '938370',
    'premier liga': '938370',
    'russian premier liga': '938370',
    'الدوري النمساوي': '544491',
    'الدوري النمساوي الممتاز': '544491',
    'austrian bundesliga': '544491',
    'الدوري التشيكي': '938182',
    'دوري الدرجة الأولى التشيكي': '938182',
    'chance liga': '938182',
    'الدوري البولندي': '937879',
    'الدوري البولندي الممتاز': '937879',
    'ekstraklasa': '937879',
    'الدوري الكرواتي': '936758',
    'الدوري الكرواتي الممتاز': '936758',
    'croatian football league': '936758',
    'الدوري النرويجي': '916225',
    'الدوري النرويجي الممتاز': '916225',
    'eliteserien': '916225',
    'الدوري الصيني': '920266',
    'دوري السوبر الصيني': '920266',
    'chinese super league': '920266',
    'الدوري الياباني': '937875',
    'الدوري الياباني الممتاز': '937875',
    'j1 league': '937875',
  };

  static final Map<String, String> _normalizedNameToId = {
    for (final entry in _nameToId.entries) normalize(entry.key): entry.value,
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

  /// Cleans common noise suffixes (e.g. ": Fixtures, Standings & News | YSscores").
  static String _cleanNoise(String input) {
    var clean = input.trim();
    clean = clean
        .replaceAll(
          RegExp(
            r'\s*[:\-–|]\s*(Fixtures|Standings|News|مباريات|ترتيب|أخبار|اخبار|نتائج).*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    clean = clean
        .replaceAll(RegExp(r'\s*[|]\s*YSscores.*$', caseSensitive: false), '')
        .trim();
    return clean.isEmpty ? input.trim() : clean;
  }

  /// Resolves a league ID from name, title, or slug.
  static String? resolveId(String? nameOrSlug) {
    if (nameOrSlug == null || nameOrSlug.trim().isEmpty) return null;
    final rawTrimmed = nameOrSlug.trim();

    if (RegExp(r'^[0-9]+$').hasMatch(rawTrimmed) && rawTrimmed != '0') {
      return _nameToId[rawTrimmed] ?? rawTrimmed;
    }

    final trimmed = _cleanNoise(rawTrimmed);
    final lower = trimmed.toLowerCase();
    if (_nameToId.containsKey(lower)) {
      return _nameToId[lower];
    }

    final normInput = normalize(trimmed);
    if (_normalizedNameToId.containsKey(normInput)) {
      return _normalizedNameToId[normInput];
    }

    // If the title includes a stage suffix (e.g. "دوري أبطال أوروبا | مرحلة الدوري")
    // that doesn't have its own dedicated ID, resolve the base tournament name.
    if (trimmed.contains('|')) {
      final base = trimmed.split('|').first.trim();
      if (base.isNotEmpty) {
        final baseLower = base.toLowerCase();
        if (_nameToId.containsKey(baseLower)) {
          return _nameToId[baseLower];
        }
        final baseNorm = normalize(base);
        if (_normalizedNameToId.containsKey(baseNorm)) {
          return _normalizedNameToId[baseNorm];
        }
      }
    }

    return null;
  }

  static const Map<String, ({String ar, String en})> _idToTitles = {
    // 1. UEFA & European Continental
    '12048': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '943230': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '904988': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '288': (ar: 'دوري أبطال أوروبا', en: 'UEFA Champions League'),
    '89249': (ar: 'الدوري الأوروبي', en: 'UEFA Europa League'),
    '943229': (ar: 'الدوري الأوروبي', en: 'UEFA Europa League'),
    '937603': (ar: 'الدوري الأوروبي', en: 'UEFA Europa League'),
    '31250': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '943231': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '937604': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '937351': (ar: 'دوري المؤتمر الأوروبي', en: 'UEFA Conference League'),
    '937605': (ar: 'كأس السوبر الأوروبي', en: 'UEFA Super Cup'),
    '312135': (ar: 'دوري الأمم الأوروبية', en: 'UEFA Nations League'),
    '920741': (ar: 'دوري الأمم الأوروبية', en: 'UEFA Nations League'),

    // 2. Top 5 European Domestic Leagues & Cups
    '6811': (ar: 'الدوري الإنجليزي الممتاز', en: 'Premier League'),
    '937599': (ar: 'الدوري الإنجليزي الممتاز', en: 'Premier League'),
    '284': (ar: 'الدوري الإنجليزي الممتاز', en: 'Premier League'),
    '89492': (ar: 'كأس الاتحاد الإنجليزي', en: 'FA Cup'),
    '908818': (ar: 'كأس الاتحاد الإنجليزي', en: 'FA Cup'),
    '937601': (ar: 'كأس الاتحاد الإنجليزي', en: 'FA Cup'),
    '47742': (ar: 'كأس الرابطة الإنجليزية', en: 'EFL Cup'),
    '938001': (ar: 'كأس الرابطة الإنجليزية', en: 'EFL Cup'),
    '937600': (ar: 'كأس الرابطة الإنجليزية', en: 'EFL Cup'),
    '937602': (ar: 'درع المجتمع الإنجليزي', en: 'Community Shield'),
    '41019': (ar: 'دوري البطولة الإنجليزية', en: 'EFL Championship'),
    '938218': (ar: 'دوري البطولة الإنجليزية', en: 'EFL Championship'),

    '1933': (ar: 'الدوري الإسباني', en: 'LaLiga'),
    '938652': (ar: 'الدوري الإسباني', en: 'LaLiga'),
    '285': (ar: 'الدوري الإسباني', en: 'LaLiga'),
    '938653': (ar: 'كأس ملك إسبانيا', en: 'Copa del Rey'),
    '88013': (ar: 'كأس السوبر الإسباني', en: 'Spanish Super Cup'),
    '59771441': (ar: 'كأس السوبر الإسباني', en: 'Spanish Super Cup'),
    '943488': (ar: 'كأس السوبر الإسباني', en: 'Spanish Super Cup'),

    '3734': (ar: 'الدوري الإيطالي', en: 'Serie A'),
    '936357': (ar: 'الدوري الإيطالي', en: 'Serie A'),
    '287': (ar: 'الدوري الإيطالي', en: 'Serie A'),
    '17027': (ar: 'كأس إيطاليا', en: 'Coppa Italia'),
    '938423': (ar: 'كأس إيطاليا', en: 'Coppa Italia'),
    '936358': (ar: 'كأس إيطاليا', en: 'Coppa Italia'),
    '936359': (ar: 'كأس السوبر الإيطالي', en: 'Italian Super Cup'),

    '2606': (ar: 'الدوري الألماني', en: 'Bundesliga'),
    '938769': (ar: 'الدوري الألماني', en: 'Bundesliga'),
    '286': (ar: 'الدوري الألماني', en: 'Bundesliga'),
    '45529': (ar: 'كأس ألمانيا', en: 'DFB-Pokal'),
    '936417': (ar: 'كأس ألمانيا', en: 'DFB-Pokal'),
    '938770': (ar: 'كأس ألمانيا', en: 'DFB-Pokal'),
    '938771': (ar: 'كأس السوبر الألماني', en: 'DFB Supercup'),

    '1985': (ar: 'الدوري الفرنسي', en: 'Ligue 1'),
    '937873': (ar: 'الدوري الفرنسي', en: 'Ligue 1'),
    '2847': (ar: 'الدوري الفرنسي', en: 'Ligue 1'),
    '937874': (ar: 'كأس فرنسا', en: 'Coupe de France'),
    '937876': (ar: 'كأس السوبر الفرنسي', en: 'Trophée des Champions'),

    // 3. Saudi, Egyptian & Arab Competitions
    '7167': (ar: 'دوري روشن السعودي', en: 'Saudi Pro League'),
    '941825': (ar: 'دوري روشن السعودي', en: 'Saudi Pro League'),
    '4750': (ar: 'دوري روشن السعودي', en: 'Saudi Pro League'),
    '9609': (ar: 'كأس خادم الحرمين الشريفين', en: 'King Cup'),
    '938426': (ar: 'كأس خادم الحرمين الشريفين', en: 'King Cup'),
    '941826': (ar: 'كأس خادم الحرمين الشريفين', en: 'King Cup'),
    '116112': (ar: 'كأس السوبر السعودي', en: 'Saudi Super Cup'),
    '97986963': (ar: 'كأس السوبر السعودي', en: 'Saudi Super Cup'),
    '941827': (ar: 'كأس السوبر السعودي', en: 'Saudi Super Cup'),
    '89554': (ar: 'دوري الدرجة الأولى السعودي', en: 'First Division League'),
    '91937926': (ar: 'دوري الدرجة الأولى السعودي', en: 'First Division League'),

    '58553': (ar: 'الدوري المصري الممتاز', en: 'Egyptian Premier League'),
    '943009': (ar: 'الدوري المصري الممتاز', en: 'Egyptian Premier League'),
    '3894': (ar: 'الدوري المصري الممتاز', en: 'Egyptian Premier League'),
    '58881': (ar: 'كأس مصر', en: 'Egypt Cup'),
    '3746233': (ar: 'كأس مصر', en: 'Egypt Cup'),
    '943010': (ar: 'كأس مصر', en: 'Egypt Cup'),
    '560100': (ar: 'كأس الرابطة المصرية', en: 'Egyptian League Cup'),
    '1254598': (ar: 'كأس الرابطة المصرية', en: 'Egyptian League Cup'),
    '943011': (ar: 'كأس الرابطة المصرية', en: 'Egyptian League Cup'),
    '943012': (ar: 'كأس السوبر المصري', en: 'Egyptian Super Cup'),
    '38371': (ar: 'الدوري المصري - القسم الثاني', en: 'Egyptian Second Division'),
    '941513': (ar: 'الدوري المصري - القسم الثاني', en: 'Egyptian Second Division'),

    '99376': (ar: 'الدوري العراقي', en: 'Iraq Stars League'),
    '3680601': (ar: 'الدوري العراقي', en: 'Iraq Stars League'),
    '364189': (ar: 'الدوري العراقي الدرجة الأولى', en: 'Iraqi First Division'),
    '73242049': (ar: 'الدوري العراقي الدرجة الأولى', en: 'Iraqi First Division'),

    '41135': (ar: 'الدوري المغربي', en: 'Botola Pro'),
    '34872360': (ar: 'الدوري المغربي', en: 'Botola Pro'),
    '57146': (ar: 'الرابطة المحترفة الجزائرية الأولى', en: 'Algerian Professional League 1'),
    '942806': (ar: 'الرابطة المحترفة الجزائرية الأولى', en: 'Algerian Professional League 1'),
    '76040': (ar: 'الرابطة التونسية لكرة القدم', en: 'Tunisian Professional League 1'),
    '97887515': (ar: 'الرابطة التونسية لكرة القدم', en: 'Tunisian Professional League 1'),
    '524482': (ar: 'كأس السوبر السوري', en: 'Syrian Super Cup'),
    '59814632': (ar: 'كأس السوبر السوري', en: 'Syrian Super Cup'),
    '30067': (ar: 'الدوري السوري الممتاز', en: 'Syrian Premier League'),
    '59013714': (ar: 'الدوري السوري الممتاز', en: 'Syrian Premier League'),
    '83369': (ar: 'الدوري القطري', en: 'Qatar Stars League'),
    '941155': (ar: 'الدوري القطري', en: 'Qatar Stars League'),
    '769121': (ar: 'كأس قطر', en: 'Qatar Cup'),
    '76943325': (ar: 'كأس قطر', en: 'Qatar Cup'),
    '600141': (ar: 'كأس نجوم قطر', en: 'QSL Cup'),
    '1610546': (ar: 'كأس نجوم قطر', en: 'QSL Cup'),
    '98096': (ar: 'كأس السوبر الإماراتي', en: 'UAE Super Cup'),
    '59592212': (ar: 'كأس السوبر الإماراتي', en: 'UAE Super Cup'),
    '9468': (ar: 'الدوري الإماراتي للمحترفين', en: 'UAE Pro League'),
    '939531': (ar: 'الدوري الإماراتي للمحترفين', en: 'UAE Pro League'),
    '654106': (ar: 'كأس مصرف أبوظبي الإسلامي', en: 'ADIB Cup'),
    '67197392': (ar: 'كأس مصرف أبوظبي الإسلامي', en: 'ADIB Cup'),
    '41480': (ar: 'الدوري الكويتي', en: 'Kuwait Premier League'),
    '943480': (ar: 'الدوري الكويتي', en: 'Kuwait Premier League'),
    '81518': (ar: 'الدوري الأردني للمحترفين', en: 'Jordanian Pro League'),
    '82075541': (ar: 'الدوري الأردني للمحترفين', en: 'Jordanian Pro League'),
    '91130': (ar: 'دوري المحترفين العماني', en: 'Oman Professional League'),
    '943388': (ar: 'دوري المحترفين العماني', en: 'Oman Professional League'),
    '26232': (ar: 'الدوري البحريني الممتاز', en: 'Bahraini Premier League'),
    '942854': (ar: 'الدوري البحريني الممتاز', en: 'Bahraini Premier League'),
    '537188': (ar: 'الدوري السوداني الممتاز', en: 'Sudan Premier League'),
    '24554571': (ar: 'الدوري السوداني الممتاز', en: 'Sudan Premier League'),
    '784120': (ar: 'الدوري الليبي', en: 'Libyan Premier League'),
    '69555066': (ar: 'الدوري الليبي', en: 'Libyan Premier League'),
    '915871': (ar: 'الدوري الليبي', en: 'Libyan Premier League'),
    '559469': (ar: 'كأس الجمهورية اليمنية', en: 'Yemen Republic Cup'),
    '24483495': (ar: 'كأس الجمهورية اليمنية', en: 'Yemen Republic Cup'),
    '751343': (ar: 'الدوري اليمني', en: 'Yemeni League'),
    '30130539': (ar: 'الدوري اليمني', en: 'Yemeni League'),

    // 4. African, Asian & Gulf Continental
    '67845': (ar: 'كأس السوبر الأفريقي', en: 'CAF Super Cup'),
    '17324407': (ar: 'كأس السوبر الأفريقي', en: 'CAF Super Cup'),
    '77783': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '911131': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '943487': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '943601': (ar: 'دوري أبطال أفريقيا', en: 'CAF Champions League'),
    '97533': (
      ar: 'دوري أبطال أفريقيا | الأدوار الإقصائية',
      en: 'CAF Champions League | Qualification',
    ),
    '76684': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '911121': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '943602': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '73510208': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '41791876': (ar: 'كأس الكونفيدرالية الإفريقية', en: 'CAF Confederation Cup'),
    '44444': (
      ar: 'كأس الكونفيدرالية | الأدوار الإقصائية',
      en: 'CAF Confederation Cup | Qualification',
    ),
    '61351': (
      ar: 'تصفيات كأس أمم أفريقيا',
      en: 'Africa Cup of Nations Qualification',
    ),
    '943876': (
      ar: 'تصفيات كأس أمم أفريقيا',
      en: 'Africa Cup of Nations Qualification',
    ),
    '855126': (ar: 'دوري أبطال آسيا للنخبة', en: 'AFC Champions League Elite'),
    '943983': (ar: 'دوري أبطال آسيا للنخبة', en: 'AFC Champions League Elite'),
    '943501': (ar: 'دوري أبطال آسيا للنخبة', en: 'AFC Champions League Elite'),
    '854128': (ar: 'دوري أبطال آسيا 2', en: 'AFC Champions League Two'),
    '944055': (ar: 'دوري أبطال آسيا 2', en: 'AFC Champions League Two'),
    '901130': (ar: 'دوري التحدي الآسيوي', en: 'AFC Challenge League'),
    '944396': (ar: 'دوري التحدي الآسيوي', en: 'AFC Challenge League'),
    '596133': (ar: 'دوري أبطال الخليج', en: 'Gulf Club Champions League'),
    '57789573': (ar: 'دوري أبطال الخليج', en: 'Gulf Club Champions League'),
    '796368': (ar: 'كأس الخليج العربي', en: 'Arabian Gulf Cup'),
    '15949033': (ar: 'كأس الخليج العربي', en: 'Arabian Gulf Cup'),
    '875325': (ar: 'كأس الخليج تحت 17 سنة', en: 'Gulf Cup U-17'),
    '98026338': (ar: 'كأس الخليج تحت 17 سنة', en: 'Gulf Cup U-17'),
    '67195': (
      ar: 'بطولة إتحاد غرب آسيا للناشئين',
      en: 'WAFF U-16 Championship',
    ),
    '52732116': (
      ar: 'بطولة إتحاد غرب آسيا للناشئين',
      en: 'WAFF U-16 Championship',
    ),

    // 5. Other European, American & International Competitions
    '6682': (ar: 'الدوري التركي الممتاز', en: 'Süper Lig'),
    '939779': (ar: 'الدوري التركي الممتاز', en: 'Süper Lig'),
    '937881': (ar: 'الدوري التركي الممتاز', en: 'Süper Lig'),
    '79123': (ar: 'الدوري الأمريكي لكرة القدم', en: 'Major League Soccer'),
    '913550': (ar: 'الدوري الأمريكي لكرة القدم', en: 'Major League Soccer'),
    '47821': (ar: 'الدوري الهولندي الممتاز', en: 'Eredivisie'),
    '937276': (ar: 'الدوري الهولندي الممتاز', en: 'Eredivisie'),
    '937877': (ar: 'الدوري الهولندي الممتاز', en: 'Eredivisie'),
    '54416': (ar: 'الدوري البرتغالي الممتاز', en: 'Liga Portugal'),
    '938823': (ar: 'الدوري البرتغالي الممتاز', en: 'Liga Portugal'),
    '937878': (ar: 'الدوري البرتغالي الممتاز', en: 'Liga Portugal'),
    '797102': (ar: 'كأس البرتغال', en: 'Portugal Cup'),
    '903290': (ar: 'كأس البرتغال', en: 'Portugal Cup'),
    '47037': (ar: 'الدوري البلجيكي', en: 'Belgian Pro League'),
    '937988': (ar: 'الدوري البلجيكي', en: 'Belgian Pro League'),
    '937882': (ar: 'الدوري البلجيكي', en: 'Belgian Pro League'),
    '474185': (ar: 'كأس السوبر البلجيكي', en: 'Pro League Super Cup'),
    '937891': (ar: 'كأس السوبر البلجيكي', en: 'Pro League Super Cup'),
    '90322': (ar: 'دوري السوبر الدنماركي', en: 'Danish Superliga'),
    '935487': (ar: 'دوري السوبر الدنماركي', en: 'Danish Superliga'),
    '573139': (ar: 'الدوري الإسكتلندي الممتاز', en: 'Scottish Premiership'),
    '937650': (ar: 'الدوري الإسكتلندي الممتاز', en: 'Scottish Premiership'),
    '308191': (ar: 'دوري السوبر السويسري', en: 'Swiss Super League'),
    '937880': (ar: 'دوري السوبر السويسري', en: 'Swiss Super League'),
    '138192': (ar: 'الدوري اليوناني', en: 'Super League Greece'),
    '941071': (ar: 'الدوري اليوناني', en: 'Super League Greece'),
    '252344': (ar: 'الدوري السويدي الممتاز', en: 'Sweden League'),
    '916322': (ar: 'الدوري السويدي الممتاز', en: 'Sweden League'),
    '13178': (ar: 'كوبا ليبرتادوريس', en: 'Copa Libertadores'),
    '924592': (ar: 'كوبا ليبرتادوريس', en: 'Copa Libertadores'),
    '970117': (ar: 'كوبا سودا أمريكانا', en: 'Conmebol Sudamericana'),
    '924591': (ar: 'كوبا سودا أمريكانا', en: 'Conmebol Sudamericana'),
    '40224': (ar: 'الدوري البرازيلي', en: 'Campeonato Brasileiro Série A'),
    '916145': (ar: 'الدوري البرازيلي', en: 'Campeonato Brasileiro Série A'),
    '75166': (ar: 'دوري الدرجة الأولى الأرجنتيني', en: 'Argentine Primera División'),
    '905256': (ar: 'دوري الدرجة الأولى الأرجنتيني', en: 'Argentine Primera División'),
    '538294': (ar: 'كأس الأرجنتين', en: 'Copa Argentina'),
    '917618': (ar: 'كأس الأرجنتين', en: 'Copa Argentina'),
    '475137': (ar: 'كأس الدوريات', en: 'Leagues Cup'),
    '938331': (ar: 'كأس الدوريات', en: 'Leagues Cup'),
    '233484': (ar: 'الدوري النرويجي الممتاز', en: 'Eliteserien'),
    '916225': (ar: 'الدوري النرويجي الممتاز', en: 'Eliteserien'),
    '827478': (ar: 'الدوري البولندي الممتاز', en: 'Ekstraklasa'),
    '937879': (ar: 'الدوري البولندي الممتاز', en: 'Ekstraklasa'),
    '904490': (ar: 'الدوري الكرواتي الممتاز', en: 'Croatian Football League'),
    '936758': (ar: 'الدوري الكرواتي الممتاز', en: 'Croatian Football League'),
    '544491': (ar: 'الدوري النمساوي', en: 'Austrian Bundesliga'),
    '938366': (ar: 'الدوري النمساوي', en: 'Austrian Bundesliga'),
    '914492': (ar: 'دوري الدرجة الأولى التشيكي', en: 'Chance Liga'),
    '938182': (ar: 'دوري الدرجة الأولى التشيكي', en: 'Chance Liga'),
    '505443': (ar: 'الدوري الروسي الممتاز', en: 'Premier Liga'),
    '938370': (ar: 'الدوري الروسي الممتاز', en: 'Premier Liga'),
    '535485': (ar: 'الدوري المكسيكي الممتاز', en: 'Liga MX'),
    '938179': (ar: 'الدوري المكسيكي الممتاز', en: 'Liga MX'),
    '184480': (ar: 'الدوري الياباني الممتاز', en: 'J1 League'),
    '937875': (ar: 'الدوري الياباني الممتاز', en: 'J1 League'),
    '841486': (ar: 'دوري السوبر الصيني', en: 'Chinese Super League'),
    '920266': (ar: 'دوري السوبر الصيني', en: 'Chinese Super League'),
    '884138': (ar: 'كأس الكونكاكاف أمريكا الوسطى', en: 'Concacaf Central American'),
    '938385': (ar: 'كأس الكونكاكاف أمريكا الوسطى', en: 'Concacaf Central American'),
    '39714': (ar: 'مباراة ودية - أندية', en: 'Club Friendlies'),
    '915708': (ar: 'مباراة ودية - أندية', en: 'Club Friendlies'),
    '51893': (ar: 'كأس آسيا', en: 'AFC Asian Cup'),
    '930140': (ar: 'كأس آسيا', en: 'AFC Asian Cup'),
    '900005': (ar: 'كأس آسيا', en: 'AFC Asian Cup'),
    '287145': (ar: 'دوري أمم الكونكاكاف', en: 'Concacaf Nations League'),
    '941120': (ar: 'دوري أمم الكونكاكاف', en: 'Concacaf Nations League'),
    '54947': (ar: 'مباراة ودية', en: 'Friendlies'),
    '914609': (ar: 'مباراة ودية', en: 'Friendlies'),
    '77059': (ar: 'كأس العالم', en: 'FIFA World Cup'),
    '894789': (ar: 'كأس العالم', en: 'FIFA World Cup'),
    '900001': (ar: 'كأس العالم', en: 'FIFA World Cup'),
    '83188': (ar: 'كأس العالم تحت 17 سنة', en: 'FIFA U-17 World Cup'),
    '945377': (ar: 'كأس العالم تحت 17 سنة', en: 'FIFA U-17 World Cup'),
    '842143': (ar: 'كأس الإنتركونتيننتال للأندية', en: 'FIFA Intercontinental Cup'),
    '26995682': (ar: 'كأس الإنتركونتيننتال للأندية', en: 'FIFA Intercontinental Cup'),
    '900002': (ar: 'كأس أمم أوروبا', en: 'UEFA Euro'),
    '900003': (ar: 'كوبا أمريكا', en: 'Copa America'),
    '900004': (ar: 'كأس أمم أفريقيا', en: 'Africa Cup of Nations'),
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
    'دوري أبطال أفريقيا | الأدوار الإقصائية':
        'CAF Champions League | Qualification',
    'دوري أبطال إفريقيا | الأدوار الإقصائية':
        'CAF Champions League | Qualification',
    'تصفيات دوري أبطال أفريقيا': 'CAF Champions League | Qualification',
    'كأس الكونفيدرالية': 'CAF Confederation Cup',
    'كأس الكونفيدرالية الإفريقية': 'CAF Confederation Cup',
    'كأس الكونفدرالية الإفريقية': 'CAF Confederation Cup',
    'كأس الكونفيدرالية | الأدوار الإقصائية':
        'CAF Confederation Cup | Qualification',
    'كأس الكونفيدرالية الإفريقية | الأدوار الإقصائية':
        'CAF Confederation Cup | Qualification',
    'تصفيات كأس الكونفيدرالية': 'CAF Confederation Cup | Qualification',
    'كأس السوبر الأفريقي': 'CAF Super Cup',
    'كأس السوبر الإفريقي': 'CAF Super Cup',
    'كأس العرب': 'Arab Cup',
    'تصفيات كأس العالم': 'World Cup Qualification',
    'تصفيات كأس العالم - أفريقيا': 'World Cup Qualification - Africa',
    'تصفيات كأس العالم - أوروبا': 'World Cup Qualification - Europe',
    'تصفيات كأس العالم - آسيا': 'World Cup Qualification - Asia',
    'كأس العالم': 'FIFA World Cup',
    'كأس العالم تحت 17 سنة': 'FIFA U-17 World Cup',
    'كأس الإنتركونتيننتال للأندية': 'FIFA Intercontinental Cup',
    'كأس القارات للأندية': 'FIFA Intercontinental Cup',
    'دوري أبطال أوروبا': 'UEFA Champions League',
    'الدوري الأوروبي': 'UEFA Europa League',
    'دوري المؤتمر الأوروبي': 'UEFA Conference League',
    'دوري المؤتمر الاوروبي': 'UEFA Conference League',
    'دوري المؤتمر': 'UEFA Conference League',
    'دوري المؤتمر الأوروبي | الأدوار الإقصائية':
        'UEFA Conference League | Knockout Stage',
    'دوري المؤتمر الاوروبي | الأدوار الإقصائية':
        'UEFA Conference League | Knockout Stage',
    'كأس السوبر الأوروبي': 'UEFA Super Cup',
    'دوري الأمم الأوروبية': 'UEFA Nations League',
    'كأس أمم أوروبا': 'UEFA Euro',
    'يورو': 'UEFA Euro',
    'كأس آسيا': 'AFC Asian Cup',
    'دوري أبطال آسيا للنخبة': 'AFC Champions League Elite',
    'دوري أبطال آسيا 2': 'AFC Champions League Two',
    'دوري التحدي الآسيوي': 'AFC Challenge League',
    'دوري أبطال الخليج': 'Gulf Club Champions League',
    'كأس الخليج العربي': 'Arabian Gulf Cup',
    'كأس الخليج تحت 17 سنة': 'Gulf Cup U-17',
    'بطولة إتحاد غرب آسيا للناشئين': 'WAFF U-16 Championship',

    // Domestic Leagues & Cups
    'الدوري الإنجليزي الممتاز': 'Premier League',
    'الدوري الإنجليزي': 'Premier League',
    'البريميرليج': 'Premier League',
    'دوري البطولة الإنجليزية': 'EFL Championship',
    'كأس الاتحاد الإنجليزي': 'FA Cup',
    'كأس الرابطة الإنجليزية': 'EFL Cup',
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
    'كأس ألمانيا': 'DFB-Pokal',
    'كأس السوبر الألماني': 'DFB Supercup',

    'الدوري الفرنسي': 'Ligue 1',
    'ليج 1': 'Ligue 1',
    'كأس فرنسا': 'Coupe de France',
    'كأس السوبر الفرنسي': 'Trophée des Champions',

    'دوري روشن السعودي': 'Saudi Pro League',
    'الدوري السعودي للمحترفين': 'Saudi Pro League',
    'الدوري السعودي': 'Saudi Pro League',
    'دوري الدرجة الأولى السعودي': 'First Division League',
    'كأس خادم الحرمين الشريفين': 'King Cup',
    'كأس الملك': 'King Cup',
    'كأس السوبر السعودي': 'Saudi Super Cup',

    'الدوري المصري الممتاز': 'Egyptian Premier League',
    'الدوري المصري': 'Egyptian Premier League',
    'الدوري المصري - القسم الثاني': 'Egyptian Second Division',
    'كأس مصر': 'Egypt Cup',
    'كأس الرابطة المصرية': 'Egyptian League Cup',
    'كأس رابطة الأندية المصرية': 'Egyptian League Cup',
    'كأس عاصمة مصر': 'Egyptian League Cup',
    'كأس السوبر المصري': 'Egyptian Super Cup',

    'الدوري العراقي': 'Iraq Stars League',
    'دوري نجوم العراق': 'Iraq Stars League',
    'الدوري العراقي الدرجة الأولى': 'Iraqi First Division',
    'الدوري المغربي': 'Botola Pro',
    'الرابطة المحترفة الجزائرية الأولى': 'Algerian Professional League 1',
    'الرابطة التونسية لكرة القدم': 'Tunisian Professional League 1',
    'كأس السوبر السوري': 'Syrian Super Cup',
    'الدوري السوري الممتاز': 'Syrian Premier League',
    'الدوري القطري': 'Qatar Stars League',
    'كأس قطر': 'Qatar Cup',
    'كأس نجوم قطر': 'QSL Cup',
    'كأس السوبر الإماراتي': 'UAE Super Cup',
    'الدوري الإماراتي للمحترفين': 'UAE Pro League',
    'كأس مصرف أبوظبي الإسلامي': 'ADIB Cup',
    'الدوري الكويتي': 'Kuwait Premier League',
    'الدوري الأردني للمحترفين': 'Jordanian Pro League',
    'دوري المحترفين العماني': 'Oman Professional League',
    'الدوري البحريني الممتاز': 'Bahraini Premier League',
    'الدوري السوداني الممتاز': 'Sudan Premier League',
    'الدوري الليبي': 'Libyan Premier League',
    'كأس الجمهورية اليمنية': 'Yemen Republic Cup',
    'الدوري اليمني': 'Yemeni League',
    'مباراة ودية - أندية': 'Club Friendlies',
    'مباراة ودية': 'Friendlies',
  };

  static final Map<String, String> _enToAr = {
    for (final entry in _arToEn.entries) entry.value.toLowerCase(): entry.key,
    'uefa europa conference league': 'دوري المؤتمر الأوروبي',
    'europa conference league': 'دوري المؤتمر الأوروبي',
    'uefa conference league': 'دوري المؤتمر الأوروبي',
    'conference league': 'دوري المؤتمر الأوروبي',
    'caf champions league | qualification':
        'دوري أبطال أفريقيا | الأدوار الإقصائية',
    'caf confederation cup | qualification':
        'كأس الكونفيدرالية | الأدوار الإقصائية',
    'uefa conference league | knockout stage':
        'دوري المؤتمر الأوروبي | الأدوار الإقصائية',
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
      if (id != null) {
        final rId = resolveId(id);
        if (rId != null && _idToTitles.containsKey(rId)) {
          final pair = _idToTitles[rId]!;
          return isArabic ? pair.ar : pair.en;
        }
      }
      return '';
    }

    final trimmed = _cleanNoise(titleOrId);

    // 0. If the input explicitly carries a stage suffix (e.g. "| Qualification" or "| الأدوار الإقصائية"),
    // preserve the stage distinction so it isn't collapsed into the base tournament name.
    if (trimmed.contains('|')) {
      if (!isArabic) {
        if (_arToEn.containsKey(trimmed)) return _arToEn[trimmed]!;
        final normTrimmed = normalize(trimmed);
        for (final entry in _arToEn.entries) {
          if (normalize(entry.key) == normTrimmed) return entry.value;
        }
        if (!RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) return trimmed;
      } else {
        final lower = trimmed.toLowerCase();
        if (_enToAr.containsKey(lower)) return _enToAr[lower]!;
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) return trimmed;
      }
    }

    // 1. Check if trimmed is an ID or if id is provided in _idToTitles
    if (_idToTitles.containsKey(trimmed)) {
      final pair = _idToTitles[trimmed]!;
      return isArabic ? pair.ar : pair.en;
    }

    if (id != null && _idToTitles.containsKey(id.trim())) {
      final pair = _idToTitles[id.trim()]!;
      return isArabic ? pair.ar : pair.en;
    }

    final resolvedId =
        (id != null ? resolveId(id) : null) ?? resolveId(trimmed);
    if (resolvedId != null && _idToTitles.containsKey(resolvedId)) {
      final pair = _idToTitles[resolvedId]!;
      return isArabic ? pair.ar : pair.en;
    }

    // 2. Localization between Arabic and English
    if (!isArabic) {
      if (_arToEn.containsKey(trimmed)) {
        return _arToEn[trimmed]!;
      }
      final normInput = normalize(trimmed);
      if (normInput.contains('مؤتمر')) {
        return 'UEFA Conference League';
      }
      for (final entry in _arToEn.entries) {
        if (normalize(entry.key) == normInput) {
          return entry.value;
        }
      }
      if (!RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) {
        final lower = trimmed.toLowerCase();
        if (lower.contains('conference')) {
          return 'UEFA Conference League';
        }
        return trimmed;
      }
    } else {
      final lower = trimmed.toLowerCase();
      if (_enToAr.containsKey(lower)) {
        return _enToAr[lower]!;
      }
      if (lower.contains('conference')) {
        return 'دوري المؤتمر الأوروبي';
      }
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) {
        final norm = normalize(trimmed);
        if (norm.contains('مؤتمر')) {
          return 'دوري المؤتمر الأوروبي';
        }
        return trimmed;
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

    // Resolve effective IDs if passed as ID or if name is a pure numeric string
    final effIdA = cleanIdA.isNotEmpty
        ? cleanIdA
        : (int.tryParse(cleanA) != null ? cleanA : '');
    final effIdB = cleanIdB.isNotEmpty
        ? cleanIdB
        : (int.tryParse(cleanB) != null ? cleanB : '');

    // 1. Strict ID discrimination: If BOTH items provide an ID, they MUST match or alias
    if (effIdA.isNotEmpty && effIdB.isNotEmpty) {
      if (effIdA == effIdB) return true;
      final resIdA = resolveId(effIdA) ?? effIdA;
      final resIdB = resolveId(effIdB) ?? effIdB;
      if (resIdA == resIdB) return true;
      final pairA = _idToTitles[effIdA] ?? _idToTitles[resIdA];
      final pairB = _idToTitles[effIdB] ?? _idToTitles[resIdB];
      if (pairA != null && pairB != null && pairA == pairB) return true;
      // Both entities have explicit, different IDs -> they are NOT the same competition!
      return false;
    }

    // 2. Direct ID match if one is ID and other matched
    if (cleanIdA.isNotEmpty && cleanIdB.isNotEmpty && cleanIdA == cleanIdB) {
      return true;
    }

    // 2b. Stage-tolerant base name match
    final baseA =
        cleanA.contains('|') ? cleanA.split('|').first.trim() : cleanA;
    final baseB =
        cleanB.contains('|') ? cleanB.split('|').first.trim() : cleanB;

    // 3. Direct name match (case-insensitive)
    if (cleanA.isNotEmpty &&
        cleanB.isNotEmpty &&
        cleanA.toLowerCase() == cleanB.toLowerCase()) {
      return true;
    }

    // 4. Normalized Arabic match
    if (cleanA.isNotEmpty && cleanB.isNotEmpty) {
      final normA = normalize(cleanA);
      final normB = normalize(cleanB);
      if (normA == normB) return true;
    }

    // 5. Stage-tolerant base name match (only if neither has an explicit conflicting stage)
    if (baseA.isNotEmpty &&
        baseB.isNotEmpty &&
        (baseA != cleanA || baseB != cleanB)) {
      if (baseA.toLowerCase() == baseB.toLowerCase() ||
          normalize(baseA) == normalize(baseB) ||
          areSameCompetition(baseA, baseB, idA: idA, idB: idB)) {
        return true;
      }
    }

    // 6. Resolve IDs from names or IDs
    final resIdA = effIdA.isNotEmpty
        ? (resolveId(effIdA) ?? effIdA)
        : (cleanA.isNotEmpty ? resolveId(cleanA) : null);

    final resIdB = effIdB.isNotEmpty
        ? (resolveId(effIdB) ?? effIdB)
        : (cleanB.isNotEmpty ? resolveId(cleanB) : null);

    if (resIdA != null && resIdB != null && resIdA == resIdB) {
      return true;
    }

    // 7. Cross-check with _idToTitles (which maps duplicate API IDs to canonical names)
    final pairA = (effIdA.isNotEmpty && _idToTitles.containsKey(effIdA))
        ? _idToTitles[effIdA]
        : ((resIdA != null && _idToTitles.containsKey(resIdA))
            ? _idToTitles[resIdA]
            : null);

    final pairB = (effIdB.isNotEmpty && _idToTitles.containsKey(effIdB))
        ? _idToTitles[effIdB]
        : ((resIdB != null && _idToTitles.containsKey(resIdB))
            ? _idToTitles[resIdB]
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

    // 8. Cross-language mapping (_arToEn and _enToAr)
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
