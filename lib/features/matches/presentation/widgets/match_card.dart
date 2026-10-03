import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/circular_live_clock.dart';
import '../../../../core/widgets/penalty_shootout_widget.dart';
import '../../../../core/widgets/starred_button.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../bloc/matches_bloc.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback? onFavoriteTap;
  final bool showLeague;
  final String? timeFormat;

  const MatchCard({
    super.key,
    required this.match,
    this.onFavoriteTap,
    this.showLeague = false,
    this.timeFormat,
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
      statusCode: match.statusCode,
      period: match.period,
      minute: match.minute,
      extraTime: match.extraTime,
      time: match.time,
      date: match.date,
      score1: match.score1,
      score2: match.score2,
      timestamp: match.timestamp,
    );
    final isLive = MatchStatusHelper.isLive(phase);
    final isUpcoming = MatchStatusHelper.isUpcoming(phase);
    final isFinished = MatchStatusHelper.isFinished(phase);

    final score1Str = ScoreHelper.normalizeScore(match.score1);
    final score2Str = ScoreHelper.normalizeScore(match.score2);
    final hasScores = score1Str != '-' && score2Str != '-';
    final hasPenalties = match.hasPenalties;

    return RepaintBoundary(
      child: Container(
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
          onLongPress: () => _showMatchOptionsBottomSheet(context),
          child: Padding(
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
        // Home Team (Logo on top, name below) - Tappable
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () {
              final targetId =
                  (match.team1Id != null && match.team1Id!.trim().isNotEmpty)
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
                  style:
                      AppTypography.getBodyMedium(
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
              matchId: match.id.replaceAll('match:', '').trim(),
              status: match.status,
              statusCode: match.statusCode,
              minute: match.minute,
              extraTime: match.extraTime,
              time: match.time,
              period: match.period,
              date: match.date,
              score1: match.score1,
              score2: match.score2,
              timestamp: match.timestamp,
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

        // Away Team (Logo on top, name below) - Tappable
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () {
              final targetId =
                  (match.team2Id != null && match.team2Id!.trim().isNotEmpty)
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
                  style:
                      AppTypography.getBodyMedium(
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
        // Home Team (Name on left/start, Logo on right/end next to capsule) - Tappable
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () {
              final targetId =
                  (match.team1Id != null && match.team1Id!.trim().isNotEmpty)
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    match.team1,
                    style:
                        AppTypography.getBodyMedium(
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

        // Away Team (Logo on left/start next to capsule, Name on right/end) - Tappable
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () {
              final targetId =
                  (match.team2Id != null && match.team2Id!.trim().isNotEmpty)
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
                    style:
                        AppTypography.getBodyMedium(
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
    final pillBg = isDark ? const Color(0xFF1B2232) : const Color(0xFFEDF2F7);

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
      String activeFormat = timeFormat ?? '24h';
      if (timeFormat == null) {
        try {
          activeFormat =
              context.select<MatchesBloc, String>((b) => b.state.timeFormat);
        } catch (_) {
          try {
            if (sl.isRegistered<LocalStorageService>()) {
              activeFormat = sl<LocalStorageService>().getTimeFormat();
            }
          } catch (_) {}
        }
      }
      final timeStr =
          (match.time != null && match.time!.isNotEmpty && match.time != '-')
          ? DateFormatter.formatDisplayTime(
              match.time!,
              timeFormat: activeFormat,
              isArabic: isArabic,
            )
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
      String activeFormat = timeFormat ?? '24h';
      if (timeFormat == null) {
        try {
          activeFormat =
              context.select<MatchesBloc, String>((b) => b.state.timeFormat);
        } catch (_) {
          try {
            if (sl.isRegistered<LocalStorageService>()) {
              activeFormat = sl<LocalStorageService>().getTimeFormat();
            }
          } catch (_) {}
        }
      }
      String statusStr = match.status ?? (match.time ?? 'VS');
      if (match.status == null ||
          match.status!.trim().isEmpty ||
          match.status == match.time ||
          match.status == 'لم تبدأ') {
        if (match.time != null && match.time!.isNotEmpty && match.time != '-') {
          statusStr = DateFormatter.formatDisplayTime(
            match.time!,
            timeFormat: activeFormat,
            isArabic: isArabic,
          );
        }
      }
      content = Text(
        statusStr,
        style: TextStyle(
          fontSize: isSmall ? 11 : 12,
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

  void _showMatchOptionsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = AppLocalizations.of(context).isArabic;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, favState) {
            final isTeam1Fav = favState.isFavoriteTeam(
              id: match.team1Id,
              name: match.team1,
            );
            final isTeam2Fav = favState.isFavoriteTeam(
              id: match.team2Id,
              name: match.team2,
            );
            final isMatchFav = favState.isFavoriteMatch(match.id);
            final isLeagueFav = match.leagueTitle != null &&
                favState.isFavoriteCompetition(
                  id: match.leagueId,
                  name: match.leagueTitle,
                );

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusXl),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.yellowCard,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'خيارات المفضلة' : 'Favorite Options',
                            style: AppTypography.getBodyLarge(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),

                    // Team 1
                    ListTile(
                      leading: AppImage(
                        imageUrl: match.team1Logo,
                        width: 28,
                        height: 28,
                        borderRadius: 14,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.shield_outlined,
                      ),
                      title: Text(
                        match.team1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isTeam1Fav
                            ? (isArabic ? 'في قائمة الفرق المفضلة' : 'In Favorite Teams')
                            : (isArabic ? 'إضافة إلى الفرق المفضلة' : 'Add to Favorite Teams'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isTeam1Fav ? AppColors.primary : null,
                        ),
                      ),
                      trailing: StarredButton(
                        isStarred: isTeam1Fav,
                        size: 24,
                        onTap: () {
                          context.read<FavoritesCubit>().toggleTeam(
                                match.team1,
                                id: match.team1Id,
                              );
                        },
                      ),
                      onTap: () {
                        context.read<FavoritesCubit>().toggleTeam(
                              match.team1,
                              id: match.team1Id,
                            );
                      },
                    ),

                    // Team 2
                    ListTile(
                      leading: AppImage(
                        imageUrl: match.team2Logo,
                        width: 28,
                        height: 28,
                        borderRadius: 14,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.shield_outlined,
                      ),
                      title: Text(
                        match.team2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isTeam2Fav
                            ? (isArabic ? 'في قائمة الفرق المفضلة' : 'In Favorite Teams')
                            : (isArabic ? 'إضافة إلى الفرق المفضلة' : 'Add to Favorite Teams'),
                        style: TextStyle(
                           fontSize: 11,
                          color: isTeam2Fav ? AppColors.primary : null,
                        ),
                      ),
                      trailing: StarredButton(
                        isStarred: isTeam2Fav,
                        size: 24,
                        onTap: () {
                          context.read<FavoritesCubit>().toggleTeam(
                                match.team2,
                                id: match.team2Id,
                              );
                        },
                      ),
                      onTap: () {
                        context.read<FavoritesCubit>().toggleTeam(
                              match.team2,
                              id: match.team2Id,
                            );
                      },
                    ),

                    // Match
                    ListTile(
                      leading: const Icon(Icons.sports_soccer_rounded, size: 24),
                      title: Text(
                        isArabic ? 'المباراة' : 'Match',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isMatchFav
                            ? (isArabic ? 'في قائمة المباريات المفضلة' : 'In Favorite Matches')
                            : (isArabic ? 'إضافة المباراة للمفضلة' : 'Add Match to Favorites'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMatchFav ? AppColors.primary : null,
                        ),
                      ),
                      trailing: StarredButton(
                        isStarred: isMatchFav,
                        size: 24,
                        onTap: () {
                          if (onFavoriteTap != null) {
                            onFavoriteTap!();
                          } else {
                            context.read<FavoritesCubit>().toggleMatch(match.id);
                          }
                        },
                      ),
                      onTap: () {
                        if (onFavoriteTap != null) {
                          onFavoriteTap!();
                        } else {
                          context.read<FavoritesCubit>().toggleMatch(match.id);
                        }
                      },
                    ),

                    // League (if available)
                    if (match.leagueTitle != null && match.leagueTitle!.isNotEmpty)
                      ListTile(
                        leading: AppImage(
                          imageUrl: match.leagueLogo,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          placeholderIcon: Icons.emoji_events_outlined,
                        ),
                        title: Text(
                          match.leagueTitle!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isLeagueFav
                              ? (isArabic ? 'في البطولات المفضلة' : 'In Favorite Competitions')
                              : (isArabic ? 'إضافة البطولة للمفضلة' : 'Add Competition to Favorites'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isLeagueFav ? AppColors.primary : null,
                          ),
                        ),
                        trailing: StarredButton(
                          isStarred: isLeagueFav,
                          size: 24,
                          onTap: () {
                            context.read<FavoritesCubit>().toggleCompetition(
                              id: match.leagueId,
                              name: match.leagueTitle,
                            );
                          },
                        ),
                        onTap: () {
                          context.read<FavoritesCubit>().toggleCompetition(
                            id: match.leagueId,
                            name: match.leagueTitle,
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
