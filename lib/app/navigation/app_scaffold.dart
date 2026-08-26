import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/matches/presentation/bloc/matches_bloc.dart';
import '../../features/matches/presentation/bloc/matches_state.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, matchesState) {
        final liveCount = matchesState.liveMatchesCount;

        // Desktop Layout (> 1024px)
        if (width >= AppDimensions.tabletMaxWidth) {
          return Scaffold(
            body: Row(
              children: [
                _buildDesktopSidebar(context, isDark, isArabic, liveCount),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
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
                  onDestinationSelected: (index) => _onTap(context, index),
                  labelType: NavigationRailLabelType.all,
                  destinations: _buildRailDestinations(l10n, liveCount),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // Mobile Layout (< 768px)
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _onTap(context, index),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home_rounded),
                label: l10n.translate('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: liveCount > 0,
                  label: Text(liveCount.toString()),
                  backgroundColor: AppColors.liveRed,
                  child: const Icon(Icons.sports_soccer_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: liveCount > 0,
                  label: Text(liveCount.toString()),
                  backgroundColor: AppColors.liveRed,
                  child: const Icon(Icons.sports_soccer_rounded),
                ),
                label: l10n.translate('nav_matches'),
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
            ],
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<NavigationRailDestination> _buildRailDestinations(AppLocalizations l10n, int liveCount) {
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: Text(l10n.translate('nav_home')),
      ),
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: liveCount > 0,
          label: Text(liveCount.toString()),
          backgroundColor: AppColors.liveRed,
          child: const Icon(Icons.sports_soccer_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: liveCount > 0,
          label: Text(liveCount.toString()),
          backgroundColor: AppColors.liveRed,
          child: const Icon(Icons.sports_soccer_rounded),
        ),
        label: Text(l10n.translate('nav_matches')),
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
    ];
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    bool isDark,
    bool isArabic,
    int liveCount,
  ) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = navigationShell.currentIndex;

    final navItems = [
      (Icons.home_rounded, l10n.translate('nav_home'), 0, null),
      (Icons.sports_soccer_rounded, l10n.translate('nav_matches'), 1, liveCount > 0 ? liveCount.toString() : null),
      (Icons.table_chart_rounded, l10n.translate('nav_standings'), 2, null),
      (Icons.swap_horiz_rounded, l10n.translate('nav_transfers'), 3, null),
      (Icons.video_library_rounded, l10n.translate('nav_videos'), 4, null),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sports_soccer_rounded, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                '154Score',
                style: AppTypography.getHeadingLarge(isDark: isDark, isArabic: isArabic).copyWith(
                  fontWeight: FontWeight.w900,
                ),
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
                selectedTileColor: AppColors.primary.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                leading: Icon(
                  item.$1,
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
                title: Text(
                  item.$2,
                  style: AppTypography.getBodyMedium(isDark: isDark, isArabic: isArabic).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                trailing: item.$4 != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          item.$4!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      )
                    : null,
                onTap: () => _onTap(context, item.$3),
              ),
            );
          }),

          const Spacer(),

          // Bottom Shortcut
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.translate('nav_settings')),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}
