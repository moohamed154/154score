import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/animated_score_text.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/penalty_shootout_widget.dart';
import '../../../../core/widgets/status_pill.dart';
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
    final isLive = ScoreHelper.isLiveStatus(match.status);
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final score1Str = ScoreHelper.normalizeScore(match.score1);
    final score2Str = ScoreHelper.normalizeScore(match.score2);

    final hasPenalties = match.hasPenalties;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F7FF))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isLive
              ? AppColors.liveRed.withValues(alpha: 0.35)
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
              vertical: 10,
            ),
            child: Row(
              children: [
                // Home Team
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      onTap: () {
                        final tId = Uri.encodeComponent(match.team1);
                        context.push(
                          '/team/$tId',
                          extra: {
                            'name': match.team1,
                            'logo': match.team1Logo,
                            'leagueId': match.leagueId,
                          },
                        );
                      },
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
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmall ? 13 : 14,
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
                  ),
                ),

                // Center Score & Status
                Container(
                  constraints: BoxConstraints(minWidth: isSmall ? 60 : 72),
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (score1Str != '-' || score2Str != '-') ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScoreText(score: score1Str, isLive: isLive),
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
                            AnimatedScoreText(score: score2Str, isLive: isLive),
                          ],
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
                      StatusPill(
                        status: match.status,
                        time: match.time,
                        compact: true,
                      ),
                    ],
                  ),
                ),

                // Away Team
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      onTap: () {
                        final tId = Uri.encodeComponent(match.team2);
                        context.push(
                          '/team/$tId',
                          extra: {
                            'name': match.team2,
                            'logo': match.team2Logo,
                            'leagueId': match.leagueId,
                          },
                        );
                      },
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
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmall ? 13 : 14,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
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
