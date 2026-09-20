class ScoreHelper {
  ScoreHelper._();

  static bool isLiveStatus(String? status) {
    if (status == null) return false;
    final lower = status.toLowerCase();
    return lower.contains('live') ||
        lower.contains('مباشر') ||
        lower.contains('شوط') ||
        lower.contains('half') ||
        lower.contains('إضافي') ||
        lower.contains('extra') ||
        lower.contains('استراحة') ||
        lower.contains('break');
  }

  static bool isFinishedStatus(String? status) {
    if (status == null) return false;
    final lower = status.toLowerCase();
    if (lower.contains('مباشر') || lower.contains('live') || lower.contains('شوط')) {
      return false;
    }
    if ((lower.contains('penalties') || lower.contains('ترجيح')) &&
        !lower.contains('بعد') &&
        !lower.contains('انتهت') &&
        !lower.contains('ft') &&
        !lower.contains('ended')) {
      return false;
    }
    return lower.contains('ended') ||
        lower.contains('انتهت') ||
        lower.contains('ft') ||
        lower.contains('final');
  }

  static bool isUpcomingStatus(String? status) {
    if (status == null) return true;
    final lower = status.toLowerCase();
    return lower.contains('not started') ||
        lower.contains('لم تبدأ') ||
        lower.contains('upcoming') ||
        (!isLiveStatus(status) && !isFinishedStatus(status));
  }

  static String normalizeScore(String? score) {
    if (score == null || score.trim().isEmpty) {
      return '-';
    }
    final trimmed = score.trim();
    // Sometimes scores come as "04", normalize to "4" if numeric
    final parsed = int.tryParse(trimmed);
    if (parsed != null) {
      return parsed.toString();
    }
    return trimmed;
  }
}
