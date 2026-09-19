import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/core/constants/app_typography.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/utils/url_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';
import '../../bloc/match_details_bloc.dart';

/// Renders a single player node positioned tactically on the pitch board.
class PitchPlayerNode extends StatelessWidget {
  final LineupPlayerEntity player;
  final bool isHome;
  final Color? teamColor;

  const PitchPlayerNode({
    super.key,
    required this.player,
    required this.isHome,
    this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    final ringColor = teamColor ??
        (isHome ? const Color(0xFF10B981) : const Color(0xFF38BDF8));

    return Semantics(
      label: '${player.name}, #${player.number ?? '-'}, ${player.position ?? ''}',
      button: true,
      child: GestureDetector(
        onTap: () => showLineupPlayerModal(context, player),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Stack with Number, Rating, Cards, Goals, Assists, Captain & Sub Badges
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Circular Avatar with Crisp White Border
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (UrlHelper.normalizePlayerPhotoUrl(player.photo) != null &&
                            UrlHelper.isValidImageUrl(
                              UrlHelper.normalizePlayerPhotoUrl(player.photo),
                            ))
                        ? CachedNetworkImage(
                            imageUrl: UrlHelper.normalizePlayerPhotoUrl(player.photo)!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            memCacheWidth: 90,
                            memCacheHeight: 90,
                            placeholder: (_, __) => _buildFallbackJersey(ringColor),
                            errorWidget: (_, __, ___) =>
                                _buildFallbackJersey(ringColor),
                          )
                        : _buildFallbackJersey(ringColor),
                  ),
                ),

                // Goals & Assists Badges Stacked Vertically on Left Edge
                if (player.goals > 0 || player.assists > 0)
                  Positioned(
                    left: -19,
                    top: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Goals Badge (e.g. "2 ⚽" or "⚽")
                        if (player.goals > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: player.goals > 1 ? 4.0 : 2.5,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.7,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (player.goals > 1) ...[
                                  Text(
                                    '${player.goals}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 2.5),
                                ],
                                const Icon(
                                  Icons.sports_soccer_rounded,
                                  size: 11,
                                  color: Color(0xFF34D399),
                                ),
                              ],
                            ),
                          ),

                        if (player.goals > 0 && player.assists > 0)
                          const SizedBox(height: 2),

                        // Assists Badge (e.g. "2 👟" or "👟")
                        if (player.assists > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: player.assists > 1 ? 4.0 : 3.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.7,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (player.assists > 1) ...[
                                  Text(
                                    '${player.assists}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 2.5),
                                ],
                                const CustomPaint(
                                  size: Size(11, 7.5),
                                  painter: FootballBootPainter(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                // Yellow / Red Card Badge (Top-Left)
                if (player.redCards > 0)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 7.5,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(1.5),
                        border: Border.all(color: Colors.white, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (player.yellowCards > 0)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 7.5,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        borderRadius: BorderRadius.circular(1.5),
                        border: Border.all(color: Colors.white, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Captain 'C' Badge
                if (player.isCaptain)
                  Positioned(
                    top: (player.yellowCards > 0 || player.redCards > 0) ? 9 : -2,
                    left: -3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isArabic ? 'ق' : 'C',
                        style: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                // Man of the Match Star Badge
                if (player.isManOfMatch)
                  Positioned(
                    top: -5,
                    right: player.number != null ? 10 : -2,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),

                // Player Jersey Number Badge (Top-Right)
                if (player.number != null)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: player.isGoalkeeper
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${player.number}',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                // Rating Pill (Bottom-Right)
                if (player.rating != null &&
                    player.rating!.isNotEmpty &&
                    player.rating != '0' &&
                    player.rating != '-')
                  Positioned(
                    bottom: -2,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(player.rating!),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        player.rating!,
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                // Substitution Swap Indicator (Bottom-Left)
                if (player.substituteOut || player.substituteIn)
                  Positioned(
                    bottom: -3,
                    left: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 0.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 7.5,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 1),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 7.5,
                            color: Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Player Short Name Tag (Matches screenshot dark capsule with short name)
            Container(
              constraints: const BoxConstraints(maxWidth: 84),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                player.displayName.isNotEmpty
                    ? player.displayName
                    : _getShortName(player.name),
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackJersey(Color ringColor) {
    return Container(
      color: Colors.grey.shade900,
      alignment: Alignment.center,
      child: player.number != null
          ? Text(
              '${player.number}',
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: ringColor,
              ),
            )
          : const Icon(Icons.person, size: 22, color: Colors.white70),
    );
  }

  static Color _getRatingColor(String ratingStr) {
    final val = double.tryParse(ratingStr);
    if (val == null) return const Color(0xFF10B981);
    if (val >= 8.0) return const Color(0xFF38BDF8); // Sky blue
    if (val >= 7.0) return const Color(0xFF22C55E); // Green
    if (val >= 6.0) return const Color(0xFFF59E0B); // Amber / Orange
    return const Color(0xFFDC2626); // Low rating red
  }

  static String _getShortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    return parts.last;
  }
}

/// Global reusable interactive bottom sheet displaying player match performance,
/// in-game contributions (goals, assists, cards, substitutions), and MOTM highlight.
void showLineupPlayerModal(
  BuildContext context,
  LineupPlayerEntity p,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final isArabic = l10n.isArabic;

  // Query match events from MatchDetailsBloc to show specific match event minutes & details
  final playerEvents = <MatchEventEntity>[];
  try {
    final state = context.read<MatchDetailsBloc>().state;
    final cleanPName = p.name.trim().toLowerCase();
    final cleanShort = (p.shortName ?? '').trim().toLowerCase();

    for (final e in state.events) {
      if (e.isPeriodMarker) continue;
      final eName = e.playerName.trim().toLowerCase();
      final eSec = (e.secondaryPlayerName ?? '').trim().toLowerCase();

      bool isMatch = false;
      if (eName.isNotEmpty &&
          (cleanPName.contains(eName) || eName.contains(cleanPName))) {
        isMatch = true;
      } else if (cleanShort.isNotEmpty &&
          eName.isNotEmpty &&
          (cleanShort.contains(eName) || eName.contains(cleanShort))) {
        isMatch = true;
      } else if (eSec.isNotEmpty &&
          (cleanPName.contains(eSec) || eSec.contains(cleanPName))) {
        isMatch = true;
      } else if (cleanShort.isNotEmpty &&
          eSec.isNotEmpty &&
          (cleanShort.contains(eSec) || eSec.contains(cleanShort))) {
        isMatch = true;
      } else if (p.number != null &&
          (e.playerNumber == p.number || e.secondaryPlayerNumber == p.number)) {
        isMatch = true;
      }

      if (isMatch) {
        playerEvents.add(e);
      }
    }
  } catch (_) {}

  final hasContributions = p.goals > 0 ||
      p.assists > 0 ||
      p.yellowCards > 0 ||
      p.redCards > 0 ||
      p.ownGoals > 0 ||
      p.substituteIn ||
      p.substituteOut ||
      p.isManOfMatch ||
      playerEvents.isNotEmpty;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Player Header Row
                Row(
                  children: [
                    // Photo / Fallback Jersey
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: (UrlHelper.normalizePlayerPhotoUrl(p.photo) != null &&
                                UrlHelper.isValidImageUrl(
                                  UrlHelper.normalizePlayerPhotoUrl(p.photo),
                                ))
                            ? CachedNetworkImage(
                                imageUrl: UrlHelper.normalizePlayerPhotoUrl(p.photo)!,
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                                memCacheWidth: 120,
                                memCacheHeight: 120,
                                placeholder: (_, __) => _buildPlayerJerseyPlaceholder(p.number),
                                errorWidget: (_, __, ___) => _buildPlayerJerseyPlaceholder(p.number),
                              )
                            : _buildPlayerJerseyPlaceholder(p.number),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name, Position & MOTM Star
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: AppTypography.getHeadingMedium(
                                    isDark: isDark,
                                    isArabic: isArabic,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.isManOfMatch) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.5),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        isArabic ? 'رجل المباراة' : 'MOTM',
                                        style: GoogleFonts.cairo(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.detailedPosition ??
                                p.position ??
                                (p.isGoalkeeper
                                    ? (isArabic ? 'حارس المرمى' : 'Goalkeeper')
                                    : '-'),
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Number Badge
                    if (p.number != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '#${p.number}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Key Attributes Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModalAttr(
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'التقييم' : 'Rating',
                      value: p.rating ?? '-',
                      badgeColor: p.rating != null
                          ? PitchPlayerNode._getRatingColor(p.rating!)
                          : null,
                    ),
                    _buildModalAttr(
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'الحالة' : 'Status',
                      value: p.isStarter
                          ? (isArabic ? 'أساسي' : 'Starter')
                          : (isArabic ? 'بديل' : 'Substitute'),
                    ),
                    _buildModalAttr(
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'القائد' : 'Captain',
                      value: p.isCaptain
                          ? (isArabic ? 'نعم' : 'Yes')
                          : (isArabic ? 'لا' : 'No'),
                      badgeColor: p.isCaptain ? const Color(0xFFF59E0B) : null,
                    ),
                    if (p.isManOfMatch)
                      _buildModalAttr(
                        isDark: isDark,
                        isArabic: isArabic,
                        title: isArabic ? 'الأفضل' : 'MOTM',
                        value: isArabic ? '⭐ نعم' : '⭐ Yes',
                        badgeColor: const Color(0xFFF59E0B),
                      ),
                  ],
                ),

                // Player Match Contributions & Events Section
                if (hasContributions) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.sports_soccer_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic
                                  ? 'ما قدمه اللاعب في المباراة'
                                  : 'Player Match Contributions',
                              style: (isArabic
                                      ? GoogleFonts.cairo
                                      : GoogleFonts.inter)(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (p.goals > 0)
                              _buildContributionBadge(
                                icon: Icons.sports_soccer_rounded,
                                label:
                                    '${p.goals} ${p.goals == 1 ? (isArabic ? "هدف" : "Goal") : (p.goals == 2 ? (isArabic ? "هدفان" : "Goals") : (isArabic ? "أهداف" : "Goals"))}${p.goals >= 3 ? (isArabic ? " (هاتريك 🔥)" : " (Hat-trick 🔥)") : ""}',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                            if (p.assists > 0)
                              _buildContributionBadge(
                                icon: Icons.handshake_outlined,
                                label:
                                    '${p.assists} ${p.assists == 1 ? (isArabic ? "صناعة هدف" : "Assist") : (isArabic ? "صناعة أهداف" : "Assists")}',
                                color: const Color(0xFF38BDF8),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                            if (p.yellowCards > 0)
                              _buildContributionBadge(
                                icon: Icons.crop_portrait_rounded,
                                label:
                                    '${p.yellowCards} ${isArabic ? (p.yellowCards == 1 ? "بطاقة صفراء" : "بطاقات صفراء") : "Yellow Cards"}',
                                color: const Color(0xFFFACC15),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                            if (p.redCards > 0)
                              _buildContributionBadge(
                                icon: Icons.crop_portrait_rounded,
                                label: isArabic ? 'بطاقة حمراء' : 'Red Card',
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                            if (p.ownGoals > 0)
                              _buildContributionBadge(
                                icon: Icons.sports_soccer_rounded,
                                label: isArabic ? 'هدف في مرماه' : 'Own Goal',
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                            if (p.substituteOut)
                              _buildContributionBadge(
                                icon: Icons.swap_horiz_rounded,
                                label: isArabic
                                    ? 'تم استبداله${p.substituteTime != null ? " (د ${p.substituteTime}')" : ""}${p.subbedForName != null && p.subbedForName!.isNotEmpty ? " ➔ ${p.subbedForName}" : ""}'
                                    : 'Subbed Out${p.substituteTime != null ? " (${p.substituteTime}')" : ""}${p.subbedForName != null && p.subbedForName!.isNotEmpty ? " ➔ ${p.subbedForName}" : ""}',
                                color: const Color(0xFFF97316),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                            if (p.substituteIn)
                              _buildContributionBadge(
                                icon: Icons.swap_horiz_rounded,
                                label: isArabic
                                    ? 'شارك كبديل${p.substituteTime != null ? " (د ${p.substituteTime}')" : ""}${p.subbedForName != null && p.subbedForName!.isNotEmpty ? " ➔ ${p.subbedForName}" : ""}'
                                    : 'Subbed In${p.substituteTime != null ? " (${p.substituteTime}')" : ""}${p.subbedForName != null && p.subbedForName!.isNotEmpty ? " ➔ ${p.subbedForName}" : ""}',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                                isArabic: isArabic,
                              ),
                          ],
                        ),
                        if (playerEvents.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          ...playerEvents.map(
                            (e) => _buildModalTimelineRow(
                              event: e,
                              isDark: isDark,
                              isArabic: isArabic,
                              context: ctx,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic
                                ? (p.isStarter
                                    ? 'شارك كأساسي في المباراة دون أحداث مسجلة'
                                    : 'متواجد على مقاعد البدلاء دون مشاركة')
                                : (p.isStarter
                                    ? 'Started the match with no logged cards/goals'
                                    : 'Available on the substitute bench'),
                            style: (isArabic
                                    ? GoogleFonts.cairo
                                    : GoogleFonts.inter)(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final cleanName = p.name.trim();
                      if (cleanName.isNotEmpty) {
                        final pId = p.playerId ?? '0';
                        final slug = Uri.encodeComponent(
                          cleanName.replaceAll(RegExp(r'\s+'), '-'),
                        );
                        context.push('/player/$pId/$slug');
                      }
                    },
                    icon: const Icon(Icons.person_outline_rounded, size: 18),
                    label: Text(
                      isArabic ? 'الملف الشخصي للاعب' : 'View Player Profile',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildPlayerJerseyPlaceholder(int? number) {
  return Container(
    color: Colors.grey.shade900,
    alignment: Alignment.center,
    child: number != null
        ? Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          )
        : const Icon(Icons.person, size: 24, color: Colors.white70),
  );
}

Widget _buildModalAttr({
  required bool isDark,
  required bool isArabic,
  required String title,
  required String value,
  Color? badgeColor,
}) {
  return Column(
    children: [
      Text(
        title,
        style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 11,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor ??
              (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: badgeColor != null
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    ],
  );
}

Widget _buildContributionBadge({
  required IconData icon,
  required String label,
  required Color color,
  required bool isDark,
  required bool isArabic,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.20 : 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withValues(alpha: 0.45),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    ),
  );
}

Widget _buildModalTimelineRow({
  required MatchEventEntity event,
  required bool isDark,
  required bool isArabic,
  required BuildContext context,
}) {
  IconData icon;
  Color iconColor;
  String title;

  switch (event.type) {
    case 'goal':
      icon = Icons.sports_soccer_rounded;
      iconColor = const Color(0xFF10B981);
      title = isArabic ? 'هدف' : 'Goal';
      if (event.score != null && event.score!.isNotEmpty) {
        title += ' (${event.score})';
      }
      if (event.secondaryPlayerName != null &&
          event.secondaryPlayerName!.isNotEmpty) {
        title += isArabic
            ? ' • صناعة: ${event.secondaryPlayerName}'
            : ' • Assist: ${event.secondaryPlayerName}';
      }
      break;
    case 'yellow_card':
      icon = Icons.crop_portrait_rounded;
      iconColor = const Color(0xFFFACC15);
      title = isArabic ? 'بطاقة صفراء' : 'Yellow Card';
      break;
    case 'red_card':
      icon = Icons.crop_portrait_rounded;
      iconColor = const Color(0xFFEF4444);
      title = isArabic ? 'بطاقة حمراء' : 'Red Card';
      break;
    case 'substitution':
      icon = Icons.swap_horiz_rounded;
      iconColor = const Color(0xFFF97316);
      title = isArabic ? 'تبديل' : 'Substitution';
      if (event.secondaryPlayerName != null &&
          event.secondaryPlayerName!.isNotEmpty) {
        title += ' (${event.playerName} ➔ ${event.secondaryPlayerName})';
      }
      break;
    default:
      icon = Icons.sports_soccer_rounded;
      iconColor = AppColors.primary;
      title = event.playerName;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        // Minute
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "${event.minute}'",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (event.hasVideo)
          InkWell(
            onTap: () =>
                UrlHelper.navigateToVideo(context, url: event.videoUrl),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isArabic ? 'فيديو' : 'Video',
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// Custom painter rendering a vector silhouette of a football cleat/boot with studs.
class FootballBootPainter extends CustomPainter {
  final Color color;

  const FootballBootPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.15, h * 0.20);
    path.quadraticBezierTo(w * 0.05, h * 0.50, w * 0.10, h * 0.78);
    path.lineTo(w * 0.45, h * 0.78);
    path.lineTo(w * 0.88, h * 0.74);
    path.quadraticBezierTo(w * 1.02, h * 0.62, w * 0.94, h * 0.48);
    path.quadraticBezierTo(w * 0.65, h * 0.38, w * 0.40, h * 0.20);
    path.quadraticBezierTo(w * 0.28, h * 0.25, w * 0.15, h * 0.20);
    path.close();

    canvas.drawPath(path, paint);

    // Cleat studs on outsole
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.78, w * 0.12, h * 0.18),
        const Radius.circular(0.8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.60, h * 0.74, w * 0.11, h * 0.20),
        const Radius.circular(0.8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.78, h * 0.74, w * 0.11, h * 0.20),
        const Radius.circular(0.8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant FootballBootPainter oldDelegate) =>
      color != oldDelegate.color;
}
