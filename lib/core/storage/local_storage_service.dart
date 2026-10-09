import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_sync_service.dart';
import '../utils/league_resolver.dart';
import '../utils/team_resolver.dart';

abstract class LocalStorageService {
  Future<void> init();

  // Language
  String getLanguage();
  Future<bool> setLanguage(String langCode);

  // News Language ('app', 'ar', 'en')
  String getNewsLanguage() => 'app';
  Future<bool> setNewsLanguage(String langCode) async => true;
  String getEffectiveNewsLanguage() =>
      getNewsLanguage() == 'app' ? getLanguage() : getNewsLanguage();

  // Theme Mode ('system', 'light', 'dark')
  String getThemeMode();
  Future<bool> setThemeMode(String themeMode);

  // Time Format ('12h', '24h')
  String getTimeFormat();
  Future<bool> setTimeFormat(String format);

  // Timezone Offset
  int getTimezoneOffset();
  Future<bool> setTimezoneOffset(int offset);
  bool isTimezoneAuto() => true;
  Future<bool> setTimezoneAuto(bool isAuto) async => true;
  int getDeviceTimezoneOffset() => DateTime.now().timeZoneOffset.inHours;

  // Favorites
  List<String> getFavoriteTeams();
  Future<bool> toggleFavoriteTeam(String teamName, {String? id});
  bool isFavoriteTeam(String teamName, {String? id});
  Map<String, String> getFavoriteTeamTitles();
  Future<bool> registerTeamTitles(Map<String, String> titles);
  String resolveTeamTitle(String teamOrId, {bool? isArabic});

  List<String> getFavoriteCompetitions();
  bool hasCustomFavoriteCompetitions();
  Future<bool> setFavoriteCompetitions(List<String> list);
  Future<bool> toggleFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  });
  bool isFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  });
  Map<String, String> getFavoriteCompetitionTitles();
  Future<bool> registerCompetitionTitles(Map<String, String> titles);
  String resolveCompetitionTitle(String compOrId);

  List<String> getFavoriteMatches();
  Future<bool> toggleFavoriteMatch(String matchId);
  bool isFavoriteMatch(String matchId);

  // Cached Rankings / Standings Directory
  String? getCachedRankings({String? lang});
  Future<bool> setCachedRankings(String json, {String? lang});

  // Tips Persistence
  bool isReorderTipDismissed();
  Future<bool> setReorderTipDismissed(bool dismissed);

  // Matches Filter & Sort Order Persistence
  String? getMatchesFilter();
  Future<bool> setMatchesFilter(String filter);
  String? getMatchesSortOrder();
  Future<bool> setMatchesSortOrder(String sortOrder);
  bool getHideFavorites();
  Future<bool> setHideFavorites(bool hide);

  // Team & Match Notifications
  bool isTeamNotificationEnabled(String teamIdOrName) => false;
  Future<bool> toggleTeamNotification(String teamIdOrName) async => false;
  bool isTeamNotificationMuted(String teamIdOrName) => false;
  Future<bool> setTeamNotificationMuted(String teamIdOrName, bool muted) async => false;

  bool isMatchNotificationEnabled(String matchId) => false;
  Future<bool> toggleMatchNotification(String matchId) async => false;
  Future<bool> setMatchNotificationEnabled(String matchId, bool enabled) async => false;
  List<String> getMatchNotificationIds() => [];

  // Granular Notification Toggles
  bool isNewsNotificationEnabled();
  Future<bool> setNewsNotificationEnabled(bool enabled);
  bool isMatchLineupNotificationEnabled();
  Future<bool> setMatchLineupNotificationEnabled(bool enabled);
  bool isMatchGoalsNotificationEnabled();
  Future<bool> setMatchGoalsNotificationEnabled(bool enabled);
  bool isMatchStartEndNotificationEnabled();
  Future<bool> setMatchStartEndNotificationEnabled(bool enabled);

  // Match Notification Scope: 'starred_only' vs 'all_matches'
  static const String matchNotifScopeStarred = 'starred_only';
  static const String matchNotifScopeAll = 'all_matches';
  String getMatchNotificationScope();
  Future<bool> setMatchNotificationScope(String scope);

  // Live Match Mode (Zero Delay Foreground Service on Android / APNs on iOS)
  bool isLiveMatchModeEnabled() => true;
  Future<bool> setLiveMatchModeEnabled(bool enabled) async => true;
  bool isNotificationMatchingStarredTeams({
    required String title,
    required String body,
    String? matchId,
    Map<String, dynamic>? data,
  });

  // Read Notifications IDs
  List<String> getReadNotificationIds();
  Future<bool> markNotificationAsRead(String id);
  Future<bool> markAllNotificationsAsRead(List<String> ids);

  // Developer / Debugging Mode
  bool isDeveloperModeEnabled();
  Future<bool> setDeveloperModeEnabled(bool enabled);
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageServiceImpl(this._prefs);

  static const String _keyLanguage = 'app_language';
  static const String _keyNewsLanguage = 'app_news_language';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyTimeFormat = 'app_time_format';
  static const String _keyTimezoneOffset = 'app_timezone_offset';
  static const String _keyTimezoneAuto = 'app_timezone_auto';
  static const String _keyFavoriteTeams = 'app_favorite_teams';
  static const String _keyFavoriteTeamTitles = 'app_favorite_team_titles';
  static const String _keyFavoriteCompetitions = 'app_favorite_competitions';
  static const String _keyFavoriteCompetitionTitles =
      'app_favorite_competition_titles';
  static const String _keyFavoriteMatches = 'app_favorite_matches';
  static const String _keyCachedRankings = 'app_cached_rankings';
  static const String _keyReorderTipDismissed = 'app_reorder_tip_dismissed';
  static const String _keyMatchesFilter = 'app_matches_filter';
  static const String _keyMatchesSortOrder = 'app_matches_sort_order';
  static const String _keyHideFavorites = 'app_hide_favorites';

  static const List<String> defaultFeaturedCompetitions = [
    'دوري أبطال أوروبا',
    'الدوري الإنجليزي الممتاز',
    'كأس السوبر الإسباني',
    'الدوري الإسباني',
    'الدوري الإيطالي',
    'الدوري الألماني',
    'الدوري الفرنسي',
    'الدوري السعودي للمحترفين',
  ];

  static const Map<String, String> defaultKnownTitles = {
    '12048': 'دوري أبطال أوروبا',
    '943230': 'دوري أبطال أوروبا',
    '6811': 'الدوري الإنجليزي الممتاز',
    '937599': 'الدوري الإنجليزي الممتاز',
    '88013': 'كأس السوبر الإسباني',
    '59771441': 'كأس السوبر الإسباني',
    '1933': 'الدوري الإسباني',
    '938652': 'الدوري الإسباني',
    '3734': 'الدوري الإيطالي',
    '936357': 'الدوري الإيطالي',
    '2606': 'الدوري الألماني',
    '938769': 'الدوري الألماني',
    '1985': 'الدوري الفرنسي',
    '937873': 'الدوري الفرنسي',
    '7167': 'الدوري السعودي للمحترفين',
    '941825': 'الدوري السعودي للمحترفين',
    '894789': 'كأس العالم',
    '943487': 'دوري أبطال أفريقيا',
    '911131': 'دوري أبطال أفريقيا',
    '98026338': 'كأس الخليج تحت 17 سنة',
    '937603': 'الدوري الأوروبي',
    '77059': 'كأس القارات للأندية',
  };

  static const Map<String, String> defaultNameToId = {
    // Arabic names
    'دوري أبطال أوروبا': '12048',
    'الدوري الإنجليزي الممتاز': '6811',
    'الدوري الإنجليزي': '6811',
    'البريميرليج': '6811',
    'كأس السوبر الإسباني': '88013',
    'الدوري الإسباني': '1933',
    'لا ليغا': '1933',
    'الدوري الإيطالي': '3734',
    'الدوري الألماني': '2606',
    'الدوري الفرنسي': '1985',
    'الدوري السعودي للمحترفين': '7167',
    'دوري روشن السعودي': '7167',
    'كأس العالم': '894789',
    'دوري أبطال أفريقيا': '943487',
    'كأس الخليج تحت 17 سنة': '98026338',
    'الدوري الأوروبي': '937603',
    'كأس القارات للأندية': '77059',
    // English names
    'uefa champions league': '12048',
    'champions league': '12048',
    'premier league': '6811',
    'supercopa de españa': '88013',
    'supercopa de espana': '88013',
    'laliga': '1933',
    'la liga': '1933',
    'serie a': '3734',
    'bundesliga': '2606',
    'ligue 1': '1985',
    'saudi pro league': '7167',
    'fifa world cup': '894789',
    'caf champions league': '943487',
    'gulf cup u17': '98026338',
    'uefa europa league': '937603',
    'europa league': '937603',
    'fifa intercontinental cup': '77059',
    'intercontinental cup': '77059',
  };

  @override
  Future<void> init() async {}

  @override
  String getLanguage() {
    return _prefs.getString(_keyLanguage) ?? 'ar';
  }

  @override
  Future<bool> setLanguage(String langCode) async {
    final result = await _prefs.setString(_keyLanguage, langCode);
    await _prefs.setString('154score_notif_lang', langCode);
    unawaited(NotificationSyncService.instance.syncAllSubscriptions());
    return result;
  }

  @override
  String getNewsLanguage() {
    return _prefs.getString(_keyNewsLanguage) ?? 'app';
  }

  @override
  Future<bool> setNewsLanguage(String langCode) {
    return _prefs.setString(_keyNewsLanguage, langCode);
  }

  @override
  String getEffectiveNewsLanguage() {
    final newsLang = getNewsLanguage();
    if (newsLang == 'app') {
      return getLanguage();
    }
    return newsLang;
  }

  @override
  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  @override
  Future<bool> setThemeMode(String themeMode) {
    return _prefs.setString(_keyThemeMode, themeMode);
  }

  @override
  String getTimeFormat() {
    return _prefs.getString(_keyTimeFormat) ?? '24h';
  }

  @override
  Future<bool> setTimeFormat(String format) {
    return _prefs.setString(_keyTimeFormat, format);
  }

  @override
  int getDeviceTimezoneOffset() {
    return DateTime.now().timeZoneOffset.inHours;
  }

  @override
  bool isTimezoneAuto() {
    return _prefs.getBool(_keyTimezoneAuto) ?? (_prefs.getInt(_keyTimezoneOffset) == null);
  }

  @override
  int getTimezoneOffset() {
    if (isTimezoneAuto()) {
      return getDeviceTimezoneOffset();
    }
    return _prefs.getInt(_keyTimezoneOffset) ?? getDeviceTimezoneOffset();
  }

  @override
  Future<bool> setTimezoneOffset(int offset) async {
    await _prefs.setBool(_keyTimezoneAuto, false);
    return _prefs.setInt(_keyTimezoneOffset, offset);
  }

  @override
  Future<bool> setTimezoneAuto(bool isAuto) async {
    await _prefs.setBool(_keyTimezoneAuto, isAuto);
    if (isAuto) {
      return _prefs.setInt(_keyTimezoneOffset, getDeviceTimezoneOffset());
    }
    return true;
  }

  static const Map<String, String> knownTeamNameToId = {
    // Al Ahly (Egypt)
    'الأهلي': '101745',
    'الاهلي': '101745',
    'الأهلي المصري': '101745',
    'الاهلي المصري': '101745',
    'al ahly': '101745',
    'al-ahly': '101745',
    'ahly': '101745',
    'el ahly': '101745',
    // Al Ahli Saudi
    'الأهلي السعودي': '2530',
    'الاهلي السعودي': '2530',
    'al ahli saudi': '2530',
    'al-ahli saudi': '2530',
    // Other popular clubs & nations
    'الزمالك': '80591',
    'zamalek': '80591',
    'مصر': '10255',
    'egypt': '10255',
    'ريال مدريد': '8633',
    'real madrid': '8633',
    'برشلونة': '8634',
    'barcelona': '8634',
    'أتلتيكو مدريد': '9906',
    'atletico madrid': '9906',
    'مانشستر سيتي': '8456',
    'manchester city': '8456',
    'مانشستر يونايتد': '10260',
    'manchester united': '10260',
    'ليفربول': '8650',
    'liverpool': '8650',
    'أرسنال': '9825',
    'arsenal': '9825',
    'تشيلسي': '8455',
    'chelsea': '8455',
    'توتنهام': '8586',
    'tottenham': '8586',
    'بايرن ميونخ': '9823',
    'bayern munich': '9823',
    'بوروسيا دورتموند': '9789',
    'borussia dortmund': '9789',
    'يوفنتوس': '9885',
    'juventus': '9885',
    'ميلان': '8564',
    'ac milan': '8564',
    'إنتر ميلان': '8636',
    'inter milan': '8636',
    'باريس سان جيرمان': '9847',
    'paris saint-germain': '9847',
    'الهلال': '2529',
    'al hilal': '2529',
    'النصر': '101918',
    'al nassr': '101918',
    'الاتحاد': '8577',
    'al ittihad': '8577',
    'السعودية': '7795',
    'saudi arabia': '7795',
    'البرازيل': '8256',
    'brazil': '8256',
    'الأرجنتين': '6706',
    'argentina': '6706',
  };

  @override
  List<String> getFavoriteTeams() {
    final rawList = _prefs.getStringList(_keyFavoriteTeams) ?? [];
    if (rawList.isEmpty) return [];

    bool needsSave = false;
    final migratedList = <String>[];
    final titleMapToRegister = <String, String>{};

    for (final item in rawList) {
      final clean = item.trim();
      if (clean.isEmpty) continue;
      if (int.tryParse(clean) != null) {
        if (!migratedList.contains(clean)) migratedList.add(clean);
        continue;
      }
      final knownId =
          knownTeamNameToId[clean.toLowerCase()] ?? knownTeamNameToId[clean];
      if (knownId != null) {
        if (!migratedList.contains(knownId)) {
          migratedList.add(knownId);
        }
        titleMapToRegister[knownId] = clean;
        needsSave = true;
      } else {
        if (!migratedList.contains(clean)) migratedList.add(clean);
      }
    }

    if (needsSave) {
      unawaited(_prefs.setStringList(_keyFavoriteTeams, migratedList));
      if (titleMapToRegister.isNotEmpty) {
        unawaited(registerTeamTitles(titleMapToRegister));
      }
    }

    return migratedList;
  }

  @override
  Map<String, String> getFavoriteTeamTitles() {
    final res = <String, String>{};
    final raw = _prefs.getString(_keyFavoriteTeamTitles);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k != null && v != null) {
              res[k.toString()] = v.toString();
            }
          });
        }
      } catch (_) {}
    }
    return res;
  }

  @override
  Future<bool> registerTeamTitles(Map<String, String> titles) async {
    final current = getFavoriteTeamTitles();
    current.addAll(titles);
    titles.forEach((id, name) {
      if (name.trim().isNotEmpty) {
        current[name.trim().toLowerCase()] = id;
      }
    });
    return _prefs.setString(_keyFavoriteTeamTitles, jsonEncode(current));
  }

  @override
  String resolveTeamTitle(String teamOrId, {bool? isArabic}) {
    final trimmed = teamOrId.trim();
    if (isArabic != null) {
      final loc = TeamResolver.getLocalizedName(trimmed, isArabic: isArabic);
      if (loc != null) return loc;
    }
    final titles = getFavoriteTeamTitles();
    return titles[trimmed] ?? trimmed;
  }

  @override
  bool isFavoriteTeam(String teamName, {String? id}) {
    final list = getFavoriteTeams();
    if (list.isEmpty) return false;

    final cleanName = teamName.trim();
    final cleanId = (id != null && id.trim().isNotEmpty)
        ? id.trim()
        : (int.tryParse(cleanName) != null ? cleanName : null);

    // 1. Strict Match by ID (prevents similar named clubs across leagues from colliding)
    if (cleanId != null && cleanId.isNotEmpty) {
      final lowerId = cleanId.toLowerCase();
      if (list.any((fav) => fav.trim().toLowerCase() == lowerId)) {
        return true;
      }
      final titles = getFavoriteTeamTitles();
      if (titles.containsKey(lowerId)) {
        final title = titles[lowerId]!.trim().toLowerCase();
        if (list.any((fav) => fav.trim().toLowerCase() == title)) {
          return true;
        }
      }
      for (final fav in list) {
        final mapped = titles[fav.trim().toLowerCase()];
        if (mapped != null && mapped.trim().toLowerCase() == lowerId) {
          return true;
        }
      }
      // If team has an ID and did not match any favorite ID, NEVER match by name!
      return false;
    }

    // 2. Query only has name (no ID): Check if name corresponds to a known ID
    final knownId =
        knownTeamNameToId[cleanName.toLowerCase()] ?? knownTeamNameToId[cleanName];
    if (knownId != null) {
      if (list.any((fav) => fav.trim().toLowerCase() == knownId.toLowerCase())) {
        return true;
      }
    }

    // 3. Fallback name match for custom teams without IDs
    for (final fav in list) {
      final cleanFav = fav.trim();
      if (cleanName.isNotEmpty &&
          cleanFav.toLowerCase() == cleanName.toLowerCase()) {
        return true;
      }
      if (cleanName.isNotEmpty && TeamResolver.areSameTeam(cleanFav, cleanName)) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<bool> toggleFavoriteTeam(String teamName, {String? id}) async {
    final list = getFavoriteTeams().toList();
    final cleanName = teamName.trim();
    final cleanId = (id != null && id.trim().isNotEmpty)
        ? id.trim()
        : (knownTeamNameToId[cleanName.toLowerCase()] ?? knownTeamNameToId[cleanName]);

    final isFav = isFavoriteTeam(cleanName, id: cleanId);

    if (isFav) {
      // Remove all matching variants (both languages, aliases, ID)
      list.removeWhere((item) {
        final cleanItem = item.trim();
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            cleanItem.toLowerCase() == cleanId.toLowerCase()) {
          return true;
        }
        if (cleanName.isNotEmpty &&
            cleanItem.toLowerCase() == cleanName.toLowerCase()) {
          return true;
        }
        if (cleanName.isNotEmpty &&
            TeamResolver.areSameTeam(cleanItem, cleanName)) {
          return true;
        }
        return false;
      });
    } else {
      if (cleanId != null && cleanId.isNotEmpty) {
        if (!list.contains(cleanId)) {
          list.add(cleanId);
        }
        if (cleanName.isNotEmpty) {
          unawaited(registerTeamTitles({cleanId: cleanName}));
        }
      } else if (cleanName.isNotEmpty && !list.contains(cleanName)) {
        list.add(cleanName);
      }
    }
    final saved = await _prefs.setStringList(_keyFavoriteTeams, list);
    final keyToSync = (cleanId != null && cleanId.isNotEmpty) ? cleanId : cleanName;
    if (!isFav) {
      if (keyToSync.isNotEmpty) {
        unawaited(NotificationSyncService.instance.subscribeToTeam(keyToSync));
      }
    } else {
      if (keyToSync.isNotEmpty) {
        unawaited(NotificationSyncService.instance.unsubscribeFromTeam(keyToSync));
      }
    }
    return saved;
  }

  @override
  List<String> getFavoriteCompetitions() {
    if (!hasCustomFavoriteCompetitions()) {
      return defaultFeaturedCompetitions;
    }
    return _prefs.getStringList(_keyFavoriteCompetitions) ?? [];
  }

  @override
  bool hasCustomFavoriteCompetitions() {
    return _prefs.containsKey(_keyFavoriteCompetitions);
  }

  @override
  Future<bool> setFavoriteCompetitions(List<String> list) async {
    return _prefs.setStringList(_keyFavoriteCompetitions, list);
  }

  @override
  Map<String, String> getFavoriteCompetitionTitles() {
    final res = Map<String, String>.from(defaultKnownTitles);
    final raw = _prefs.getString(_keyFavoriteCompetitionTitles);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k != null && v != null) {
              res[k.toString()] = v.toString();
            }
          });
        }
      } catch (_) {}
    }
    return res;
  }

  @override
  Future<bool> registerCompetitionTitles(Map<String, String> titles) async {
    final current = getFavoriteCompetitionTitles();
    current.addAll(titles);
    // Also store reverse mapping title.toLowerCase() -> id so looking up any name finds the id
    titles.forEach((id, name) {
      if (name.trim().isNotEmpty) {
        current[name.trim().toLowerCase()] = id;
      }
    });
    return _prefs.setString(_keyFavoriteCompetitionTitles, jsonEncode(current));
  }

  @override
  String resolveCompetitionTitle(String compOrId) {
    final trimmed = compOrId.trim();
    final titles = getFavoriteCompetitionTitles();
    return titles[trimmed] ?? trimmed;
  }

  @override
  bool isFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) {
    final list = getFavoriteCompetitions();
    if (list.isEmpty) return false;

    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : ((compName != null && compName.trim().isNotEmpty)
            ? compName.trim()
            : (slug?.trim() ?? ''));
    final cleanId = id?.trim();

    final titles = getFavoriteCompetitionTitles();

    for (final fav in list) {
      final favTrim = fav.trim();
      final favId = titles[favTrim];
      if (LeagueResolver.areSameCompetition(
        favTrim,
        effectiveName,
        idA: favId,
        idB: cleanId,
      )) {
        return true;
      }
      if (slug != null && slug.trim().isNotEmpty) {
        if (LeagueResolver.areSameCompetition(
          favTrim,
          slug.trim(),
          idA: favId,
          idB: cleanId,
        )) {
          return true;
        }
      }
      if (cleanId != null && cleanId.isNotEmpty) {
        if (LeagueResolver.areSameCompetition(
          favTrim,
          null,
          idA: favId,
          idB: cleanId,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Future<bool> toggleFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) async {
    final list = getFavoriteCompetitions().toList();
    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : ((compName != null && compName.trim().isNotEmpty)
            ? compName.trim()
            : (slug?.trim() ?? ''));
    final cleanId = id?.trim();

    final isFav = isFavoriteCompetition(
      compName: compName,
      id: cleanId,
      name: effectiveName,
      slug: slug,
    );

    final titles = getFavoriteCompetitionTitles();

    if (isFav) {
      list.removeWhere((item) {
        final itemTrim = item.trim();
        final favId = titles[itemTrim];
        return LeagueResolver.areSameCompetition(
          itemTrim,
          effectiveName,
          idA: favId,
          idB: cleanId,
        );
      });
    } else {
      final canonicalName = effectiveName.isNotEmpty
          ? effectiveName
          : (cleanId ?? '');

      if (canonicalName.isNotEmpty &&
          !list.any((item) {
            final itemTrim = item.trim();
            final favId = titles[itemTrim];
            return LeagueResolver.areSameCompetition(
              itemTrim,
              canonicalName,
              idA: favId,
              idB: cleanId,
            );
          })) {
        list.add(canonicalName);
      }
      if (cleanId != null && cleanId.isNotEmpty && canonicalName.isNotEmpty) {
        unawaited(registerCompetitionTitles({cleanId: canonicalName}));
      }
    }

    return setFavoriteCompetitions(list);
  }

  @override
  List<String> getFavoriteMatches() {
    return _prefs.getStringList(_keyFavoriteMatches) ?? [];
  }

  @override
  Future<bool> toggleFavoriteMatch(String matchId) async {
    final list = getFavoriteMatches().toList();
    if (list.contains(matchId)) {
      list.remove(matchId);
    } else {
      list.add(matchId);
    }
    return _prefs.setStringList(_keyFavoriteMatches, list);
  }

  @override
  bool isFavoriteMatch(String matchId) {
    if (matchId.trim().isEmpty) return false;
    final clean = matchId.replaceAll('match:', '').trim();
    final list = getFavoriteMatches();
    return list.any((item) {
      final c = item.replaceAll('match:', '').trim();
      return c == clean || item == matchId;
    });
  }

  @override
  String? getCachedRankings({String? lang}) {
    final effectiveLang = lang ?? getLanguage();
    final keyed = _prefs.getString('${_keyCachedRankings}_$effectiveLang');
    if (keyed != null) return keyed;
    // Only fall back to unkeyed legacy cache for Arabic to avoid bleeding Arabic data into English
    if (effectiveLang == 'ar') {
      return _prefs.getString(_keyCachedRankings);
    }
    return null;
  }

  @override
  Future<bool> setCachedRankings(String json, {String? lang}) {
    final effectiveLang = lang ?? getLanguage();
    return _prefs.setString('${_keyCachedRankings}_$effectiveLang', json);
  }

  @override
  bool isReorderTipDismissed() {
    return _prefs.getBool(_keyReorderTipDismissed) ?? false;
  }

  @override
  Future<bool> setReorderTipDismissed(bool dismissed) {
    return _prefs.setBool(_keyReorderTipDismissed, dismissed);
  }

  @override
  String? getMatchesFilter() {
    return _prefs.getString(_keyMatchesFilter);
  }

  @override
  Future<bool> setMatchesFilter(String filter) {
    return _prefs.setString(_keyMatchesFilter, filter);
  }

  @override
  String? getMatchesSortOrder() {
    return _prefs.getString(_keyMatchesSortOrder);
  }

  @override
  Future<bool> setMatchesSortOrder(String sortOrder) {
    return _prefs.setString(_keyMatchesSortOrder, sortOrder);
  }

  @override
  bool getHideFavorites() {
    return _prefs.getBool(_keyHideFavorites) ?? false;
  }

  @override
  Future<bool> setHideFavorites(bool hide) {
    return _prefs.setBool(_keyHideFavorites, hide);
  }

  static const String _keyTeamNotifications = 'team_notifications';
  static const String _keyTeamNotificationsMuted = 'team_notifications_muted';
  static const String _keyMatchNotifications = 'match_notifications';
  static const String _keyNotifNews = 'notif_news_enabled';
  static const String _keyNotifLineup = 'notif_lineup_enabled';
  static const String _keyNotifGoals = 'notif_goals_enabled';
  static const String _keyNotifStartEnd = 'notif_start_end_enabled';
  static const String _keyMatchNotifScope = 'app_notif_match_scope';
  static const String _keyReadNotifications = 'read_notifications_ids';

  @override
  bool isTeamNotificationEnabled(String teamIdOrName) {
    if (teamIdOrName.trim().isEmpty) return false;
    final key = teamIdOrName.trim().toLowerCase();
    if (isTeamNotificationMuted(key)) return false;
    final list = _prefs.getStringList(_keyTeamNotifications) ?? [];
    if (list.contains(key)) return true;
    if (isFavoriteTeam(teamIdOrName, id: teamIdOrName)) {
      return true;
    }
    return false;
  }

  @override
  bool isTeamNotificationMuted(String teamIdOrName) {
    if (teamIdOrName.trim().isEmpty) return false;
    final key = teamIdOrName.trim().toLowerCase();
    final list = _prefs.getStringList(_keyTeamNotificationsMuted) ?? [];
    return list.contains(key);
  }

  @override
  Future<bool> setTeamNotificationMuted(String teamIdOrName, bool muted) async {
    final key = teamIdOrName.trim().toLowerCase();
    if (key.isEmpty) return false;
    final list = (_prefs.getStringList(_keyTeamNotificationsMuted) ?? []).toList();
    if (muted) {
      if (!list.contains(key)) list.add(key);
    } else {
      list.remove(key);
    }
    return _prefs.setStringList(_keyTeamNotificationsMuted, list);
  }

  @override
  Future<bool> toggleTeamNotification(String teamIdOrName) async {
    final key = teamIdOrName.trim().toLowerCase();
    if (key.isEmpty) return false;
    final list = (_prefs.getStringList(_keyTeamNotifications) ?? []).toList();
    final isCurrentlyActive = isTeamNotificationEnabled(key);
    final nextStatus = !isCurrentlyActive;

    if (nextStatus) {
      if (!list.contains(key)) list.add(key);
      await setTeamNotificationMuted(key, false);
    } else {
      list.remove(key);
      await setTeamNotificationMuted(key, true);
    }
    await _prefs.setStringList(_keyTeamNotifications, list);
    if (nextStatus) {
      unawaited(NotificationSyncService.instance.subscribeToTeam(key));
    } else {
      unawaited(NotificationSyncService.instance.unsubscribeFromTeam(key));
    }
    return nextStatus;
  }

  @override
  List<String> getMatchNotificationIds() {
    return _prefs.getStringList(_keyMatchNotifications) ?? [];
  }

  @override
  bool isMatchNotificationEnabled(String matchId) {
    if (matchId.trim().isEmpty) return false;
    final clean = matchId.replaceAll('match:', '').trim();
    final list = _prefs.getStringList(_keyMatchNotifications) ?? [];
    if (list.any((item) {
      final c = item.replaceAll('match:', '').trim();
      return c == clean || item == matchId;
    })) {
      return true;
    }
    return isFavoriteMatch(matchId);
  }

  @override
  Future<bool> toggleMatchNotification(String matchId) async {
    final id = matchId.trim();
    if (id.isEmpty) return false;
    final list = (_prefs.getStringList(_keyMatchNotifications) ?? []).toList();
    final isCurrentlyEnabled = isMatchNotificationEnabled(id);
    final nextState = !isCurrentlyEnabled;

    if (nextState) {
      if (!list.contains(id)) list.add(id);
      if (!isFavoriteMatch(id)) await toggleFavoriteMatch(id);
    } else {
      list.remove(id);
      if (isFavoriteMatch(id)) await toggleFavoriteMatch(id);
    }
    await _prefs.setStringList(_keyMatchNotifications, list);
    if (nextState) {
      unawaited(NotificationSyncService.instance.subscribeToMatch(id));
    } else {
      unawaited(NotificationSyncService.instance.unsubscribeFromMatch(id));
    }
    return nextState;
  }

  @override
  Future<bool> setMatchNotificationEnabled(String matchId, bool enabled) async {
    final id = matchId.trim();
    if (id.isEmpty) return false;
    final list = (_prefs.getStringList(_keyMatchNotifications) ?? []).toList();
    if (enabled) {
      if (!list.contains(id)) list.add(id);
      if (!isFavoriteMatch(id)) await toggleFavoriteMatch(id);
    } else {
      list.remove(id);
      if (isFavoriteMatch(id)) await toggleFavoriteMatch(id);
    }
    final saved = await _prefs.setStringList(_keyMatchNotifications, list);
    if (enabled) {
      unawaited(NotificationSyncService.instance.subscribeToMatch(id));
    } else {
      unawaited(NotificationSyncService.instance.unsubscribeFromMatch(id));
    }
    return saved;
  }

  @override
  bool isNewsNotificationEnabled() => _prefs.getBool(_keyNotifNews) ?? true;

  @override
  Future<bool> setNewsNotificationEnabled(bool enabled) async {
    final res = await _prefs.setBool(_keyNotifNews, enabled);
    unawaited(NotificationSyncService.instance.syncAllSubscriptions());
    return res;
  }

  @override
  bool isMatchLineupNotificationEnabled() =>
      _prefs.getBool(_keyNotifLineup) ?? true;

  @override
  Future<bool> setMatchLineupNotificationEnabled(bool enabled) async {
    final res = await _prefs.setBool(_keyNotifLineup, enabled);
    unawaited(NotificationSyncService.instance.syncAllSubscriptions());
    return res;
  }

  @override
  bool isMatchGoalsNotificationEnabled() =>
      _prefs.getBool(_keyNotifGoals) ?? true;

  @override
  Future<bool> setMatchGoalsNotificationEnabled(bool enabled) async {
    final res = await _prefs.setBool(_keyNotifGoals, enabled);
    unawaited(NotificationSyncService.instance.syncAllSubscriptions());
    return res;
  }

  @override
  bool isMatchStartEndNotificationEnabled() =>
      _prefs.getBool(_keyNotifStartEnd) ?? true;

  @override
  Future<bool> setMatchStartEndNotificationEnabled(bool enabled) async {
    final res = await _prefs.setBool(_keyNotifStartEnd, enabled);
    unawaited(NotificationSyncService.instance.syncAllSubscriptions());
    return res;
  }

  @override
  String getMatchNotificationScope() =>
      _prefs.getString(_keyMatchNotifScope) ??
      LocalStorageService.matchNotifScopeStarred;

  @override
  Future<bool> setMatchNotificationScope(String scope) async {
    final res = await _prefs.setString(_keyMatchNotifScope, scope);
    unawaited(NotificationSyncService.instance.syncAllSubscriptions());
    return res;
  }

  static const String _keyLiveMatchMode = 'live_match_mode_enabled';

  @override
  bool isLiveMatchModeEnabled() => _prefs.getBool(_keyLiveMatchMode) ?? true;

  @override
  Future<bool> setLiveMatchModeEnabled(bool enabled) =>
      _prefs.setBool(_keyLiveMatchMode, enabled);

  @override
  bool isNotificationMatchingStarredTeams({
    required String title,
    required String body,
    String? matchId,
    Map<String, dynamic>? data,
  }) {
    // 1. If the match ID itself is favorited or has notification enabled
    if (matchId != null && matchId.isNotEmpty) {
      final favMatches = getFavoriteMatches();
      final matchNotifs = getMatchNotificationIds();
      if (favMatches.contains(matchId) || matchNotifs.contains(matchId)) return true;
    }

    // 2. Collect all starred / subscribed team tokens (IDs & titles, excluding muted)
    final favTeams = getFavoriteTeams();
    final favTitles = getFavoriteTeamTitles();
    final teamNotifs = _prefs.getStringList(_keyTeamNotifications) ?? [];
    final mutedTeams = (_prefs.getStringList(_keyTeamNotificationsMuted) ?? []).toSet();

    final Set<String> targetNames = {};
    for (final t in favTitles.values) {
      final trimmed = t.trim().toLowerCase();
      if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed)) targetNames.add(trimmed);
    }
    for (final t in favTitles.keys) {
      final trimmed = t.trim().toLowerCase();
      if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed)) targetNames.add(trimmed);
    }
    for (final t in teamNotifs) {
      final trimmed = t.trim().toLowerCase();
      if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed)) targetNames.add(trimmed);
    }

    final Set<String> targetIds = {};
    for (final id in favTeams) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed.toLowerCase())) targetIds.add(trimmed);
    }
    for (final id in teamNotifs) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && !mutedTeams.contains(trimmed.toLowerCase())) targetIds.add(trimmed);
    }

    // If user hasn't starred or subscribed to any teams at all, don't filter out everything
    // but in starred_only mode without any stars, no match alerts
    if (targetNames.isEmpty && targetIds.isEmpty) {
      return false;
    }

    // 3. Check data payload fields if present
    if (data != null) {
      final homeId = data['home_team_id']?.toString() ?? data['home_id']?.toString();
      final awayId = data['away_team_id']?.toString() ?? data['away_id']?.toString();
      final teamId = data['team_id']?.toString();
      if ((homeId != null && targetIds.contains(homeId)) ||
          (awayId != null && targetIds.contains(awayId)) ||
          (teamId != null && targetIds.contains(teamId))) {
        return true;
      }

      final homeName = data['home_team']?.toString().toLowerCase();
      final awayName = data['away_team']?.toString().toLowerCase();
      if (homeName != null && targetNames.any((n) => homeName.contains(n) || n.contains(homeName))) {
        return true;
      }
      if (awayName != null && targetNames.any((n) => awayName.contains(n) || n.contains(awayName))) {
        return true;
      }
    }

    // 4. Check notification title and body text against starred team names
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    for (final name in targetNames) {
      if (lowerTitle.contains(name) || lowerBody.contains(name)) {
        return true;
      }
    }

    return false;
  }

  @override
  List<String> getReadNotificationIds() =>
      _prefs.getStringList(_keyReadNotifications) ?? [];

  @override
  Future<bool> markNotificationAsRead(String id) async {
    if (id.isEmpty) return false;
    final list = (_prefs.getStringList(_keyReadNotifications) ?? []).toList();
    if (!list.contains(id)) {
      list.add(id);
      return _prefs.setStringList(_keyReadNotifications, list);
    }
    return true;
  }

  @override
  Future<bool> markAllNotificationsAsRead(List<String> ids) async {
    final list = (_prefs.getStringList(_keyReadNotifications) ?? []).toSet();
    list.addAll(ids);
    return _prefs.setStringList(_keyReadNotifications, list.toList());
  }

  static const String _keyDeveloperMode = 'app_developer_mode_enabled';

  @override
  bool isDeveloperModeEnabled() {
    return _prefs.getBool(_keyDeveloperMode) ?? false;
  }

  @override
  Future<bool> setDeveloperModeEnabled(bool enabled) {
    return _prefs.setBool(_keyDeveloperMode, enabled);
  }
}
