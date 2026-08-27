import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class HorizontalDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const HorizontalDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<HorizontalDateSelector> createState() => _HorizontalDateSelectorState();
}

class _HorizontalDateSelectorState extends State<HorizontalDateSelector> {
  late ScrollController _scrollController;
  final int _rangeDays = 14; // -7 to +7 days

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dates = List.generate(_rangeDays * 2 + 1, (i) {
      return today.add(Duration(days: i - _rangeDays));
    });

    return Container(
      height: 62,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Row(
        children: [
          // Date List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected =
                    date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;

                final isCurrentDay =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                String dayLabel;
                final diff = date.difference(today).inDays;
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

                return InkWell(
                  onTap: () => widget.onDateSelected(date),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : Colors.transparent),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayLabel,
                          style:
                              AppTypography.getBodySmall(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.black
                                    : (isCurrentDay
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors
                                                      .lightTextSecondary)),
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
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
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Arbitrary Calendar Date Picker Button
          Container(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: IconButton(
              icon: Icon(
                Icons.calendar_month_rounded,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                size: 22,
              ),
              tooltip: l10n.translate('select_date'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: widget.selectedDate,
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
                  widget.onDateSelected(picked);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
