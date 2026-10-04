import 'dart:math' as math;
import 'date_formatter.dart';

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
    String? statusCode,
    String? period,
    String? minute,
    String? extraTime,
    String? time,
    String? date,
    String? score1,
    String? score2,
    int? timestamp,
    DateTime? now,
  }) {
    final code = (statusCode ?? '').trim().toUpperCase();
    final p = (period ?? '').trim().toLowerCase();
    final s = (status ?? '').trim().toLowerCase();

    // 0. Explicit status_code / period checks from Mobile App JSON
    if (code == 'HALF_TIME' ||
        code == 'HALFTIME' ||
        code == 'HT' ||
        code == 'BREAK' ||
        p == 'break' ||
        p == 'ht' ||
        p == 'halftime' ||
        p == 'extra_break' ||
        p == 'half_time') {
      return MatchPhase.halfTime;
    }
    if (code == 'PENALTIES' || p == 'penalties' || p == 'pen') {
      return MatchPhase.penalties;
    }
    if (code == 'EXTRA_TIME_1ST' ||
        code == 'EXTRA_TIME_2ND' ||
        code == 'EXTRA_TIME' ||
        code == 'ET' ||
        p == '1st_extra' ||
        p == '2nd_extra' ||
        p.contains('extra') ||
        p.contains('et')) {
      return MatchPhase.extraTime;
    }
    if (code == 'FINISHED' || code == 'FT' || p == 'finished' || p == 'ended') {
      return MatchPhase.finished;
    }
    if (code == 'POSTPONED' || p == 'postponed') {
      return MatchPhase.postponed;
    }
    if (code == 'CANCELLED' || code == 'ABANDONED' || p == 'cancelled') {
      return MatchPhase.cancelled;
    }
    if (code == 'INTERRUPTED' ||
        code == 'SUSPENDED' ||
        p == 'interrupted' ||
        p == 'suspended') {
      return MatchPhase.postponed;
    }
    if (code == 'LIVE' ||
        code == 'IN_PLAY_1ST' ||
        code == 'IN_PLAY_2ND' ||
        p == '1st_half' ||
        p == '2nd_half' ||
        p == '1st' ||
        p == '2nd') {
      return MatchPhase.live;
    }

    final hasLiveIndicator =
        (minute != null && minute.isNotEmpty && minute != 'null') ||
        (extraTime != null &&
            extraTime.isNotEmpty &&
            extraTime != 'null' &&
            extraTime != '+00:00' &&
            extraTime != '00:00');

    final isExplicitUpcoming =
        code == 'UPCOMING' ||
        code == 'NOT_STARTED' ||
        code == 'SCHEDULED' ||
        p == 'upcoming' ||
        p == 'not_started' ||
        p == 'scheduled' ||
        s.contains('لم تبدأ') ||
        s.contains('not started') ||
        s.contains('قادمة') ||
        s.contains('upcoming') ||
        s == 'ns';

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
        s.contains('نهاية الشوط 1') ||
        s.contains('نهاية الشوط الاول') ||
        s == 'نهاية الشوط' ||
        s == 'half time' ||
        s == 'halftime' ||
        s.contains('half time') ||
        s.contains('halftime')) {
      return MatchPhase.halfTime;
    }

    // 4. Finished
    if (s.contains('انتهت') ||
        (s.contains('نهاية') &&
            !s.contains('شوط') &&
            !s.contains('أول') &&
            !s.contains('اول') &&
            !s.contains('1')) ||
        s.contains('نهاية المباراة') ||
        s.contains('نهاية اللقاء') ||
        s.contains('نهاية الوقت الأصلي واللقاء') ||
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

    // 5.1 Timestamp check: The gold standard for time truth
    // If timestamp is in the future in UTC, match is strictly UPCOMING!
    if (timestamp != null && timestamp > 0) {
      final nowUtcSec =
          (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
          1000;
      final diffSeconds = nowUtcSec - timestamp;
      if (diffSeconds < 0) {
        return MatchPhase.upcoming;
      }
    }

    final hasActiveScores =
        (score1 != null &&
        score2 != null &&
        score1.isNotEmpty &&
        score2.isNotEmpty &&
        score1 != '-' &&
        score2 != '-' &&
        (score1 != '0' || score2 != '0'));

    // 5.2 If explicitly marked upcoming and no live indicator or active scores, it's upcoming
    if (isExplicitUpcoming && !hasLiveIndicator && !hasActiveScores) {
      return MatchPhase.upcoming;
    }

    final currentTime = now ?? DateTime.now();
    final todayStr = DateFormatter.toApiDateString(currentTime);
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    DateTime? matchDate;
    if (date != null && date.trim().isNotEmpty) {
      matchDate = DateTime.tryParse(date.trim());
    }
    final isPastDate =
        matchDate != null &&
        DateTime(
          matchDate.year,
          matchDate.month,
          matchDate.day,
        ).isBefore(today);
    final isFutureDate =
        matchDate != null &&
        DateTime(matchDate.year, matchDate.month, matchDate.day).isAfter(today);

    // 5.3 Historical match guard: A match on a past date can NEVER be live or upcoming
    if (isPastDate) {
      return MatchPhase.finished;
    }

    // 5.4 Future match guard
    if (isFutureDate) {
      return MatchPhase.upcoming;
    }

    // 6. Explicit Live / In-play keywords or minute/extraTime from API
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
        hasLiveIndicator) {
      return MatchPhase.live;
    }

    final isToday =
        date == null || date.trim().isEmpty || date.trim() == todayStr;

    // 7. Auto-finish guard: Only transition to finished if active scores exist and match duration has clearly elapsed (> 150 mins)
    // Matches DO NOT become live or change to half-time solely based on wall clock time.
    // They ONLY become live when official live indicators (status text, status code, minute, or active scores) are present.
    if (timestamp != null && timestamp > 0) {
      final nowUtcSec =
          (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
          1000;
      final diff = nowUtcSec - timestamp;
      if (diff > 150 * 60 && hasActiveScores) {
        return MatchPhase.finished;
      }
    } else if (isToday &&
        time != null &&
        time.isNotEmpty &&
        time != '-') {
      final startMins = parseTimeToMinutes(time);
      if (startMins != null) {
        final currentMins = currentTime.hour * 60 + currentTime.minute;
        var elapsed = currentMins - startMins;
        if (elapsed < -720) elapsed += 1440;
        if (elapsed > 150 && hasActiveScores) {
          return MatchPhase.finished;
        }
      }
    }

    // 8. Score-based in-play detection: If scores are active and non-zero on today's date
    if (isToday && hasActiveScores) {
      return MatchPhase.live;
    }

    // If date is not today, but match has non-zero scores and no upcoming indicator, it is finished
    if (!isToday && hasActiveScores) {
      return MatchPhase.finished;
    }

    // 9. Upcoming
    if (isExplicitUpcoming ||
        (time != null && time.isNotEmpty && !s.contains('انتهت'))) {
      return MatchPhase.upcoming;
    }

    if (status == null || status.trim().isEmpty) {
      if (hasActiveScores) {
        return MatchPhase.finished;
      }
      return (time != null && time.isNotEmpty)
          ? MatchPhase.upcoming
          : MatchPhase.unknown;
    }

    return MatchPhase.unknown;
  }

  /// Convenience helper to parse phase directly from any object with match properties.
  static MatchPhase parseMatch(dynamic match, {DateTime? now}) {
    return parseStatus(
      match.status,
      statusCode: match.statusCode,
      period: match.period,
      minute: match.minute,
      extraTime: match.extraTime,
      time: match.time,
      date: match.date,
      score1: match.score1,
      score2: match.score2,
      timestamp: match.timestamp,
      now: now,
    );
  }

  static bool isLive(MatchPhase phase) {
    return phase == MatchPhase.live ||
        phase == MatchPhase.halfTime ||
        phase == MatchPhase.extraTime ||
        phase == MatchPhase.penalties;
  }

  static bool isHalfTime(MatchPhase phase) {
    return phase == MatchPhase.halfTime;
  }

  /// Whether the match is actively in-play (clock is ticking)
  static bool isInPlay(MatchPhase phase) {
    return phase == MatchPhase.live || phase == MatchPhase.extraTime;
  }

  static bool isFinished(MatchPhase phase) {
    return phase == MatchPhase.finished;
  }

  static bool isUpcoming(MatchPhase phase) {
    return phase == MatchPhase.upcoming;
  }

  static bool isPostponed(MatchPhase phase) {
    return phase == MatchPhase.postponed;
  }

  static bool isCancelled(MatchPhase phase) {
    return phase == MatchPhase.cancelled;
  }

  static bool isPostponedOrCancelled(MatchPhase phase) {
    return phase == MatchPhase.postponed || phase == MatchPhase.cancelled;
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
        final formattedElapsed = elapsedPart.contains(':')
            ? elapsedPart
            : '0$elapsedPart:00';
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
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*([صم]|AM|PM|am|pm)?')
        .firstMatch(clean);
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
    int? timestamp,
    int? htTime,
    DateTime? now,
  }) {
    int elapsed;
    if (timestamp != null && timestamp > 0) {
      final nowSec =
          (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
          1000;
      elapsed = (nowSec - timestamp) ~/ 60;
    } else {
      final startMins = parseTimeToMinutes(time);
      if (startMins == null) return (minute: 0, extraMinute: 0);

      final current = now ?? DateTime.now();
      final currentMins = current.hour * 60 + current.minute;
      elapsed = currentMins - startMins;

      // Handle midnight wrap-around (e.g. kick-off 23:30, current 00:15 -> 45 mins elapsed)
      if (elapsed < -720) {
        elapsed += 1440;
      }
    }

    if (elapsed < 0) {
      return (minute: 0, extraMinute: 0);
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
      int secondHalfElapsed;
      if (htTime != null && htTime > 0) {
        final nowSec =
            (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
            1000;
        secondHalfElapsed = math.max(0, (nowSec - htTime) ~/ 60);
      } else {
        secondHalfElapsed = elapsed > 68
            ? elapsed - 68
            : (elapsed > 45 ? elapsed - 45 : 0);
      }
      final min = 45 + secondHalfElapsed;
      if (min < 46) return (minute: 46, extraMinute: 0);
      if (min <= 90) return (minute: min, extraMinute: 0);
      if (min <= 102) return (minute: 90, extraMinute: min - 90);
      return (minute: 90, extraMinute: 5);
    }

    // Generic live match
    if (elapsed <= 0) return (minute: 1, extraMinute: 0);
    if (elapsed <= 45) return (minute: elapsed, extraMinute: 0);
    if (elapsed <= 68) return (minute: 45, extraMinute: 0);
    final secHalfMin = 45 + (elapsed - 68);
    if (secHalfMin <= 90) return (minute: secHalfMin, extraMinute: 0);
    if (secHalfMin <= 102) return (minute: 90, extraMinute: secHalfMin - 90);
    return (minute: 90, extraMinute: 5);
  }

  /// Estimates the current match minute as an integer based on kick-off time and current time.
  static int? estimateMinuteNumber({
    required String? time,
    String? status,
    String? period,
    int? timestamp,
    int? htTime,
    DateTime? now,
  }) {
    int elapsed;
    if (timestamp != null && timestamp > 0) {
      final nowSec =
          (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
          1000;
      elapsed = (nowSec - timestamp) ~/ 60;
    } else {
      final startMins = parseTimeToMinutes(time);
      if (startMins == null) return null;

      final current = now ?? DateTime.now();
      final currentMins = current.hour * 60 + current.minute;
      elapsed = currentMins - startMins;

      // Handle midnight wrap-around (e.g. kick-off 23:30, current 00:15 -> 45 mins elapsed)
      if (elapsed < -720) {
        elapsed += 1440;
      }
    }

    if (elapsed < 0) {
      return 0;
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
      int secondHalfElapsed;
      if (htTime != null && htTime > 0) {
        final nowSec =
            (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
            1000;
        secondHalfElapsed = math.max(0, (nowSec - htTime) ~/ 60);
      } else {
        secondHalfElapsed = elapsed > 68
            ? elapsed - 68
            : (elapsed > 45 ? elapsed - 45 : 0);
      }
      final min = 45 + secondHalfElapsed;
      if (min < 46) return 46;
      if (min <= 90) return min;
      return 90;
    }

    // Generic live match
    if (elapsed <= 0) return 1;
    if (elapsed <= 45) return elapsed;
    if (elapsed <= 68) return 45;
    final secHalfMin = 45 + (elapsed - 68);
    if (secHalfMin <= 90) return secHalfMin;
    return 90;
  }

  /// Calculates live match minute, seconds, and extra-time stoppage
  /// from kickoff timestamp / time and current time matching Yalla Shoot logic.
  static ({
    int minute,
    int second,
    int elapsedExtraSeconds,
    int totalExtraMinutes,
  }) calculateLiveClock({
    required String? time,
    String? status,
    String? period,
    int? timestamp,
    int? htTime,
    DateTime? now,
  }) {
    int elapsedSeconds = 0;
    if (timestamp != null && timestamp > 0) {
      final nowSec =
          (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
          1000;
      elapsedSeconds = nowSec - timestamp;
    } else {
      final startMins = parseTimeToMinutes(time);
      if (startMins != null) {
        final current = now ?? DateTime.now();
        final currentMins = current.hour * 60 + current.minute;
        var diffMins = currentMins - startMins;
        if (diffMins < -720) {
          diffMins += 1440;
        }
        elapsedSeconds = diffMins * 60 + current.second;
      }
    }

    if (elapsedSeconds < 0) {
      return (
        minute: 0,
        second: 0,
        elapsedExtraSeconds: 0,
        totalExtraMinutes: 0,
      );
    }

    final s = (status ?? '').toLowerCase();
    final p = (period ?? '').toLowerCase();

    final is1stHalf =
        p.contains('1st') ||
        p.contains('first') ||
        s.contains('الأول') ||
        s.contains('الاول');
    final is2ndHalf =
        p.contains('2nd') || p.contains('second') || s.contains('الثاني');
    final is1stExtra =
        p.contains('1st_extra') ||
        s.contains('الإضافي الأول') ||
        s.contains('الاضافي الاول');
    final is2ndExtra =
        p.contains('2nd_extra') ||
        s.contains('الإضافي الثاني') ||
        s.contains('الاضافي الثاني');
    final isHt =
        p.contains('ht') ||
        p.contains('break') ||
        s.contains('استراحة') ||
        s.contains('بين الشوطين') ||
        s.contains('half time');

    if (isHt) {
      return (
        minute: 45,
        second: 0,
        elapsedExtraSeconds: 0,
        totalExtraMinutes: 0,
      );
    }

    if (is1stHalf) {
      if (elapsedSeconds <= 45 * 60) {
        return (
          minute: elapsedSeconds ~/ 60,
          second: elapsedSeconds % 60,
          elapsedExtraSeconds: 0,
          totalExtraMinutes: 0,
        );
      } else {
        final extraSec = elapsedSeconds - (45 * 60);
        final totalExtra = (extraSec ~/ 60) >= 3 ? ((extraSec ~/ 60) + 1) : 3;
        return (
          minute: 45,
          second: 0,
          elapsedExtraSeconds: extraSec,
          totalExtraMinutes: totalExtra,
        );
      }
    }

    if (is2ndHalf) {
      int secHalfElapsed;
      if (htTime != null && htTime > 0) {
        final nowSec =
            (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
            1000;
        secHalfElapsed = math.max(0, nowSec - htTime);
      } else {
        secHalfElapsed = elapsedSeconds > (60 * 60)
            ? (elapsedSeconds - (60 * 60))
            : (elapsedSeconds > (45 * 60) ? (elapsedSeconds - (45 * 60)) : 0);
      }

      if (secHalfElapsed <= 45 * 60) {
        return (
          minute: 45 + (secHalfElapsed ~/ 60),
          second: secHalfElapsed % 60,
          elapsedExtraSeconds: 0,
          totalExtraMinutes: 0,
        );
      } else {
        final extraSec = secHalfElapsed - (45 * 60);
        final totalExtra = (extraSec ~/ 60) >= 5 ? ((extraSec ~/ 60) + 1) : 5;
        return (
          minute: 90,
          second: 0,
          elapsedExtraSeconds: extraSec,
          totalExtraMinutes: totalExtra,
        );
      }
    }

    if (is1stExtra) {
      final et1Elapsed =
          elapsedSeconds > (115 * 60) ? (elapsedSeconds - (115 * 60)) : 0;
      if (et1Elapsed <= 15 * 60) {
        return (
          minute: 90 + (et1Elapsed ~/ 60),
          second: et1Elapsed % 60,
          elapsedExtraSeconds: 0,
          totalExtraMinutes: 0,
        );
      } else {
        final extraSec = et1Elapsed - (15 * 60);
        return (
          minute: 105,
          second: 0,
          elapsedExtraSeconds: extraSec,
          totalExtraMinutes: 2,
        );
      }
    }

    if (is2ndExtra) {
      final et2Elapsed =
          elapsedSeconds > (135 * 60) ? (elapsedSeconds - (135 * 60)) : 0;
      if (et2Elapsed <= 15 * 60) {
        return (
          minute: 105 + (et2Elapsed ~/ 60),
          second: et2Elapsed % 60,
          elapsedExtraSeconds: 0,
          totalExtraMinutes: 0,
        );
      } else {
        final extraSec = et2Elapsed - (15 * 60);
        return (
          minute: 120,
          second: 0,
          elapsedExtraSeconds: extraSec,
          totalExtraMinutes: 2,
        );
      }
    }

    // Generic live match
    if (elapsedSeconds <= 45 * 60) {
      return (
        minute: elapsedSeconds ~/ 60,
        second: elapsedSeconds % 60,
        elapsedExtraSeconds: 0,
        totalExtraMinutes: 0,
      );
    } else if (elapsedSeconds <= 60 * 60) {
      return (
        minute: 45,
        second: 0,
        elapsedExtraSeconds: 0,
        totalExtraMinutes: 0,
      );
    } else if (elapsedSeconds <= 105 * 60) {
      final secHalf = elapsedSeconds - (60 * 60);
      if (secHalf <= 45 * 60) {
        return (
          minute: 45 + (secHalf ~/ 60),
          second: secHalf % 60,
          elapsedExtraSeconds: 0,
          totalExtraMinutes: 0,
        );
      } else {
        final extraSec = secHalf - (45 * 60);
        return (
          minute: 90,
          second: 0,
          elapsedExtraSeconds: extraSec,
          totalExtraMinutes: 5,
        );
      }
    } else {
      return (
        minute: 90,
        second: 0,
        elapsedExtraSeconds: 5 * 60,
        totalExtraMinutes: 5,
      );
    }
  }

  /// Estimates the real-time match display label (e.g. "75'", "45' +2'", "استراحة")
  /// when the API does not explicitly return the minute field.
  static String? estimateMinuteFromKickoff({
    required String? time,
    String? status,
    String? period,
    int? htTime,
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
      int secondHalfElapsed;
      if (htTime != null && htTime > 0) {
        final nowSec =
            (now?.toUtc() ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/
            1000;
        secondHalfElapsed = math.max(0, (nowSec - htTime) ~/ 60);
      } else {
        secondHalfElapsed = elapsed > 68
            ? elapsed - 68
            : (elapsed > 45 ? elapsed - 45 : 0);
      }
      final min = 45 + secondHalfElapsed;
      if (min < 46) return "46'";
      if (min <= 90) return "$min'";
      final extra = (min - 90).clamp(1, 15);
      return "90' +$extra'";
    }

    // Generic live match
    if (elapsed <= 0) return "1'";
    if (elapsed <= 45) return "$elapsed'";
    if (elapsed <= 68) return isArabic ? 'استراحة' : 'HT';
    final secHalfMin = 45 + (elapsed - 68);
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
    int? timestamp,
    int? htTime,
    required bool isArabic,
  }) {
    int? minNum;
    if (minute != null && minute.isNotEmpty && minute != 'null') {
      minNum = int.tryParse(minute.replaceAll("'", '').trim().split('+').first);
    }
    if (minNum == null || minNum == 0) {
      minNum = estimateMinuteNumber(
        time: time,
        status: rawStatus,
        period: period,
        timestamp: timestamp,
        htTime: htTime,
      );
    }
    final p = (period ?? '').toLowerCase();
    final s = (rawStatus ?? '').toLowerCase();
    final is1stHalf =
        p.contains('1st') ||
        s.contains('الأول') ||
        s.contains('الاول') ||
        s.contains('first');
    final baseMin = (minNum != null && minNum > 0)
        ? minNum
        : (is1stHalf ? 45 : 90);

    final formattedExtra = formatExtraTime(extraTime, minute: baseMin);

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
          return "$baseMin'  $formattedExtra";
        }
        if (minNum != null && minNum > 0) {
          return "$minNum'";
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
