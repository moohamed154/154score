import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';

/// Compact date navigation button group: [<] [📅] [>]
/// Designed to sit cleanly in the top AppBar or toolbar.
class DateNavigationButtons extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isDark;

  const DateNavigationButtons({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    // 5-day standard range centered on Today: [-2, -1, 0, 1, 2]
    final dates = List.generate(5, (i) {
      return todayMidnight.add(Duration(days: i - 2));
    });

    final isSelectedInStandardRange = dates.any(
      (d) =>
          d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous Day Arrow (<)
        _buildArrowButton(
          context: context,
          icon: Icons.chevron_left_rounded,
          tooltip: 'اليوم السابق',
          onTap: () {
            final prev = selectedDate.subtract(const Duration(days: 1));
            onDateSelected(prev);
          },
        ),

        const SizedBox(width: 3),

        // Calendar Picker Icon Button (📅)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onDateSelected(picked);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !isSelectedInStandardRange
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: !isSelectedInStandardRange
                      ? Colors.transparent
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: !isSelectedInStandardRange
                    ? Colors.black
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                size: 18,
              ),
            ),
          ),
        ),

        const SizedBox(width: 3),

        // Next Day Arrow (>)
        _buildArrowButton(
          context: context,
          icon: Icons.chevron_right_rounded,
          tooltip: 'اليوم التالي',
          onTap: () {
            final next = selectedDate.add(const Duration(days: 1));
            onDateSelected(next);
          },
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
