import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get websocketUrl => AppConfig.apiBaseUrl;

  // WebSocket Channels / Rooms
  static const String wsChannelAr = 'live_matches_ar';
  static const String wsChannelEn = 'live_matches_en';
  static const String wsChannelMatchesAr = 'live_matches_ar';
  static const String wsChannelTransfersAr = 'transfers_ar';
  static String wsMatchRoom(String matchId) => 'match:$matchId';

  // Static Asset & Image Endpoints (Section 2)
  static const String logoDark = 'https://imgs.ysscores.com/images/logodark.png';
  static const String logoLight = 'https://imgs.ysscores.com/images/logolight.png';

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

  // 2. Matches & Predictions Operations
  static const String matches = '/api/matches';
  static const String matchesLive = '/api/matches/live';
  static String matchesByDate(String date) => '/api/matches/date/$date';
  static String matchDetails(String id) => '/api/matches/$id/details';
  static String matchEvents(String id) => '/api/matches/$id/events';
  static String matchStats(String id) => '/api/matches/$id/stats';
  static String matchNews(String id) => '/api/matches/$id/news';
  static String matchLineups(String id) => '/api/matches/$id/lineups';
  static String matchLineup(String id) => '/api/matches/$id/lineup';
  static String matchStandings(String id) => '/api/matches/$id/standings';
  static String matchPredictions(String id) => '/api/matches/$id/predictions';
  static String predictions(String id) => '/api/predictions/$id';

  // 3. News Operations
  static const String news = '/api/news';
  static String newsDetails(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/news/$id/$slug'
      : '/api/news/$id';

  // 4. Teams Operations
  static String teamProfile(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/teams/$id/$slug'
      : '/api/teams/$id';
  static String teamPlayers(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/teams/$id/$slug/players'
      : '/api/teams/$id/players';
  static String teamMatches(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/teams/$id/$slug/matches'
      : '/api/teams/$id/matches';
  static String teamStandings(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/teams/$id/$slug/standings'
      : '/api/teams/$id/standings';
  static String teamTransfers(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/teams/$id/$slug/transfers'
      : '/api/teams/$id/transfers';
  static String teamNews(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/teams/$id/$slug/news'
      : '/api/teams/$id/news';

  // 5. Players Operations
  static String playerProfile(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/players/$id/$slug'
      : '/api/players/$id';

  // 6. Profiles Operations (Stadium, Referee, Commentator)
  static String stadium(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/stadium/$id/$slug'
      : '/api/stadium/$id';
  static String referee(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/referee/$id/$slug'
      : '/api/referee/$id';
  static String commentator(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/commentator/$id/$slug'
      : '/api/commentator/$id';
  static String coach(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/coach/$id/$slug'
      : '/api/coach/$id';

  // 7. Content & Search Operations
  static const String search = '/api/search';
  static const String transfers = '/api/transfers';
  static const String videos = '/api/videos';
  static String videoDetails(String id) => '/api/videos/$id';

  // 8. League Operations & Aliases
  static const String rank = '/api/rank';
  static const String leagues = '/api/leagues';
  static const String championships = '/api/championships';
  static const String competitions = '/api/competitions';
  static String leagueProfile(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug'
      : '/api/leagues/$id';
  static String leagueStandings(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/standings'
      : '/api/leagues/$id/standings';
  static String leagueTopScorers(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/top-scorers'
      : '/api/leagues/$id/top-scorers';
  static String leagueScorers(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/scorers'
      : '/api/leagues/$id/scorers';
  static String leagueMatches(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/matches'
      : '/api/leagues/$id/matches';
  static String leagueNews(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/news'
      : '/api/leagues/$id/news';
  static String leagueTeams(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/teams'
      : '/api/leagues/$id/teams';
  static String leagueAssists(String id, [String? slug]) =>
      (slug != null && slug.isNotEmpty)
      ? '/api/leagues/$id/$slug/assists'
      : '/api/leagues/$id/assists';

  // 8. Notifications Operations
  static const String notifications = '/api/notifications';

  // 9. Push Notifications & Background Workers (Section 4.7)
  static const String pushNotificationsProviders =
      '/notifications/push_notifications_providers';
  static const String pushNotificationsProvidersFallback =
      '/api/notifications/push_notifications_providers';

  static const String notificationPostService =
      '/notifications/notification_post_service';
  static const String notificationPostServiceFallback =
      '/api/notifications/notification_post_service';

  static const String matchReminderBackgroundTask =
      '/notifications/match_reminder_background_task';
  static const String matchReminderBackgroundTaskFallback =
      '/api/notifications/match_reminder_background_task';
}
