import 'dart:convert';
import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:score154/core/constants/app_colors.dart';

import '../../core/di/injection_container.dart';
import '../../core/utils/league_resolver.dart';
import '../../core/utils/url_helper.dart';
import '../../features/favorites/presentation/views/favorites_view.dart';
import '../../features/home/presentation/views/home_view.dart';

import '../../features/leagues/presentation/bloc/league_bloc.dart';
import '../../features/leagues/presentation/views/league_view.dart';
import '../../features/match_details/presentation/bloc/match_details_bloc.dart';
import '../../features/match_details/presentation/views/match_details_view.dart';
import '../../features/matches/domain/entities/match_entity.dart';
import '../../features/news/presentation/views/news_detail_view.dart';
import '../../features/news/presentation/views/news_view.dart';
import '../../features/players/presentation/bloc/player_bloc.dart';
import '../../features/players/presentation/views/player_view.dart';
import '../../features/profiles/presentation/views/generic_profile_view.dart';
import '../../features/notifications/presentation/views/notifications_view.dart';
import '../../features/search/presentation/views/search_view.dart';
import '../../features/settings/presentation/views/language_settings_view.dart';
import '../../features/settings/presentation/views/notification_settings_view.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import '../../features/settings/presentation/views/theme_settings_view.dart';
import '../../features/settings/presentation/views/time_format_settings_view.dart';
import '../../features/settings/presentation/views/timezone_selection_view.dart';
import '../../features/standings/presentation/views/standings_view.dart';
import '../../features/teams/presentation/bloc/team_bloc.dart';
import '../../features/teams/presentation/views/team_view.dart';
import '../../features/transfers/presentation/views/transfers_view.dart';
import '../../features/videos/domain/entities/video_entity.dart';
import '../../features/videos/presentation/views/video_details_view.dart';
import '../../features/videos/presentation/views/videos_view.dart';
import '../../core/network/debug_console.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../../features/onboarding/presentation/viewmodels/onboarding_cubit.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/maintenance/domain/entities/maintenance_info.dart';
import '../../features/maintenance/presentation/viewmodels/maintenance_cubit.dart';
import '../../features/maintenance/presentation/views/maintenance_view.dart';
import '../navigation/app_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

Page<dynamic> _buildCupertinoPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CupertinoPage<void>(
    key: state.pageKey,
    name: state.name ?? state.matchedLocation,
    child: child,
  );
}

class AppRouter {
  AppRouter._();

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  static String? _pendingRoute;

  /// Retrieves and clears any pending route queued during splash / launch.
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Checks if the splash screen is currently active.
  static bool get isSplashActive {
    try {
      final loc = router.routerDelegate.currentConfiguration.uri.toString();
      return loc.isEmpty || loc == '/splash' || loc.startsWith('/splash');
    } catch (_) {
      return false;
    }
  }

  static bool get isMaintenanceActive {
    try {
      final loc = router.routerDelegate.currentConfiguration.uri.toString();
      return loc == '/maintenance' || loc.startsWith('/maintenance');
    } catch (_) {
      return false;
    }
  }

  /// Explicit navigation helper for match details
  static void navigateToMatch(String matchId) {
    final clean = matchId.replaceAll('match:', '').trim();
    if (clean.isEmpty) return;
    final path = '/match/$clean';
    if (isSplashActive) {
      _pendingRoute = path;
    } else {
      router.push(path);
    }
  }

  /// Explicit navigation helper for news articles
  static void navigateToNews(String articleId) {
    final clean = articleId.trim();
    if (clean.isEmpty) return;
    final path = '/news/$clean';
    if (isSplashActive) {
      _pendingRoute = path;
    } else {
      router.push(path);
    }
  }

  /// Called when the user taps a notification.
  /// Parses String (JSON, raw path, or ID) or Map, extracts match/news ID, and navigates.
  static void handleNotificationPayload(dynamic payload) {
    if (payload == null) return;
    try {
      Map<String, dynamic> data;
      if (payload is Map<String, dynamic>) {
        data = payload;
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      } else if (payload is String) {
        final str = payload.trim();
        if (str.isEmpty) return;
        if (str.startsWith('{') && str.endsWith('}')) {
          data = (jsonDecode(str) as Map).cast<String, dynamic>();
        } else if (str.contains('/match/')) {
          final id =
              str.split('/match/').last.split('?').first.split('/').first;
          navigateToMatch(id);
          return;
        } else if (str.contains('/news/')) {
          final id = str.split('/news/').last.split('?').first.split('/').first;
          navigateToNews(id);
          return;
        } else if (str.startsWith('match:')) {
          navigateToMatch(str.replaceAll('match:', ''));
          return;
        } else if (int.tryParse(str) != null) {
          navigateToMatch(str);
          return;
        } else {
          return;
        }
      } else {
        return;
      }

      // Check if data contains nested data or payload strings/maps
      if (data['data'] is Map) {
        data = {...data, ...(data['data'] as Map).cast<String, dynamic>()};
      } else if (data['data'] is String &&
          (data['data'] as String).trim().startsWith('{')) {
        try {
          final inner = (jsonDecode(data['data'] as String) as Map)
              .cast<String, dynamic>();
          data = {...data, ...inner};
        } catch (_) {}
      }

      if (data['payload'] is String &&
          (data['payload'] as String).trim().startsWith('{')) {
        try {
          final inner = (jsonDecode(data['payload'] as String) as Map)
              .cast<String, dynamic>();
          data = {...data, ...inner};
        } catch (_) {}
      }

      final type =
          (data['type'] ?? data['event_type'] ?? '').toString().toLowerCase();

      final rawMatchId = (data['match_id'] ??
              data['matchId'] ??
              data['matchID'] ??
              data['match'])
          ?.toString();
      final rawArticleId = (data['article_id'] ??
              data['articleId'] ??
              data['news_id'] ??
              data['newsId'] ??
              data['article'])
          ?.toString();
      final genericId = data['id']?.toString();

      if (type == 'news' || (rawArticleId != null && rawArticleId.isNotEmpty)) {
        final targetNewsId = (rawArticleId != null && rawArticleId.isNotEmpty)
            ? rawArticleId
            : genericId;
        if (targetNewsId != null && targetNewsId.isNotEmpty) {
          navigateToNews(targetNewsId);
          return;
        }
      }

      if (rawMatchId != null && rawMatchId.isNotEmpty) {
        navigateToMatch(rawMatchId);
        return;
      }

      if (genericId != null &&
          genericId.isNotEmpty &&
          genericId != 'alert' &&
          genericId != 'live') {
        if (type == 'news') {
          navigateToNews(genericId);
        } else {
          navigateToMatch(genericId);
        }
        return;
      }

      if (type == 'notifications') {
        if (isSplashActive) {
          _pendingRoute = '/notifications';
        } else {
          router.push('/notifications');
        }
      }
    } catch (e) {
      debugPrint('[AppRouter] handleNotificationPayload error: $e');
    }
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: [DebugConsoleRouteObserver()],
    initialLocation: '/splash',
    redirect: (context, state) {
      final uriStr = state.uri.toString();
      // Handle custom scheme deep links e.g. score154://match/12345
      if (state.uri.scheme == 'score154' || uriStr.startsWith('score154:')) {
        if (uriStr.contains('match/')) {
          final id = uriStr
              .split('match/')
              .last
              .split('?')
              .first
              .split('/')
              .first
              .trim();
          if (id.isNotEmpty) {
            return '/match/$id';
          }
        } else if (uriStr.contains('news/')) {
          final id = uriStr
              .split('news/')
              .last
              .split('?')
              .first
              .split('/')
              .first
              .trim();
          if (id.isNotEmpty) {
            return '/news/$id';
          }
        }
        return '/';
      }
      return null;
    },
    errorBuilder: (context, state) {
      final uriStr = state.uri.toString();
      if (uriStr.contains('match/')) {
        final id = uriStr
            .split('match/')
            .last
            .split('?')
            .first
            .split('/')
            .first
            .trim();
        if (id.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateToMatch(id);
          });
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
      } else if (uriStr.contains('news/')) {
        final id =
            uriStr.split('news/').last.split('?').first.split('/').first.trim();
        if (id.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateToNews(id);
          });
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
      }
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الصفحة غير موجودة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeView()),
            ],
          ),

          // Branch 1: News
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => const NewsView(),
              ),
            ],
          ),

          // Branch 2: Standings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/standings',
                builder: (context, state) => const StandingsView(),
              ),
            ],
          ),

          // Branch 3: Transfers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transfers',
                builder: (context, state) => const TransfersView(),
              ),
            ],
          ),

          // Branch 4: Videos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/videos',
                builder: (context, state) => const VideosView(),
              ),
            ],
          ),
          // Branch 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _buildCupertinoPage(
                  state: state,
                  child: const SettingsView(),
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'timezone',
                    pageBuilder: (context, state) => _buildCupertinoPage(
                      state: state,
                      child: const TimezoneSelectionView(),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'notifications',
                    pageBuilder: (context, state) => _buildCupertinoPage(
                      state: state,
                      child: const NotificationSettingsView(),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'time-format',
                    pageBuilder: (context, state) => _buildCupertinoPage(
                      state: state,
                      child: const TimeFormatSettingsView(),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'language',
                    pageBuilder: (context, state) => _buildCupertinoPage(
                      state: state,
                      child: const LanguageSettingsView(),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'theme',
                    pageBuilder: (context, state) => _buildCupertinoPage(
                      state: state,
                      child: const ThemeSettingsView(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Splash Screen
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),

      // Maintenance Screen
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/maintenance',
        builder: (context, state) {
          final info = state.extra is MaintenanceInfo
              ? state.extra as MaintenanceInfo
              : null;
          return BlocProvider<MaintenanceCubit>(
            create: (_) => sl<MaintenanceCubit>(),
            child: MaintenanceView(initialInfo: info),
          );
        },
      ),

      // First-launch onboarding (shown once)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => BlocProvider<OnboardingCubit>(
          create: (_) => sl<OnboardingCubit>(),
          child: const OnboardingView(),
        ),
      ),

      // Favorites
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/favorites',
        pageBuilder: (context, state) => _buildCupertinoPage(
          state: state,
          child: const FavoritesView(),
        ),
      ),

      // Search
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/search',
        pageBuilder: (context, state) => _buildCupertinoPage(
          state: state,
          child: const GlobalSearchView(),
        ),
      ),

      // Notifications
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        pageBuilder: (context, state) => _buildCupertinoPage(
          state: state,
          child: const NotificationsView(),
        ),
      ),

      // News Detail
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/news/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final slug = extra?['slug']?.toString();
          return _buildCupertinoPage(
            state: state,
            child: NewsDetailView(articleId: id, slug: slug),
          );
        },
      ),

      // Match Details
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/match/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final match = state.extra as MatchEntity?;
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<MatchDetailsBloc>(param1: id),
              child: MatchDetailsView(matchId: id, initialMatch: match),
            ),
          );
        },
      ),

      // League Page
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/league/:id',
        pageBuilder: (context, state) {
          var id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = extra?['tab'] as int? ??
              (tabParam != null ? int.tryParse(tabParam) ?? 0 : 0);
          final title = extra?['title']?.toString();
          if ((id == '0' || id.isEmpty) && title != null) {
            id = LeagueResolver.resolveId(title) ?? id;
          }
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<LeagueBloc>(param1: id, param2: extra),
              child: LeagueView(
                leagueId: id,
                initialTitle: title,
                initialLogo: extra?['logo']?.toString(),
                initialTabIndex: initialTab,
              ),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/league/:id/:slug',
        pageBuilder: (context, state) {
          var id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = extra?['tab'] as int? ??
              (tabParam != null ? int.tryParse(tabParam) ?? 0 : 0);
          final title = extra?['title']?.toString() ??
              (slug.isNotEmpty ? UrlHelper.slugToName(slug) : null);
          if (id == '0' || id.isEmpty) {
            id = LeagueResolver.resolveId(title) ??
                LeagueResolver.resolveId(slug) ??
                id;
          }
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<LeagueBloc>(param1: id, param2: extra),
              child: LeagueView(
                leagueId: id,
                initialTitle: title,
                initialLogo: extra?['logo']?.toString(),
                initialTabIndex: initialTab,
              ),
            ),
          );
        },
      ),

      // Team Page
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/team/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<TeamBloc>(param1: id, param2: extra),
              child: TeamView(
                teamId: id,
                initialName: extra?['name']?.toString(),
                initialLogo: extra?['logo']?.toString(),
                leagueId: extra?['leagueId']?.toString(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/team/:id/:slug',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final name = extra?['name']?.toString() ??
              (slug.isNotEmpty ? UrlHelper.slugToName(slug) : null);
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<TeamBloc>(param1: id, param2: extra),
              child: TeamView(
                teamId: id,
                initialName: name,
                initialLogo: extra?['logo']?.toString(),
                leagueId: extra?['leagueId']?.toString(),
              ),
            ),
          );
        },
      ),

      // Standings with specific league
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/standings/:leagueId',
        pageBuilder: (context, state) {
          final leagueId = state.pathParameters['leagueId'];
          return _buildCupertinoPage(
            state: state,
            child: StandingsView(initialLeagueId: leagueId),
          );
        },
      ),

      // Video Details
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/video/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final video = state.extra as VideoItemEntity?;
          return _buildCupertinoPage(
            state: state,
            child: VideoDetailsView(videoId: id, initialVideo: video),
          );
        },
      ),

      // Stadium Profile
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/stadium/:id/:slug',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          return _buildCupertinoPage(
            state: state,
            child: GenericProfileView(
              id: id,
              slug: slug,
              type: ProfileType.stadium,
            ),
          );
        },
      ),

      // Referee Profile
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/referee/:id/:slug',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          return _buildCupertinoPage(
            state: state,
            child: GenericProfileView(
              id: id,
              slug: slug,
              type: ProfileType.referee,
            ),
          );
        },
      ),

      // Commentator Profile
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/commentator/:id/:slug',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          return _buildCupertinoPage(
            state: state,
            child: GenericProfileView(
              id: id,
              slug: slug,
              type: ProfileType.commentator,
            ),
          );
        },
      ),

      // Coach Profile
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/coach/:id/:slug',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          return _buildCupertinoPage(
            state: state,
            child: GenericProfileView(
              id: id,
              slug: slug,
              type: ProfileType.coach,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/coach/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.uri.queryParameters['slug'] ?? '';
          return _buildCupertinoPage(
            state: state,
            child: GenericProfileView(
              id: id,
              slug: slug,
              type: ProfileType.coach,
            ),
          );
        },
      ),

      // Player Profile
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/player/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.uri.queryParameters['slug'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<PlayerBloc>(
                param1: id,
                param2: {'slug': slug, if (extra != null) ...extra},
              ),
              child: PlayerView(
                playerId: id,
                initialSlug: slug,
                initialName: extra?['name']?.toString(),
                initialPhoto: extra?['photo']?.toString(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/player/:id/:slug',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return _buildCupertinoPage(
            state: state,
            child: BlocProvider(
              create: (_) => sl<PlayerBloc>(
                param1: id,
                param2: {'slug': slug, if (extra != null) ...extra},
              ),
              child: PlayerView(
                playerId: id,
                initialSlug: slug,
                initialName: extra?['name']?.toString(),
                initialPhoto: extra?['photo']?.toString(),
              ),
            ),
          );
        },
      ),

      // Settings is now a shell branch (Branch 7) — see StatefulShellRoute above.
    ],
  );
}
