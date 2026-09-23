import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toApiDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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

  static String formatDisplayTime(
    String? timeStr, {
    required String timeFormat,
    required bool isArabic,
  }) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr == '-') {
      return '-';
    }

    final trimmed = timeStr.trim();

    // Regex matching "20:30", "8:30 pm", "08:30 م", "8:30", "08:30"
    final regExp = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([صم]|AM|PM|am|pm))?$');
    final match = regExp.firstMatch(trimmed);

    if (match == null) {
      return trimmed;
    }

    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minuteStr = match.group(2)!;
    final period = match.group(3)?.toLowerCase();

    // Adjust 12h inputs if present
    if (period != null) {
      if ((period == 'pm' || period == 'م') && hour < 12) {
        hour += 12;
      } else if ((period == 'am' || period == 'ص') && hour == 12) {
        hour = 0;
      }
    }

    if (timeFormat == '12h') {
      final isPm = hour >= 12;
      var h12 = hour % 12;
      if (h12 == 0) h12 = 12;
      final h12Str = h12.toString().padLeft(2, '0');
      final marker = isArabic ? (isPm ? 'م' : 'ص') : (isPm ? 'PM' : 'AM');
      return '$h12Str:$minuteStr $marker';
    } else {
      // 24h format
      final h24Str = hour.toString().padLeft(2, '0');
      return '$h24Str:$minuteStr';
    }
  }
}
