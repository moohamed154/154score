import 'package:material_ui/material_ui.dart';

/// Helper utility for detecting Arabic text content and providing appropriate
/// TextDirection and alignment regardless of the overarching app UI language.
class TextDirectionHelper {
  TextDirectionHelper._();

  static final RegExp _arabicRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  /// Returns `true` if [text] contains any Arabic Unicode characters.
  static bool isArabic(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return _arabicRegex.hasMatch(text);
  }

  /// Returns [TextDirection.rtl] if [text] contains Arabic, otherwise [fallback].
  static TextDirection getDirection(
    String? text, {
    TextDirection fallback = TextDirection.ltr,
  }) {
    if (text == null || text.trim().isEmpty) return fallback;
    return isArabic(text) ? TextDirection.rtl : fallback;
  }

  /// Returns [TextAlign.right] for Arabic text, otherwise [fallback].
  static TextAlign getTextAlign(
    String? text, {
    TextAlign fallback = TextAlign.start,
  }) {
    if (text == null || text.trim().isEmpty) return fallback;
    return isArabic(text) ? TextAlign.right : fallback;
  }
}
