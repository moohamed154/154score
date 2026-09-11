import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import '../bloc/matches_state.dart';

class MatchFilterBottomSheet extends StatefulWidget {
  const MatchFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<MatchesBloc>(),
          child: const MatchFilterBottomSheet(),
        );
      },
    );
  }

  @override
  State<MatchFilterBottomSheet> createState() => _MatchFilterBottomSheetState();
}

class _MatchFilterBottomSheetState extends State<MatchFilterBottomSheet> {
  late MatchFilterType _tempFilter;
  late MatchesSortOrder _tempSortOrder;

  @override
  void initState() {
    super.initState();
    final state = context.read<MatchesBloc>().state;
    _tempFilter = state.activeFilter;
    _tempSortOrder = state.sortOrder;
  }

  void _resetFilters() {
    setState(() {
      _tempFilter = MatchFilterType.all;
      _tempSortOrder = MatchesSortOrder.importance;
    });
  }

  void _applyFilters() {
    context.read<MatchesBloc>().add(
          ApplyMatchesFilterEvent(
            filter: _tempFilter,
            sortOrder: _tempSortOrder,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final mediaQuery = MediaQuery.of(context);

    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        final hasAnyFilters = _tempFilter != MatchFilterType.all ||
            _tempSortOrder != MatchesSortOrder.importance;

        return Container(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.translate('filter_title'),
                        style: AppTypography.getHeadingSmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (hasAnyFilters)
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          l10n.translate('filter_reset'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.liveRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // Scrollable Options Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Match Status
                      _buildSectionHeader(
                        context,
                        title: l10n.translate('filter_status_header'),
                        icon: Icons.sports_soccer_outlined,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 10),
                      _buildStatusChips(
                        context,
                        isDark,
                        isArabic,
                        state.liveMatchesCount,
                      ),

                      const SizedBox(height: 24),

                      // Section 2: Sort Order
                      _buildSectionHeader(
                        context,
                        title: l10n.translate('filter_sort_header'),
                        icon: Icons.sort_rounded,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 10),
                      _buildSortOrderOptions(context, isDark, isArabic),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: EdgeInsets.only(
                  left: AppDimensions.lg,
                  right: AppDimensions.lg,
                  top: 12,
                  bottom: mediaQuery.padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    child: Text(
                      l10n.translate('filter_apply'),
                      style: AppTypography.getButton(
                        isDark: false,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required bool isArabic,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.getBodyMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildStatusChips(
    BuildContext context,
    bool isDark,
    bool isArabic,
    int liveCount,
  ) {
    final l10n = AppLocalizations.of(context);
    final statuses = [
      (MatchFilterType.all, l10n.translate('filter_all'), Icons.grid_view_rounded),
      (MatchFilterType.live, l10n.translate('filter_live'), Icons.fiber_manual_record_rounded),
      (MatchFilterType.upcoming, l10n.translate('filter_upcoming'), Icons.schedule_rounded),
      (MatchFilterType.finished, l10n.translate('filter_finished'), Icons.check_circle_outline_rounded),
      (MatchFilterType.favorites, l10n.translate('filter_favorites'), Icons.star_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((item) {
        final isSelected = _tempFilter == item.$1;
        final isLive = item.$1 == MatchFilterType.live;

        return ChoiceChip(
          showCheckmark: false,
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _tempFilter = item.$1;
            });
          },
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          selectedColor: isLive ? AppColors.liveRed : AppColors.primary,
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.$3,
                size: isLive ? 12 : 16,
                color: isSelected
                    ? (isLive ? Colors.white : Colors.black)
                    : (isLive
                        ? AppColors.liveRed
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ),
              const SizedBox(width: 6),
              Text(
                item.$2,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isLive ? Colors.white : Colors.black)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                ),
              ),
              if (isLive && liveCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black26 : AppColors.liveRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$liveCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortOrderOptions(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    final options = [
      (
        MatchesSortOrder.importance,
        l10n.translate('filter_sort_importance'),
        Icons.auto_awesome_rounded,
      ),
      (
        MatchesSortOrder.time,
        l10n.translate('filter_sort_time'),
        Icons.access_time_filled_rounded,
      ),
      (
        MatchesSortOrder.league,
        l10n.translate('filter_sort_league'),
        Icons.emoji_events_rounded,
      ),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = _tempSortOrder == opt.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: isSelected
                  ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.12))
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _tempSortOrder = opt.$1;
                  });
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opt.$3,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
