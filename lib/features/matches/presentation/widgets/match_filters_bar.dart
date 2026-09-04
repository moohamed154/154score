import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/matches_event.dart';

class MatchFiltersBar extends StatelessWidget {
  final MatchFilterType activeFilter;
  final int liveCount;
  final Function(MatchFilterType) onFilterSelected;

  const MatchFiltersBar({
    super.key,
    required this.activeFilter,
    required this.liveCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final filters = [
      (MatchFilterType.all, l10n.translate('filter_all'), null),
      (
        MatchFilterType.live,
        l10n.translate('filter_live'),
        liveCount > 0 ? liveCount.toString() : null,
      ),
      (MatchFilterType.upcoming, l10n.translate('filter_upcoming'), null),
      (MatchFilterType.finished, l10n.translate('filter_finished'), null),
      (MatchFilterType.favorites, l10n.translate('filter_favorites'), null),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = activeFilter == item.$1;
          final isLiveFilter = item.$1 == MatchFilterType.live;

          return ChoiceChip(
            showCheckmark: false,
            selected: isSelected,
            onSelected: (_) => onFilterSelected(item.$1),
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            selectedColor: isLiveFilter ? AppColors.liveRed : AppColors.primary,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLiveFilter && liveCount > 0) ...[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : AppColors.liveRed,
                    ),
                  ),
                ],
                Text(
                  item.$2,
                  style:
                      AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.black
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                      ),
                ),
                if (item.$3 != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black26 : AppColors.liveRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.$3!,
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
        },
      ),
    );
  }
}
