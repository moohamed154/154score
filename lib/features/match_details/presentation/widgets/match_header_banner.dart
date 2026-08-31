import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/match_score_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../matches/domain/entities/match_entity.dart';

class MatchHeaderBanner extends StatelessWidget {
  final MatchEntity match;
  final String? liveScore1;
  final String? liveScore2;
  final String? liveStatus;
  final String? penaltyScore1;
  final String? penaltyScore2;

  const MatchHeaderBanner({
    super.key,
    required this.match,
    this.liveScore1,
    this.liveScore2,
    this.liveStatus,
    this.penaltyScore1,
    this.penaltyScore2,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);

    final s1 = liveScore1 ?? match.score1;
    final s2 = liveScore2 ?? match.score2;
    final p1 = penaltyScore1 ?? match.penaltyScore1;
    final p2 = penaltyScore2 ?? match.penaltyScore2;
    final effectiveStatus = liveStatus ?? match.status;
    final isLive = ScoreHelper.isLiveStatus(effectiveStatus);

    final logoSize = isSmall ? 40.0 : 48.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppDimensions.sm : AppDimensions.lg,
        vertical: isSmall ? AppDimensions.sm : AppDimensions.md,
      ),
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
          // Tappable League Badge
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () {
              if (match.leagueId != null || match.leagueTitle != null) {
                final lId = match.leagueId ?? '937599';
                context.push(
                  '/league/$lId',
                  extra: {'title': match.leagueTitle, 'logo': match.leagueLogo},
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (match.leagueLogo != null) ...[
                    AppImage(
                      imageUrl: match.leagueLogo,
                      width: 18,
                      height: 18,
                      borderRadius: 4,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      match.leagueTitle ?? 'Match Center',
                      style:
                          AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 11 : 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isArabic
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isSmall ? 8 : 14),

          // Teams and Score Lineup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home Team (Tappable)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          AppImage(
                            imageUrl: match.team1Logo,
                            width: logoSize,
                            height: logoSize,
                            borderRadius: logoSize / 2,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.shield_outlined,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.team1,
                            style:
                                AppTypography.getBodyLarge(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isSmall ? 13 : 15,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Center Score & Status & Penalties
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MatchScoreWidget(
                      score1: s1,
                      score2: s2,
                      penaltyScore1: p1,
                      penaltyScore2: p2,
                      halfTimeScore1: match.halfTimeScore1,
                      halfTimeScore2: match.halfTimeScore2,
                      isLive: isLive,
                      isLarge: !isSmall,
                    ),
                    const SizedBox(height: 6),
                    StatusPill(
                      status: effectiveStatus,
                      minute: match.minute,
                      extraTime: match.extraTime,
                      time: match.time,
                      compact: isSmall,
                    ),
                  ],
                ),
              ),

              // Away Team (Tappable)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          AppImage(
                            imageUrl: match.team2Logo,
                            width: logoSize,
                            height: logoSize,
                            borderRadius: logoSize / 2,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.shield_outlined,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.team2,
                            style:
                                AppTypography.getBodyLarge(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isSmall ? 13 : 15,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
