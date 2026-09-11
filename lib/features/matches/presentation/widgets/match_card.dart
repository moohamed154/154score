import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/circular_live_clock.dart';
import '../../../../core/widgets/penalty_shootout_widget.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback? onFavoriteTap;
  final bool showLeague;

  const MatchCard({
    super.key,
    required this.match,
    this.onFavoriteTap,
    this.showLeague = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final phase = MatchStatusHelper.parseStatus(
      match.status,
      minute: match.minute,
      extraTime: match.extraTime,
      time: match.time,
      date: match.date,
      score1: match.score1,
      score2: match.score2,
    );
    final isLive = MatchStatusHelper.isLive(phase);
    final isUpcoming = MatchStatusHelper.isUpcoming(phase);
    final isFinished = MatchStatusHelper.isFinished(phase);

    final score1Str = ScoreHelper.normalizeScore(match.score1);
    final score2Str = ScoreHelper.normalizeScore(match.score2);
    final hasScores = score1Str != '-' && score2Str != '-';
    final hasPenalties = match.hasPenalties;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? (isDark ? const Color(0xFF161B26) : const Color(0xFFF0F7FF))
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 10 : 14,
                  vertical: isLive ? (isSmall ? 10 : 12) : (isSmall ? 8 : 10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showLeague &&
                        match.leagueTitle != null &&
                        match.leagueTitle!.trim().isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (match.leagueLogo != null &&
                                match.leagueLogo!.trim().isNotEmpty) ...[
                              AppImage(
                                imageUrl: match.leagueLogo,
                                width: 14,
                                height: 14,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.emoji_events_outlined,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                match.leagueTitle!,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    isLive
                        ? _buildLiveContent(
                            context,
                            isDark: isDark,
                            isArabic: isArabic,
                            isSmall: isSmall,
                            score1Str: score1Str,
                            score2Str: score2Str,
                            hasPenalties: hasPenalties,
                          )
                        : _buildDefaultContent(
                            context,
                            isDark: isDark,
                            isArabic: isArabic,
                            isSmall: isSmall,
                            isUpcoming: isUpcoming,
                            isFinished: isFinished,
                            hasScores: hasScores,
                            score1Str: score1Str,
                            score2Str: score2Str,
                            hasPenalties: hasPenalties,
                          ),
                  ],
                ),
              ),
              if (onFavoriteTap != null)
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: InkWell(
                    onTap: onFavoriteTap,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        match.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: isSmall ? 16 : 18,
                        color: match.isFavorite
                            ? AppColors.yellowCard
                            : (isDark
                                ? AppColors.darkTextMuted.withValues(alpha: 0.4)
                                : AppColors.lightTextMuted.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Live State: Home Logo & Name (top/bottom) | Score 1 | Circular Clock | Score 2 | Away Logo & Name
  Widget _buildLiveContent(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required bool isSmall,
    required String score1Str,
    required String score2Str,
    required bool hasPenalties,
  }) {
    final logoSize = isSmall ? 34.0 : 40.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Home Team (Logo on top, name below)
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                style: AppTypography.getBodyMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? 12 : 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Home Score
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
          child: Text(
            score1Str,
            style: TextStyle(
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),

        // Center Circular Live Clock & Penalties (if any)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularLiveClock(
              status: match.status,
              minute: match.minute,
              extraTime: match.extraTime,
              time: match.time,
              period: match.period,
              date: match.date,
              score1: match.score1,
              score2: match.score2,
              size: isSmall ? 48 : 56,
            ),
            if (hasPenalties) ...[
              const SizedBox(height: 3),
              PenaltyShootoutWidget(
                penaltyScore1: match.penaltyScore1!,
                penaltyScore2: match.penaltyScore2!,
                isCompact: true,
              ),
            ],
          ],
        ),

        // Away Score
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
          child: Text(
            score2Str,
            style: TextStyle(
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),

        // Away Team (Logo on top, name below)
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                style: AppTypography.getBodyMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? 12 : 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Default State (Upcoming & Finished): Horizontal Name & Logo | Center Pill | Logo & Name
  Widget _buildDefaultContent(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required bool isSmall,
    required bool isUpcoming,
    required bool isFinished,
    required bool hasScores,
    required String score1Str,
    required String score2Str,
    required bool hasPenalties,
  }) {
    final logoSize = isSmall ? 22.0 : 26.0;

    return Row(
      children: [
        // Home Team (Name on left/start, Logo on right/end next to capsule)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  match.team1,
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 12 : 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(width: isSmall ? 6 : 8),
              AppImage(
                imageUrl: match.team1Logo,
                width: logoSize,
                height: logoSize,
                borderRadius: logoSize / 2,
                fit: BoxFit.contain,
                placeholderIcon: Icons.shield_outlined,
              ),
            ],
          ),
        ),

        SizedBox(width: isSmall ? 8 : 12),

        // Center Pill Capsule
        _buildCenterPill(
          context,
          isDark: isDark,
          isArabic: isArabic,
          isSmall: isSmall,
          isUpcoming: isUpcoming,
          isFinished: isFinished,
          hasScores: hasScores,
          score1Str: score1Str,
          score2Str: score2Str,
          hasPenalties: hasPenalties,
        ),

        SizedBox(width: isSmall ? 8 : 12),

        // Away Team (Logo on left/start next to capsule, Name on right/end)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AppImage(
                imageUrl: match.team2Logo,
                width: logoSize,
                height: logoSize,
                borderRadius: logoSize / 2,
                fit: BoxFit.contain,
                placeholderIcon: Icons.shield_outlined,
              ),
              SizedBox(width: isSmall ? 6 : 8),
              Flexible(
                child: Text(
                  match.team2,
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 12 : 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Capsule Pill for upcoming match time or finished scores
  Widget _buildCenterPill(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required bool isSmall,
    required bool isUpcoming,
    required bool isFinished,
    required bool hasScores,
    required String score1Str,
    required String score2Str,
    required bool hasPenalties,
  }) {
    final pillBg = isDark
        ? const Color(0xFF1B2232)
        : const Color(0xFFEDF2F7);

    Widget content;

    if (hasScores && !isUpcoming) {
      // Finished / Result state: e.g. "3 - 3"
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score1Str,
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          Text(
            score2Str,
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      );
    } else if (isUpcoming) {
      // Upcoming state: e.g. "09:00 PM"
      final timeStr =
          (match.time != null && match.time!.isNotEmpty && match.time != '-')
              ? match.time!
              : 'VS';
      content = Text(
        timeStr,
        style: TextStyle(
          fontSize: isSmall ? 12 : 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      );
    } else {
      // Other state (e.g. postponed, cancelled)
      final statusStr = match.status ?? (match.time ?? 'VS');
      content = Text(
        statusStr,
        style: TextStyle(
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextMuted
              : AppColors.lightTextMuted,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: isSmall ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: content,
        ),
        if (isFinished) ...[
          const SizedBox(height: 2),
          Text(
            isArabic ? 'انتهت' : 'FT',
            style: TextStyle(
              fontSize: isSmall ? 9 : 10,
              fontWeight: FontWeight.w600,
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
      ],
    );
  }
}
