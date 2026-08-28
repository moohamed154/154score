class MatchMinuteResult {
  final int mainMinute;
  final int extraMinute;
  final String formatted;
  final bool isPeriodMarker;

  const MatchMinuteResult({
    required this.mainMinute,
    required this.extraMinute,
    required this.formatted,
    this.isPeriodMarker = false,
  });

  double get sortWeight => mainMinute + (extraMinute / 100.0);

  @override
  String toString() =>
      'MatchMinuteResult(main: $mainMinute, extra: $extraMinute, formatted: $formatted)';
}

class MatchMinuteParser {
  MatchMinuteParser._();

  // Matches patterns like "82’", "82'", "90’ +4", "90 + 4", "45+2", "45’ + 2’", "14"
  static final RegExp _minuteRegex = RegExp(
    r'(\d+)\s*(?:[\u2019\u0027\u201D\u0022\u2018\u201C]|\s)*\s*(?:\+\s*(\d+))?',
  );

  static MatchMinuteResult parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const MatchMinuteResult(
        mainMinute: 0,
        extraMinute: 0,
        formatted: '',
      );
    }

    final trimmed = raw.trim();

    // Check if it's a score like "1 - 0" or period marker
    if (trimmed.contains('-') && !trimmed.startsWith('-')) {
      return const MatchMinuteResult(
        mainMinute: 0,
        extraMinute: 0,
        formatted: '',
        isPeriodMarker: true,
      );
    }

    final match = _minuteRegex.firstMatch(trimmed);
    if (match != null) {
      final mainStr = match.group(1);
      final extraStr = match.group(2);

      final mainMin = int.tryParse(mainStr ?? '') ?? 0;
      final extraMin = extraStr != null ? (int.tryParse(extraStr) ?? 0) : 0;

      String formatted = '$mainMin';
      if (extraMin > 0) {
        formatted += '+$extraMin';
      }

      return MatchMinuteResult(
        mainMinute: mainMin,
        extraMinute: extraMin,
        formatted: formatted,
      );
    }

    return const MatchMinuteResult(
      mainMinute: 0,
      extraMinute: 0,
      formatted: '',
    );
  }
}
