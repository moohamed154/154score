import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/matches/presentation/views/matches_view.dart';
import '../../features/players/presentation/bloc/player_bloc.dart';
import '../../features/players/presentation/views/player_view.dart';
import '../../features/profiles/presentation/views/generic_profile_view.dart';
import '../../features/search/presentation/views/search_view.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import '../../features/standings/presentation/views/standings_view.dart';
import '../../features/teams/presentation/bloc/team_bloc.dart';
import '../../features/teams/presentation/views/team_view.dart';
import '../../features/transfers/presentation/views/transfers_view.dart';
import '../../features/videos/domain/entities/video_entity.dart';
import '../../features/videos/presentation/views/video_details_view.dart';
import '../../features/videos/presentation/views/videos_view.dart';
import '../../core/network/debug_console.dart';
import '../../features/splash/presentation/views/splash_view.dart';
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

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: [DebugConsoleRouteObserver()],
    initialLocation: '/splash',
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

          // Branch 1: Matches
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matches',
                builder: (context, state) => const MatchesView(),
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
          // Branch 5: Favorites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => _buildCupertinoPage(
                  state: state,
                  child: const FavoritesView(),
                ),
              ),
            ],
          ),

          // Branch 6: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => _buildCupertinoPage(
                  state: state,
                  child: const GlobalSearchView(),
                ),
              ),
            ],
          ),

          // Branch 7: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _buildCupertinoPage(
                  state: state,
                  child: const SettingsView(),
                ),
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
          final initialTab =
              extra?['tab'] as int? ??
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
          final initialTab =
              extra?['tab'] as int? ??
              (tabParam != null ? int.tryParse(tabParam) ?? 0 : 0);
          final title =
              extra?['title']?.toString() ??
              (slug.isNotEmpty ? UrlHelper.slugToName(slug) : null);
          if (id == '0' || id.isEmpty) {
            id =
                LeagueResolver.resolveId(title) ??
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
          final name =
              extra?['name']?.toString() ??
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
