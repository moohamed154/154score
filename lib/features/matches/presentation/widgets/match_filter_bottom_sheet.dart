import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
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
  String? _tempLeagueId;
  String? _tempLeagueTitle;
  String _leagueSearchQuery = '';
  final TextEditingController _leagueSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<MatchesBloc>().state;
    _tempFilter = state.activeFilter;
    _tempSortOrder = state.sortOrder;
    _tempLeagueId = state.selectedLeagueId;
    _tempLeagueTitle = state.selectedLeagueTitle;
  }

  @override
  void dispose() {
    _leagueSearchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _tempFilter = MatchFilterType.all;
      _tempSortOrder = MatchesSortOrder.importance;
      _tempLeagueId = null;
      _tempLeagueTitle = null;
      _leagueSearchQuery = '';
      _leagueSearchController.clear();
    });
  }

  void _applyFilters() {
    context.read<MatchesBloc>().add(
          ApplyMatchesFilterEvent(
            filter: _tempFilter,
            leagueId: _tempLeagueId,
            leagueTitle: _tempLeagueTitle,
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
        final availableLeagues = state.availableLeagues;
        final filteredLeaguesList = _leagueSearchQuery.isEmpty
            ? availableLeagues
            : availableLeagues.where((l) {
                return l.title.toLowerCase().contains(_leagueSearchQuery.toLowerCase());
              }).toList();

        final hasAnyFilters = _tempFilter != MatchFilterType.all ||
            _tempLeagueId != null ||
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: 16,
                  ),
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
                    _buildStatusChips(context, isDark, isArabic, state.liveMatchesCount),

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

                    const SizedBox(height: 24),

                    // Section 3: League / Championship Filter
                    _buildSectionHeader(
                      context,
                      title: l10n.translate('filter_league_header'),
                      icon: Icons.emoji_events_outlined,
                      isDark: isDark,
                      isArabic: isArabic,
                      trailing: availableLeagues.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${availableLeagues.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // League Search Box (if more than 3 leagues)
                    if (availableLeagues.length > 3) ...[
                      TextField(
                        controller: _leagueSearchController,
                        onChanged: (val) {
                          setState(() {
                            _leagueSearchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: l10n.translate('search_championship'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _leagueSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _leagueSearchQuery = '';
                                      _leagueSearchController.clear();
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // All Championships Tile
                    _buildLeagueOptionTile(
                      context,
                      isDark: isDark,
                      isArabic: isArabic,
                      isSelected: _tempLeagueId == null && _tempLeagueTitle == null,
                      title: l10n.translate('filter_all_leagues'),
                      matchCount: state.allLeagues.fold<int>(
                        0,
                        (sum, l) => sum + l.matches.length,
                      ),
                      logo: null,
                      onTap: () {
                        setState(() {
                          _tempLeagueId = null;
                          _tempLeagueTitle = null;
                        });
                      },
                    ),

                    const SizedBox(height: 6),

                    // League Options List
                    ...filteredLeaguesList.map((league) {
                      final isSelected = (_tempLeagueId != null &&
                              _tempLeagueId == league.id) ||
                          (_tempLeagueTitle != null &&
                              _tempLeagueTitle == league.title);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildLeagueOptionTile(
                          context,
                          isDark: isDark,
                          isArabic: isArabic,
                          isSelected: isSelected,
                          title: league.title,
                          matchCount: league.matchCount,
                          logo: league.logo,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _tempLeagueId = null;
                                _tempLeagueTitle = null;
                              } else {
                                _tempLeagueId = league.id;
                                _tempLeagueTitle = league.title;
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ],
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
            child: InkWell(
              onTap: () {
                setState(() {
                  _tempSortOrder = opt.$1;
                });
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.primary.withValues(alpha: 0.12))
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
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
        );
      }).toList(),
    );
  }

  Widget _buildLeagueOptionTile(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required bool isSelected,
    required String title,
    required int matchCount,
    required String? logo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1))
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              if (logo != null && logo.isNotEmpty)
                AppImage(
                  imageUrl: logo,
                  width: 26,
                  height: 26,
                  placeholderIcon: Icons.emoji_events_outlined,
                )
              else
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.public_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$matchCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white30 : Colors.black26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
