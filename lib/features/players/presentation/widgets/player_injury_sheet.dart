import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
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

    final sheetBg = isDark ? const Color(0xFF131927) : AppColors.lightCard;
    final cardBg = isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9);
    final borderColor =
        isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : AppColors.lightTextMuted;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row: Red Pill ("Injury details") + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isArabic ? 'تفاصيل الإصابة' : 'Injury details',
                      style: const TextStyle(
                        color: Color(0xFFFB7185),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Player Identity Row: Rounded avatar + Player Name in Mint/Cyan
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImage(
                      imageUrl: profile.photo,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playerName,
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3 Highlight Cards: Injury Type, Injury Date, Expected Return
              _buildTile(
                title: isArabic ? 'نوع الإصابة' : 'Injury type',
                value: (injury?.injury.isNotEmpty == true)
                    ? injury!.injury
                    : (isArabic ? 'إصابة غير محددة' : 'Unspecified injury'),
                cardBg: cardBg,
                borderColor: borderColor,
                mutedColor: mutedColor,
                textColor: textColor,
              ),

              const SizedBox(height: 10),

              _buildTile(
                title: isArabic ? 'تاريخ الإصابة' : 'Injury date',
                value: (injury?.injuryDate.isNotEmpty == true)
                    ? injury!.injuryDate
                    : (isArabic ? 'غير متوفر' : 'N/A'),
                cardBg: cardBg,
                borderColor: borderColor,
                mutedColor: mutedColor,
                textColor: textColor,
              ),

              const SizedBox(height: 10),

              _buildTile(
                title: isArabic ? 'العودة المتوقعة' : 'Expected return',
                value: injury?.getLocalizedReturn(isArabic: isArabic) ??
                    (isArabic ? 'غير محدد' : 'TBD'),
                cardBg: cardBg,
                borderColor: borderColor,
                mutedColor: mutedColor,
                textColor: textColor,
              ),

              const SizedBox(height: 20),

              // Injury Description Section
              Text(
                isArabic ? 'وصف الإصابة' : 'Injury description',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                (injury?.injuryDescription.isNotEmpty == true)
                    ? injury!.injuryDescription
                    : (isArabic
                        ? 'لا تتوفر تفاصيل إضافية حول الإصابة في الوقت الحالي.'
                        : 'No additional details available for this injury at this time.'),
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required String value,
    required Color cardBg,
    required Color borderColor,
    required Color mutedColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
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
