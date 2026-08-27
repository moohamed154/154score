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
    String? time,
  }) {
    if (status == null || status.trim().isEmpty) {
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
        s.contains('استراحة') ||
        s.contains('شوط أول') ||
        s.contains('نهاية الشوط الأول') ||
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
        s.contains("'") ||
        (minute != null && minute.isNotEmpty)) {
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

  static String getDisplayLabel(
    MatchPhase phase,
    String? rawStatus, {
    String? minute,
    String? time,
    required bool isArabic,
  }) {
    switch (phase) {
      case MatchPhase.live:
        if (minute != null && minute.isNotEmpty) {
          final cleanMin = minute.replaceAll("'", '').trim();
          return "$cleanMin'";
        }
        return isArabic ? 'مباشر' : 'LIVE';

      case MatchPhase.halfTime:
        return isArabic ? 'استراحة' : 'HT';

      case MatchPhase.extraTime:
        if (minute != null && minute.isNotEmpty) {
          return "$minute'";
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
