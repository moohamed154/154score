import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:ysscores/core/widgets/live_match_clock.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/animated_score_text.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/match_entity.dart';

class LiveMatchCard extends StatelessWidget {
  final MatchEntity match;
  final double width;

  const LiveMatchCard({super.key, required this.match, this.width = 280.0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final score1Str = ScoreHelper.normalizeScore(match.score1);
    final score2Str = ScoreHelper.normalizeScore(match.score2);

    return Container(
      width: width,
      margin: const EdgeInsetsDirectional.only(end: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2838), const Color(0xFF141B24)]
              : [Colors.white, const Color(0xFFF1F6FD)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: AppColors.liveRed.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () {
            context.push(
              '/match/${Uri.encodeComponent(match.id)}',
              extra: match,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top League & Live Minute
                Row(
                  children: [
                    if (match.leagueLogo != null) ...[
                      AppImage(
                        imageUrl: match.leagueLogo,
                        width: 18,
                        height: 18,
                        borderRadius: 4,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        match.leagueTitle ?? 'Live Match',
                        style:
                            AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    LiveMatchClock(
                      status: match.status,
                      minute: match.minute,
                      extraTime: match.extraTime,
                      time: match.time,
                      period: match.period,
                      date: match.date,
                      score1: match.score1,
                      score2: match.score2,
                      showLiveDot: true,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Teams and Scores
                Column(
                  children: [
                    // Home Team Row
                    Row(
                      children: [
                        AppImage(
                          imageUrl: match.team1Logo,
                          width: 26,
                          height: 26,
                          borderRadius: 13,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.team1,
                            style:
                                AppTypography.getBodyLarge(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedScoreText(
                          score: score1Str,
                          isLive: true,
                          isLarge: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Away Team Row
                    Row(
                      children: [
                        AppImage(
                          imageUrl: match.team2Logo,
                          width: 26,
                          height: 26,
                          borderRadius: 13,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.team2,
                            style:
                                AppTypography.getBodyLarge(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedScoreText(
                          score: score2Str,
                          isLive: true,
                          isLarge: true,
                        ),
                      ],
                    ),
                    if (match.hasPenalties) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2638) : const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                        ),
                        child: Text(
                          isArabic
                              ? 'ركلات ترجيح (${match.penaltyScore1 ?? "-"} - ${match.penaltyScore2 ?? "-"})'
                              : 'Penalties (${match.penaltyScore1 ?? "-"} - ${match.penaltyScore2 ?? "-"})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
