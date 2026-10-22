import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toApiDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

    // Regex matching "20:30", "20:30:00", "8:30 pm", "08:30 م", "8:30", "08:30"
    final regExp = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?(?:\s*([صم]|AM|PM|am|pm))?$',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);

    if (match == null) {
      // Fallback for full DateTime strings like "2026-09-27 21:45:00"
      final parsedDate = DateTime.tryParse(trimmed);
      if (parsedDate != null) {
        final hour = parsedDate.hour;
        final minuteStr = parsedDate.minute.toString().padLeft(2, '0');
        return _formatHourMinute(
          hour,
          minuteStr,
          timeFormat: timeFormat,
          isArabic: isArabic,
        );
      }
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

    return _formatHourMinute(
      hour,
      minuteStr,
      timeFormat: timeFormat,
      isArabic: isArabic,
    );
  }

  /// Formats a raw date/time string (e.g. "2026-10-21 23:10:08.000000",
  /// "2026-10-21 23:10:08", or "2026-10-21") into a clean, human-readable format.
  /// Example outputs:
  /// - 12h: "2026-10-21 • 11:10 PM" (EN) / "2026-10-21 • 11:10 م" (AR)
  /// - 24h: "2026-10-21 • 23:10"
  static String formatDateTime(
    dynamic rawDate, {
    required bool isArabic,
    String? timeFormat,
  }) {
    if (rawDate == null) return '';
    DateTime? dt;
    String rawStr = '';
    if (rawDate is DateTime) {
      dt = rawDate;
      rawStr = dt.toIso8601String();
    } else {
      rawStr = rawDate.toString().trim();
      if (rawStr.isEmpty) return '';
      final cleaned = rawStr.replaceAll('.000000', '');
      dt = DateTime.tryParse(cleaned);
      if (dt == null) return rawStr;
    }

    final yyyy = dt.year.toString();
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final datePart = '$yyyy-$mm-$dd';

    if (!rawStr.contains(':')) {
      return datePart;
    }

    final activeTimeFormat = timeFormat ?? '24h';
    final timePart = _formatHourMinute(
      dt.hour,
      dt.minute.toString().padLeft(2, '0'),
      timeFormat: activeTimeFormat,
      isArabic: isArabic,
    );

    return '$datePart • $timePart';
  }

  static String _formatHourMinute(
    int hour,
    String minuteStr, {
    required String timeFormat,
    required bool isArabic,
  }) {
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
