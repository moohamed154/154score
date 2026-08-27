import 'package:flutter/material.dart';

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

      // Standings
      'standings_title': 'League Standings',
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

      // Errors & Empty
      'error_title': 'Something went wrong',
      'error_network': 'Unable to connect to the server. Please check your internet connection.',
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

      // Standings
      'standings_title': 'جدول الترتيب',
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

      // Errors & Empty
      'error_title': 'حدث خطأ ما',
      'error_network': 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة ثانية.',
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
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
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
