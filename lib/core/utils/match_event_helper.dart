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
    return list;
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
    if (textLower.contains('انتهت') ||
        textLower.contains('نهاية المباراة') ||
        textLower.contains('full-time') ||
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
