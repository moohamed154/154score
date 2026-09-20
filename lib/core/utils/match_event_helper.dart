import '../../features/match_details/domain/entities/match_details_entity.dart';
import 'match_minute_parser.dart';

class MatchEventHelper {
  MatchEventHelper._();

  /// Normalizes and merges two lists of events with strict deduplication and chronological ordering.
  static List<MatchEventEntity> mergeEvents({
    required List<MatchEventEntity> existingEvents,
    required List<MatchEventEntity> incomingEvents,
  }) {
    final Map<String, MatchEventEntity> eventMap = {};

    for (final e in existingEvents) {
      final key = _generateEventKey(e);
      eventMap[key] = e;
    }

    for (final e in incomingEvents) {
      final key = _generateEventKey(e);
      if (eventMap.containsKey(key)) {
        final existing = eventMap[key]!;
        final videoUrl = e.videoUrl ?? existing.videoUrl;
        eventMap[key] = e.copyWith(videoUrl: videoUrl);
      } else {
        eventMap[key] = e;
      }
    }

    final list = eventMap.values.toList();
    list.sort((a, b) => _compareEvents(a, b));
    return normalizeEvents(list);
  }

  /// Checks if the half-scores payload explicitly contains extra-time or penalty periods.
  static bool? hasExtraTimeInHalfScores(Map<String, dynamic>? halfScores) {
    if (halfScores == null || halfScores.isEmpty) return null;
    for (final key in halfScores.keys) {
      final k = key.toLowerCase();
      if (k.contains('extra') ||
          k.contains('et') ||
          k.contains('penal') ||
          k.contains('shootout') ||
          k.contains('إضافي') ||
          k.contains('اضافي') ||
          k.contains('ترجيح')) {
        return true;
      }
    }
    return false;
  }

  /// Detects whether extra time was played in the match based on event markers or in-play events.
  static bool detectExtraTime(List<MatchEventEntity> events) {
    for (final ev in events) {
      final name = ev.playerName.toLowerCase();
      final type = ev.type.toLowerCase();

      // 1. Period markers indicating extra time or penalties
      if (ev.isPeriodMarker ||
          type.contains('period') ||
          type == 'start-end-match' ||
          type == 'whistle') {
        if (name.contains('إضافي') ||
            name.contains('اضافي') ||
            name.contains('extra') ||
            name.contains('overtime') ||
            name.contains('aet') ||
            name.contains('ترجيح') ||
            name.contains('penalt') ||
            name.contains('shootout')) {
          return true;
        }
      }

      // 2. In-play events during extra time (e.g. min 91-125 that are NOT 90+ stoppage time)
      if (!ev.isPeriodMarker &&
          type != 'start-end-match' &&
          type != 'whistle' &&
          type != 'period_marker') {
        final parsed = MatchMinuteParser.parse(ev.minute);
        if (parsed.mainMinute > 90 && parsed.mainMinute <= 125) {
          // Extra time events: 91..120 with extraMinute == 0, or extra time stoppage (105+, 120+)
          if (parsed.extraMinute == 0 ||
              parsed.mainMinute == 105 ||
              parsed.mainMinute == 120) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Identifies full-time period marker events (excluding first-half or half-time markers).
  static bool isFullTimeMarker(MatchEventEntity ev) {
    final name = ev.playerName.trim().toLowerCase();
    final type = ev.type.trim().toLowerCase();

    // Exclude first half, half time, or start markers
    if (name.contains('الأول') ||
        name.contains('اول') ||
        name.contains('1st') ||
        name.contains('half time') ||
        name.contains('halftime') ||
        name.contains('ht') ||
        name.contains('استراحة') ||
        name.contains('بداية')) {
      return false;
    }

    if (type == 'ft' ||
        type == 'full_time' ||
        type == 'fulltime' ||
        type == 'match-end') {
      return true;
    }

    if (name == 'نهاية المباراة' ||
        name == 'نهاية اللقاء' ||
        name == 'انتهت المباراة' ||
        name == 'صافرة النهاية' ||
        name == 'full time' ||
        name == 'full-time' ||
        name == 'match finished' ||
        name == 'ft' ||
        name.contains('نهاية المباراة') ||
        name.contains('نهاية اللقاء') ||
        name.contains('انتهت المباراة') ||
        name.contains('نهاية الوقت الأصلي واللقاء') ||
        name.contains('full time') ||
        name.contains('full-time') ||
        name.contains('match finished')) {
      return true;
    }

    // Period marker with "نهاية" at or after 90th minute
    if ((ev.isPeriodMarker || type == 'start-end-match') &&
        name.contains('نهاية') &&
        !name.contains('إضافي') &&
        !name.contains('اضافي')) {
      final parsed = MatchMinuteParser.parse(ev.minute);
      if (parsed.mainMinute >= 90) {
        return true;
      }
    }

    return false;
  }

  /// Normalizes match events so that full-time period markers display '90' for regular matches
  /// and '120' only when extra time was actually played.
  static List<MatchEventEntity> normalizeEvents(
    List<MatchEventEntity> events, {
    bool? hasExtraTime,
  }) {
    if (events.isEmpty) return events;

    final extraTimePlayed = hasExtraTime ?? detectExtraTime(events);
    if (extraTimePlayed) return events;

    return events.map((ev) {
      if (isFullTimeMarker(ev)) {
        final parsed = MatchMinuteParser.parse(ev.minute);
        if (parsed.mainMinute >= 120) {
          return ev.copyWith(minute: '90');
        }
      }
      return ev;
    }).toList();
  }

  static String _generateEventKey(MatchEventEntity event) {
    final parsed = MatchMinuteParser.parse(event.minute);
    final min = parsed.formatted.toLowerCase();
    final team = event.isHomeTeam ? 'home' : 'away';
    final type = event.type.toLowerCase();
    final player = event.playerName.trim().toLowerCase();
    final sec = (event.secondaryPlayerName ?? '').trim().toLowerCase();
    return '${min}_${team}_${type}_${player}_$sec';
  }

  static int _compareEvents(MatchEventEntity a, MatchEventEntity b) {
    final weightA = _getEventSortWeight(a);
    final weightB = _getEventSortWeight(b);

    if (weightA != weightB) {
      return weightA.compareTo(weightB);
    }

    // Preserve deterministic ordering for events at the same minute
    return a.playerName.compareTo(b.playerName);
  }

  static double _getEventSortWeight(MatchEventEntity event) {
    final textLower = '${event.type} ${event.playerName}'.toLowerCase();

    // Check for period/whistle markers
    if (textLower.contains('بدأت') ||
        textLower.contains('بداية اللقاء') ||
        textLower.contains('kickoff') ||
        textLower.contains('match-start')) {
      return -1.0;
    }
    if (textLower.contains('منتصف المباراة') ||
        textLower.contains('نهاية الشوط الأول') ||
        textLower.contains('half-time') ||
        event.type == 'ht') {
      return 45.5;
    }
    if (textLower.contains('بداية الشوط الثاني') ||
        textLower.contains('2nd half')) {
      return 45.8;
    }
    if (textLower.contains('نهاية الوقت الأصلي')) {
      return 90.5;
    }
    if (textLower.contains('بداية الشوط الإضافي الأول')) {
      return 90.8;
    }
    if (textLower.contains('نهاية الشوط الإضافي الأول')) {
      return 105.5;
    }
    if (textLower.contains('بداية الشوط الإضافي الثاني')) {
      return 105.8;
    }
    if (textLower.contains('نهاية الشوط الإضافي الثاني')) {
      return 120.5;
    }
    if (textLower.contains('ركلات الترجيح')) {
      return 120.8;
    }
    if (textLower.contains('انتهت') ||
        textLower.contains('نهاية المباراة') ||
        textLower.contains('نهاية اللقاء') ||
        textLower.contains('full-time') ||
        textLower.contains('full time') ||
        event.type == 'ft') {
      return 999.0;
    }

    final parsed = MatchMinuteParser.parse(event.minute);
    return parsed.sortWeight;
  }

  /// Sanitizes minute string by delegating to MatchMinuteParser
  static String sanitizeMinute(String minuteStr) {
    final parsed = MatchMinuteParser.parse(minuteStr);
    return parsed.formatted;
  }
}
