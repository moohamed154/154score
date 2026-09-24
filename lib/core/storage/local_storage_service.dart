import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
  Future<bool> setTimezoneOffset(int offset, {bool isAuto = false});
  bool isTimezoneAuto() => true;
  Future<bool> setTimezoneAuto(bool isAuto) async => true;
  int getDeviceTimezoneOffset() => DateTime.now().timeZoneOffset.inHours;

  // Favorites
  List<String> getFavoriteTeams();
  Future<bool> toggleFavoriteTeam(String teamName);
  bool isFavoriteTeam(String teamName);

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
  Future<bool> setTimezoneOffset(int offset, {bool isAuto = false}) async {
    await _prefs.setBool(_keyTimezoneAuto, isAuto);
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
  Future<bool> toggleFavoriteTeam(String teamName) async {
    final list = getFavoriteTeams().toList();
    if (list.contains(teamName)) {
      list.remove(teamName);
    } else {
      list.add(teamName);
    }
    return _prefs.setStringList(_keyFavoriteTeams, list);
  }

  @override
  bool isFavoriteTeam(String teamName) {
    return getFavoriteTeams().contains(teamName);
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
}
