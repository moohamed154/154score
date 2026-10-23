import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/profile_entity.dart';
import '../cubit/profile_cubit.dart';

class ProfileStadiumHeroCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const ProfileStadiumHeroCard({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
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
          if (p.image != null && p.image!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AppImage(
                imageUrl: p.image,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                placeholderIcon: Icons.stadium_rounded,
              ),
            )
          else
            Container(
              height: 140,
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              child: const Center(
                child: Icon(
                  Icons.stadium_rounded,
                  size: 58,
                  color: AppColors.primary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (p.countryFlag != null) ...[
                      const SizedBox(width: 8),
                      AppImage(
                        imageUrl: p.countryFlag,
                        width: 22,
                        height: 16,
                        borderRadius: 2,
                      ),
                    ],
                  ],
                ),
                if (p.englishName != null &&
                    p.englishName!.isNotEmpty &&
                    p.englishName != p.name) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.englishName!,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: false,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                ProfileRoleBadge(
                  icon: Icons.stadium_rounded,
                  label: p.role ??
                      (isArabic ? 'استاد كرة قدم' : 'Football Stadium'),
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePersonHeroCard extends StatelessWidget {
  final ProfileEntity profile;
  final ProfileType type;
  final bool isDark;
  final bool isArabic;

  const ProfilePersonHeroCard({
    super.key,
    required this.profile,
    required this.type,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final roleText = p.role ??
        (type == ProfileType.referee
            ? (isArabic ? 'حكم كرة قدم' : 'Football Referee')
            : type == ProfileType.coach
                ? (isArabic ? 'المدير الفني' : 'Head Coach')
                : type == ProfileType.player
                    ? (isArabic ? 'لاعب كرة قدم' : 'Football Player')
                    : (isArabic ? 'معلق رياضي' : 'Sports Commentator'));

    final placeholderIcon = type == ProfileType.referee
        ? Icons.sports_rounded
        : type == ProfileType.coach
            ? Icons.sports_soccer_rounded
            : type == ProfileType.player
                ? Icons.person_rounded
                : Icons.mic_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            isDark ? AppColors.darkCard : AppColors.lightCard,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: AppImage(
                imageUrl: p.image,
                width: 100,
                height: 100,
                placeholderIcon: placeholderIcon,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            p.name,
            style: AppTypography.getHeadingLarge(
              isDark: isDark,
              isArabic: isArabic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (p.englishName != null &&
              p.englishName!.isNotEmpty &&
              p.englishName != p.name) ...[
            const SizedBox(height: 4),
            Text(
              p.englishName!,
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: false,
              ).copyWith(
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ProfileRoleBadge(
                icon: placeholderIcon,
                label: roleText,
                color: AppColors.primary,
                isDark: isDark,
              ),
              if (p.currentTeam != null)
                ProfileRoleBadge(
                  flagUrl: p.currentTeam!.logo,
                  icon: Icons.shield_outlined,
                  label: p.currentTeam!.name,
                  color: Colors.tealAccent,
                  isDark: isDark,
                ),
              if (p.channel != null && p.channel!.isNotEmpty)
                ProfileRoleBadge(
                  icon: Icons.live_tv_rounded,
                  label: p.channel!,
                  color: Colors.blueAccent,
                  isDark: isDark,
                ),
              if (p.country != null && p.country!.isNotEmpty)
                ProfileRoleBadge(
                  flagUrl: p.countryFlag,
                  icon: Icons.public_rounded,
                  label: p.country!,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileRoleBadge extends StatelessWidget {
  final IconData? icon;
  final String? flagUrl;
  final String label;
  final Color color;
  final bool isDark;

  const ProfileRoleBadge({
    super.key,
    this.icon,
    this.flagUrl,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flagUrl != null && flagUrl!.isNotEmpty) ...[
            AppImage(
              imageUrl: flagUrl,
              width: 16,
              height: 11,
              borderRadius: 2,
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
