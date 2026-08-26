import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/animated_score_text.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback? onFavoriteTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isLive = ScoreHelper.isLiveStatus(match.status);

    final score1Str = ScoreHelper.normalizeScore(match.score1);
    final score2Str = ScoreHelper.normalizeScore(match.score2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F7FF))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isLive
              ? AppColors.liveRed.withOpacity(0.35)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isLive ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          onTap: () {
            context.push('/match/${Uri.encodeComponent(match.id)}', extra: match);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      AppImage(
                        imageUrl: match.team1Logo,
                        width: 26,
                        height: 26,
                        borderRadius: 13,
                        placeholderIcon: Icons.shield_outlined,
                      ),
                    ],
                  ),
                ),

                // Center Score & Status
                Container(
                  constraints: const BoxConstraints(minWidth: 76),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (score1Str != '-' || score2Str != '-') ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScoreText(score: score1Str, isLive: isLive),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                ':',
                                style: AppTypography.getScoreMedium(isDark: isDark).copyWith(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            AnimatedScoreText(score: score2Str, isLive: isLive),
                          ],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AppImage(
                        imageUrl: match.team2Logo,
                        width: 26,
                        height: 26,
                        borderRadius: 13,
                        placeholderIcon: Icons.shield_outlined,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Flexible(
                        child: Text(
                          match.team2,
                          style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onFavoriteTap,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        match.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 20,
                        color: match.isFavorite ? AppColors.yellowCard : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
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
