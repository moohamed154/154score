class UtcOffsetInfo {
  final int offset;
  final String titleAr;
  final String titleEn;
  final List<String> citiesAr;
  final List<String> citiesEn;
  final String? timezoneAbbr;

  const UtcOffsetInfo({
    required this.offset,
    required this.titleAr,
    required this.titleEn,
    required this.citiesAr,
    required this.citiesEn,
    this.timezoneAbbr,
  });

  String get formattedOffset {
    if (offset > 0) return 'UTC +$offset';
    if (offset < 0) return 'UTC $offset';
    return 'UTC +0';
  }

  String title(bool isArabic) => isArabic ? titleAr : titleEn;

  String citiesText(bool isArabic) {
    final list = isArabic ? citiesAr : citiesEn;
    return list.join(isArabic ? '، ' : ', ');
  }

  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    // Check offset numbers e.g. "3", "+3", "-5", "utc+3", "utc -5"
    final offsetStr = offset.toString();
    final plusOffsetStr = '+$offset';
    final formatted = formattedOffset.toLowerCase();
    final formattedNoSpace = formatted.replaceAll(' ', '');

    if (offsetStr == clean ||
        plusOffsetStr == clean ||
        formatted == clean ||
        formattedNoSpace == clean ||
        formatted.contains(clean)) {
      return true;
    }

    if (timezoneAbbr != null && timezoneAbbr!.toLowerCase().contains(clean)) {
      return true;
    }

    if (titleAr.toLowerCase().contains(clean) ||
        titleEn.toLowerCase().contains(clean)) {
      return true;
    }

    for (final city in citiesAr) {
      if (city.toLowerCase().contains(clean)) return true;
    }

    for (final city in citiesEn) {
      if (city.toLowerCase().contains(clean)) return true;
    }

    return false;
  }

  static const List<UtcOffsetInfo> allOffsets = [
    UtcOffsetInfo(
      offset: -12,
      titleAr: 'توقيت جزر بيكر وهاولاند',
      titleEn: 'Baker & Howland Islands Time',
      citiesAr: ['جزيرة بيكر', 'جزيرة هاولاند'],
      citiesEn: ['Baker Island', 'Howland Island'],
      timezoneAbbr: 'AoE',
    ),
    UtcOffsetInfo(
      offset: -11,
      titleAr: 'توقيت ساموا الأمريكية ونييوي',
      titleEn: 'American Samoa & Niue Time',
      citiesAr: ['باجو باجو', 'نييوي', 'ساموا الأمريكية', 'ميدواي'],
      citiesEn: ['Pago Pago', 'Niue', 'American Samoa', 'Midway'],
      timezoneAbbr: 'SST',
    ),
    UtcOffsetInfo(
      offset: -10,
      titleAr: 'توقيت هاواي وتاهيتي',
      titleEn: 'Hawaii-Aleutian Time',
      citiesAr: ['هونولولو', 'بابيتي', 'هاواي', 'تاهيتي'],
      citiesEn: ['Honolulu', 'Papeete', 'Hawaii', 'Tahiti'],
      timezoneAbbr: 'HST',
    ),
    UtcOffsetInfo(
      offset: -9,
      titleAr: 'توقيت ألاسكا',
      titleEn: 'Alaska Standard Time',
      citiesAr: ['أنكوريج', 'جونو', 'ألاسكا'],
      citiesEn: ['Anchorage', 'Juneau', 'Alaska'],
      timezoneAbbr: 'AKST',
    ),
    UtcOffsetInfo(
      offset: -8,
      titleAr: 'توقيت المحيط الهادئ (كاليفورنيا، فانكوفر)',
      titleEn: 'Pacific Time (US & Canada)',
      citiesAr: ['لوس أنجلوس', 'سان فرانسيسكو', 'سياتل', 'فانكوفر'],
      citiesEn: ['Los Angeles', 'San Francisco', 'Seattle', 'Vancouver'],
      timezoneAbbr: 'PST',
    ),
    UtcOffsetInfo(
      offset: -7,
      titleAr: 'التوقيت الجبلي (دنفر، فينيكس)',
      titleEn: 'Mountain Time (US & Canada)',
      citiesAr: ['دنفر', 'فينيكس', 'سولت ليك', 'كالجاري', 'إدمونتون'],
      citiesEn: ['Denver', 'Phoenix', 'Salt Lake City', 'Calgary', 'Edmonton'],
      timezoneAbbr: 'MST',
    ),
    UtcOffsetInfo(
      offset: -6,
      titleAr: 'التوقيت المركزي (شيكاغو، مكسيكو سيتي)',
      titleEn: 'Central Time (US & Canada & Mexico)',
      citiesAr: ['شيكاغو', 'هيوستن', 'دالاس', 'مكسيكو سيتي', 'غواتيمالا'],
      citiesEn: ['Chicago', 'Houston', 'Dallas', 'Mexico City', 'Guatemala'],
      timezoneAbbr: 'CST',
    ),
    UtcOffsetInfo(
      offset: -5,
      titleAr: 'التوقيت الشرقي (نيويورك، ميامي، بوغوتا)',
      titleEn: 'Eastern Time (US & Canada & Colombia)',
      citiesAr: ['نيويورك', 'واشنطن', 'ميامي', 'تورونتو', 'بوغوتا', 'ليما'],
      citiesEn: ['New York', 'Washington', 'Miami', 'Toronto', 'Bogota', 'Lima'],
      timezoneAbbr: 'EST',
    ),
    UtcOffsetInfo(
      offset: -4,
      titleAr: 'توقيت الأطلسي وفنزويلا (سانتياغو، كاراكاس)',
      titleEn: 'Atlantic Time (Caracas, Santiago, La Paz)',
      citiesAr: ['سانتياغو', 'كاراكاس', 'لا باز', 'سانتو دومينغو', 'هاليفاكس'],
      citiesEn: ['Santiago', 'Caracas', 'La Paz', 'Santo Domingo', 'Halifax'],
      timezoneAbbr: 'AST',
    ),
    UtcOffsetInfo(
      offset: -3,
      titleAr: 'توقيت الأرجنتين والبرازيل (بوينس آيرس، ساو باولو)',
      titleEn: 'Argentina & Brazil (Buenos Aires, Sao Paulo)',
      citiesAr: ['بوينس آيرس', 'ساو باولو', 'ريو دي جانيرو', 'مونتيفيديو'],
      citiesEn: ['Buenos Aires', 'Sao Paulo', 'Rio de Janeiro', 'Montevideo'],
      timezoneAbbr: 'ART/BRT',
    ),
    UtcOffsetInfo(
      offset: -2,
      titleAr: 'توقيت جنوب المحيط الأطلسي',
      titleEn: 'South Atlantic Time',
      citiesAr: ['فرناندو دي نورونها', 'جورجيا الجنوبية'],
      citiesEn: ['Fernando de Noronha', 'South Georgia'],
      timezoneAbbr: 'FNT',
    ),
    UtcOffsetInfo(
      offset: -1,
      titleAr: 'توقيت الرأس الأخضر وجزر الأزور',
      titleEn: 'Cape Verde & Azores Time',
      citiesAr: ['كاب فيردي', 'الرأس الأخضر', 'جزر الأزور', 'بونتا ديلغادا'],
      citiesEn: ['Cape Verde', 'Praia', 'Azores', 'Ponta Delgada'],
      timezoneAbbr: 'CVT/AZOT',
    ),
    UtcOffsetInfo(
      offset: 0,
      titleAr: 'توقيت جرينتش ولندن والمغرب',
      titleEn: 'Greenwich Mean Time (London, Dublin, Lisbon, Casablanca)',
      citiesAr: ['لندن', 'دبلن', 'لشبونة', 'الدار البيضاء', 'الرباط', 'أكرا', 'ريكيافيك'],
      citiesEn: ['London', 'Dublin', 'Lisbon', 'Casablanca', 'Rabat', 'Accra', 'Reykjavik'],
      timezoneAbbr: 'GMT/WET',
    ),
    UtcOffsetInfo(
      offset: 1,
      titleAr: 'توقيت وسط أوروبا والجزائر وتونس',
      titleEn: 'Central European Time (Paris, Berlin, Rome, Madrid, Algiers)',
      citiesAr: ['باريس', 'مدريد', 'برلين', 'روما', 'أمستردام', 'الجزائر', 'تونس', 'بروكسل'],
      citiesEn: ['Paris', 'Madrid', 'Berlin', 'Rome', 'Amsterdam', 'Algiers', 'Tunis', 'Brussels'],
      timezoneAbbr: 'CET',
    ),
    UtcOffsetInfo(
      offset: 2,
      titleAr: 'توقيت القاهرة والقدس وطرابلس وعمان',
      titleEn: 'Eastern European Time (Cairo, Jerusalem, Tripoli, Amman, Beirut)',
      citiesAr: ['القاهرة', 'القدس', 'طرابلس', 'عمان', 'بيروت', 'دمشق', 'أثينا', 'كييف', 'جوهانسبرغ'],
      citiesEn: ['Cairo', 'Jerusalem', 'Tripoli', 'Amman', 'Beirut', 'Damascus', 'Athens', 'Kyiv', 'Johannesburg'],
      timezoneAbbr: 'EET/CAT',
    ),
    UtcOffsetInfo(
      offset: 3,
      titleAr: 'توقيت مكة والرياض والكويت والدوحة وبغداد',
      titleEn: 'Arabia Standard Time (Riyadh, Kuwait, Doha, Baghdad, Moscow)',
      citiesAr: ['الرياض', 'مكة', 'الكويت', 'الدوحة', 'بغداد', 'المنامة', 'صنعاء', 'موسكو', 'إسطنبول'],
      citiesEn: ['Riyadh', 'Mecca', 'Kuwait', 'Doha', 'Baghdad', 'Manama', 'Sanaa', 'Moscow', 'Istanbul'],
      timezoneAbbr: 'AST/MSK',
    ),
    UtcOffsetInfo(
      offset: 4,
      titleAr: 'توقيت الخليج (دبي، أبوظبي، مسقط، باكو)',
      titleEn: 'Gulf Standard Time (Dubai, Abu Dhabi, Muscat, Baku)',
      citiesAr: ['دبي', 'أبوظبي', 'مسقط', 'باكو', 'تبليسي', 'يريفان'],
      citiesEn: ['Dubai', 'Abu Dhabi', 'Muscat', 'Baku', 'Tbilisi', 'Yerevan'],
      timezoneAbbr: 'GST',
    ),
    UtcOffsetInfo(
      offset: 5,
      titleAr: 'توقيت باكستان وآسيا الوسطى (إسلام آباد، كراتشي، طشقند)',
      titleEn: 'Pakistan & Central Asia Time (Islamabad, Karachi, Tashkent)',
      citiesAr: ['إسلام آباد', 'كراتشي', 'طشقند', 'يكاترينبورغ', 'عشق آباد'],
      citiesEn: ['Islamabad', 'Karachi', 'Tashkent', 'Yekaterinburg', 'Ashgabat'],
      timezoneAbbr: 'PKT',
    ),
    UtcOffsetInfo(
      offset: 6,
      titleAr: 'توقيت بنغلاديش وكازاخستان (دكا، ألماتي، أستانا)',
      titleEn: 'Bangladesh & Kazakhstan Time (Dhaka, Almaty, Astana)',
      citiesAr: ['دكا', 'ألماتي', 'أستانا', 'بيشكيك', 'أومسك'],
      citiesEn: ['Dhaka', 'Almaty', 'Astana', 'Bishkek', 'Omsk'],
      timezoneAbbr: 'BST',
    ),
    UtcOffsetInfo(
      offset: 7,
      titleAr: 'توقيت الهند الصينية (بانكوك، جاكرتا، هانوي)',
      titleEn: 'Indochina Time (Bangkok, Jakarta, Hanoi)',
      citiesAr: ['بانكوك', 'جاكرتا', 'هانوي', 'هو تشي منه', 'بنوم بنه'],
      citiesEn: ['Bangkok', 'Jakarta', 'Hanoi', 'Ho Chi Minh City', 'Phnom Penh'],
      timezoneAbbr: 'ICT',
    ),
    UtcOffsetInfo(
      offset: 8,
      titleAr: 'توقيت الصين وسنغافورة (بكين، سنغافورة، كوالالمبور)',
      titleEn: 'China & Singapore Time (Beijing, Singapore, Kuala Lumpur)',
      citiesAr: ['بكين', 'سنغافورة', 'كوالالمبور', 'هونغ كونغ', 'تايبيه', 'بيرث', 'مانيلا'],
      citiesEn: ['Beijing', 'Singapore', 'Kuala Lumpur', 'Hong Kong', 'Taipei', 'Perth', 'Manila'],
      timezoneAbbr: 'CST/SGT',
    ),
    UtcOffsetInfo(
      offset: 9,
      titleAr: 'توقيت اليابان وكوريا (طوكيو، سيول)',
      titleEn: 'Japan & Korea Standard Time (Tokyo, Seoul)',
      citiesAr: ['طوكيو', 'سيول', 'أوساكا', 'بيونغ يانغ', 'سابورو'],
      citiesEn: ['Tokyo', 'Seoul', 'Osaka', 'Pyongyang', 'Sapporo'],
      timezoneAbbr: 'JST/KST',
    ),
    UtcOffsetInfo(
      offset: 10,
      titleAr: 'توقيت شرق أستراليا (سيدني، ملبورن، بريزبان)',
      titleEn: 'Australian Eastern Time (Sydney, Melbourne, Brisbane)',
      citiesAr: ['سيدني', 'ملبورن', 'بريزبان', 'فلاديفوستوك', 'غوام'],
      citiesEn: ['Sydney', 'Melbourne', 'Brisbane', 'Vladivostok', 'Guam'],
      timezoneAbbr: 'AEST',
    ),
    UtcOffsetInfo(
      offset: 11,
      titleAr: 'توقيت جزر سليمان وكاليدونيا الجديدة',
      titleEn: 'Solomon Islands & New Caledonia Time',
      citiesAr: ['نوميا', 'جزر سليمان', 'ماغادان', 'فانواتو'],
      citiesEn: ['Noumea', 'Solomon Islands', 'Magadan', 'Vanuatu'],
      timezoneAbbr: 'SBT',
    ),
    UtcOffsetInfo(
      offset: 12,
      titleAr: 'توقيت نيوزيلندا وفيجي (أوكلاند، فيجي)',
      titleEn: 'New Zealand & Fiji Time (Auckland, Wellington, Fiji)',
      citiesAr: ['أوكلاند', 'ويلينغتون', 'فيجي', 'سوفا', 'جزر مارشال'],
      citiesEn: ['Auckland', 'Wellington', 'Fiji', 'Suva', 'Marshall Islands'],
      timezoneAbbr: 'NZST',
    ),
    UtcOffsetInfo(
      offset: 13,
      titleAr: 'توقيت تونغا وساموا',
      titleEn: 'Tonga & Samoa Time (Nuku\'alofa, Apia)',
      citiesAr: ['نوكوالوفا', 'أبيا', 'تونغا', 'ساموا'],
      citiesEn: ['Nuku\'alofa', 'Apia', 'Tonga', 'Samoa'],
      timezoneAbbr: 'TOT',
    ),
    UtcOffsetInfo(
      offset: 14,
      titleAr: 'توقيت جزر الخط وكيريتيماس',
      titleEn: 'Line Islands Time (Kiritimati)',
      citiesAr: ['كيريتيماس', 'جزر الخط', 'كيريباتي'],
      citiesEn: ['Kiritimati', 'Line Islands', 'Kiribati'],
      timezoneAbbr: 'LINT',
    ),
  ];

  static UtcOffsetInfo findByOffset(int offset) {
    return allOffsets.firstWhere(
      (element) => element.offset == offset,
      orElse: () => UtcOffsetInfo(
        offset: offset,
        titleAr: 'UTC ${offset >= 0 ? "+$offset" : "$offset"}',
        titleEn: 'UTC ${offset >= 0 ? "+$offset" : "$offset"}',
        citiesAr: [],
        citiesEn: [],
      ),
    );
  }
}
