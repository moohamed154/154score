import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/core/constants/app_typography.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
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
            // Avatar Stack with Number, Rating, and Captain Badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Circular Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (player.photo != null && player.photo!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: player.photo!,
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

                // Captain 'C' Badge
                if (player.isCaptain)
                  Positioned(
                    top: -3,
                    left: isArabic ? null : -3,
                    right: isArabic ? -3 : null,
                    child: Container(
                      width: 16.5,
                      height: 16.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                // Rating Pill (if present)
                if (player.rating != null && player.rating!.isNotEmpty)
                  Positioned(
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.5,
                        vertical: 1.2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(player.rating!),
                        borderRadius: BorderRadius.circular(6),
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
                  )
                else if (player.number != null)
                  Positioned(
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 1.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '#${player.number}',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4.5),

            // Player Short Name Tag
            Container(
              constraints: const BoxConstraints(maxWidth: 76),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Text(
                _getShortName(player.name),
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
    if (val == null) return AppColors.primary;
    if (val >= 7.2) return const Color(0xFF16A34A); // High rating green
    if (val >= 6.2) return const Color(0xFFD97706); // Mid rating amber
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
                        child: (p.photo != null && p.photo!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: p.photo!,
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
                const SizedBox(height: 12),
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
