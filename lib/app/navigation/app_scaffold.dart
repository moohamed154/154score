import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/di/injection_container.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/widgets/app_brand_logo.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/matches/presentation/bloc/matches_bloc.dart';
import '../../features/matches/presentation/bloc/matches_event.dart';
import '../../features/matches/presentation/bloc/matches_state.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../../features/settings/presentation/cubit/settings_cubits.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/standings/presentation/bloc/standings_bloc.dart';
import '../../features/transfers/presentation/bloc/transfers_bloc.dart';
import '../../features/videos/presentation/bloc/videos_bloc.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final width = MediaQuery.of(context).size.width;

    return MultiBlocListener(
      listeners: [
        BlocListener<NewsLanguageCubit, String>(
          listener: (context, newsLang) {
            final appLang =
                context.read<LocaleCubit>().state.locale.languageCode;
            final targetLang = newsLang == 'app' ? appLang : newsLang;
            context.read<NewsBloc>().add(ChangeNewsLanguageEvent(targetLang));
          },
        ),
      ],
      child: BlocConsumer<LocaleCubit, LocaleState>(
        listenWhen: (prev, curr) => prev.locale != curr.locale,
        listener: (context, localeState) {
          final lang = localeState.locale.languageCode;
          final token = localeState.requestToken;

          final matchesCompleter = Completer<void>();
          final standingsCompleter = Completer<void>();
          final transfersCompleter = Completer<void>();
          final videosCompleter = Completer<void>();
          final homeCompleter = Completer<void>();
          final newsCompleter = Completer<void>();
          final notificationsCompleter = Completer<void>();

          context.read<MatchesBloc>().add(
                ChangeMatchesLanguageEvent(lang, completer: matchesCompleter),
              );
          context.read<StandingsBloc>().add(
                ChangeStandingsLanguageEvent(lang,
                    completer: standingsCompleter),
              );
          context.read<TransfersBloc>().add(
                ChangeTransfersLanguageEvent(lang,
                    completer: transfersCompleter),
              );
          context.read<VideosBloc>().add(
                ChangeVideosLanguageEvent(lang, completer: videosCompleter),
              );
          final newsLangSetting = sl<LocalStorageService>().getNewsLanguage();
          if (newsLangSetting == 'app') {
            context.read<NewsBloc>().add(
                  ChangeNewsLanguageEvent(lang, completer: newsCompleter),
                );
          } else {
            newsCompleter.complete();
          }
          context.read<NotificationsBloc>().add(
                LoadNotificationsEvent(
                    lang: lang,
                    isRefresh: true,
                    completer: notificationsCompleter),
              );
          context.read<HomeCubit>().changeLanguage(
                lang,
                completer: homeCompleter,
              );

          // When all background refreshes finish (or timeout), notify LocaleCubit to hide indicator
          Future.wait([
            matchesCompleter.future,
            standingsCompleter.future,
            transfersCompleter.future,
            videosCompleter.future,
            homeCompleter.future,
            newsCompleter.future,
            notificationsCompleter.future,
          ]).timeout(const Duration(seconds: 5), onTimeout: () => []).then((_) {
            if (context.mounted) {
              context.read<LocaleCubit>().notifyRefreshCompleted(token: token);
            }
          });
        },
        builder: (context, localeState) {
          Widget contentWithIndicator() {
            return Stack(
              children: [
                navigationShell,
                if (localeState.showIndicator)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            );
          }

          return BlocBuilder<MatchesBloc, MatchesState>(
            builder: (context, matchesState) {
              final liveCount = matchesState.liveMatchesCount;

              // Desktop Layout (> 1024px)
              if (width >= AppDimensions.tabletMaxWidth) {
                return Scaffold(
                  body: Row(
                    children: [
                      _buildDesktopSidebar(context, isDark, isArabic),
                      const VerticalDivider(width: 1),
                      Expanded(child: contentWithIndicator()),
                    ],
                  ),
                );
              }

              // Tablet Layout (768px - 1024px)
              if (width >= AppDimensions.mobileMaxWidth) {
                return Scaffold(
                  body: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: (index) =>
                            _onTap(context, index),
                        labelType: NavigationRailLabelType.all,
                        destinations: _buildRailDestinations(l10n, liveCount),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: contentWithIndicator()),
                    ],
                  ),
                );
              }

              // Shell branches are 0: Home, 1: News, 2: Standings, 3: Transfers, 4: Videos, 5: Settings
              final navIndex = navigationShell.currentIndex.clamp(0, 5);

              return Scaffold(
                body: contentWithIndicator(),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: navIndex,
                  onTap: (index) => _onTap(context, index),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home_rounded),
                      label: l10n.translate('nav_home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.newspaper_outlined),
                      activeIcon: const Icon(Icons.newspaper_rounded),
                      label: l10n.translate('nav_news'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.table_chart_outlined),
                      activeIcon: const Icon(Icons.table_chart_rounded),
                      label: l10n.translate('nav_standings'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.swap_horiz_outlined),
                      activeIcon: const Icon(Icons.swap_horiz_rounded),
                      label: l10n.translate('nav_transfers'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.video_library_outlined),
                      activeIcon: const Icon(Icons.video_library_rounded),
                      label: l10n.translate('nav_videos'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.more_horiz_outlined),
                      activeIcon: const Icon(Icons.more_horiz_rounded),
                      label: l10n.translate('nav_settings'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<NavigationRailDestination> _buildRailDestinations(
    AppLocalizations l10n,
    int liveCount,
  ) {
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: Text(l10n.translate('nav_home')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.newspaper_outlined),
        selectedIcon: const Icon(Icons.newspaper_rounded),
        label: Text(l10n.translate('nav_news')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.table_chart_outlined),
        selectedIcon: const Icon(Icons.table_chart_rounded),
        label: Text(l10n.translate('nav_standings')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.swap_horiz_outlined),
        selectedIcon: const Icon(Icons.swap_horiz_rounded),
        label: Text(l10n.translate('nav_transfers')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.video_library_outlined),
        selectedIcon: const Icon(Icons.video_library_rounded),
        label: Text(l10n.translate('nav_videos')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.more_horiz_outlined),
        selectedIcon: const Icon(Icons.more_horiz_rounded),
        label: Text(l10n.translate('nav_settings')),
      ),
    ];
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = navigationShell.currentIndex;

    final navItems = [
      (Icons.home_rounded, l10n.translate('nav_home'), 0),
      (Icons.newspaper_rounded, l10n.translate('nav_news'), 1),
      (Icons.table_chart_rounded, l10n.translate('nav_standings'), 2),
      (Icons.swap_horiz_rounded, l10n.translate('nav_transfers'), 3),
      (Icons.video_library_rounded, l10n.translate('nav_videos'), 4),
      (Icons.more_horiz_rounded, l10n.translate('nav_settings'), 5),
    ];

    return Container(
      width: 240,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding
          Row(
            children: [
              AppBrandLogo(size: 44, isDark: isDark),
              const SizedBox(width: 12),
              Text(
                '154Score',
                style: AppTypography.getHeadingLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Navigation Links
          ...navItems.map((item) {
            final isSelected = selectedIndex == item.$3;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: isSelected,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                leading: Icon(
                  item.$1,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                ),
                title: Text(
                  item.$2,
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                onTap: () => _onTap(context, item.$3),
              ),
            );
          }),

          const Spacer(),

          // Bottom Shortcuts
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            leading: const Icon(Icons.favorite_border_rounded),
            title: Text(l10n.translate('nav_favorites')),
            onTap: () => context.push('/favorites'),
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            leading: const Icon(Icons.search_rounded),
            title: Text(l10n.translate('nav_search')),
            onTap: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}
