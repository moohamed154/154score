class ScoreHelper {
  ScoreHelper._();

  static bool isCancelledStatus(String? status, [String? statusCode]) {
    final code = (statusCode ?? '').trim().toUpperCase();
    if (code == 'CANCELLED' ||
        code == 'CANCELED' ||
        code == 'ABANDONED' ||
        code == 'VOID') {
      return true;
    }
    if (status == null || status.trim().isEmpty) return false;
    final lower = status.trim().toLowerCase();
    return lower.contains('ألغيت') ||
        lower.contains('الغيت') ||
        lower.contains('ملغاة') ||
        lower.contains('ملغاه') ||
        lower.contains('ألغية') ||
        lower.contains('الغية') ||
        lower.contains('cancelled') ||
        lower.contains('canceled') ||
        lower.contains('abandoned');
  }

  static bool isPostponedStatus(String? status, [String? statusCode]) {
    final code = (statusCode ?? '').trim().toUpperCase();
    if (code == 'POSTPONED' ||
        code == 'SUSPENDED' ||
        code == 'INTERRUPTED' ||
        code == 'DELAYED') {
      return true;
    }
    if (status == null || status.trim().isEmpty) return false;
    final lower = status.trim().toLowerCase();
    return lower.contains('تأجل') ||
        lower.contains('تاجل') ||
        lower.contains('مؤجل') ||
        lower.contains('مؤجلة') ||
        lower.contains('مؤجله') ||
        lower.contains('postponed') ||
        lower.contains('delayed') ||
        lower.contains('suspended') ||
        lower.contains('interrupted');
  }

  static bool isCancelledOrPostponed(String? status, [String? statusCode]) {
    return isCancelledStatus(status, statusCode) ||
        isPostponedStatus(status, statusCode);
  }

  static bool isLiveStatus(String? status, [String? statusCode]) {
    if (isCancelledOrPostponed(status, statusCode)) return false;
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

  static bool isFinishedStatus(String? status, [String? statusCode]) {
    if (isCancelledOrPostponed(status, statusCode)) return false;
    if (status == null) return false;
    final lower = status.toLowerCase();
    if (lower.contains('مباشر') ||
        lower.contains('live') ||
        lower.contains('شوط')) {
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

  static bool isUpcomingStatus(String? status, [String? statusCode]) {
    if (isCancelledOrPostponed(status, statusCode)) return false;
    if (status == null) return true;
    final lower = status.toLowerCase();
    return lower.contains('not started') ||
        lower.contains('لم تبدأ') ||
        lower.contains('upcoming') ||
        (!isLiveStatus(status, statusCode) && !isFinishedStatus(status, statusCode));
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
