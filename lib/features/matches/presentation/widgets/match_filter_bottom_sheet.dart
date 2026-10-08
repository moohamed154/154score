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
    final bloc = context.read<MatchesBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: bloc,
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
  late bool _tempHideFavorites;

  @override
  void initState() {
    super.initState();
    final state = context.read<MatchesBloc>().state;
    _tempFilter = state.activeFilter;
    _tempSortOrder = (state.sortOrder == MatchesSortOrder.importance)
        ? MatchesSortOrder.championship
        : state.sortOrder;
    _tempHideFavorites = state.hideFavorites;
  }

  void _resetFilters() {
    setState(() {
      _tempFilter = MatchFilterType.all;
      _tempSortOrder = MatchesSortOrder.championship;
      _tempHideFavorites = false;
    });
  }

  void _applyFilters() {
    context.read<MatchesBloc>().add(
      ApplyMatchesFilterEvent(
        filter: _tempFilter,
        sortOrder: _tempSortOrder,
        hideFavorites: _tempHideFavorites,
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
        final isDefault =
            _tempFilter == MatchFilterType.all &&
            (_tempSortOrder == MatchesSortOrder.championship ||
                _tempSortOrder == MatchesSortOrder.importance) &&
            !_tempHideFavorites;

        return Container(
          height: mediaQuery.size.height * 0.85,
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
                    if (!isDefault)
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
              Expanded(
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
                      // Top Row: Hide Favourites Switch (exact Yalla Shoot style)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _tempHideFavorites
                                  ? Icons.visibility_off_outlined
                                  : Icons.star_outline_rounded,
                              size: 20,
                              color: _tempHideFavorites
                                  ? AppColors.liveRed
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.translate('filter_hide_favorites'),
                                style: AppTypography.getBodyMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Switch.adaptive(
                              value: _tempHideFavorites,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withValues(
                                alpha: 0.5,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _tempHideFavorites = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section: Sort Order Mode Cards (Championship, Time, Important ONLY)
                      _buildModeCard(
                        context: context,
                        isDark: isDark,
                        isArabic: isArabic,
                        title: l10n.translate('filter_sort_championship'),
                        subtitle: l10n.translate('filter_championship_subtitle'),
                        icon: Icons.emoji_events_outlined,
                        isSelected:
                            _tempSortOrder == MatchesSortOrder.championship ||
                            _tempSortOrder == MatchesSortOrder.importance,
                        onTap: () {
                          setState(() {
                            _tempSortOrder = MatchesSortOrder.championship;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildModeCard(
                        context: context,
                        isDark: isDark,
                        isArabic: isArabic,
                        title: l10n.translate('filter_sort_time'),
                        subtitle: l10n.translate('filter_time_subtitle'),
                        icon: Icons.access_time_rounded,
                        isSelected: _tempSortOrder == MatchesSortOrder.time,
                        onTap: () {
                          setState(() {
                            _tempSortOrder = MatchesSortOrder.time;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildModeCard(
                        context: context,
                        isDark: isDark,
                        isArabic: isArabic,
                        title: l10n.translate('filter_important_only'),
                        subtitle: l10n.translate('filter_important_only_subtitle'),
                        icon: Icons.local_fire_department_outlined,
                        isSelected:
                            _tempSortOrder == MatchesSortOrder.importantOnly,
                        onTap: () {
                          setState(() {
                            _tempSortOrder = MatchesSortOrder.importantOnly;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Section: Match Status Chips
                      _buildSectionHeader(
                        context,
                        title: l10n.translate('filter_status_header'),
                        icon: Icons.sports_soccer_outlined,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusChips(
                        context,
                        isDark,
                        isArabic,
                        state.liveMatchesCount,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar (Apply button)
              Container(
                padding: EdgeInsets.only(
                  left: AppDimensions.lg,
                  right: AppDimensions.lg,
                  top: 12,
                  bottom: mediaQuery.padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.translate('filter_apply'),
                      style: AppTypography.getButton(
                        isDark: false,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
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

  Widget _buildModeCard({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? (isDark
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.primary.withValues(alpha: 0.08))
          : (isDark ? AppColors.darkCard : AppColors.lightCard),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.8 : 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white30 : Colors.black26),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.getBodyMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
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
      (
        MatchFilterType.all,
        l10n.translate('filter_all'),
        Icons.grid_view_rounded,
      ),
      (
        MatchFilterType.live,
        l10n.translate('filter_live'),
        Icons.fiber_manual_record_rounded,
      ),
      (
        MatchFilterType.upcoming,
        l10n.translate('filter_upcoming'),
        Icons.schedule_rounded,
      ),
      (
        MatchFilterType.finished,
        l10n.translate('filter_finished'),
        Icons.check_circle_outline_rounded,
      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
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
}
