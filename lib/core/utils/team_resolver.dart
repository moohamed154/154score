class TeamResolver {
  TeamResolver._();

  /// Canonical team dictionary mapping normalized/clean aliases to canonical IDs/keys
  /// and localized names (Arabic & English).
  static const Map<String, ({String canonical, String ar, String en})> _teamMap = {
    // --- National Teams ---
    // Egypt
    'مصر': (canonical: 'egypt', ar: 'مصر', en: 'Egypt'),
    'منتخب مصر': (canonical: 'egypt', ar: 'مصر', en: 'Egypt'),
    'الفراعنة': (canonical: 'egypt', ar: 'مصر', en: 'Egypt'),
    'egypt': (canonical: 'egypt', ar: 'مصر', en: 'Egypt'),
    'national team egypt': (canonical: 'egypt', ar: 'مصر', en: 'Egypt'),
    'egypt national team': (canonical: 'egypt', ar: 'مصر', en: 'Egypt'),

    // Angola
    'أنغولا': (canonical: 'angola', ar: 'أنغولا', en: 'Angola'),
    'انغولا': (canonical: 'angola', ar: 'أنغولا', en: 'Angola'),
    'منتخب أنغولا': (canonical: 'angola', ar: 'أنغولا', en: 'Angola'),
    'منتخب انغولا': (canonical: 'angola', ar: 'أنغولا', en: 'Angola'),
    'angola': (canonical: 'angola', ar: 'أنغولا', en: 'Angola'),

    // Saudi Arabia
    'السعودية': (canonical: 'saudi_arabia', ar: 'السعودية', en: 'Saudi Arabia'),
    'منتخب السعودية': (canonical: 'saudi_arabia', ar: 'السعودية', en: 'Saudi Arabia'),
    'الأخضر': (canonical: 'saudi_arabia', ar: 'السعودية', en: 'Saudi Arabia'),
    'الاخضر': (canonical: 'saudi_arabia', ar: 'السعودية', en: 'Saudi Arabia'),
    'saudi arabia': (canonical: 'saudi_arabia', ar: 'السعودية', en: 'Saudi Arabia'),
    'ksa': (canonical: 'saudi_arabia', ar: 'السعودية', en: 'Saudi Arabia'),

    // Morocco
    'المغرب': (canonical: 'morocco', ar: 'المغرب', en: 'Morocco'),
    'منتخب المغرب': (canonical: 'morocco', ar: 'المغرب', en: 'Morocco'),
    'أسود الأطلس': (canonical: 'morocco', ar: 'المغرب', en: 'Morocco'),
    'morocco': (canonical: 'morocco', ar: 'المغرب', en: 'Morocco'),

    // Algeria
    'الجزائر': (canonical: 'algeria', ar: 'الجزائر', en: 'Algeria'),
    'منتخب الجزائر': (canonical: 'algeria', ar: 'الجزائر', en: 'Algeria'),
    'محاربو الصحراء': (canonical: 'algeria', ar: 'الجزائر', en: 'Algeria'),
    'algeria': (canonical: 'algeria', ar: 'الجزائر', en: 'Algeria'),

    // Tunisia
    'تونس': (canonical: 'tunisia', ar: 'تونس', en: 'Tunisia'),
    'منتخب تونس': (canonical: 'tunisia', ar: 'تونس', en: 'Tunisia'),
    'نسور قرطاج': (canonical: 'tunisia', ar: 'تونس', en: 'Tunisia'),
    'tunisia': (canonical: 'tunisia', ar: 'تونس', en: 'Tunisia'),

    // Qatar
    'قطر': (canonical: 'qatar', ar: 'قطر', en: 'Qatar'),
    'منتخب قطر': (canonical: 'qatar', ar: 'قطر', en: 'Qatar'),
    'العنابي': (canonical: 'qatar', ar: 'قطر', en: 'Qatar'),
    'qatar': (canonical: 'qatar', ar: 'قطر', en: 'Qatar'),

    // UAE
    'الإمارات': (canonical: 'uae', ar: 'الإمارات', en: 'UAE'),
    'الامارات': (canonical: 'uae', ar: 'الإمارات', en: 'UAE'),
    'منتخب الإمارات': (canonical: 'uae', ar: 'الإمارات', en: 'UAE'),
    'uae': (canonical: 'uae', ar: 'الإمارات', en: 'UAE'),
    'united arab emirates': (canonical: 'uae', ar: 'الإمارات', en: 'UAE'),

    // Jordan
    'الأردن': (canonical: 'jordan', ar: 'الأردن', en: 'Jordan'),
    'الاردن': (canonical: 'jordan', ar: 'الأردن', en: 'Jordan'),
    'منتخب الأردن': (canonical: 'jordan', ar: 'الأردن', en: 'Jordan'),
    'النشامى': (canonical: 'jordan', ar: 'الأردن', en: 'Jordan'),
    'jordan': (canonical: 'jordan', ar: 'الأردن', en: 'Jordan'),

    // Iraq
    'العراق': (canonical: 'iraq', ar: 'العراق', en: 'Iraq'),
    'منتخب العراق': (canonical: 'iraq', ar: 'العراق', en: 'Iraq'),
    'أسود الرافدين': (canonical: 'iraq', ar: 'العراق', en: 'Iraq'),
    'iraq': (canonical: 'iraq', ar: 'العراق', en: 'Iraq'),

    // Kuwait
    'الكويت': (canonical: 'kuwait', ar: 'الكويت', en: 'Kuwait'),
    'منتخب الكويت': (canonical: 'kuwait', ar: 'الكويت', en: 'Kuwait'),
    'الأزرق': (canonical: 'kuwait', ar: 'الكويت', en: 'Kuwait'),
    'kuwait': (canonical: 'kuwait', ar: 'الكويت', en: 'Kuwait'),

    // Oman
    'عمان': (canonical: 'oman', ar: 'عمان', en: 'Oman'),
    'عُمان': (canonical: 'oman', ar: 'عمان', en: 'Oman'),
    'منتخب عمان': (canonical: 'oman', ar: 'عمان', en: 'Oman'),
    'oman': (canonical: 'oman', ar: 'عمان', en: 'Oman'),

    // Bahrain
    'البحرين': (canonical: 'bahrain', ar: 'البحرين', en: 'Bahrain'),
    'منتخب البحرين': (canonical: 'bahrain', ar: 'البحرين', en: 'Bahrain'),
    'bahrain': (canonical: 'bahrain', ar: 'البحرين', en: 'Bahrain'),

    // Palestine
    'فلسطين': (canonical: 'palestine', ar: 'فلسطين', en: 'Palestine'),
    'منتخب فلسطين': (canonical: 'palestine', ar: 'فلسطين', en: 'Palestine'),
    'الفدائي': (canonical: 'palestine', ar: 'فلسطين', en: 'Palestine'),
    'palestine': (canonical: 'palestine', ar: 'فلسطين', en: 'Palestine'),

    // Syria
    'سوريا': (canonical: 'syria', ar: 'سوريا', en: 'Syria'),
    'منتخب سوريا': (canonical: 'syria', ar: 'سوريا', en: 'Syria'),
    'نسور قاسيون': (canonical: 'syria', ar: 'سوريا', en: 'Syria'),
    'syria': (canonical: 'syria', ar: 'سوريا', en: 'Syria'),

    // Lebanon
    'لبنان': (canonical: 'lebanon', ar: 'لبنان', en: 'Lebanon'),
    'منتخب لبنان': (canonical: 'lebanon', ar: 'لبنان', en: 'Lebanon'),
    'lebanon': (canonical: 'lebanon', ar: 'لبنان', en: 'Lebanon'),

    // Sudan
    'السودان': (canonical: 'sudan', ar: 'السودان', en: 'Sudan'),
    'منتخب السودان': (canonical: 'sudan', ar: 'السودان', en: 'Sudan'),
    'صقور الجديان': (canonical: 'sudan', ar: 'السودان', en: 'Sudan'),
    'sudan': (canonical: 'sudan', ar: 'السودان', en: 'Sudan'),

    // Libya
    'ليبيا': (canonical: 'libya', ar: 'ليبيا', en: 'Libya'),
    'منتخب ليبيا': (canonical: 'libya', ar: 'ليبيا', en: 'Libya'),
    'فرسان المتوسط': (canonical: 'libya', ar: 'ليبيا', en: 'Libya'),
    'libya': (canonical: 'libya', ar: 'ليبيا', en: 'Libya'),

    // Yemen
    'اليمن': (canonical: 'yemen', ar: 'اليمن', en: 'Yemen'),
    'منتخب اليمن': (canonical: 'yemen', ar: 'اليمن', en: 'Yemen'),
    'yemen': (canonical: 'yemen', ar: 'اليمن', en: 'Yemen'),

    // Mauritania
    'موريتانيا': (canonical: 'mauritania', ar: 'موريتانيا', en: 'Mauritania'),
    'منتخب موريتانيا': (canonical: 'mauritania', ar: 'موريتانيا', en: 'Mauritania'),
    'المرابطون': (canonical: 'mauritania', ar: 'موريتانيا', en: 'Mauritania'),
    'mauritania': (canonical: 'mauritania', ar: 'موريتانيا', en: 'Mauritania'),

    // Brazil
    'البرازيل': (canonical: 'brazil', ar: 'البرازيل', en: 'Brazil'),
    'منتخب البرازيل': (canonical: 'brazil', ar: 'البرازيل', en: 'Brazil'),
    'السامبا': (canonical: 'brazil', ar: 'البرازيل', en: 'Brazil'),
    'brazil': (canonical: 'brazil', ar: 'البرازيل', en: 'Brazil'),
    'brasil': (canonical: 'brazil', ar: 'البرازيل', en: 'Brazil'),

    // Argentina
    'الأرجنتين': (canonical: 'argentina', ar: 'الأرجنتين', en: 'Argentina'),
    'الارجنتين': (canonical: 'argentina', ar: 'الأرجنتين', en: 'Argentina'),
    'منتخب الأرجنتين': (canonical: 'argentina', ar: 'الأرجنتين', en: 'Argentina'),
    'التانغو': (canonical: 'argentina', ar: 'الأرجنتين', en: 'Argentina'),
    'argentina': (canonical: 'argentina', ar: 'الأرجنتين', en: 'Argentina'),

    // France
    'فرنسا': (canonical: 'france', ar: 'فرنسا', en: 'France'),
    'منتخب فرنسا': (canonical: 'france', ar: 'فرنسا', en: 'France'),
    'الديوك': (canonical: 'france', ar: 'فرنسا', en: 'France'),
    'france': (canonical: 'france', ar: 'فرنسا', en: 'France'),

    // Germany
    'ألمانيا': (canonical: 'germany', ar: 'ألمانيا', en: 'Germany'),
    'المانيا': (canonical: 'germany', ar: 'ألمانيا', en: 'Germany'),
    'منتخب ألمانيا': (canonical: 'germany', ar: 'ألمانيا', en: 'Germany'),
    'الماكينات': (canonical: 'germany', ar: 'ألمانيا', en: 'Germany'),
    'germany': (canonical: 'germany', ar: 'ألمانيا', en: 'Germany'),

    // Spain
    'إسبانيا': (canonical: 'spain', ar: 'إسبانيا', en: 'Spain'),
    'اسبانيا': (canonical: 'spain', ar: 'إسبانيا', en: 'Spain'),
    'منتخب إسبانيا': (canonical: 'spain', ar: 'إسبانيا', en: 'Spain'),
    'الماتادور': (canonical: 'spain', ar: 'إسبانيا', en: 'Spain'),
    'spain': (canonical: 'spain', ar: 'إسبانيا', en: 'Spain'),

    // England
    'إنجلترا': (canonical: 'england', ar: 'إنجلترا', en: 'England'),
    'انجلترا': (canonical: 'england', ar: 'إنجلترا', en: 'England'),
    'منتخب إنجلترا': (canonical: 'england', ar: 'إنجلترا', en: 'England'),
    'الأسود الثلاثة': (canonical: 'england', ar: 'إنجلترا', en: 'England'),
    'england': (canonical: 'england', ar: 'إنجلترا', en: 'England'),

    // Portugal
    'البرتغال': (canonical: 'portugal', ar: 'البرتغال', en: 'Portugal'),
    'منتخب البرتغال': (canonical: 'portugal', ar: 'البرتغال', en: 'Portugal'),
    'برازيل أوروبا': (canonical: 'portugal', ar: 'البرتغال', en: 'Portugal'),
    'portugal': (canonical: 'portugal', ar: 'البرتغال', en: 'Portugal'),

    // Italy
    'إيطاليا': (canonical: 'italy', ar: 'إيطاليا', en: 'Italy'),
    'ايطاليا': (canonical: 'italy', ar: 'إيطاليا', en: 'Italy'),
    'منتخب إيطاليا': (canonical: 'italy', ar: 'إيطاليا', en: 'Italy'),
    'الآزوري': (canonical: 'italy', ar: 'إيطاليا', en: 'Italy'),
    'الازوري': (canonical: 'italy', ar: 'إيطاليا', en: 'Italy'),
    'italy': (canonical: 'italy', ar: 'إيطاليا', en: 'Italy'),

    // Netherlands
    'هولندا': (canonical: 'netherlands', ar: 'هولندا', en: 'Netherlands'),
    'منتخب هولندا': (canonical: 'netherlands', ar: 'هولندا', en: 'Netherlands'),
    'الطواحين': (canonical: 'netherlands', ar: 'هولندا', en: 'Netherlands'),
    'netherlands': (canonical: 'netherlands', ar: 'هولندا', en: 'Netherlands'),
    'holland': (canonical: 'netherlands', ar: 'هولندا', en: 'Netherlands'),

    // Croatia
    'كرواتيا': (canonical: 'croatia', ar: 'كرواتيا', en: 'Croatia'),
    'منتخب كرواتيا': (canonical: 'croatia', ar: 'كرواتيا', en: 'Croatia'),
    'croatia': (canonical: 'croatia', ar: 'كرواتيا', en: 'Croatia'),

    // Belgium
    'بلجيكا': (canonical: 'belgium', ar: 'بلجيكا', en: 'Belgium'),
    'منتخب بلجيكا': (canonical: 'belgium', ar: 'بلجيكا', en: 'Belgium'),
    'الشياطين الحمر': (canonical: 'belgium', ar: 'بلجيكا', en: 'Belgium'),
    'belgium': (canonical: 'belgium', ar: 'بلجيكا', en: 'Belgium'),

    // Senegal
    'السنغال': (canonical: 'senegal', ar: 'السنغال', en: 'Senegal'),
    'منتخب السنغال': (canonical: 'senegal', ar: 'السنغال', en: 'Senegal'),
    'أسود التيرانغا': (canonical: 'senegal', ar: 'السنغال', en: 'Senegal'),
    'senegal': (canonical: 'senegal', ar: 'السنغال', en: 'Senegal'),

    // Nigeria
    'نيجيريا': (canonical: 'nigeria', ar: 'نيجيريا', en: 'Nigeria'),
    'منتخب نيجيريا': (canonical: 'nigeria', ar: 'نيجيريا', en: 'Nigeria'),
    'النسور الخضراء': (canonical: 'nigeria', ar: 'نيجيريا', en: 'Nigeria'),
    'nigeria': (canonical: 'nigeria', ar: 'نيجيريا', en: 'Nigeria'),

    // Ivory Coast
    'ساحل العاج': (canonical: 'ivory_coast', ar: 'كوت ديفوار', en: 'Ivory Coast'),
    'كوت ديفوار': (canonical: 'ivory_coast', ar: 'كوت ديفوار', en: 'Ivory Coast'),
    'منتخب كوت ديفوار': (canonical: 'ivory_coast', ar: 'كوت ديفوار', en: 'Ivory Coast'),
    'الأفيال': (canonical: 'ivory_coast', ar: 'كوت ديفوار', en: 'Ivory Coast'),
    'ivory coast': (canonical: 'ivory_coast', ar: 'كوت ديفوار', en: 'Ivory Coast'),
    "cote d'ivoire": (canonical: 'ivory_coast', ar: 'كوت ديفوار', en: 'Ivory Coast'),

    // Cameroon
    'الكاميرون': (canonical: 'cameroon', ar: 'الكاميرون', en: 'Cameroon'),
    'منتخب الكاميرون': (canonical: 'cameroon', ar: 'الكاميرون', en: 'Cameroon'),
    'الأسود غير المروضة': (canonical: 'cameroon', ar: 'الكاميرون', en: 'Cameroon'),
    'cameroon': (canonical: 'cameroon', ar: 'الكاميرون', en: 'Cameroon'),

    // Ghana
    'غانا': (canonical: 'ghana', ar: 'غانا', en: 'Ghana'),
    'منتخب غانا': (canonical: 'ghana', ar: 'غانا', en: 'Ghana'),
    'النجوم السوداء': (canonical: 'ghana', ar: 'غانا', en: 'Ghana'),
    'ghana': (canonical: 'ghana', ar: 'غانا', en: 'Ghana'),

    // South Africa
    'جنوب إفريقيا': (canonical: 'south_africa', ar: 'جنوب إفريقيا', en: 'South Africa'),
    'جنوب افريقيا': (canonical: 'south_africa', ar: 'جنوب إفريقيا', en: 'South Africa'),
    'بافانا بافانا': (canonical: 'south_africa', ar: 'جنوب إفريقيا', en: 'South Africa'),
    'south africa': (canonical: 'south_africa', ar: 'جنوب إفريقيا', en: 'South Africa'),

    // DR Congo
    'الكونغو الديمقراطية': (canonical: 'dr_congo', ar: 'الكونغو الديمقراطية', en: 'DR Congo'),
    'الكونغو': (canonical: 'dr_congo', ar: 'الكونغو الديمقراطية', en: 'DR Congo'),
    'dr congo': (canonical: 'dr_congo', ar: 'الكونغو الديمقراطية', en: 'DR Congo'),
    'congo dr': (canonical: 'dr_congo', ar: 'الكونغو الديمقراطية', en: 'DR Congo'),

    // USA
    'أمريكا': (canonical: 'usa', ar: 'أمريكا', en: 'USA'),
    'الولايات المتحدة': (canonical: 'usa', ar: 'الولايات المتحدة', en: 'USA'),
    'usa': (canonical: 'usa', ar: 'أمريكا', en: 'USA'),
    'united states': (canonical: 'usa', ar: 'أمريكا', en: 'USA'),

    // Mexico
    'المكسيك': (canonical: 'mexico', ar: 'المكسيك', en: 'Mexico'),
    'منتخب المكسيك': (canonical: 'mexico', ar: 'المكسيك', en: 'Mexico'),
    'mexico': (canonical: 'mexico', ar: 'المكسيك', en: 'Mexico'),

    // Japan
    'اليابان': (canonical: 'japan', ar: 'اليابان', en: 'Japan'),
    'منتخب اليابان': (canonical: 'japan', ar: 'اليابان', en: 'Japan'),
    'الساموراي': (canonical: 'japan', ar: 'اليابان', en: 'Japan'),
    'japan': (canonical: 'japan', ar: 'اليابان', en: 'Japan'),

    // South Korea
    'كوريا الجنوبية': (canonical: 'south_korea', ar: 'كوريا الجنوبية', en: 'South Korea'),
    'منتخب كوريا الجنوبية': (canonical: 'south_korea', ar: 'كوريا الجنوبية', en: 'South Korea'),
    'south korea': (canonical: 'south_korea', ar: 'كوريا الجنوبية', en: 'South Korea'),
    'korea republic': (canonical: 'south_korea', ar: 'كوريا الجنوبية', en: 'South Korea'),

    // --- Major European Clubs ---
    // Real Madrid
    'ريال مدريد': (canonical: 'real_madrid', ar: 'ريال مدريد', en: 'Real Madrid'),
    'الميرنجي': (canonical: 'real_madrid', ar: 'ريال مدريد', en: 'Real Madrid'),
    'الملكي': (canonical: 'real_madrid', ar: 'ريال مدريد', en: 'Real Madrid'),
    'real madrid': (canonical: 'real_madrid', ar: 'ريال مدريد', en: 'Real Madrid'),
    'real madrid cf': (canonical: 'real_madrid', ar: 'ريال مدريد', en: 'Real Madrid'),

    // Barcelona
    'برشلونة': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),
    'البارسا': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),
    'البارشا': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),
    'البلواغرانا': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),
    'barcelona': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),
    'fc barcelona': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),
    'barca': (canonical: 'barcelona', ar: 'برشلونة', en: 'Barcelona'),

    // Atletico Madrid
    'أتلتيكو مدريد': (canonical: 'atletico_madrid', ar: 'أتلتيكو مدريد', en: 'Atletico Madrid'),
    'اتلتيكو مدريد': (canonical: 'atletico_madrid', ar: 'أتلتيكو مدريد', en: 'Atletico Madrid'),
    'الروخي بلانكوس': (canonical: 'atletico_madrid', ar: 'أتلتيكو مدريد', en: 'Atletico Madrid'),
    'atletico madrid': (canonical: 'atletico_madrid', ar: 'أتلتيكو مدريد', en: 'Atletico Madrid'),
    'atletico de madrid': (canonical: 'atletico_madrid', ar: 'أتلتيكو مدريد', en: 'Atletico Madrid'),

    // Liverpool
    'ليفربول': (canonical: 'liverpool', ar: 'ليفربول', en: 'Liverpool'),
    'الريدز': (canonical: 'liverpool', ar: 'ليفربول', en: 'Liverpool'),
    'liverpool': (canonical: 'liverpool', ar: 'ليفربول', en: 'Liverpool'),
    'liverpool fc': (canonical: 'liverpool', ar: 'ليفربول', en: 'Liverpool'),

    // Manchester City
    'مانشستر سيتي': (canonical: 'man_city', ar: 'مانشستر سيتي', en: 'Manchester City'),
    'مان سيتي': (canonical: 'man_city', ar: 'مانشستر سيتي', en: 'Manchester City'),
    'السيتيزنز': (canonical: 'man_city', ar: 'مانشستر سيتي', en: 'Manchester City'),
    'manchester city': (canonical: 'man_city', ar: 'مانشستر سيتي', en: 'Manchester City'),
    'man city': (canonical: 'man_city', ar: 'مانشستر سيتي', en: 'Manchester City'),
    'manchester city fc': (canonical: 'man_city', ar: 'مانشستر سيتي', en: 'Manchester City'),

    // Manchester United
    'مانشستر يونايتد': (canonical: 'man_united', ar: 'مانشستر يونايتد', en: 'Manchester United'),
    'مان يونايتد': (canonical: 'man_united', ar: 'مانشستر يونايتد', en: 'Manchester United'),
    'الشياطين الحمر مانشستر': (canonical: 'man_united', ar: 'مانشستر يونايتد', en: 'Manchester United'),
    'manchester united': (canonical: 'man_united', ar: 'مانشستر يونايتد', en: 'Manchester United'),
    'man united': (canonical: 'man_united', ar: 'مانشستر يونايتد', en: 'Manchester United'),
    'man utd': (canonical: 'man_united', ar: 'مانشستر يونايتد', en: 'Manchester United'),

    // Arsenal
    'أرسنال': (canonical: 'arsenal', ar: 'أرسنال', en: 'Arsenal'),
    'ارسنال': (canonical: 'arsenal', ar: 'أرسنال', en: 'Arsenal'),
    'الجانرز': (canonical: 'arsenal', ar: 'أرسنال', en: 'Arsenal'),
    'المدفعجية': (canonical: 'arsenal', ar: 'أرسنال', en: 'Arsenal'),
    'arsenal': (canonical: 'arsenal', ar: 'أرسنال', en: 'Arsenal'),
    'arsenal fc': (canonical: 'arsenal', ar: 'أرسنال', en: 'Arsenal'),

    // Chelsea
    'تشيلسي': (canonical: 'chelsea', ar: 'تشيلسي', en: 'Chelsea'),
    'البلوز': (canonical: 'chelsea', ar: 'تشيلسي', en: 'Chelsea'),
    'chelsea': (canonical: 'chelsea', ar: 'تشيلسي', en: 'Chelsea'),
    'chelsea fc': (canonical: 'chelsea', ar: 'تشيلسي', en: 'Chelsea'),

    // Tottenham
    'توتنهام': (canonical: 'tottenham', ar: 'توتنهام', en: 'Tottenham Hotspur'),
    'توتنهام هوتسبير': (canonical: 'tottenham', ar: 'توتنهام', en: 'Tottenham Hotspur'),
    'السبيرز': (canonical: 'tottenham', ar: 'توتنهام', en: 'Tottenham Hotspur'),
    'tottenham': (canonical: 'tottenham', ar: 'توتنهام', en: 'Tottenham Hotspur'),
    'tottenham hotspur': (canonical: 'tottenham', ar: 'توتنهام', en: 'Tottenham Hotspur'),
    'spurs': (canonical: 'tottenham', ar: 'توتنهام', en: 'Tottenham Hotspur'),

    // Bayern Munich
    'بايرن ميونخ': (canonical: 'bayern_munich', ar: 'بايرن ميونخ', en: 'Bayern Munich'),
    'بايرن ميونيخ': (canonical: 'bayern_munich', ar: 'بايرن ميونخ', en: 'Bayern Munich'),
    'البايرن': (canonical: 'bayern_munich', ar: 'بايرن ميونخ', en: 'Bayern Munich'),
    'bayern munich': (canonical: 'bayern_munich', ar: 'بايرن ميونخ', en: 'Bayern Munich'),
    'fc bayern munchen': (canonical: 'bayern_munich', ar: 'بايرن ميونخ', en: 'Bayern Munich'),
    'bayern': (canonical: 'bayern_munich', ar: 'بايرن ميونخ', en: 'Bayern Munich'),

    // Borussia Dortmund
    'بوروسيا دورتموند': (canonical: 'dortmund', ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund'),
    'دورتموند': (canonical: 'dortmund', ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund'),
    'borussia dortmund': (canonical: 'dortmund', ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund'),
    'dortmund': (canonical: 'dortmund', ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund'),
    'bvb': (canonical: 'dortmund', ar: 'بوروسيا دورتموند', en: 'Borussia Dortmund'),

    // Bayer Leverkusen
    'باير ليفركوزن': (canonical: 'leverkusen', ar: 'باير ليفركوزن', en: 'Bayer Leverkusen'),
    'ليفركوزن': (canonical: 'leverkusen', ar: 'باير ليفركوزن', en: 'Bayer Leverkusen'),
    'bayer leverkusen': (canonical: 'leverkusen', ar: 'باير ليفركوزن', en: 'Bayer Leverkusen'),
    'leverkusen': (canonical: 'leverkusen', ar: 'باير ليفركوزن', en: 'Bayer Leverkusen'),

    // Paris Saint-Germain
    'باريس سان جيرمان': (canonical: 'psg', ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),
    'باريس سان جرمان': (canonical: 'psg', ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),
    'باريس': (canonical: 'psg', ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),
    'paris saint-germain': (canonical: 'psg', ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),
    'paris saint germain': (canonical: 'psg', ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),
    'psg': (canonical: 'psg', ar: 'باريس سان جيرمان', en: 'Paris Saint-Germain'),

    // Juventus
    'يوفنتوس': (canonical: 'juventus', ar: 'يوفنتوس', en: 'Juventus'),
    'اليوفي': (canonical: 'juventus', ar: 'يوفنتوس', en: 'Juventus'),
    'السيدة العجوز': (canonical: 'juventus', ar: 'يوفنتوس', en: 'Juventus'),
    'juventus': (canonical: 'juventus', ar: 'يوفنتوس', en: 'Juventus'),
    'juve': (canonical: 'juventus', ar: 'يوفنتوس', en: 'Juventus'),

    // Inter Milan
    'إنتر ميلان': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'انتر ميلان': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'إنتر': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'انتر': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'النيراتزوري': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'inter milan': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'inter': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),
    'internazionale': (canonical: 'inter_milan', ar: 'إنتر ميلان', en: 'Inter Milan'),

    // AC Milan
    'ميلان': (canonical: 'ac_milan', ar: 'إيه سي ميلان', en: 'AC Milan'),
    'إيه سي ميلان': (canonical: 'ac_milan', ar: 'إيه سي ميلان', en: 'AC Milan'),
    'ايه سي ميلان': (canonical: 'ac_milan', ar: 'إيه سي ميلان', en: 'AC Milan'),
    'الروسونيري': (canonical: 'ac_milan', ar: 'إيه سي ميلان', en: 'AC Milan'),
    'ac milan': (canonical: 'ac_milan', ar: 'إيه سي ميلان', en: 'AC Milan'),
    'milan': (canonical: 'ac_milan', ar: 'إيه سي ميلان', en: 'AC Milan'),

    // Napoli
    'نابولي': (canonical: 'napoli', ar: 'نابولي', en: 'Napoli'),
    'napoli': (canonical: 'napoli', ar: 'نابولي', en: 'Napoli'),

    // Roma
    'روما': (canonical: 'roma', ar: 'روما', en: 'AS Roma'),
    'as roma': (canonical: 'roma', ar: 'روما', en: 'AS Roma'),
    'roma': (canonical: 'roma', ar: 'روما', en: 'AS Roma'),

    // --- Major Arab / African Clubs ---
    // Al Ahly
    'الأهلي': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'الاهلي': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'الأهلي المصري': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'الاهلي المصري': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'النادي الأهلي': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'المارد الأحمر': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'al ahly': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'al-ahly': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'ahly': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),
    'el ahly': (canonical: 'al_ahly', ar: 'الأهلي', en: 'Al Ahly'),

    // Zamalek
    'الزمالك': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),
    'الزمالك المصري': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),
    'نادي الزمالك': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),
    'الفارس الأبيض': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),
    'zamalek': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),
    'el zamalek': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),
    'zamalek sc': (canonical: 'zamalek', ar: 'الزمالك', en: 'Zamalek'),

    // Pyramids
    'بيراميدز': (canonical: 'pyramids', ar: 'بيراميدز', en: 'Pyramids FC'),
    'نادي بيراميدز': (canonical: 'pyramids', ar: 'بيراميدز', en: 'Pyramids FC'),
    'pyramids': (canonical: 'pyramids', ar: 'بيراميدز', en: 'Pyramids FC'),
    'pyramids fc': (canonical: 'pyramids', ar: 'بيراميدز', en: 'Pyramids FC'),

    // Al Hilal
    'الهلال': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),
    'الهلال السعودي': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),
    'نادي الهلال': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),
    'الزعيم': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),
    'al hilal': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),
    'al-hilal': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),
    'hilal': (canonical: 'al_hilal', ar: 'الهلال', en: 'Al Hilal'),

    // Al Nassr
    'النصر': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),
    'النصر السعودي': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),
    'نادي النصر': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),
    'العالمي': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),
    'al nassr': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),
    'al-nassr': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),
    'nassr': (canonical: 'al_nassr', ar: 'النصر', en: 'Al Nassr'),

    // Al Ittihad
    'الاتحاد': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),
    'الاتحاد السعودي': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),
    'نادي الاتحاد': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),
    'العميد': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),
    'al ittihad': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),
    'al-ittihad': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),
    'ittihad': (canonical: 'al_ittihad', ar: 'الاتحاد', en: 'Al Ittihad'),

    // Al Ahli Saudi
    'الأهلي السعودي': (canonical: 'al_ahli_saudi', ar: 'الأهلي السعودي', en: 'Al Ahli'),
    'الاهلي السعودي': (canonical: 'al_ahli_saudi', ar: 'الأهلي السعودي', en: 'Al Ahli'),
    'al ahli saudi': (canonical: 'al_ahli_saudi', ar: 'الأهلي السعودي', en: 'Al Ahli'),
    'al-ahli saudi': (canonical: 'al_ahli_saudi', ar: 'الأهلي السعودي', en: 'Al Ahli'),

    // Al Shabab
    'الشباب': (canonical: 'al_shabab', ar: 'الشباب', en: 'Al Shabab'),
    'الشباب السعودي': (canonical: 'al_shabab', ar: 'الشباب', en: 'Al Shabab'),
    'al shabab': (canonical: 'al_shabab', ar: 'الشباب', en: 'Al Shabab'),

    // Al Ain
    'العين': (canonical: 'al_ain', ar: 'العين', en: 'Al Ain'),
    'العين الإماراتي': (canonical: 'al_ain', ar: 'العين', en: 'Al Ain'),
    'al ain': (canonical: 'al_ain', ar: 'العين', en: 'Al Ain'),

    // Wydad
    'الوداد': (canonical: 'wydad', ar: 'الوداد', en: 'Wydad AC'),
    'الوداد البيضاوي': (canonical: 'wydad', ar: 'الوداد', en: 'Wydad AC'),
    'الوداد الرياضي': (canonical: 'wydad', ar: 'الوداد', en: 'Wydad AC'),
    'wydad': (canonical: 'wydad', ar: 'الوداد', en: 'Wydad AC'),
    'wydad ac': (canonical: 'wydad', ar: 'الوداد', en: 'Wydad AC'),

    // Raja
    'الرجاء': (canonical: 'raja', ar: 'الرجاء', en: 'Raja CA'),
    'الرجاء البيضاوي': (canonical: 'raja', ar: 'الرجاء', en: 'Raja CA'),
    'الرجاء الرياضي': (canonical: 'raja', ar: 'الرجاء', en: 'Raja CA'),
    'raja': (canonical: 'raja', ar: 'الرجاء', en: 'Raja CA'),
    'raja ca': (canonical: 'raja', ar: 'الرجاء', en: 'Raja CA'),

    // Esperance
    'الترجي': (canonical: 'esperance', ar: 'الترجي', en: 'Esperance Tunis'),
    'الترجي الرياضي': (canonical: 'esperance', ar: 'الترجي', en: 'Esperance Tunis'),
    'الترجي التونسي': (canonical: 'esperance', ar: 'الترجي', en: 'Esperance Tunis'),
    'esperance': (canonical: 'esperance', ar: 'الترجي', en: 'Esperance Tunis'),
    'esperance de tunis': (canonical: 'esperance', ar: 'الترجي', en: 'Esperance Tunis'),

    // Mamelodi Sundowns
    'صن داونز': (canonical: 'sundowns', ar: 'صن داونز', en: 'Mamelodi Sundowns'),
    'ماميلودي صن داونز': (canonical: 'sundowns', ar: 'صن داونز', en: 'Mamelodi Sundowns'),
    'mamelodi sundowns': (canonical: 'sundowns', ar: 'صن داونز', en: 'Mamelodi Sundowns'),
    'sundowns': (canonical: 'sundowns', ar: 'صن داونز', en: 'Mamelodi Sundowns'),
  };

  /// Normalizes Arabic text for tolerant matching (standardizes letters, strips diacritics).
  static String normalize(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\-_/\\]'), ' ');
    // Remove Arabic diacritics
    s = s.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    // Standardize Alef
    s = s.replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627');
    // Standardize Teh Marbuta
    s = s.replaceAll('\u0629', '\u0647');
    // Standardize Alef Maksura
    s = s.replaceAll('\u0649', '\u064A');
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Strips redundant prefixes like "منتخب " (national team) or "نادي " (club) or "fc", "sc".
  static String stripCommonPrefixes(String input) {
    var s = normalize(input);
    final prefixes = [
      'منتخب ',
      'نادي ',
      'فريق ',
      'fc ',
      'sc ',
      'cf ',
      'ac ',
      'the ',
    ];
    for (final p in prefixes) {
      if (s.startsWith(p)) {
        s = s.substring(p.length).trim();
      }
    }
    final suffixes = [
      ' fc',
      ' sc',
      ' cf',
      ' ac',
      ' national team',
    ];
    for (final suf in suffixes) {
      if (s.endsWith(suf)) {
        s = s.substring(0, s.length - suf.length).trim();
      }
    }
    return s;
  }

  /// Resolves the canonical key for a team by checking direct aliases,
  /// normalized forms, and prefix-stripped forms.
  static String? getCanonicalKey(String? nameOrId) {
    if (nameOrId == null || nameOrId.trim().isEmpty) return null;
    final trimmed = nameOrId.trim().toLowerCase();

    // 1. Direct dictionary match
    if (_teamMap.containsKey(trimmed)) {
      return _teamMap[trimmed]!.canonical;
    }

    // 2. Normalized dictionary match
    final norm = normalize(trimmed);
    for (final entry in _teamMap.entries) {
      if (normalize(entry.key) == norm) {
        return entry.value.canonical;
      }
    }

    // 3. Prefix-stripped match
    final stripped = stripCommonPrefixes(trimmed);
    for (final entry in _teamMap.entries) {
      if (stripCommonPrefixes(entry.key) == stripped) {
        return entry.value.canonical;
      }
    }

    // 4. Check if canonical key itself
    for (final entry in _teamMap.values) {
      if (entry.canonical == trimmed || entry.canonical == stripped) {
        return entry.canonical;
      }
    }

    return null;
  }

  /// Returns the localized title (Arabic or English) if team is known.
  static String? getLocalizedName(String? nameOrId, {required bool isArabic}) {
    if (nameOrId == null || nameOrId.trim().isEmpty) return null;
    final trimmed = nameOrId.trim().toLowerCase();

    // 1. Direct dictionary match
    if (_teamMap.containsKey(trimmed)) {
      return isArabic ? _teamMap[trimmed]!.ar : _teamMap[trimmed]!.en;
    }

    // 2. Check canonical key
    final canonical = getCanonicalKey(nameOrId);
    if (canonical != null) {
      for (final entry in _teamMap.values) {
        if (entry.canonical == canonical) {
          return isArabic ? entry.ar : entry.en;
        }
      }
    }

    return null;
  }

  /// Determines if two team names or identifiers refer to the same team.
  /// Handles cross-lingual differences (e.g. 'مصر' vs 'Egypt'),
  /// variations ('منتخب مصر' vs 'مصر'), and common club naming variations.
  static bool areSameTeam(String? a, String? b) {
    if (a == null || b == null) return false;
    final cleanA = a.trim();
    final cleanB = b.trim();
    if (cleanA.isEmpty || cleanB.isEmpty) return false;

    // 1. Exact or lower-case match
    if (cleanA.toLowerCase() == cleanB.toLowerCase()) return true;

    // 2. Normalized match
    final normA = normalize(cleanA);
    final normB = normalize(cleanB);
    if (normA == normB) return true;

    // 3. Prefix-stripped match
    final strippedA = stripCommonPrefixes(cleanA);
    final strippedB = stripCommonPrefixes(cleanB);
    if (strippedA.isNotEmpty && strippedA == strippedB) return true;

    // 4. Canonical key match
    final canA = getCanonicalKey(cleanA);
    final canB = getCanonicalKey(cleanB);
    if (canA != null && canB != null && canA == canB) return true;

    // 5. Containment match for national teams / clubs (minimum 4 characters)
    if (normA.length >= 4 && normB.length >= 4) {
      if (normA.contains(normB) || normB.contains(normA)) {
        return true;
      }
    }

    return false;
  }
}
