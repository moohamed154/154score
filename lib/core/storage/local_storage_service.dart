import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/team_resolver.dart';

abstract class LocalStorageService {
  Future<void> init();

  // Language
  String getLanguage();
  Future<bool> setLanguage(String langCode);

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

  // Team & Match Notifications
  bool isTeamNotificationEnabled(String teamIdOrName) => false;
  Future<bool> toggleTeamNotification(String teamIdOrName) async => false;

  // Granular Notification Toggles
  bool isNewsNotificationEnabled();
  Future<bool> setNewsNotificationEnabled(bool enabled);
  bool isMatchLineupNotificationEnabled();
  Future<bool> setMatchLineupNotificationEnabled(bool enabled);
  bool isMatchGoalsNotificationEnabled();
  Future<bool> setMatchGoalsNotificationEnabled(bool enabled);
  bool isMatchStartEndNotificationEnabled();
  Future<bool> setMatchStartEndNotificationEnabled(bool enabled);

  // Read Notifications IDs
  List<String> getReadNotificationIds();
  Future<bool> markNotificationAsRead(String id);
  Future<bool> markAllNotificationsAsRead(List<String> ids);
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageServiceImpl(this._prefs);

  static const String _keyLanguage = 'app_language';
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
  Future<bool> setLanguage(String langCode) {
    return _prefs.setString(_keyLanguage, langCode);
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

  @override
  List<String> getFavoriteTeams() {
    return _prefs.getStringList(_keyFavoriteTeams) ?? [];
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
    final cleanId = id?.trim();

    // 1. Direct match on name or ID, or via TeamResolver cross-lingual match
    for (final fav in list) {
      final cleanFav = fav.trim();
      if (cleanName.isNotEmpty &&
          cleanFav.toLowerCase() == cleanName.toLowerCase()) {
        return true;
      }
      if (cleanId != null &&
          cleanId.isNotEmpty &&
          cleanFav.toLowerCase() == cleanId.toLowerCase()) {
        return true;
      }
      if (cleanName.isNotEmpty && TeamResolver.areSameTeam(cleanFav, cleanName)) {
        return true;
      }
      if (cleanId != null &&
          cleanId.isNotEmpty &&
          TeamResolver.areSameTeam(cleanFav, cleanId)) {
        return true;
      }
    }

    // 2. Check teamTitles mapping
    final titles = getFavoriteTeamTitles();
    if (cleanId != null && titles.containsKey(cleanId)) {
      final mappedName = titles[cleanId]!;
      for (final fav in list) {
        if (fav.trim().toLowerCase() == mappedName.trim().toLowerCase() ||
            TeamResolver.areSameTeam(fav, mappedName)) {
          return true;
        }
      }
    }
    if (cleanName.isNotEmpty && titles.containsKey(cleanName.toLowerCase())) {
      final mappedId = titles[cleanName.toLowerCase()]!;
      for (final fav in list) {
        if (fav.trim().toLowerCase() == mappedId.trim().toLowerCase() ||
            TeamResolver.areSameTeam(fav, mappedId)) {
          return true;
        }
      }
    }

    // 3. Check canonical key
    final nameKey = cleanName.isNotEmpty ? TeamResolver.getCanonicalKey(cleanName) : null;
    final idKey = (cleanId != null && cleanId.isNotEmpty) ? TeamResolver.getCanonicalKey(cleanId) : null;
    if (nameKey != null || idKey != null) {
      for (final fav in list) {
        final favKey = TeamResolver.getCanonicalKey(fav);
        if (favKey != null) {
          if (nameKey != null && favKey == nameKey) return true;
          if (idKey != null && favKey == idKey) return true;
        }
      }
    }

    return false;
  }

  @override
  Future<bool> toggleFavoriteTeam(String teamName, {String? id}) async {
    final list = getFavoriteTeams().toList();
    final isFav = isFavoriteTeam(teamName, id: id);
    final cleanName = teamName.trim();
    final cleanId = id?.trim();

    if (isFav) {
      // Remove all matching variants (both languages, aliases, ID)
      list.removeWhere((item) {
        final cleanItem = item.trim();
        if (cleanName.isNotEmpty &&
            cleanItem.toLowerCase() == cleanName.toLowerCase()) {
          return true;
        }
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            cleanItem.toLowerCase() == cleanId.toLowerCase()) {
          return true;
        }
        if (cleanName.isNotEmpty &&
            TeamResolver.areSameTeam(cleanItem, cleanName)) {
          return true;
        }
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            TeamResolver.areSameTeam(cleanItem, cleanId)) {
          return true;
        }
        return false;
      });
    } else {
      if (cleanName.isNotEmpty && !list.contains(cleanName)) {
        list.add(cleanName);
      }
      if (cleanId != null && cleanId.isNotEmpty && cleanName.isNotEmpty) {
        unawaited(registerTeamTitles({cleanId: cleanName}));
      }
    }
    return _prefs.setStringList(_keyFavoriteTeams, list);
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
  Future<bool> setFavoriteCompetitions(List<String> list) {
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

    final targets = <String>{};
    void addTarget(String? s) {
      if (s != null && s.trim().isNotEmpty) {
        targets.add(s.trim().toLowerCase());
      }
    }

    addTarget(compName);
    addTarget(id);
    addTarget(name);
    addTarget(slug);

    final titles = getFavoriteCompetitionTitles();
    if (id != null && titles.containsKey(id.trim())) {
      addTarget(titles[id.trim()]);
    }
    if (compName != null && titles.containsKey(compName.trim())) {
      addTarget(titles[compName.trim()]);
    }
    if (name != null && titles.containsKey(name.trim())) {
      addTarget(titles[name.trim()]);
    }

    for (final candidate in [compName, name, slug]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        final clean = candidate.trim().toLowerCase();
        final resolvedId = defaultNameToId[clean] ?? titles[clean];
        if (resolvedId != null) addTarget(resolvedId);
      }
    }

    for (final fav in list) {
      final cleanFav = fav.trim().toLowerCase();
      if (targets.contains(cleanFav)) return true;
      if (titles.containsKey(fav.trim())) {
        final mapped = titles[fav.trim()]!.trim().toLowerCase();
        if (targets.contains(mapped)) return true;
      }
      if (titles.containsKey(cleanFav)) {
        final mapped = titles[cleanFav]!.trim().toLowerCase();
        if (targets.contains(mapped)) return true;
      }
      final resolvedId = defaultNameToId[cleanFav];
      if (resolvedId != null && targets.contains(resolvedId.toLowerCase())) {
        return true;
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
    final isFav = isFavoriteCompetition(
      compName: compName,
      id: id,
      name: name,
      slug: slug,
    );

    final targets = <String>{};
    void addTarget(String? s) {
      if (s != null && s.trim().isNotEmpty) {
        targets.add(s.trim().toLowerCase());
      }
    }

    addTarget(compName);
    addTarget(id);
    addTarget(name);
    addTarget(slug);

    final titles = getFavoriteCompetitionTitles();
    if (id != null && titles.containsKey(id.trim())) {
      addTarget(titles[id.trim()]);
    }
    if (name != null && titles.containsKey(name.trim())) {
      addTarget(titles[name.trim()]);
    }
    if (compName != null && titles.containsKey(compName.trim())) {
      addTarget(titles[compName.trim()]);
    }

    if (isFav) {
      list.removeWhere((item) {
        final cleanItem = item.trim().toLowerCase();
        if (targets.contains(cleanItem)) return true;
        if (titles.containsKey(item.trim()) &&
            targets.contains(titles[item.trim()]!.trim().toLowerCase())) {
          return true;
        }
        return false;
      });
    } else {
      final canonicalName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : ((compName != null && compName.trim().isNotEmpty)
                ? compName.trim()
                : (id?.trim() ?? ''));

      if (canonicalName.isNotEmpty && !list.contains(canonicalName)) {
        list.add(canonicalName);
      }
      if (id != null && id.trim().isNotEmpty && canonicalName.isNotEmpty) {
        unawaited(registerCompetitionTitles({id.trim(): canonicalName}));
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
    return getFavoriteMatches().contains(matchId);
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

  static const String _keyTeamNotifications = 'team_notifications';
  static const String _keyNotifNews = 'notif_news_enabled';
  static const String _keyNotifLineup = 'notif_lineup_enabled';
  static const String _keyNotifGoals = 'notif_goals_enabled';
  static const String _keyNotifStartEnd = 'notif_start_end_enabled';
  static const String _keyReadNotifications = 'read_notifications_ids';

  @override
  bool isTeamNotificationEnabled(String teamIdOrName) {
    if (teamIdOrName.trim().isEmpty) return false;
    final list = _prefs.getStringList(_keyTeamNotifications) ?? [];
    return list.contains(teamIdOrName.trim().toLowerCase());
  }

  @override
  Future<bool> toggleTeamNotification(String teamIdOrName) async {
    final key = teamIdOrName.trim().toLowerCase();
    if (key.isEmpty) return false;
    final list = (_prefs.getStringList(_keyTeamNotifications) ?? []).toList();
    final enabled = !list.contains(key);
    if (enabled) {
      list.add(key);
    } else {
      list.remove(key);
    }
    await _prefs.setStringList(_keyTeamNotifications, list);
    return enabled;
  }

  @override
  bool isNewsNotificationEnabled() => _prefs.getBool(_keyNotifNews) ?? true;

  @override
  Future<bool> setNewsNotificationEnabled(bool enabled) =>
      _prefs.setBool(_keyNotifNews, enabled);

  @override
  bool isMatchLineupNotificationEnabled() =>
      _prefs.getBool(_keyNotifLineup) ?? true;

  @override
  Future<bool> setMatchLineupNotificationEnabled(bool enabled) =>
      _prefs.setBool(_keyNotifLineup, enabled);

  @override
  bool isMatchGoalsNotificationEnabled() =>
      _prefs.getBool(_keyNotifGoals) ?? true;

  @override
  Future<bool> setMatchGoalsNotificationEnabled(bool enabled) =>
      _prefs.setBool(_keyNotifGoals, enabled);

  @override
  bool isMatchStartEndNotificationEnabled() =>
      _prefs.getBool(_keyNotifStartEnd) ?? true;

  @override
  Future<bool> setMatchStartEndNotificationEnabled(bool enabled) =>
      _prefs.setBool(_keyNotifStartEnd, enabled);

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
}
