import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/player_profile_entity.dart';

class PlayerBioCard extends StatelessWidget {
  final PlayerProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const PlayerBioCard({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_BioItem>[];

    if (profile.age != null && profile.age! > 0) {
      final ageText = isArabic ? '${profile.age} سنة' : '${profile.age} yrs';
      final subtitle = profile.birthDay ?? '';
      items.add(
        _BioItem(
          label: isArabic ? 'العمر والميلاد' : 'Age & Birth Date',
          value: ageText,
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          icon: Icons.cake_outlined,
          color: Colors.amber,
        ),
      );
    } else if (profile.birthDay != null && profile.birthDay!.isNotEmpty) {
      items.add(
        _BioItem(
          label: isArabic ? 'تاريخ الميلاد' : 'Birth Date',
          value: profile.birthDay!,
          icon: Icons.cake_outlined,
          color: Colors.amber,
        ),
      );
    }

    if (profile.height != null && profile.height! > 0) {
      items.add(
        _BioItem(
          label: isArabic ? 'الطول' : 'Height',
          value: '${profile.height} cm',
          icon: Icons.height_rounded,
          color: Colors.cyan,
        ),
      );
    }

    if (profile.weight != null && profile.weight! > 0) {
      items.add(
        _BioItem(
          label: isArabic ? 'الوزن' : 'Weight',
          value: '${profile.weight} kg',
          icon: Icons.fitness_center_rounded,
          color: Colors.orange,
        ),
      );
    }

    if (profile.footName != null && profile.footName!.isNotEmpty) {
      items.add(
        _BioItem(
          label: isArabic ? 'القدم المفضلة' : 'Preferred Foot',
          value: profile.footName!,
          icon: Icons.directions_run_rounded,
          color: Colors.green,
        ),
      );
    }

    if (profile.clubNumber != null && profile.clubNumber! > 0) {
      items.add(
        _BioItem(
          label: isArabic ? 'رقم القميص' : 'Jersey Number',
          value: '#${profile.clubNumber}',
          icon: Icons.tag_rounded,
          color: AppColors.primary,
        ),
      );
    }

    if (profile.interNumber != null && profile.interNumber! > 0) {
      items.add(
        _BioItem(
          label: isArabic ? 'الرقم الدولي' : 'International #',
          value: '#${profile.interNumber}',
          icon: Icons.flag_outlined,
          color: Colors.indigoAccent,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'البيانات الشخصية' : 'Personal Profile',
                style: AppTypography.getBodyLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final it = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.5)
                        : AppColors.lightBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: it.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(it.icon, size: 18, color: it.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            it.label,
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  it.value,
                                  style: AppTypography.getBodyMedium(
                                    isDark: isDark,
                                    isArabic: isArabic,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (it.subtitle != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${it.subtitle})',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BioItem {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _BioItem({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });
}
