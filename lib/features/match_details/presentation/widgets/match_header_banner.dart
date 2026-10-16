import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/circular_live_clock.dart';
import '../../../../core/widgets/penalty_shootout_widget.dart';
import '../../../matches/domain/entities/match_entity.dart';

class MatchHeaderBanner extends StatelessWidget {
  final MatchEntity match;
  final String? liveScore1;
  final String? liveScore2;
  final String? liveStatus;
  final String? liveStatusCode;
  final String? liveMinute;
  final String? liveExtraTime;
  final String? livePeriod;
  final String? penaltyScore1;
  final String? penaltyScore2;
  final bool showLeagueBadge;

  const MatchHeaderBanner({
    super.key,
    required this.match,
    this.liveScore1,
    this.liveScore2,
    this.liveStatus,
    this.liveStatusCode,
    this.liveMinute,
    this.liveExtraTime,
    this.livePeriod,
    this.penaltyScore1,
    this.penaltyScore2,
    this.showLeagueBadge = false,
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
    final effectiveStatusCode = liveStatusCode ?? match.statusCode;
    final effectiveMinute = liveMinute ?? match.minute;
    final effectiveExtraTime = liveExtraTime ?? match.extraTime;
    final effectivePeriod = livePeriod ?? match.period;

    final phase = MatchStatusHelper.parseStatus(
      effectiveStatus,
      statusCode: effectiveStatusCode,
      period: effectivePeriod,
      minute: effectiveMinute,
      extraTime: effectiveExtraTime,
      time: match.time,
      date: match.date,
      score1: s1,
      score2: s2,
      timestamp: match.timestamp,
    );
    final isCancelled = MatchStatusHelper.isCancelled(phase) ||
        ScoreHelper.isCancelledStatus(effectiveStatus, effectiveStatusCode) ||
        ScoreHelper.isCancelledStatus(match.status, match.statusCode);
    final isPostponed = MatchStatusHelper.isPostponed(phase) ||
        ScoreHelper.isPostponedStatus(effectiveStatus, effectiveStatusCode) ||
        ScoreHelper.isPostponedStatus(match.status, match.statusCode);
    final isLive = !isCancelled &&
        !isPostponed &&
        (MatchStatusHelper.isLive(phase) ||
            ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode));
    final isUpcoming =
        !isCancelled && !isPostponed && MatchStatusHelper.isUpcoming(phase);
    final isFinished =
        !isCancelled && !isPostponed && MatchStatusHelper.isFinished(phase);

    final score1Str = ScoreHelper.normalizeScore(s1);
    final score2Str = ScoreHelper.normalizeScore(s2);
    final hasScores = score1Str != '-' && score2Str != '-';
    final hasPenalties = (p1 != null && p1.isNotEmpty && p1 != '-') &&
        (p2 != null && p2.isNotEmpty && p2 != '-');

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
          if (showLeagueBadge) ...[
            // Tappable League Badge
            InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              onTap: () {
                final lId = match.leagueId ??
                    LeagueResolver.resolveId(match.leagueTitle);
                if (lId != null && lId.isNotEmpty) {
                  final logo = UrlHelper.resolveChampionshipLogo(
                    lId,
                    currentLogo: match.leagueLogo,
                    isDark: isDark,
                  );
                  context.push(
                    '/league/$lId',
                    extra: {'title': match.leagueTitle, 'logo': logo},
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
                        imageUrl: UrlHelper.resolveChampionshipLogo(
                          match.leagueId ??
                              LeagueResolver.resolveId(match.leagueTitle),
                          currentLogo: match.leagueLogo,
                          isDark: isDark,
                        ),
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
                        style: AppTypography.getBodySmall(
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
          ],

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
                      final targetId = (match.team1Id != null &&
                              match.team1Id!.trim().isNotEmpty)
                          ? match.team1Id!.trim()
                          : Uri.encodeComponent(match.team1.trim());
                      context.push(
                        '/team/$targetId',
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
                            style: AppTypography.getBodyLarge(
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

              // If LIVE: Home Score
              if (isLive)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
                  child: Text(
                    score1Str,
                    style: TextStyle(
                      fontSize: isSmall ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),

              // Center Widget: CircularLiveClock (if Live) OR Center Pill (if Finished/Upcoming/Other)
              if (isLive)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularLiveClock(
                      matchId: match.id.replaceAll('match:', '').trim(),
                      status: effectiveStatus,
                      statusCode: effectiveStatusCode,
                      minute: effectiveMinute,
                      extraTime: effectiveExtraTime,
                      time: match.time,
                      period: effectivePeriod,
                      date: match.date,
                      score1: s1,
                      score2: s2,
                      timestamp: match.timestamp,
                      htTime: match.htTime,
                      size: isSmall ? 48 : 56,
                    ),
                    if (hasPenalties) ...[
                      const SizedBox(height: 3),
                      PenaltyShootoutWidget(
                        penaltyScore1: p1,
                        penaltyScore2: p2,
                        isCompact: true,
                      ),
                    ],
                  ],
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
                  child: _buildCenterPill(
                    context,
                    isDark: isDark,
                    isArabic: isArabic,
                    isSmall: isSmall,
                    isUpcoming: isUpcoming,
                    isFinished: isFinished,
                    isCancelled: isCancelled,
                    isPostponed: isPostponed,
                    hasScores: hasScores,
                    score1Str: score1Str,
                    score2Str: score2Str,
                    hasPenalties: hasPenalties,
                    p1: p1,
                    p2: p2,
                    effectiveStatus: effectiveStatus,
                  ),
                ),

              // If LIVE: Away Score
              if (isLive)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
                  child: Text(
                    score2Str,
                    style: TextStyle(
                      fontSize: isSmall ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),

              // Away Team (Tappable)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    onTap: () {
                      final targetId = (match.team2Id != null &&
                              match.team2Id!.trim().isNotEmpty)
                          ? match.team2Id!.trim()
                          : Uri.encodeComponent(match.team2.trim());
                      context.push(
                        '/team/$targetId',
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
                            style: AppTypography.getBodyLarge(
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

  Widget _buildCenterPill(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required bool isSmall,
    required bool isUpcoming,
    required bool isFinished,
    bool isCancelled = false,
    bool isPostponed = false,
    required bool hasScores,
    required String score1Str,
    required String score2Str,
    required bool hasPenalties,
    String? p1,
    String? p2,
    String? effectiveStatus,
  }) {
    final pillBg = isDark ? const Color(0xFF1B2232) : const Color(0xFFEDF2F7);

    if (isCancelled || isPostponed) {
      final timeFormat = sl<LocalStorageService>().getTimeFormat();
      final timeStr =
          (match.time != null && match.time!.isNotEmpty && match.time != '-')
              ? DateFormatter.formatDisplayTime(
                  match.time!,
                  timeFormat: timeFormat,
                  isArabic: isArabic,
                )
              : '';
      final statusLabel = isCancelled
          ? (isArabic ? 'ألغيت' : 'Canceled')
          : (isArabic ? 'تأجلت' : 'Postponed');

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (timeStr.isNotEmpty) ...[
            Text(
              timeStr,
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 18,
              vertical: isSmall ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: isCancelled
                    ? (isDark
                        ? const Color(0xFFF87171)
                        : const Color(0xFFDC2626))
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
            ),
          ),
        ],
      );
    }

    Widget content;

    if (hasScores && !isUpcoming) {
      // Finished / Result state: e.g. "3 - 3"
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score1Str,
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          Text(
            score2Str,
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
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
      final timeFormat = sl<LocalStorageService>().getTimeFormat();
      final timeStr =
          (match.time != null && match.time!.isNotEmpty && match.time != '-')
              ? DateFormatter.formatDisplayTime(
                  match.time!,
                  timeFormat: timeFormat,
                  isArabic: isArabic,
                )
              : 'VS';
      content = Text(
        timeStr,
        style: TextStyle(
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.w600,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      );
    } else {
      // Other state (e.g. postponed, cancelled)
      final statusStr = effectiveStatus ?? match.status ?? (match.time ?? 'VS');
      content = Text(
        statusStr,
        style: TextStyle(
          fontSize: isSmall ? 12 : 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 14 : 18,
            vertical: isSmall ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: content,
        ),
        if (isFinished) ...[
          const SizedBox(height: 3),
          Text(
            isArabic ? 'انتهت' : 'FT',
            style: TextStyle(
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
        if (hasPenalties && p1 != null && p2 != null) ...[
          const SizedBox(height: 3),
          PenaltyShootoutWidget(
            penaltyScore1: p1,
            penaltyScore2: p2,
            isCompact: true,
          ),
        ],
      ],
    );
  }
}
