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
  Future<bool> setTimezoneOffset(int offset);

  // Favorites
  List<String> getFavoriteTeams();
  Future<bool> toggleFavoriteTeam(String teamName);
  bool isFavoriteTeam(String teamName);

  List<String> getFavoriteCompetitions();
  Future<bool> toggleFavoriteCompetition(String compName);
  bool isFavoriteCompetition(String compName);

  List<String> getFavoriteMatches();
  Future<bool> toggleFavoriteMatch(String matchId);
  bool isFavoriteMatch(String matchId);
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageServiceImpl(this._prefs);

  static const String _keyLanguage = 'app_language';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyTimeFormat = 'app_time_format';
  static const String _keyTimezoneOffset = 'app_timezone_offset';
  static const String _keyFavoriteTeams = 'app_favorite_teams';
  static const String _keyFavoriteCompetitions = 'app_favorite_competitions';
  static const String _keyFavoriteMatches = 'app_favorite_matches';

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
    return _prefs.getString(_keyThemeMode) ?? 'dark';
  }

  @override
  Future<bool> setThemeMode(String themeMode) {
    return _prefs.setString(_keyThemeMode, themeMode);
  }

  @override
  String getTimeFormat() {
    return _prefs.getString(_keyTimeFormat) ?? '12h';
  }

  @override
  Future<bool> setTimeFormat(String format) {
    return _prefs.setString(_keyTimeFormat, format);
  }

  @override
  int getTimezoneOffset() {
    return _prefs.getInt(_keyTimezoneOffset) ?? 3;
  }

  @override
  Future<bool> setTimezoneOffset(int offset) {
    return _prefs.setInt(_keyTimezoneOffset, offset);
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
    return _prefs.getStringList(_keyFavoriteCompetitions) ?? [];
  }

  @override
  Future<bool> toggleFavoriteCompetition(String compName) async {
    final list = getFavoriteCompetitions().toList();
    if (list.contains(compName)) {
      list.remove(compName);
    } else {
      list.add(compName);
    }
    return _prefs.setStringList(_keyFavoriteCompetitions, list);
  }

  @override
  bool isFavoriteCompetition(String compName) {
    return getFavoriteCompetitions().contains(compName);
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
}
