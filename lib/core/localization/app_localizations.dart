import 'package:material_ui/material_ui.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('ar'), Locale('en')];

  bool get isArabic => locale.languageCode == 'ar';
  String get langCode => locale.languageCode;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': '154Score',
      'app_tagline': 'Real-Time Live Football Scores & News',

      // Navigation
      'nav_home': 'Home',
      'nav_matches': 'Matches',
      'nav_news': 'News',
      'nav_transfers': 'Transfers',
      'nav_videos': 'Videos',
      'nav_standings': 'Standings',
      'nav_favorites': 'Favorites',
      'nav_settings': 'Settings',
      'nav_search': 'Search',

      // Home & Headers
      'live_now': 'LIVE NOW',
      'live_matches': 'Live Matches',
      'upcoming_matches': 'Upcoming Matches',
      'finished_matches': 'Finished Matches',
      'popular_competitions': 'Top Competitions',
      'latest_news': 'Latest News',
      'latest_videos': 'Latest Highlights',
      'latest_transfers': 'Latest Transfers',
      'view_all': 'View All',
      'yesterday': 'Yesterday',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'select_date': 'Select Date',

      // Match Filters
      'filter_all': 'All',
      'filter_live': 'Live',
      'filter_upcoming': 'Upcoming',
      'filter_finished': 'Finished',
      'filter_favorites': 'Favorites',
      'sort_by': 'Sort By',
      'sort_time': 'Time',
      'sort_competition': 'Competition',

      // Match Statuses
      'status_not_started': 'Not Started',
      'status_live': 'Live',
      'status_first_half': '1st Half',
      'status_half_time': 'Half Time',
      'status_second_half': '2nd Half',
      'status_ended': 'Ended',
      'status_penalties': 'Penalties',
      'status_extra_time': 'Extra Time',
      'status_postponed': 'Postponed',
      'status_cancelled': 'Cancelled',

      // Match Details Tabs
      'tab_overview': 'Overview',
      'tab_events': 'Events',
      'tab_stats': 'Stats',
      'tab_info': 'Info',
      'tab_news': 'News',
      'tab_lineups': 'Lineups',

      // Match Events
      'event_goal': 'Goal',
      'event_penalty': 'Penalty',
      'event_yellow_card': 'Yellow Card',
      'event_red_card': 'Red Card',
      'event_substitution': 'Substitution',
      'event_var': 'VAR Decision',
      'no_events': 'No events recorded yet',

      // Match Stats
      'stat_possession': 'Ball Possession',
      'stat_shots': 'Total Shots',
      'stat_shots_on_target': 'Shots on Target',
      'stat_corners': 'Corner Kicks',
      'stat_fouls': 'Fouls',
      'stat_offsides': 'Offsides',
      'stat_yellow_cards': 'Yellow Cards',
      'stat_red_cards': 'Red Cards',
      'stat_saves': 'Goalkeeper Saves',
      'no_stats': 'Statistics not available for this match',

      // Match Info
      'info_channel': 'Broadcast Channel',
      'info_commentator': 'Commentator',
      'info_referee': 'Referee',
      'info_stadium': 'Stadium',
      'info_round': 'Round / Gameweek',
      'info_venue': 'Venue',

      // Standings & Championships
      'standings_title': 'Championships',
      'search_championship': 'Search Championship',
      'long_press_reorder_hint':
          'Long press any championship to modify its order',
      'favorite_championships': 'Favorite Championships',
      'featured_championships': 'Featured Championships',
      'all_championships': 'All Championships',
      // ignore: equal_keys_in_map
      'filter_all': 'All',
      // ignore: equal_keys_in_map
      'filter_favorites': 'Favorites',
      'filter_featured': 'Featured',
      'filter_leagues': 'Leagues',
      'filter_cups': 'Cups & Continental',
      'no_favorite_championships': 'No favorite championships yet',
      'no_favorite_championships_hint':
          'Tap the star on any competition to add it to your favorites',
      'no_championships_found': 'No championships found',
      'filter_title': 'Filter & Sort Matches',
      'filter_status_header': 'Match Status',
      'filter_sort_header': 'Sort By',
      'filter_sort_importance': 'Importance',
      'filter_sort_time': 'Time',
      'filter_sort_league': 'Championship',
      'filter_league_header': 'Championship / League',
      'filter_all_leagues': 'All Championships',
      'filter_apply': 'Apply',
      'filter_reset': 'Reset',
      'filter_matches_count': 'Matches',
      'championship_type_league': 'League',
      'championship_type_cup': 'Cup',
      'championship_type_continental': 'Continental',
      'standings_pos': '#',
      'standings_team': 'Team',
      'standings_played': 'MP',
      'standings_wins': 'W',
      'standings_draws': 'D',
      'standings_losses': 'L',
      'standings_gf': 'GF',
      'standings_ga': 'GA',
      'standings_gd': 'GD',
      'standings_points': 'Pts',
      'standings_form': 'Form',
      'standings_no_legends': 'Qualification and relegation information is not available for this competition currently',

      // Transfers
      'transfers_title': 'Transfer Market',
      'transfer_type': 'Type',
      'transfer_fee': 'Fee',
      'transfer_date': 'Date',
      'transfer_free': 'Free Transfer',
      'transfer_loan': 'Loan',

      // Videos
      'videos_title': 'Video Highlights',
      'video_duration': 'Duration',
      'video_category': 'Category',
      'watch_video': 'Watch Highlight',

      // Favorites
      'favorites_title': 'My Favorites',
      'favorite_teams': 'Favorite Teams',
      'favorite_competitions': 'Favorite Competitions',
      'no_favorites_matches': 'No favorite matches found for this date',
      'no_favorites_yet':
          'No favorites added yet. Tap ⭐ on matches or teams to add.',

      // Settings
      'settings_title': 'Settings',
      'settings_appearance': 'Appearance',
      'settings_theme_mode': 'Theme',
      'theme_dark': 'Dark Mode',
      'theme_light': 'Light Mode',
      'theme_system': 'System Mode',
      'settings_language': 'Language',
      'lang_arabic': 'العربية (Arabic)',
      'lang_english': 'English',
      'settings_time': 'Time & Date',
      'time_format': 'Time Format',
      'time_12h': '12-Hour (02:30 PM)',
      'time_24h': '24-Hour (14:30)',
      'settings_timezone': 'Timezone',
      'timezone_auto': 'Automatic (Local Device)',
      'timezone_utc': 'UTC (Universal Time)',
      'timezone_offset': 'UTC Offset',
      'settings_diagnostics': 'API & WebSocket Diagnostics',
      'settings_about': 'About 154Score',
      'about_description': '154Score is a high-performance football center powered by 154score API and real-time WebSockets.',

      // Diagnostics & Status
      'diag_title': 'System Diagnostics',
      'diag_api_health': 'REST API Health',
      'diag_ping': 'Server Ping',
      'diag_ws_status': 'WebSocket Live Stream',
      'diag_metrics': 'Server Metrics',
      'diag_status_ok': 'Healthy / Connected',
      'diag_status_disconnected': 'Disconnected',
      'diag_status_error': 'Service Error',
      'check_now': 'Check Now',

      // Debug Console
      'debug_console_title': 'Network Debug Console',
      'debug_console_subtitle':
          'Print and inspect network responses in debug console',
      'debug_console_print_all': 'Print All to Debug Console',
      'debug_console_print_latest': 'Print Latest Response',
      'debug_console_auto_print': 'Auto-print responses to Debug Console',
      'debug_console_clear': 'Clear History',
      'debug_console_no_logs': 'No network responses recorded yet.',
      'debug_console_printed_notice': 'Printed response to Debug Console',
      'debug_console_printed_all_notice':
          'All responses printed to Debug Console',
      'debug_console_print_this': 'Print to Debug Console',
      'debug_console_copy': 'Copy Response',
      'debug_console_copied': 'Copied to clipboard',

      'error_title': 'Something went wrong',
      'error_network': 'Unable to connect to the server. Please check your internet connection.',
      'error_service_unavailable':
          'Data is temporarily unavailable. Please try again.',
      'error_rate_limited':
          'Too many requests. Please wait a moment and try again.',
      'error_not_found': 'Content could not be found.',
      'try_again': 'Try Again',
      'no_matches_date': 'No matches scheduled for this date.',
      'no_live_matches': 'No live matches happening right now.',
      'no_transfers': 'No transfer records available.',
      'no_videos': 'No videos available at the moment.',
      'search_placeholder': 'Search matches, teams, leagues...',
      'search_no_results': 'No results found matching your search.',
      'clear': 'Clear',
      'close': 'Close',

      // Lineup Tab
      'tab_lineup': 'Lineup',
      'confirmed_lineup': 'Confirmed Lineup',
      'probable_lineup': 'Probable Lineup',
      'formation': 'Formation',
      'starting_xi': 'Starting XI',
      'substitutes': 'Substitutes',
      'coach': 'Coach',
      'manager': 'Manager',
      'injuries_absences': 'Absences & Injuries',
      'pitch_view': 'Pitch',
      'list_view': 'List',
      'captain_short': 'C',
      'goalkeepers': 'Goalkeepers',
      'defenders': 'Defenders',
      'midfielders': 'Midfielders',
      'forwards': 'Forwards',
      'lineup_unavailable_title': 'Lineups Not Available Yet',
      'lineup_unavailable_desc': 'Official starting lineups are usually announced 1 hour before kickoff.',
      'refresh_lineup': 'Check for Updates',
      'player_details': 'Player Details',
      'starter': 'Starter',
      'substitute': 'Substitute',
      'captain': 'Captain',
      'rating': 'Rating',
    },
    'ar': {
      'app_name': '154Score',
      'app_tagline': 'نتائج مباريات وأخبار كرة القدم المباشرة',

      // Navigation
      'nav_home': 'الرئيسية',
      'nav_matches': 'المباريات',
      'nav_news': 'الأخبار',
      'nav_transfers': 'الانتقالات',
      'nav_videos': 'الفيديوهات',
      'nav_standings': 'الترتيب',
      'nav_favorites': 'المفضلة',
      'nav_settings': 'الإعدادات',
      'nav_search': 'بحث',

      // Home & Headers
      'live_now': 'مباشر الآن',
      'live_matches': 'المباريات المباشرة',
      'upcoming_matches': 'المباريات القادمة',
      'finished_matches': 'المباريات المنتهية',
      'popular_competitions': 'أهم البطولات',
      'latest_news': 'آخر الأخبار',
      'latest_videos': 'أحدث الفيديوهات والأهداف',
      'latest_transfers': 'أحدث الانتقالات',
      'view_all': 'عرض الكل',
      'yesterday': 'أمس',
      'today': 'اليوم',
      'tomorrow': 'غداً',
      'select_date': 'اختر تاريخاً',

      // Match Filters
      'filter_all': 'الكل',
      'filter_live': 'مباشر',
      'filter_upcoming': 'لم تبدأ',
      'filter_finished': 'انتهت',
      'filter_favorites': 'المفضلة',
      'sort_by': 'ترتيب حسب',
      'sort_time': 'التوقيت',
      'sort_competition': 'البطولة',

      // Match Statuses
      'status_not_started': 'لم تبدأ',
      'status_live': 'مباشر',
      'status_first_half': 'الشوط الأول',
      'status_half_time': 'استراحة',
      'status_second_half': 'الشوط الثاني',
      'status_ended': 'انتهت',
      'status_penalties': 'ركلات الترجيح',
      'status_extra_time': 'شوط إضافي',
      'status_postponed': 'مؤجلة',
      'status_cancelled': 'ملغاة',

      // Match Details Tabs
      'tab_overview': 'نظرة عامة',
      'tab_events': 'الأحداث',
      'tab_stats': 'الإحصائيات',
      'tab_info': 'المعلومات',
      'tab_news': 'الأخبار',
      'tab_lineups': 'التشكيلة',

      // Match Events
      'event_goal': 'هدف',
      'event_penalty': 'ركلة جزاء',
      'event_yellow_card': 'بطاقة صفراء',
      'event_red_card': 'بطاقة حمراء',
      'event_substitution': 'تبديل',
      'event_var': 'تقنية الفيديو (VAR)',
      'no_events': 'لا توجد أحداث مسجلة حتى الآن',

      // Match Stats
      'stat_possession': 'الاستحواذ على الكرة',
      'stat_shots': 'إجمالي التسديدات',
      'stat_shots_on_target': 'تسديدات على المرمى',
      'stat_corners': 'الضربات الركنية',
      'stat_fouls': 'الأخطاء',
      'stat_offsides': 'التسللات',
      'stat_yellow_cards': 'البطاقات الصفراء',
      'stat_red_cards': 'البطاقات الحمراء',
      'stat_saves': 'تصديات الحارس',
      'no_stats': 'الإحصائيات غير متوفرة لهذه المباراة',

      // Match Info
      'info_channel': 'القناة الناقلة',
      'info_commentator': 'المعلق',
      'info_referee': 'الحكم',
      'info_stadium': 'الملعب',
      'info_round': 'الجولة / الدور',
      'info_venue': 'الموقع',

      // Standings & Championships
      'standings_title': 'البطولات والترتيب',
      'search_championship': 'البحث عن بطولة',
      'long_press_reorder_hint': 'اضغط مطولاً على أي بطولة لتعديل ترتيبها',
      'favorite_championships': 'البطولات المفضلة',
      'featured_championships': 'أهم البطولات',
      'all_championships': 'جميع البطولات',
      // ignore: equal_keys_in_map
      'filter_all': 'الكل',
      // ignore: equal_keys_in_map
      'filter_favorites': 'المفضلة',
      'filter_featured': 'أهم البطولات',
      'filter_leagues': 'دوريات',
      'filter_cups': 'كؤوس وقارية',
      'no_favorite_championships': 'لا توجد بطولات في المفضلة',
      'no_favorite_championships_hint':
          'اضغط على النجمة بجانب أي بطولة لإضافتها لمفضلتك',
      'no_championships_found': 'لم يتم العثور على أي بطولة',
      'filter_title': 'تصفية وترتيب المباريات',
      'filter_status_header': 'حالة المباراة',
      'filter_sort_header': 'ترتيب حسب',
      'filter_sort_importance': 'الأهمية',
      'filter_sort_time': 'التوقيت',
      'filter_sort_league': 'البطولة',
      'filter_league_header': 'البطولة / الدوري',
      'filter_all_leagues': 'جميع البطولات',
      'filter_apply': 'تطبيق',
      'filter_reset': 'إعادة ضبط',
      'filter_matches_count': 'مباراة',
      'championship_type_league': 'دوري',
      'championship_type_cup': 'كأس',
      'championship_type_continental': 'قاري',
      'standings_pos': '#',
      'standings_team': 'الفريق',
      'standings_played': 'لعب',
      'standings_wins': 'فاز',
      'standings_draws': 'تعادل',
      'standings_losses': 'خسر',
      'standings_gf': 'له',
      'standings_ga': 'عليه',
      'standings_gd': 'الفارق',
      'standings_points': 'النقاط',
      'standings_form': 'آخر المباريات',
      'standings_no_legends':
          'معلومات التأهل والهبوط غير متاحة لهذه البطولة حالياً',

      // Transfers
      'transfers_title': 'سوق الانتقالات',
      'transfer_type': 'نوع الصفقة',
      'transfer_fee': 'قيمة الصفقة',
      'transfer_date': 'تاريخ العقد',
      'transfer_free': 'انتقال حر',
      'transfer_loan': 'إعارة',

      // Videos
      'videos_title': 'أهداف وملخصات الفيديوهات',
      'video_duration': 'المدة',
      'video_category': 'البطولة',
      'watch_video': 'مشاهدة الفيديو',

      // Favorites
      'favorites_title': 'المفضلة',
      'favorite_teams': 'الفرق المفضلة',
      'favorite_competitions': 'البطولات المفضلة',
      'no_favorites_matches': 'لا توجد مباريات مفضلة في هذا اليوم',
      'no_favorites_yet':
          'لم تقم بإضافة فرق أو مباريات للمفضلة بعد. اضغط ⭐ للإضافة.',

      // Settings
      'settings_title': 'الإعدادات',
      'settings_appearance': 'المظهر والسمة',
      'settings_theme_mode': 'وضع العرض',
      'theme_dark': 'الوضع الداكن (Dark)',
      'theme_light': 'الوضع الفاتح (Light)',
      'theme_system': 'تلقائي (حسب النظام)',
      'settings_language': 'اللغة',
      'lang_arabic': 'العربية',
      'lang_english': 'English',
      'settings_time': 'الوقت والتاريخ',
      'time_format': 'صيغة الوقت',
      'time_12h': '12 ساعة (02:30 م)',
      'time_24h': '24 ساعة (14:30)',
      'settings_timezone': 'المنطقة الزمنية',
      'timezone_auto': 'تلقائي (توقيت الجهاز)',
      'timezone_utc': 'توقيت جرينتش (UTC)',
      'timezone_offset': 'فارق التوقيت',
      'settings_diagnostics': 'فحص الخادم والويب سوكت',
      'settings_about': 'حول 154Score',
      'about_description': 'تطبيق 154Score الرياضي الاحترافي لمتابعة نتائج المباريات لحظة بلحظة عبر 154score API والويب سوكت المباشر.',

      // Diagnostics & Status
      'diag_title': 'فحص وتشخيص الاتصال',
      'diag_api_health': 'حالة خادم REST API',
      'diag_ping': 'فحص الاتصال (Ping)',
      'diag_ws_status': 'البث المباشر (WebSocket)',
      'diag_metrics': 'مؤشرات أداء السيرفر',
      'diag_status_ok': 'متصل وسليم',
      'diag_status_disconnected': 'غير متصل',
      'diag_status_error': 'خطأ في الخدمة',
      'check_now': 'فحص الآن',

      // Debug Console
      'debug_console_title': 'شاشة تصحيح الشبكة (Debug Console)',
      'debug_console_subtitle': 'طباعة وفحص استجابات الشبكة في الديبج كونسول',
      'debug_console_print_all': 'طباعة الكل في الديبج كونسول',
      'debug_console_print_latest': 'طباعة أحدث استجابة',
      'debug_console_auto_print': 'طباعة الاستجابات تلقائياً في الديبج كونسول',
      'debug_console_clear': 'مسح السجلات',
      'debug_console_no_logs': 'لا توجد استجابات شبكة مسجلة بعد.',
      'debug_console_printed_notice': 'تمت طباعة الاستجابة في الديبج كونسول',
      'debug_console_printed_all_notice':
          'تمت طباعة جميع الاستجابات في الديبج كونسول',
      'debug_console_print_this': 'طباعة في الديبج كونسول',
      'debug_console_copy': 'نسخ الاستجابة',
      'debug_console_copied': 'تم النسخ إلى الحافظة',

      'error_title': 'حدث خطأ ما',
      'error_network': 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة ثانية.',
      'error_service_unavailable': 'البيانات غير متاحة مؤقتًا، حاول مرة أخرى.',
      'error_rate_limited':
          'تم تجاوز معدل الطلبات، يرجى الانتظار قليلًا والمحاولة ثانية.',
      'error_not_found': 'المحتوى المطلوب غير موجود.',
      'try_again': 'إعادة المحاولة',
      'no_matches_date': 'لا توجد مباريات مجدولة في هذا التاريخ.',
      'no_live_matches': 'لا توجد مباريات جارية حالياً.',
      'no_transfers': 'لا توجد انتقالات متاحة في الوقت الحالي.',
      'no_videos': 'لا توجد فيديوهات متاحة حالياً.',
      'search_placeholder': 'ابحث عن فرق، بطولات، مباريات...',
      'search_no_results': 'لم نتمكن من العثور على نتائج لبحثك.',
      'clear': 'مسح',
      'close': 'إغلاق',

      // Lineup Tab
      'tab_lineup': 'التشكيلة',
      'confirmed_lineup': 'تشكيلة مؤكدة',
      'probable_lineup': 'تشكيلة متوقعة',
      'formation': 'خطة اللعب',
      'starting_xi': 'التشكيلة الأساسية',
      'substitutes': 'البدلاء',
      'coach': 'المدرب',
      'manager': 'المدير الفني',
      'injuries_absences': 'الغيابات والإصابات',
      'pitch_view': 'الملعب',
      'list_view': 'القائمة',
      'captain_short': 'ق',
      'goalkeepers': 'حراسة المرمى',
      'defenders': 'الدفاع',
      'midfielders': 'الوسط',
      'forwards': 'الهجوم',
      'lineup_unavailable_title': 'لم يتم الإعلان عن التشكيلة بعد',
      'lineup_unavailable_desc': 'عادة ما يتم الكشف عن التشكيل الرسمي قبل ساعة واحدة من صافرة البداية.',
      'refresh_lineup': 'تحديث التشكيلة',
      'player_details': 'معلومات اللاعب',
      'starter': 'أساسي',
      'substitute': 'بديل',
      'captain': 'قائد الفريق',
      'rating': 'التقييم',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenience Lineup Getters
  String get tabLineup => translate('tab_lineup');
  String get confirmedLineup => translate('confirmed_lineup');
  String get probableLineup => translate('probable_lineup');
  String get formation => translate('formation');
  String get startingXi => translate('starting_xi');
  String get substitutes => translate('substitutes');
  String get coach => translate('coach');
  String get manager => translate('manager');
  String get injuriesAbsences => translate('injuries_absences');
  String get pitchView => translate('pitch_view');
  String get listView => translate('list_view');
  String get captainShort => translate('captain_short');
  String get lineupUnavailableTitle => translate('lineup_unavailable_title');
  String get lineupUnavailableDesc => translate('lineup_unavailable_desc');
  String get refreshLineup => translate('refresh_lineup');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
