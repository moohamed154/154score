import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/player_profile_entity.dart';

class PlayerInjurySheet extends StatelessWidget {
  final PlayerProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const PlayerInjurySheet({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  static Future<void> show(
    BuildContext context, {
    required PlayerProfileEntity profile,
    required bool isDark,
    required bool isArabic,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlayerInjurySheet(
        profile: profile,
        isDark: isDark,
        isArabic: isArabic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final injury = profile.injury;
    final playerName = (injury?.player != null && injury!.player!.isNotEmpty)
        ? injury.player!
        : profile.name;

    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Row: Icon + Title + Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: isDark ? 0.18 : 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            size: 17,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isArabic ? 'تفاصيل الإصابة' : 'Injury Details',
                          style: (isArabic
                                  ? GoogleFonts.cairo
                                  : GoogleFonts.inter)(
                            color: primaryTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: mutedTextColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Player Identity Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImage(
                              imageUrl: profile.photo,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholderIcon: Icons.person_rounded,
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: isArabic ? null : -2,
                            left: isArabic ? -2 : null,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              playerName,
                              style: (isArabic
                                      ? GoogleFonts.cairo
                                      : GoogleFonts.inter)(
                                color: primaryTextColor,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (profile.clubNumber != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: isDark ? 0.2 : 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${profile.clubNumber}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.primary
                                            : const Color(0xFF00963E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (profile.positionName.isNotEmpty ||
                                    profile.position != null) ...[
                                  Flexible(
                                    child: Text(
                                      profile.positionName.isNotEmpty
                                          ? profile.positionName
                                          : profile.position!,
                                      style: (isArabic
                                              ? GoogleFonts.cairo
                                              : GoogleFonts.inter)(
                                        color: mutedTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                if (profile.team != null &&
                                    profile.team!.name.isNotEmpty) ...[
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      color: mutedTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      profile.team!.name,
                                      style: (isArabic
                                              ? GoogleFonts.cairo
                                              : GoogleFonts.inter)(
                                        color: mutedTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isArabic ? 'مصاب' : 'Injured',
                              style: (isArabic
                                      ? GoogleFonts.cairo
                                      : GoogleFonts.inter)(
                                color: isDark
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFFE11D48),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3 Detail Tiles: Injury Type, Injury Date, Expected Return
                _buildDetailTile(
                  icon: Icons.healing_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: isArabic ? 'نوع الإصابة' : 'Injury type',
                  value: (injury?.injury.isNotEmpty == true)
                      ? injury!.injury
                      : (isArabic ? 'إصابة غير محددة' : 'Unspecified injury'),
                  cardBg: cardBg,
                  borderColor: cardBorder,
                  mutedColor: mutedTextColor,
                  textColor: primaryTextColor,
                  isArabic: isArabic,
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                _buildDetailTile(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: isArabic ? 'تاريخ الإصابة' : 'Injury date',
                  value: (injury?.injuryDate.isNotEmpty == true)
                      ? injury!.injuryDate
                      : (isArabic ? 'غير متوفر' : 'N/A'),
                  cardBg: cardBg,
                  borderColor: cardBorder,
                  mutedColor: mutedTextColor,
                  textColor: primaryTextColor,
                  isArabic: isArabic,
                  isDark: isDark,
                  useOutfitForValue: true,
                ),

                const SizedBox(height: 8),

                _buildDetailTile(
                  icon: Icons.event_available_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: isArabic ? 'العودة المتوقعة' : 'Expected return',
                  value: injury?.getLocalizedReturn(isArabic: isArabic) ??
                      (isArabic ? 'غير محدد' : 'TBD'),
                  cardBg: cardBg,
                  borderColor: cardBorder,
                  mutedColor: mutedTextColor,
                  textColor: primaryTextColor,
                  isArabic: isArabic,
                  isDark: isDark,
                  highlightPill: true,
                ),

                const SizedBox(height: 16),

                // Injury Description Section
                Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 17,
                      color: mutedTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'وصف الإصابة' : 'Injury description',
                      style: (isArabic
                              ? GoogleFonts.cairo
                              : GoogleFonts.inter)(
                        color: primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Text(
                    (injury?.injuryDescription.isNotEmpty == true)
                        ? injury!.injuryDescription
                        : (isArabic
                            ? 'لا تتوفر تفاصيل إضافية حول الإصابة في الوقت الحالي.'
                            : 'No additional details available for this injury at this time.'),
                    style: (isArabic
                            ? GoogleFonts.cairo
                            : GoogleFonts.inter)(
                      color: (injury?.injuryDescription.isNotEmpty == true)
                          ? primaryTextColor
                          : mutedTextColor,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color cardBg,
    required Color borderColor,
    required Color mutedColor,
    required Color textColor,
    required bool isArabic,
    required bool isDark,
    bool useOutfitForValue = false,
    bool highlightPill = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
              color: mutedColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (highlightPill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B)
                    .withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                value,
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFD97706),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                style: useOutfitForValue
                    ? GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      )
                    : (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
