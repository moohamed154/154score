import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';
import '../utils/score_helper.dart';
import 'live_pulse_badge.dart';

class StatusPill extends StatelessWidget {
  final String? status;
  final String? time;
  final bool compact;

  const StatusPill({
    super.key,
    required this.status,
    this.time,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final isLive = ScoreHelper.isLiveStatus(status);
    final isFinished = ScoreHelper.isFinishedStatus(status);

    if (isLive) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.liveRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.liveRed.withOpacity(0.4), width: 0.8),
        ),
        child: LivePulseBadge(
          minute: status,
          showText: true,
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String displayText = status ?? (time ?? '-');

    if (isFinished) {
      bgColor = isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated;
      textColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    } else {
      bgColor = AppColors.statusUpcoming.withOpacity(0.15);
      textColor = AppColors.statusUpcoming;
      if (time != null && time!.isNotEmpty && time != '-') {
        displayText = time!;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        displayText,
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10 : 11,
        ),
      ),
    );
  }
}
