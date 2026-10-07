import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// Custom Material 3 Date Picker Dialog with authentic Arabic Cairo typography
/// and a dedicated "اليوم" (Today) button in the center between Cancel and OK.
class AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool isDark;

  const AppDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.isDark,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required bool isDark,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AppDatePickerDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          isDark: isDark,
        );
      },
    );
  }

  @override
  State<AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<AppDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;
    final locale = isArabic ? 'ar' : 'en';
    final fontFn = isArabic ? GoogleFonts.cairo : GoogleFonts.inter;
    final baseTheme = Theme.of(context);

    final dialogTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.black,
      ),
      datePickerTheme: baseTheme.datePickerTheme.copyWith(
        headerHeadlineStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headerHelpStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dayStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        weekdayStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        yearStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final dateTitle = DateFormat('EEEE، d MMMM', locale).format(_selectedDate);


    return Theme(
      data: dialogTheme,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: widget.isDark
            ? AppColors.darkCard
            : AppColors.lightCard,
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header displaying selected date title in Cairo font
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'اختيار التاريخ' : 'Select Date',
                      style: fontFn(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateTitle,
                      style: fontFn(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 0.8,
                color: widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
              ),

              // Calendar picker grid with Cairo font applied to days, weekdays & months
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  currentDate: DateTime.now(),
                  onDateChanged: (newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),

              // Bottom action buttons: [إلغاء] [اليوم] [حسناً]
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: OverflowBar(
                  spacing: 8,
                  alignment: MainAxisAlignment.end,
                  children: [
                    // زر إلغاء
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        textStyle: fontFn(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      child: Text(
                        isArabic ? 'إلغاء' : 'Cancel',
                        style: fontFn(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // زر "اليوم" في المنتصف
                    TextButton(
                      onPressed: () {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        Navigator.of(context).pop(today);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: fontFn(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      child: Text(
                        isArabic ? 'اليوم' : 'Today',
                        style: fontFn(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    // زر حسناً لتأكيد التاريخ المختار
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selectedDate),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: fontFn(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      child: Text(
                        isArabic ? 'حسناً' : 'OK',
                        style: fontFn(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
