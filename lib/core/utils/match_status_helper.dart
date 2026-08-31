enum MatchPhase {
  upcoming,
  live,
  halfTime,
  extraTime,
  penalties,
  finished,
  postponed,
  cancelled,
  unknown,
}

class MatchStatusHelper {
  MatchStatusHelper._();

  static MatchPhase parseStatus(
    String? status, {
    String? minute,
    String? extraTime,
    String? time,
  }) {
    if (status == null || status.trim().isEmpty) {
      if (extraTime != null && extraTime.isNotEmpty && extraTime != 'null') {
        return MatchPhase.live;
      }
      return (time != null && time.isNotEmpty)
          ? MatchPhase.upcoming
          : MatchPhase.unknown;
    }

    final s = status.trim().toLowerCase();

    // 1. Penalties
    if (s.contains('ترجيح') ||
        s.contains('penalties') ||
        s.contains('pen') ||
        s.contains('ركلات')) {
      if (s.contains('بعد') || s.contains('انتهت') || s.contains('ft')) {
        return MatchPhase.finished;
      }
      return MatchPhase.penalties;
    }

    // 2. Extra Time
    if (s.contains('إضافي') ||
        s.contains('اضافي') ||
        s.contains('extra') ||
        s.contains('et')) {
      if (s.contains('بعد') || s.contains('انتهت') || s.contains('ft')) {
        return MatchPhase.finished;
      }
      return MatchPhase.extraTime;
    }

    // 3. Half-Time
    if (s == 'ht' ||
        s == 'استراحة' ||
        s.contains('استراحة') ||
        s.contains('بين الشوطين') ||
        s.contains('نهاية الشوط الأول') ||
        s == 'half time' ||
        s == 'halftime' ||
        s.contains('half time') ||
        s.contains('halftime')) {
      return MatchPhase.halfTime;
    }

    // 4. Finished
    if (s.contains('انتهت') ||
        s.contains('نهاية') ||
        s == 'ft' ||
        s == 'fin' ||
        s.contains('ended') ||
        s.contains('finished') ||
        s.contains('full time') ||
        s.contains('fulltime')) {
      return MatchPhase.finished;
    }

    // 5. Postponed & Cancelled
    if (s.contains('تأجل') ||
        s.contains('مؤجلة') ||
        s.contains('postponed') ||
        s.contains('delayed')) {
      return MatchPhase.postponed;
    }

    if (s.contains('ألغيت') ||
        s.contains('ملغاة') ||
        s.contains('cancelled') ||
        s.contains('canceled') ||
        s.contains('abandoned')) {
      return MatchPhase.cancelled;
    }

    // 6. Live / In-play
    if (s.contains('مباشر') ||
        s.contains('live') ||
        s.contains('جارية') ||
        s.contains('playing') ||
        s.contains('شوط') ||
        s.contains('1st_half') ||
        s.contains('2nd_half') ||
        s.contains('first half') ||
        s.contains('second half') ||
        s.contains('1st half') ||
        s.contains('2nd half') ||
        s.contains("'") ||
        (minute != null && minute.isNotEmpty && minute != 'null') ||
        (extraTime != null && extraTime.isNotEmpty && extraTime != 'null')) {
      return MatchPhase.live;
    }

    // 7. Upcoming
    if (s.contains('لم تبدأ') ||
        s.contains('قادمة') ||
        s.contains('upcoming') ||
        s.contains('not started') ||
        s == 'ns' ||
        (time != null && time.isNotEmpty && !s.contains('انتهت'))) {
      return MatchPhase.upcoming;
    }

    return MatchPhase.unknown;
  }

  static bool isLive(MatchPhase phase) {
    return phase == MatchPhase.live ||
        phase == MatchPhase.halfTime ||
        phase == MatchPhase.extraTime ||
        phase == MatchPhase.penalties;
  }

  static bool isFinished(MatchPhase phase) {
    return phase == MatchPhase.finished;
  }

  static bool isUpcoming(MatchPhase phase) {
    return phase == MatchPhase.upcoming || phase == MatchPhase.postponed;
  }

  /// Priority for match ordering:
  /// Group 1 (Live) -> 0
  /// Group 2 (Upcoming) -> 1
  /// Group 3 (Finished) -> 2
  /// Group 4 (Postponed/Cancelled/Unknown) -> 3
  static int getPriority(MatchPhase phase) {
    switch (phase) {
      case MatchPhase.live:
      case MatchPhase.halfTime:
      case MatchPhase.extraTime:
      case MatchPhase.penalties:
        return 0;
      case MatchPhase.upcoming:
        return 1;
      case MatchPhase.finished:
        return 2;
      case MatchPhase.postponed:
      case MatchPhase.cancelled:
      case MatchPhase.unknown:
        return 3;
    }
  }

  static String? formatExtraTime(String? extraTime, {int? minute}) {
    if (extraTime == null || extraTime.isEmpty || extraTime == 'null') {
      return null;
    }
    final clean = extraTime.trim();
    if (clean == '+00:00' ||
        clean == '00:00' ||
        clean == '+0' ||
        clean == '+00' ||
        clean == '0' ||
        clean == '+00:00 / 0' ||
        clean == '+00:00 / 00') {
      return null;
    }

    // Extra time should ONLY be shown at 45 (1st half) or 90+ (2nd half/extra time)
    if (minute != null && minute > 0) {
      if (minute < 45 || (minute > 45 && minute < 90)) {
        return null;
      }
    }

    // Handle "+00:00 / 10" or "01:23 / 5" -> "+10'"
    if (clean.contains('/')) {
      final parts = clean.split('/');
      final total = parts.last.trim();
      if (total.isNotEmpty && total != '0' && total != '00' && total != '00:00') {
        final totalNum = int.tryParse(total);
        return totalNum != null ? '+$totalNum\'' : '+$total';
      }
      return null;
    }

    if (clean.startsWith('+')) {
      final withoutPlus = clean.substring(1).trim();
      if (withoutPlus == '00:00' || withoutPlus == '0' || withoutPlus == '00') {
        return null;
      }
      return clean;
    }

    return '+$clean';
  }

  static String getDisplayLabel(
    MatchPhase phase,
    String? rawStatus, {
    String? minute,
    String? extraTime,
    String? time,
    required bool isArabic,
  }) {
    int? minNum;
    if (minute != null && minute.isNotEmpty && minute != 'null') {
      minNum = int.tryParse(minute.replaceAll("'", '').trim().split('+').first);
    }
    final formattedExtra = formatExtraTime(extraTime, minute: minNum);

    switch (phase) {
      case MatchPhase.live:
        if (minute != null && minute.isNotEmpty && minute != 'null') {
          final cleanMin = minute.replaceAll("'", '').trim();
          if (formattedExtra != null) {
            return "$cleanMin' $formattedExtra";
          }
          return "$cleanMin'";
        }
        if (formattedExtra != null) {
          return formattedExtra;
        }
        return isArabic ? 'مباشر' : 'LIVE';

      case MatchPhase.halfTime:
        return isArabic ? 'استراحة' : 'HT';

      case MatchPhase.extraTime:
        if (minute != null && minute.isNotEmpty && minute != 'null') {
          final cleanMin = minute.replaceAll("'", '').trim();
          if (formattedExtra != null) {
            return "$cleanMin' $formattedExtra";
          }
          return "$cleanMin'";
        }
        if (formattedExtra != null) {
          return formattedExtra;
        }
        return isArabic ? 'وقت إضافي' : 'ET';

      case MatchPhase.penalties:
        return isArabic ? 'ركلات الترجيح' : 'Penalties';

      case MatchPhase.finished:
        return isArabic ? 'انتهت' : 'FT';

      case MatchPhase.upcoming:
        if (time != null && time.isNotEmpty) {
          return time;
        }
        return isArabic ? 'لم تبدأ' : 'Upcoming';

      case MatchPhase.postponed:
        return isArabic ? 'مؤجلة' : 'Postponed';

      case MatchPhase.cancelled:
        return isArabic ? 'ملغاة' : 'Cancelled';

      case MatchPhase.unknown:
        return rawStatus ?? (isArabic ? 'لم تبدأ' : 'Upcoming');
    }
  }
}
