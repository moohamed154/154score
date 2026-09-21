import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class HorizontalDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool showNavigationButtons;

  const HorizontalDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.showNavigationButtons = false,
  });

  @override
  State<HorizontalDateSelector> createState() => _HorizontalDateSelectorState();
}

class _HorizontalDateSelectorState extends State<HorizontalDateSelector> {
  // 5-day focused range centered on Today: [-2, -1, 0, 1, 2]
  final int _rangeDays = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    // Generate the 5 days centered on Today
    final dates = List.generate(_rangeDays * 2 + 1, (i) {
      return todayMidnight.add(Duration(days: i - _rangeDays));
    });

    final isSelectedInStandardRange = dates.any(
      (d) =>
          d.year == widget.selectedDate.year &&
          d.month == widget.selectedDate.month &&
          d.day == widget.selectedDate.day,
    );

    return SizedBox(
      height: 68,
      child: Center(
        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                // 5 Centered Date Tabs (Today is in the exact center)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: dates.map((date) {
                      final isSelected =
                          date.year == widget.selectedDate.year &&
                          date.month == widget.selectedDate.month &&
                          date.day == widget.selectedDate.day;

                      final isCurrentDay =
                          date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day;

                      String dayLabel;
                      final diff = date.difference(todayMidnight).inDays;
                      if (diff == 0) {
                        dayLabel = l10n.translate('today');
                      } else if (diff == -1) {
                        dayLabel = l10n.translate('yesterday');
                      } else if (diff == 1) {
                        dayLabel = l10n.translate('tomorrow');
                      } else {
                        dayLabel = DateFormat(
                          'E',
                          isArabic ? 'ar' : 'en',
                        ).format(date);
                      }

                      final dateNumber = DateFormat(
                        'd MMM',
                        isArabic ? 'ar' : 'en',
                      ).format(date);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onDateSelected(date),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isCurrentDay
                                            ? (isDark
                                                  ? AppColors.darkCardElevated
                                                  : AppColors.lightCardElevated)
                                            : Colors.transparent),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : (isCurrentDay
                                              ? AppColors.primary.withValues(
                                                  alpha: 0.6,
                                                )
                                              : (isDark
                                                    ? AppColors.darkBorder
                                                          .withValues(
                                                            alpha: 0.4,
                                                          )
                                                    : AppColors.lightBorder
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ))),
                                    width: isCurrentDay ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          dayLabel,
                                          style:
                                              AppTypography.getBodySmall(
                                                isDark: isDark,
                                                isArabic: isArabic,
                                              ).copyWith(
                                                fontWeight:
                                                    isSelected || isCurrentDay
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.black
                                                    : (isCurrentDay
                                                          ? AppColors.primary
                                                          : (isDark
                                                                ? AppColors
                                                                      .darkTextSecondary
                                                                : AppColors
                                                                      .lightTextSecondary)),
                                                fontSize: 11,
                                              ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          dateNumber,
                                          style:
                                              AppTypography.getBodySmall(
                                                isDark: isDark,
                                                isArabic: isArabic,
                                              ).copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? Colors.black
                                                    : (isDark
                                                          ? AppColors
                                                                .darkTextPrimary
                                                          : AppColors
                                                                .lightTextPrimary),
                                                fontSize: 11,
                                              ),
                                          maxLines: 1,
                                        ),
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
                  ),
                ),

                if (widget.showNavigationButtons) ...[
                  const SizedBox(width: 4),

                  // Previous Day Arrow
                  _buildArrowButton(
                    context: context,
                    isDark: isDark,
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      final prev = widget.selectedDate.subtract(const Duration(days: 1));
                      widget.onDateSelected(prev);
                    },
                  ),

                  const SizedBox(width: 2),

                  // Calendar Picker Icon Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: widget.selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: isDark
                                  ? AppTheme.darkTheme
                                  : AppTheme.lightTheme,
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          widget.onDateSelected(picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: !isSelectedInStandardRange
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: !isSelectedInStandardRange
                                ? Colors.transparent
                                : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                          ),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: !isSelectedInStandardRange
                              ? Colors.black
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // Next Day Arrow
                  _buildArrowButton(
                    context: context,
                    isDark: isDark,
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      final next = widget.selectedDate.add(const Duration(days: 1));
                      widget.onDateSelected(next);
                    },
                  ),
                ],

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}

