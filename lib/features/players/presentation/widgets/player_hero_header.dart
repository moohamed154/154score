import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/player_profile_entity.dart';
import 'player_injury_sheet.dart';

class PlayerHeroHeader extends StatelessWidget {
  final PlayerProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const PlayerHeroHeader({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = profile.cover != null && profile.cover!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cover Banner Backdrop with gradient overlay
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                      isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: hasCover
                    ? AppImage(
                        imageUrl: profile.cover,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.sports_soccer_rounded,
                      )
                    : Center(
                        child: Icon(
                          Icons.sports_soccer_rounded,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
              ),
              // Dark gradient overlay for smooth contrast
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Player Avatar overlapping the cover bottom edge
              Positioned(
                bottom: -46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        border: Border.all(color: AppColors.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: AppImage(
                          imageUrl: profile.photo,
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.person_rounded,
                        ),
                      ),
                    ),
                    // Club Jersey Number badge
                    if (profile.clubNumber != null && profile.clubNumber! > 0)
                      Positioned(
                        bottom: 0,
                        right: isArabic ? null : -2,
                        left: isArabic ? -2 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '#${profile.clubNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    // Active Injury Cross Badge on Avatar
                    if (profile.isInjured)
                      Positioned(
                        bottom: 0,
                        left: (profile.clubNumber != null &&
                                profile.clubNumber! > 0)
                            ? (isArabic ? null : -2)
                            : (isArabic ? -2 : null),
                        right: (profile.clubNumber != null &&
                                profile.clubNumber! > 0)
                            ? (isArabic ? -2 : null)
                            : (isArabic ? null : -2),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 52),

          // Player Name & Position
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  profile.name,
                  style: AppTypography.getHeadingMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.nameEn != null &&
                    profile.nameEn!.isNotEmpty &&
                    profile.nameEn != profile.name) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.nameEn!,
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: false,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          letterSpacing: 0.3,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),

                // Chips Row: Position badge, Club chip, Country chip
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Position Badge
                    if (profile.positionName.isNotEmpty ||
                        (profile.position != null &&
                            profile.position!.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sports_soccer_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              profile.positionName.isNotEmpty
                                  ? profile.positionName
                                  : profile.position!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Club Chip (Clickable to Team details)
                    if (profile.team != null && profile.team!.name.isNotEmpty)
                      InkWell(
                        onTap: () {
                          if (profile.team!.id.isNotEmpty) {
                            context.push(
                              '/team/${profile.team!.id}?slug=${Uri.encodeComponent(profile.team!.name)}',
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (profile.team!.logo != null) ...[
                                AppImage(
                                  imageUrl: profile.team!.logo,
                                  width: 16,
                                  height: 16,
                                  placeholderIcon: Icons.shield_rounded,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                profile.team!.name,
                                style: AppTypography.getBodySmall(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isArabic
                                    ? Icons.arrow_back_ios_new_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Country Flag Chip
                    if (profile.country != null &&
                        profile.country!.name.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightCardElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile.country!.flag != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: AppImage(
                                  imageUrl: profile.country!.flag,
                                  width: 18,
                                  height: 13,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              profile.country!.name,
                              style: AppTypography.getBodySmall(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Market Value & Injury Pills Row
                if (profile.marketValue != null || profile.isInjured) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Market Value Pill
                      if (profile.marketValue != null &&
                          profile.marketValue!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F2936)
                                : const Color(0xFFE6FFFA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF14B8A6)
                                  : const Color(0xFF0D9488),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.paid_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF2DD4BF)
                                    : const Color(0xFF0D9488),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isArabic
                                    ? 'القيمة السوقية: ${profile.marketValue}'
                                    : 'Market value: ${profile.marketValue}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF2DD4BF)
                                      : const Color(0xFF0D9488),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Injury Details Button
                      if (profile.isInjured)
                        InkWell(
                          onTap: () {
                            PlayerInjurySheet.show(
                              context,
                              profile: profile,
                              isDark: isDark,
                              isArabic: isArabic,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2D151F)
                                  : const Color(0xFFFFEEF2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFFF43F5E,
                                ).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isArabic
                                      ? 'تفاصيل الإصابة'
                                      : 'Injury details',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFFB7185)
                                        : const Color(0xFFE11D48),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFFFB7185)
                                      : const Color(0xFFE11D48),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
