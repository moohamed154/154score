class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://moohamed154-154score-api.hf.space';
  static const String websocketUrl =
      'https://moohamed154-154score-api.hf.space';

  // WebSocket Channels / Rooms
  static const String wsChannelAr = 'live_matches_ar';
  static const String wsChannelEn = 'live_matches_en';
  static const String wsChannelMatchesAr = 'live_matches_ar';
  static const String wsChannelTransfersAr = 'transfers_ar';
  static String wsMatchRoom(String matchId) => 'match:$matchId';

  // 1. System Operations
  static const String root = '/';
  static const String ping = '/ping';
  static const String docs = '/api/docs';
  static const String openapi = '/api/openapi.json';
  static const String config = '/api/config';
  static const String metrics = '/api/metrics';
  static const String update = '/api/update';
  static const String maintenance = '/api/maintenance';
  static const String health = '/api/health';
  static const String serverHealth = '/api/config?type=health';

  // 2. Matches Operations
  static const String matches = '/api/matches';
  static const String matchesLive = '/api/matches/live';
  static String matchesByDate(String date) => '/api/matches/date/$date';
  static String matchDetails(String id) => '/api/matches/$id/details';
  static String matchEvents(String id) => '/api/matches/$id/events';
  static String matchStats(String id) => '/api/matches/$id/stats';
  static String matchNews(String id) => '/api/matches/$id/news';

  // 3. Profiles Operations
  static String stadium(String id, String slug) => '/api/stadium/$id/$slug';
  static String referee(String id, String slug) => '/api/referee/$id/$slug';
  static String commentator(String id, String slug) =>
      '/api/commentator/$id/$slug';

  // 4. Content & Search Operations
  static const String search = '/api/search';
  static const String transfers = '/api/transfers';
  static const String videos = '/api/videos';
  static String videoDetails(String id) => '/api/videos/$id';

  // 5. League Operations
  static String leagueProfile(String id) => '/api/leagues/$id';
  static String leagueStandings(String id) => '/api/leagues/$id/standings';
  static String leagueTopScorers(String id) => '/api/leagues/$id/top-scorers';
  static String leagueMatches(String id) => '/api/leagues/$id/matches';
  static String leagueNews(String id) => '/api/leagues/$id/news';
  static String leagueTeams(String id) => '/api/leagues/$id/teams';
}
