import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/widgets/error_view.dart';
import 'package:ysscores/core/widgets/skeleton_loader.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_event.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_state.dart';
import 'lineup_empty_state_widget.dart';
import 'lineup_squad_list_widget.dart';
import 'match_pitch_widget.dart';

enum _LineupViewMode { pitch, list }

/// Primary Lineup Tab orchestrator. Handles loading, error, empty, pitch, and squad list states.
class LineupTabView extends StatefulWidget {
  final String matchId;

  const LineupTabView({
    super.key,
    required this.matchId,
  });

  @override
  State<LineupTabView> createState() => _LineupTabViewState();
}

class _LineupTabViewState extends State<LineupTabView> {
  _LineupViewMode _viewMode = _LineupViewMode.pitch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.lineup != current.lineup,
      builder: (context, state) {
        // 1. Loading State
        if (state.status == MatchDetailsStatus.loading && state.lineup == null) {
          return _buildSkeletonLoader(context, isDark);
        }

        // 2. Error State
        if (state.status == MatchDetailsStatus.error && state.lineup == null) {
          return ErrorView(
            message: state.errorMessage,
            onRetry: () {
              context.read<MatchDetailsBloc>().add(
                    LoadMatchDetailsEvent(widget.matchId, isRefresh: true),
                  );
            },
          );
        }

        final lineup = state.lineup;

        // 3. Empty State (Lineups not released yet or empty data)
        if (lineup == null || !lineup.hasLineups) {
          return LineupEmptyStateWidget(matchId: widget.matchId);
        }

        final home = lineup.home!;
        final away = lineup.away!;

        // 4. Content State (Interactive Pitch or Squad List)
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context.read<MatchDetailsBloc>().add(
                  LoadMatchDetailsEvent(widget.matchId, isRefresh: true),
                );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Control Header Bar: Status Badge + View Mode Switcher
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hMargin,
                    vertical: AppDimensions.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge (Confirmed vs Probable)
                      _buildStatusPill(lineup.isConfirmed, isArabic),

                      // View Mode Switcher: Pitch vs List
                      _buildViewSwitcher(isDark, isArabic),
                    ],
                  ),
                ),

                // Active View Body
                if (_viewMode == _LineupViewMode.pitch) ...[
                  // 1. Tactical Pitch Board
                  MatchPitchWidget(home: home, away: away),

                  const SizedBox(height: 16),

                  // 2. Bench & Squad Details below pitch
                  LineupSquadListWidget(home: home, away: away),
                ] else ...[
                  // Dedicated List View (Starters, Bench, Coaches, Injuries)
                  LineupSquadListWidget(home: home, away: away),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(bool isConfirmed, bool isArabic) {
    final color = isConfirmed
        ? const Color(0xFF10B981) // Emerald
        : const Color(0xFFF59E0B); // Amber

    final label = isConfirmed
        ? (isArabic ? 'تشكيلة مؤكدة' : 'Confirmed Lineup')
        : (isArabic ? 'تشكيلة متوقعة' : 'Probable Lineup');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitcherOption(
            title: isArabic ? 'الملعب' : 'Pitch',
            icon: Icons.sports_soccer_rounded,
            isSelected: _viewMode == _LineupViewMode.pitch,
            isDark: isDark,
            onTap: () => setState(() => _viewMode = _LineupViewMode.pitch),
          ),
          _buildSwitcherOption(
            title: isArabic ? 'القائمة' : 'List',
            icon: Icons.format_list_bulleted_rounded,
            isSelected: _viewMode == _LineupViewMode.list,
            isDark: isDark,
            onTap: () => setState(() => _viewMode = _LineupViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.black
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.black
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context, bool isDark) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 16),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 110, height: 26, borderRadius: 14),
              SkeletonLoader(width: 120, height: 26, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 16),
          // Pitch Skeleton
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const AspectRatio(
                aspectRatio: 1 / 1.90,
                child: SkeletonLoader(
                  width: 560,
                  height: 800,
                  borderRadius: AppDimensions.radiusLg,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List Skeletons
          ...List.generate(
            4,
            (i) => const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: SkeletonLoader(
                width: 400,
                height: 48,
                borderRadius: AppDimensions.radiusMd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
