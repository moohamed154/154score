/// Global live clock synchronization registry
/// Keeps match clocks (minutes, seconds, and extra-time stoppage) perfectly in sync across
/// Homepage (MatchCard, LiveMatchCard) and Match Details Page (MatchHeaderBanner)
class LiveClockSync {
  LiveClockSync._();

  static final Map<String, _LiveClockRecord> _clocks = {};

  /// Record current clock state for a match
  static void recordClock({
    required String? matchId,
    required int minute,
    required int second,
    required int elapsedExtraSeconds,
    required int totalExtraMinutes,
  }) {
    if (matchId == null) return;
    final cleanId = _cleanMatchId(matchId);
    if (cleanId.isEmpty) return;

    _clocks[cleanId] = _LiveClockRecord(
      minute: minute,
      second: second,
      elapsedExtraSeconds: elapsedExtraSeconds,
      totalExtraMinutes: totalExtraMinutes,
      recordedAt: DateTime.now(),
    );
  }

  /// Backwards-compatible extra-time recorder
  static void recordExtraTime({
    required String? matchId,
    required int elapsedExtraSeconds,
    required int totalExtraMinutes,
  }) {
    if (matchId == null) return;
    final cleanId = _cleanMatchId(matchId);
    if (cleanId.isEmpty) return;

    final existing = _clocks[cleanId];
    _clocks[cleanId] = _LiveClockRecord(
      minute: existing?.minute ?? 0,
      second: existing?.second ?? 0,
      elapsedExtraSeconds: elapsedExtraSeconds,
      totalExtraMinutes: totalExtraMinutes,
      recordedAt: DateTime.now(),
    );
  }

  /// Retrieve current synchronized clock state for a match, automatically
  /// advancing by the exact wall-clock seconds elapsed since recorded.
  static ({
    int minute,
    int second,
    int elapsedExtraSeconds,
    int totalExtraMinutes,
  })?
  getLiveClock(String? matchId) {
    if (matchId == null) return null;
    final cleanId = _cleanMatchId(matchId);
    final record = _clocks[cleanId];
    if (record == null) return null;

    final diffSec = DateTime.now().difference(record.recordedAt).inSeconds;
    final totalElapsedSec = (diffSec > 0) ? diffSec : 0;

    int newExtraSec = record.elapsedExtraSeconds;
    final int newTotalExtra = record.totalExtraMinutes;
    int newMin = record.minute;
    int newSec = record.second;

    if (newExtraSec > 0 || newTotalExtra > 0) {
      newExtraSec += totalElapsedSec;
    } else {
      final totalSec = newSec + totalElapsedSec;
      newMin += totalSec ~/ 60;
      newSec = totalSec % 60;
    }

    return (
      minute: newMin,
      second: newSec,
      elapsedExtraSeconds: newExtraSec,
      totalExtraMinutes: newTotalExtra,
    );
  }

  /// Backwards-compatible extra-time getter
  static ({int elapsedExtraSeconds, int totalExtraMinutes})? getExtraTime(
    String? matchId,
  ) {
    final live = getLiveClock(matchId);
    if (live == null) return null;
    return (
      elapsedExtraSeconds: live.elapsedExtraSeconds,
      totalExtraMinutes: live.totalExtraMinutes,
    );
  }

  /// Clears stored cache for a match (e.g. when finished or halftime starts)
  static void clearMatch(String? matchId) {
    if (matchId == null) return;
    final cleanId = _cleanMatchId(matchId);
    _clocks.remove(cleanId);
  }

  static String _cleanMatchId(String id) {
    return id.replaceAll('match:', '').trim();
  }
}

class _LiveClockRecord {
  final int minute;
  final int second;
  final int elapsedExtraSeconds;
  final int totalExtraMinutes;
  final DateTime recordedAt;

  const _LiveClockRecord({
    required this.minute,
    required this.second,
    required this.elapsedExtraSeconds,
    required this.totalExtraMinutes,
    required this.recordedAt,
  });
}
