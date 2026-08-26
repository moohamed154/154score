class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://moohamed154-154score-api.hf.space';
  static const String websocketUrl = 'https://moohamed154-154score-api.hf.space';

  // WebSocket Channels / Rooms
  static const String wsChannelAr = 'live_matches_ar';
  static const String wsChannelEn = 'live_matches_en';

  // REST Endpoints
  static const String matches = '/api/matches';
  static String matchEvents(String id) => '/api/matches/$id/events';
  static String matchStats(String id) => '/api/matches/$id/stats';
  static String matchDetails(String id) => '/api/matches/$id/details';
  static String matchNews(String id) => '/api/matches/$id/news';

  static const String transfers = '/api/transfers';
  static const String videos = '/api/videos';
  static String videoDetails(String id) => '/api/videos/$id';

  static String leagueStandings(String id) => '/api/leagues/$id/standings';

  static String stadium(String id, String slug) => '/api/stadium/$id/$slug';
  static String referee(String id, String slug) => '/api/referee/$id/$slug';
  static String commentator(String id, String slug) => '/api/commentator/$id/$slug';

  static const String serverHealth = '/api/config?type=health';
  static const String ping = '/ping';
  static const String metrics = '/api/metrics';
}
