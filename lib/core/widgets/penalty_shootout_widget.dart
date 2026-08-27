import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';

class PenaltyShootoutWidget extends StatelessWidget {
  final String penaltyScore1;
  final String penaltyScore2;
  final bool isCompact;

  const PenaltyShootoutWidget({
    super.key,
    required this.penaltyScore1,
    required this.penaltyScore2,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final title = isCompact
        ? (isArabic ? 'ر.ت' : 'PEN')
        : (isArabic ? 'ركلات الترجيح' : 'Penalty Shootout');

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$title ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.accent : const Color(0xFF0070BA),
              ),
            ),
            Text(
              '$penaltyScore1 - $penaltyScore2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFB9DCFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_soccer_rounded,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Text(
            '$title: ',
            style:
                AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isDark ? AppColors.accent : const Color(0xFF0070BA),
                ),
          ),
          Text(
            '$penaltyScore1 : $penaltyScore2',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
