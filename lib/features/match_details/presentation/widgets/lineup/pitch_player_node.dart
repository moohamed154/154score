import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/core/constants/app_typography.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/utils/url_helper.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    final ringColor = teamColor ??
        (isHome ? const Color(0xFF10B981) : const Color(0xFF38BDF8));

    return Semantics(
      label: '${player.name}, #${player.number ?? '-'}, ${player.position ?? ''}',
      button: true,
      child: GestureDetector(
        onTap: () => _showPlayerModal(context, player, isDark, isArabic),
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

  void _showPlayerModal(
    BuildContext context,
    LineupPlayerEntity p,
    bool isDark,
    bool isArabic,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    // Photo
                    Container(
                      width: 60,
                      height: 60,
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
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                memCacheWidth: 120,
                                memCacheHeight: 120,
                                placeholder: (_, __) => _buildFallbackJersey(AppColors.primary),
                                errorWidget: (_, __, ___) =>
                                    _buildFallbackJersey(AppColors.primary),
                              )
                            : _buildFallbackJersey(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name and Position
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppTypography.getHeadingMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.position ?? (p.isGoalkeeper ? 'حارس المرمى' : '-'),
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

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Key Attributes Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttr(
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'التقييم' : 'Rating',
                      value: p.rating ?? '-',
                      badgeColor: p.rating != null
                          ? _getRatingColor(p.rating!)
                          : null,
                    ),
                    _buildAttr(
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'الحالة' : 'Status',
                      value: p.isStarter
                          ? (isArabic ? 'أساسي' : 'Starter')
                          : (isArabic ? 'بديل' : 'Substitute'),
                    ),
                    _buildAttr(
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'القائد' : 'Captain',
                      value: p.isCaptain
                          ? (isArabic ? 'نعم' : 'Yes')
                          : (isArabic ? 'لا' : 'No'),
                      badgeColor: p.isCaptain ? const Color(0xFFF59E0B) : null,
                    ),
                  ],
                ),
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
                      isArabic
                          ? 'الملف الشخصي للاعب'
                          : 'View Player Profile',
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
        );
      },
    );
  }

  Widget _buildAttr({
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
            color: badgeColor ?? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: badgeColor != null ? Colors.white : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
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
