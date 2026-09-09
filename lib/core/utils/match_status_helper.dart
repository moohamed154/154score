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

  static String? formatExtraTime(
    String? extraTime, {
    int? minute,
    int? elapsedSeconds,
  }) {
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
        clean == '+00:00 / 00' ||
        clean == '+00:00  / 0') {
      return null;
    }

    // Extra time should ONLY be shown at 45 (1st half) or 90+ (2nd half/extra time)
    if (minute != null && minute > 0) {
      if (minute < 45 || (minute > 45 && minute < 90)) {
        return null;
      }
    }

    // 1. Handle "+00:00 / 10" or "02:00 / 5" or "02:00  / 5" or "01:23 / 5"
    if (clean.contains('/')) {
      final parts = clean.split('/');
      final elapsedPart = parts.first.replaceAll('+', '').trim();
      final totalPart = parts.last.trim();
      final totalNum = int.tryParse(totalPart);

      if (elapsedSeconds != null && totalNum != null) {
        final mm = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
        final ss = (elapsedSeconds % 60).toString().padLeft(2, '0');
        return '$mm:$ss  / $totalNum';
      }

      if (elapsedPart.isNotEmpty &&
          elapsedPart != '00:00' &&
          elapsedPart != '0') {
        final formattedElapsed =
            elapsedPart.contains(':') ? elapsedPart : '0$elapsedPart:00';
        return '$formattedElapsed  / $totalPart';
      }
      if (totalNum != null && totalNum > 0) {
        return '00:00  / $totalNum';
      }
      return null;
    }

    // 2. Handle numeric total extra time e.g. "5", "+5", "2", "+2"
    final cleanDigits = clean.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final totalNum = int.tryParse(cleanDigits);
    if (totalNum != null && totalNum > 0) {
      final sec = elapsedSeconds ?? 0;
      final mm = (sec ~/ 60).toString().padLeft(2, '0');
      final ss = (sec % 60).toString().padLeft(2, '0');
      return '$mm:$ss  / $totalNum';
    }

    return clean.endsWith("'") ? '+$clean' : '+$clean\'';
  }

  /// Parses a time string into minutes since midnight (0 - 1439).
  static int? parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == '-') return null;
    final clean = timeStr.trim();
    final match =
        RegExp(r'(\d{1,2}):(\d{2})\s*([صم]|AM|PM|am|pm)?').firstMatch(clean);
    if (match == null) return null;
    var h = int.tryParse(match.group(1) ?? '0') ?? 0;
    final m = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3);
    if ((period == 'م' || period?.toUpperCase() == 'PM') && h < 12) {
      h += 12;
    } else if ((period == 'ص' || period?.toUpperCase() == 'AM') && h == 12) {
      h = 0;
    }
    return h * 60 + m;
  }

  /// Estimates the current match base minute and extra time minute based on kick-off time and current time.
  static ({int minute, int extraMinute}) estimateMatchMinutes({
    required String? time,
    String? status,
    String? period,
    DateTime? now,
  }) {
    final startMins = parseTimeToMinutes(time);
    if (startMins == null) return (minute: 0, extraMinute: 0);

    final current = now ?? DateTime.now();
    final currentMins = current.hour * 60 + current.minute;
    var elapsed = currentMins - startMins;

    // Handle midnight wrap-around (e.g. kick-off 23:30, current 00:15 -> 45 mins elapsed)
    if (elapsed < -720) {
      elapsed += 1440;
    } else if (elapsed < 0) {
      return (minute: 1, extraMinute: 0);
    }

    final s = (status ?? '').toLowerCase();
    final p = (period ?? '').toLowerCase();

    final is1stHalf =
        p.contains('1st') ||
        s.contains('الأول') ||
        s.contains('الاول') ||
        s.contains('first');
    final is2ndHalf =
        p.contains('2nd') || s.contains('الثاني') || s.contains('second');
    final isHt =
        p.contains('ht') ||
        s.contains('استراحة') ||
        s.contains('بين الشوطين') ||
        s.contains('half time');

    if (isHt) return (minute: 45, extraMinute: 0);

    if (is1stHalf) {
      if (elapsed <= 0) return (minute: 1, extraMinute: 0);
      if (elapsed <= 45) return (minute: elapsed, extraMinute: 0);
      if (elapsed <= 52) return (minute: 45, extraMinute: elapsed - 45);
      // Beyond 52 mins in 1st half: match is in half-time break
      return (minute: 45, extraMinute: 0);
    }

    if (is2ndHalf) {
      final secondHalfElapsed =
          elapsed > 60 ? elapsed - 60 : (elapsed > 45 ? elapsed - 45 : 0);
      final min = 45 + secondHalfElapsed;
      if (min < 46) return (minute: 46, extraMinute: 0);
      if (min <= 90) return (minute: min, extraMinute: 0);
      if (min <= 102) return (minute: 90, extraMinute: min - 90);
      return (minute: 90, extraMinute: 5);
    }

    // Generic live match
    if (elapsed <= 0) return (minute: 1, extraMinute: 0);
    if (elapsed <= 45) return (minute: elapsed, extraMinute: 0);
    if (elapsed <= 60) return (minute: 45, extraMinute: 0);
    final secHalfMin = 45 + (elapsed - 60);
    if (secHalfMin <= 90) return (minute: secHalfMin, extraMinute: 0);
    if (secHalfMin <= 102) return (minute: 90, extraMinute: secHalfMin - 90);
    return (minute: 90, extraMinute: 5);
  }


  /// Estimates the current match minute as an integer based on kick-off time and current time.
  static int? estimateMinuteNumber({
    required String? time,
    String? status,
    String? period,
    DateTime? now,
  }) {
    final startMins = parseTimeToMinutes(time);
    if (startMins == null) return null;

    final current = now ?? DateTime.now();
    final currentMins = current.hour * 60 + current.minute;
    var elapsed = currentMins - startMins;

    // Handle midnight wrap-around (e.g. kick-off 23:30, current 00:15 -> 45 mins elapsed)
    if (elapsed < -720) {
      elapsed += 1440;
    } else if (elapsed < 0) {
      return 1;
    }

    final s = (status ?? '').toLowerCase();
    final p = (period ?? '').toLowerCase();

    final is1stHalf =
        p.contains('1st') ||
        s.contains('الأول') ||
        s.contains('الاول') ||
        s.contains('first');
    final is2ndHalf =
        p.contains('2nd') || s.contains('الثاني') || s.contains('second');
    final isHt =
        p.contains('ht') ||
        s.contains('استراحة') ||
        s.contains('بين الشوطين') ||
        s.contains('half time');

    if (isHt) return 45;

    if (is1stHalf) {
      if (elapsed <= 0) return 1;
      if (elapsed <= 45) return elapsed;
      return 45;
    }

    if (is2ndHalf) {
      final secondHalfElapsed =
          elapsed > 60 ? elapsed - 60 : (elapsed > 45 ? elapsed - 45 : 0);
      final min = 45 + secondHalfElapsed;
      if (min < 46) return 46;
      if (min <= 90) return min;
      return 90;
    }

    // Generic live match
    if (elapsed <= 0) return 1;
    if (elapsed <= 45) return elapsed;
    if (elapsed <= 60) return 45;
    final secHalfMin = 45 + (elapsed - 60);
    if (secHalfMin <= 90) return secHalfMin;
    return 90;
  }

  /// Estimates the real-time match display label (e.g. "75'", "45' +2'", "استراحة")
  /// when the API does not explicitly return the minute field.
  static String? estimateMinuteFromKickoff({
    required String? time,
    String? status,
    String? period,
    bool isArabic = true,
    DateTime? now,
  }) {
    final startMins = parseTimeToMinutes(time);
    if (startMins == null) return null;

    final current = now ?? DateTime.now();
    final currentMins = current.hour * 60 + current.minute;
    var elapsed = currentMins - startMins;

    if (elapsed < -720) {
      elapsed += 1440;
    } else if (elapsed < 0) {
      return "1'";
    }

    final s = (status ?? '').toLowerCase();
    final p = (period ?? '').toLowerCase();

    final is1stHalf =
        p.contains('1st') ||
        s.contains('الأول') ||
        s.contains('الاول') ||
        s.contains('first');
    final is2ndHalf =
        p.contains('2nd') || s.contains('الثاني') || s.contains('second');
    final isHt =
        p.contains('ht') ||
        s.contains('استراحة') ||
        s.contains('بين الشوطين') ||
        s.contains('half time');

    if (isHt) {
      return isArabic ? 'استراحة' : 'HT';
    }

    if (is1stHalf) {
      if (elapsed <= 0) return "1'";
      if (elapsed <= 45) return "$elapsed'";
      if (elapsed <= 52) {
        final extra = elapsed - 45;
        return "45' +$extra'";
      }
      return isArabic ? 'استراحة' : 'HT';
    }

    if (is2ndHalf) {
      final secondHalfElapsed =
          elapsed > 60 ? elapsed - 60 : (elapsed > 45 ? elapsed - 45 : 0);
      final min = 45 + secondHalfElapsed;
      if (min < 46) return "46'";
      if (min <= 90) return "$min'";
      final extra = (min - 90).clamp(1, 15);
      return "90' +$extra'";
    }

    // Generic live match
    if (elapsed <= 0) return "1'";
    if (elapsed <= 45) return "$elapsed'";
    if (elapsed <= 60) return isArabic ? 'استراحة' : 'HT';
    final secHalfMin = 45 + (elapsed - 60);
    if (secHalfMin <= 90) return "$secHalfMin'";
    final extra = (secHalfMin - 90).clamp(1, 15);
    return "90' +$extra'";
  }

  static String getDisplayLabel(
    MatchPhase phase,
    String? rawStatus, {
    String? minute,
    String? extraTime,
    String? time,
    String? period,
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
        // Fallback: estimate real time from kick-off time if available
        final estimated = estimateMinuteFromKickoff(
          time: time,
          status: rawStatus,
          period: period,
          isArabic: isArabic,
        );
        if (estimated != null && estimated.isNotEmpty) {
          return estimated;
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
