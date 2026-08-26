import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toApiDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDayHeader(DateTime date, {required bool isArabic}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    if (diff == 0) {
      return isArabic ? 'اليوم' : 'Today';
    } else if (diff == -1) {
      return isArabic ? 'أمس' : 'Yesterday';
    } else if (diff == 1) {
      return isArabic ? 'غداً' : 'Tomorrow';
    }

    final locale = isArabic ? 'ar' : 'en';
    return DateFormat('EEE, d MMM', locale).format(date);
  }

  static String formatDisplayTime(String? timeStr, {required String timeFormat, required bool isArabic}) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr == '-') {
      return '-';
    }

    // Clean Arabic/English PM/AM indicators
    final trimmed = timeStr.trim();
    return trimmed;
  }
}
