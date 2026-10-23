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

  /// Checks if the half-scores payload explicitly contains extra-time periods.
  static bool? hasExtraTimeInHalfScores(Map<String, dynamic>? halfScores) {
    if (halfScores == null || halfScores.isEmpty) return null;
    bool hasExtraKeys = false;
    for (final entry in halfScores.entries) {
      final k = entry.key.toLowerCase();
      final val = entry.value;
      if (k.contains('extra') ||
          k.contains('et') ||
          k.contains('إضافي') ||
          k.contains('اضافي')) {
        hasExtraKeys = true;
        if (val != null) {
          if (val is List && val.isNotEmpty) return true;
          if (val is Map && val.isNotEmpty) return true;
          if (val is String && val.trim().isNotEmpty && val != 'null') {
            return true;
          }
          if (val is num && val > 0) return true;
        }
      }
    }
    if (hasExtraKeys) return false;
    return false;
  }

  /// Detects whether extra time was played in the match based on event markers or in-play events.
  static bool detectExtraTime(List<MatchEventEntity> events) {
    for (final ev in events) {
      final name = ev.playerName.toLowerCase();
      final type = ev.type.toLowerCase();

      // 1. Period markers indicating extra time (excluding regular penalty shootouts)
      if (ev.isPeriodMarker ||
          type.contains('period') ||
          type == 'start-end-match' ||
          type == 'whistle') {
        if (name.contains('إضافي') ||
            name.contains('اضافي') ||
            name.contains('extra') ||
            name.contains('overtime') ||
            name.contains('aet')) {
          final parsed = MatchMinuteParser.parse(ev.minute);
          // Only events strictly beyond minute 90 can indicate extra time
          if (parsed.mainMinute > 90) {
            return true;
          }
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

  /// Normalizes match events so that:
  /// 1. Full-time period markers display '90' for regular matches and '120' only when extra time was played.
  /// 2. Mislabeled period markers like "نهاية الشوط الإضافي الأول" at min 90 are corrected to "نهاية الوقت الأصلي".
  /// 3. Starting penalties marker is guaranteed to appear if the match went to penalties.
  /// 4. Half-time and second-half period scores are populated from halfScores if available.
  static List<MatchEventEntity> normalizeEvents(
    List<MatchEventEntity> events, {
    bool? hasExtraTime,
    Map<String, dynamic>? halfScores,
    bool hasShootout = false,
    String? fullTimeScore,
  }) {
    final extraTimePlayed = hasExtraTime ?? detectExtraTime(events);

    // Parse half scores if provided
    String? htScore;
    String? ftScore;
    if (halfScores != null) {
      String? parseHalf(dynamic data) {
        if (data is! List || data.length < 2) return null;
        final h = data[0]['home_scores'] ?? data[0]['score'];
        final a = data[1]['away_scores'] ?? data[1]['score'];
        if (h != null && a != null) return '$h - $a';
        return null;
      }

      htScore = parseHalf(halfScores['first_half']);
      ftScore = parseHalf(halfScores['second_half']);
    }

    if (events.isEmpty) {
      if (hasShootout) {
        return [
          MatchEventEntity(
            minute: extraTimePlayed ? '120' : '90',
            playerName: 'بداية ركلات الترجيح',
            type: 'start-end-match',
            isPeriodMarker: true,
          ),
        ];
      }
      return events;
    }

    // 1. Sanitize and correct period markers
    final sanitized = events.map((ev) {
      var item = ev;
      final parsed = MatchMinuteParser.parse(item.minute);

      // If no extra time played, fix mislabeled "نهاية الشوط الإضافي الأول" at min 90
      if (!extraTimePlayed) {
        if (item.playerName.contains('الشوط الإضافي') &&
            parsed.mainMinute <= 90) {
          item = item.copyWith(
            playerName: 'نهاية الوقت الأصلي',
            minute: '90',
          );
        }
        if (isFullTimeMarker(item) && parsed.mainMinute >= 120) {
          item = item.copyWith(minute: '90');
        }
      }

      // Populate period scores from halfScores if missing
      final scoreEmpty =
          item.score == null || item.score!.trim().isEmpty || item.score == '-';
      if (item.isPeriodMarker && scoreEmpty) {
        final pName = item.playerName.toLowerCase();
        if (htScore != null &&
            (pName.contains('نهاية الشوط الأول') ||
                pName.contains('first half end') ||
                pName.contains('استراحة') ||
                pName.contains('منتصف المباراة'))) {
          item = item.copyWith(score: htScore);
        } else if (ftScore != null &&
            (pName.contains('نهاية الوقت الأصلي') ||
                pName.contains('نهاية الشوط الثاني') ||
                pName.contains('second half end') ||
                pName.contains('regular time end'))) {
          item = item.copyWith(score: ftScore);
        } else if (fullTimeScore != null && isFullTimeMarker(item)) {
          item = item.copyWith(score: fullTimeScore);
        }
      }

      return item;
    }).toList();

    // 2. Ensure starting penalties marker is present when match went to a shootout
    final isShootoutPresent = hasShootout ||
        sanitized.any((e) =>
            e.isPeriodMarker &&
            (e.playerName.contains('ترجيح') || e.playerName.contains('shootout')));

    if (isShootoutPresent) {
      final hasStartingPenaltiesMarker = sanitized.any((e) =>
          e.isPeriodMarker &&
          (e.playerName.contains('بداية ركلات الترجيح') ||
              e.playerName.contains('starting penalties') ||
              e.playerName.contains('penalties start')));

      if (!hasStartingPenaltiesMarker) {
        final penMinute = extraTimePlayed ? '120' : '90';
        final penMarker = MatchEventEntity(
          minute: penMinute,
          playerName: 'بداية ركلات الترجيح',
          type: 'start-end-match',
          isPeriodMarker: true,
        );

        // Find position: insert right before the 2nd half end / regular time end in descending list
        final ftIdx = sanitized.indexWhere((e) => isFullTimeMarker(e));
        if (ftIdx != -1) {
          sanitized.insert(ftIdx + 1, penMarker);
        } else {
          final regIdx = sanitized.indexWhere((e) =>
              e.isPeriodMarker &&
              (e.playerName.contains('نهاية الوقت الأصلي') ||
                  e.playerName.contains('نهاية الشوط الثاني')));
          if (regIdx != -1) {
            sanitized.insert(regIdx, penMarker);
          } else {
            sanitized.insert(0, penMarker);
          }
        }
      }
    }

    return sanitized;
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
        textLower.contains('match-start') ||
        textLower.contains('بداية الشوط الأول')) {
      return -1.0;
    }
    if (textLower.contains('منتصف المباراة') ||
        textLower.contains('نهاية الشوط الأول') ||
        textLower.contains('استراحة') ||
        textLower.contains('half-time') ||
        event.type == 'ht') {
      return 45.5;
    }
    if (textLower.contains('بداية الشوط الثاني') ||
        textLower.contains('2nd half')) {
      return 45.8;
    }
    if (textLower.contains('نهاية الوقت الأصلي') ||
        textLower.contains('نهاية الشوط الثاني')) {
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
    if (textLower.contains('بداية ركلات الترجيح') ||
        textLower.contains('ركلات الترجيح') ||
        textLower.contains('shootout')) {
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
