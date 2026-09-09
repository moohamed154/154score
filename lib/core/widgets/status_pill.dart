import 'package:material_ui/material_ui.dart';
import 'package:ysscores/core/utils/match_status_helper.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';
import '../utils/score_helper.dart';
import 'live_match_clock.dart';

class StatusPill extends StatelessWidget {
  final String? status;
  final String? minute;
  final String? extraTime;
  final String? time;
  final String? period;
  final String? date;
  final String? score1;
  final String? score2;
  final bool compact;

  const StatusPill({
    super.key,
    required this.status,
    this.minute,
    this.extraTime,
    this.time,
    this.period,
    this.date,
    this.score1,
    this.score2,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final phase = MatchStatusHelper.parseStatus(
      status,
      minute: minute,
      extraTime: extraTime,
      time: time,
      date: date,
      score1: score1,
      score2: score2,
    );
    final isLive = MatchStatusHelper.isLive(phase);
    final isFinished =
        ScoreHelper.isFinishedStatus(status) || phase == MatchPhase.finished;

    if (isLive) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.liveRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: AppColors.liveRed.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: LiveMatchClock(
          status: status,
          minute: minute,
          extraTime: extraTime,
          time: time,
          period: period,
          date: date,
          score1: score1,
          score2: score2,
          showLiveDot: true,
          textStyle: TextStyle(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: AppColors.liveRed,
          ),
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String displayText = status ?? (time ?? '-');

    if (isFinished) {
      bgColor = isDark
          ? AppColors.darkCardElevated
          : AppColors.lightCardElevated;
      textColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    } else {
      bgColor = AppColors.statusUpcoming.withValues(alpha: 0.15);
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
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
            .copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
            ),
      ),
    );
  }
}
