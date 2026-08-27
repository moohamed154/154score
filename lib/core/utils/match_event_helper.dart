import '../../features/match_details/domain/entities/match_details_entity.dart';

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
      eventMap[key] = e;
    }

    final list = eventMap.values.toList();
    list.sort((a, b) => _compareEvents(a, b));
    return list;
  }

  static String _generateEventKey(MatchEventEntity event) {
    final min = event.minute.trim().toLowerCase();
    final team = event.isHomeTeam ? 'home' : 'away';
    final type = event.type.toLowerCase();
    final player = event.playerName.trim().toLowerCase();
    final sec = (event.secondaryPlayerName ?? '').trim().toLowerCase();
    return '${min}_${team}_${type}_${player}_$sec';
  }

  static int _compareEvents(MatchEventEntity a, MatchEventEntity b) {
    final minA = _extractMinute(a.minute);
    final minB = _extractMinute(b.minute);

    if (minA != minB) {
      return minA.compareTo(minB);
    }

    final extraA = _extractExtraMinute(a.minute);
    final extraB = _extractExtraMinute(b.minute);

    return extraA.compareTo(extraB);
  }

  static int _extractMinute(String minuteStr) {
    final clean = minuteStr.replaceAll("'", '').trim();
    if (clean.contains('+')) {
      final parts = clean.split('+');
      return int.tryParse(parts[0].trim()) ?? 0;
    }
    return int.tryParse(clean) ?? 0;
  }

  static int _extractExtraMinute(String minuteStr) {
    final clean = minuteStr.replaceAll("'", '').trim();
    if (clean.contains('+')) {
      final parts = clean.split('+');
      if (parts.length > 1) {
        return int.tryParse(parts[1].trim()) ?? 0;
      }
    }
    return 0;
  }
}
