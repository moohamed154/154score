import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle getHeadingLarge({
    required bool isDark,
    required bool isArabic,
  }) {
    final color = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle getHeadingMedium({
    required bool isDark,
    required bool isArabic,
  }) {
    final color = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
    );
  }

  static TextStyle getHeadingSmall({
    required bool isDark,
    required bool isArabic,
  }) {
    final color = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.2,
    );
  }

  static TextStyle getBodyLarge({
    required bool isDark,
    required bool isArabic,
  }) {
    final color = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle getBodyMedium({
    required bool isDark,
    required bool isArabic,
  }) {
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle getBodySmall({
    required bool isDark,
    required bool isArabic,
  }) {
    final color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle getButton({required bool isDark, required bool isArabic}) {
    final color = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle getScoreLarge({required bool isDark}) {
    return GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      letterSpacing: 1.0,
    );
  }

  static TextStyle getScoreMedium({required bool isDark}) {
    return GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
    );
  }

  static TextStyle getMinuteText({required bool isLive}) {
    return GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: isLive ? const Color(0xFFFF1744) : const Color(0xFF64748B),
    );
  }
}
