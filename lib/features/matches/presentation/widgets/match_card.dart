import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/animated_score_text.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/live_match_clock.dart';
import '../../../../core/widgets/penalty_shootout_widget.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback? onFavoriteTap;

  const MatchCard({super.key, required this.match, this.onFavoriteTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final phase = MatchStatusHelper.parseStatus(match.status, time: match.time);
    final isLive = MatchStatusHelper.isLive(phase);
    final isUpcoming = MatchStatusHelper.isUpcoming(phase);

    final score1Str = ScoreHelper.normalizeScore(match.score1);
    final score2Str = ScoreHelper.normalizeScore(match.score2);
    final hasScores = score1Str != '-' && score2Str != '-';
    final hasPenalties = match.hasPenalties;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? (isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F7FF))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isLive
              ? AppColors.liveRed.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isLive ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          onTap: () {
            context.push(
              '/match/${Uri.encodeComponent(match.id)}',
              extra: match,
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 12,
              vertical: isSmall ? 8 : 10,
            ),
            child: Row(
              children: [
                // Home Team
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.team1,
                          style:
                              AppTypography.getBodyLarge(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: isLive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: isSmall ? 12 : 14,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : AppDimensions.sm),
                      AppImage(
                        imageUrl: match.team1Logo,
                        width: isSmall ? 22 : 26,
                        height: isSmall ? 22 : 26,
                        borderRadius: (isSmall ? 22 : 26) / 2,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.shield_outlined,
                      ),
                    ],
                  ),
                ),

                // Center Score & Status
                Container(
                  constraints: BoxConstraints(minWidth: isSmall ? 64 : 76),
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasScores) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection:
                              isArabic ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            AnimatedScoreText(
                              score: score1Str,
                              isLive: isLive,
                              isLarge: !isSmall,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Text(
                                ':',
                                style:
                                    AppTypography.getScoreMedium(isDark: isDark)
                                        .copyWith(
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                        ),
                              ),
                            ),
                            AnimatedScoreText(
                              score: score2Str,
                              isLive: isLive,
                              isLarge: !isSmall,
                            ),
                          ],
                        ),
                      ] else if (isUpcoming) ...[
                        Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isSmall ? 11 : 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                      if (hasPenalties) ...[
                        const SizedBox(height: 2),
                        PenaltyShootoutWidget(
                          penaltyScore1: match.penaltyScore1!,
                          penaltyScore2: match.penaltyScore2!,
                          isCompact: true,
                        ),
                      ],
                      const SizedBox(height: 2),
                      LiveMatchClock(
                        status: match.status,
                        minute: match.minute,
                        extraTime: match.extraTime,
                        time: match.time,
                        showLiveDot: true,
                        textStyle:
                            AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: isSmall ? 10 : 11,
                              color: isLive
                                  ? AppColors.liveRed
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                            ),
                      ),
                    ],
                  ),
                ),

                // Away Team
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AppImage(
                        imageUrl: match.team2Logo,
                        width: isSmall ? 22 : 26,
                        height: isSmall ? 22 : 26,
                        borderRadius: (isSmall ? 22 : 26) / 2,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.shield_outlined,
                      ),
                      SizedBox(width: isSmall ? 6 : AppDimensions.sm),
                      Flexible(
                        child: Text(
                          match.team2,
                          style:
                              AppTypography.getBodyLarge(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: isLive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: isSmall ? 12 : 14,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Star
                if (onFavoriteTap != null) ...[
                  SizedBox(width: isSmall ? 2 : 4),
                  InkWell(
                    onTap: onFavoriteTap,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        match.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: isSmall ? 18 : 20,
                        color: match.isFavorite
                            ? AppColors.yellowCard
                            : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
