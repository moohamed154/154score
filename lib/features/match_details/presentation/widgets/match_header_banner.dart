import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/animated_score_text.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../matches/domain/entities/match_entity.dart';

class MatchHeaderBanner extends StatelessWidget {
  final MatchEntity match;
  final String? liveScore1;
  final String? liveScore2;
  final String? liveStatus;

  const MatchHeaderBanner({
    super.key,
    required this.match,
    this.liveScore1,
    this.liveScore2,
    this.liveStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final effectiveStatus = liveStatus ?? match.status;
    final isLive = ScoreHelper.isLiveStatus(effectiveStatus);

    final score1Str = ScoreHelper.normalizeScore(liveScore1 ?? match.score1);
    final score2Str = ScoreHelper.normalizeScore(liveScore2 ?? match.score2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // League Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (match.leagueLogo != null) ...[
                AppImage(
                  imageUrl: match.leagueLogo,
                  width: 20,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                match.leagueTitle ?? 'Match Center',
                style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Teams and Score Lineup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    AppImage(
                      imageUrl: match.team1Logo,
                      width: 52,
                      height: 52,
                      borderRadius: 26,
                      placeholderIcon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.team1,
                      style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Center Score & Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScoreText(score: score1Str, isLarge: true, isLive: isLive),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: AppTypography.getScoreLarge(isDark: isDark).copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        AnimatedScoreText(score: score2Str, isLarge: true, isLive: isLive),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StatusPill(
                      status: effectiveStatus,
                      time: match.time,
                    ),
                  ],
                ),
              ),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    AppImage(
                      imageUrl: match.team2Logo,
                      width: 52,
                      height: 52,
                      borderRadius: 26,
                      placeholderIcon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.team2,
                      style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
