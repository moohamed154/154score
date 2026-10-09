import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import 'app_date_picker_dialog.dart';

/// Compact date navigation button group: [<] [📅] [>]
/// Borderless and transparent to blend smoothly with toolbar actions.
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

    // 5-day standard range centered on Today: [-2, -1, 0, 1, 2]
    final dates = List.generate(5, (i) {
      return DateTime(today.year, today.month, today.day + (i - 2));
    });

    final isSelectedInStandardRange = dates.any(
      (d) =>
          d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day,
    );

    final iconColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous Day Arrow (<)
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 24,
            color: iconColor,
          ),
          tooltip: 'اليوم السابق',
          onPressed: () {
            final prev = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day - 1,
            );
            onDateSelected(prev);
          },
        ),

        // Calendar Picker Icon Button (📅)
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            Icons.calendar_month_rounded,
            size: 20,
            color: !isSelectedInStandardRange ? AppColors.primary : iconColor,
          ),
          tooltip: 'اختيار التاريخ',
          onPressed: () async {
            final picked = await AppDatePickerDialog.show(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              isDark: isDark,
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
        ),

        // Next Day Arrow (>)
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: iconColor,
          ),
          tooltip: 'اليوم التالي',
          onPressed: () {
            final next = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day + 1,
            );
            onDateSelected(next);
          },
        ),
      ],
    );
  }
}
