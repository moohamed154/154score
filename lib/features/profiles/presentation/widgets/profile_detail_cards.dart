import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/profile_entity.dart';
import '../cubit/profile_cubit.dart';

class ProfileVoiceSampleCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const ProfileVoiceSampleCard({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            isDark ? AppColors.darkCard : AppColors.lightCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'صوت المعلق' : 'Commentator Voice Sample',
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'استمع إلى عينة ونبرة التعليق الصوتي'
                      : 'Listen to commentary voice sample',
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
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              UrlHelper.launchExternalUrl(
                profile.voiceUrl,
                context: context,
                fallbackErrorMessage: isArabic
                    ? 'تعذر فتح البث الصوتي'
                    : 'Failed to open audio link',
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              isArabic ? 'استماع' : 'Listen',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHighlightsGrid extends StatelessWidget {
  final ProfileEntity profile;
  final ProfileType type;
  final bool isDark;
  final bool isArabic;

  const ProfileHighlightsGrid({
    super.key,
    required this.profile,
    required this.type,
    required this.isDark,
    required this.isArabic,
  });

  static bool hasHighlights(ProfileEntity p, ProfileType type) {
    if (type == ProfileType.coach) {
      return (p.country != null && p.country!.isNotEmpty) ||
          (p.birthDate != null && p.birthDate!.isNotEmpty) ||
          (p.currentTeam != null);
    }
    int count = 0;
    if (p.channel != null && p.channel!.isNotEmpty) count++;
    if (p.country != null && p.country!.isNotEmpty) count++;
    if (p.birthDate != null && p.birthDate!.isNotEmpty) count++;
    if (p.commentaryLanguage != null && p.commentaryLanguage!.isNotEmpty) {
      count++;
    }
    return count >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final items = <_HighlightItem>[];

    if (type == ProfileType.coach) {
      if (p.currentTeam != null) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'النادي الحالي' : 'Current Club',
            value: p.currentTeam!.name,
            icon: Icons.shield_outlined,
            flagUrl: p.currentTeam!.logo,
            color: AppColors.primary,
          ),
        );
      }
      if (p.country != null && p.country!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'الدولة / الجنسية' : 'Country',
            value: p.country!,
            icon: Icons.public_rounded,
            flagUrl: p.countryFlag,
            color: Colors.blueAccent,
          ),
        );
      }
      if (p.birthDate != null && p.birthDate!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'العمر والميلاد' : 'Birth & Age',
            value: p.birthDate!,
            icon: Icons.cake_outlined,
            color: Colors.amber,
          ),
        );
      }
      if (p.role != null && p.role!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'المنصب' : 'Role',
            value: p.role!,
            icon: Icons.sports_soccer_rounded,
            color: Colors.tealAccent,
          ),
        );
      }
    } else {
      if (p.channel != null && p.channel!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'القناة الناقلة' : 'Channel',
            value: p.channel!,
            icon: Icons.live_tv_rounded,
            color: Colors.blueAccent,
          ),
        );
      }
      if (p.country != null && p.country!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'الدولة / الجنسية' : 'Country',
            value: p.country!,
            icon: Icons.public_rounded,
            flagUrl: p.countryFlag,
            color: AppColors.primary,
          ),
        );
      }
      if (p.birthDate != null && p.birthDate!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'العمر والميلاد' : 'Birth & Age',
            value: p.birthDate!,
            icon: Icons.cake_outlined,
            color: Colors.amber,
          ),
        );
      }
      if (p.commentaryLanguage != null && p.commentaryLanguage!.isNotEmpty) {
        items.add(
          _HighlightItem(
            label: isArabic ? 'لغة التعليق' : 'Language',
            value: p.commentaryLanguage!,
            icon: Icons.translate_rounded,
            color: Colors.purpleAccent,
          ),
        );
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
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
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.flagUrl != null
                    ? Center(
                        child: AppImage(
                          imageUrl: item.flagUrl,
                          width: 22,
                          height: 15,
                          borderRadius: 2,
                        ),
                      )
                    : Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
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
                    Text(
                      item.value,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HighlightItem {
  final String label;
  final String value;
  final IconData icon;
  final String? flagUrl;
  final Color color;

  const _HighlightItem({
    required this.label,
    required this.value,
    required this.icon,
    this.flagUrl,
    required this.color,
  });
}

class ProfileSectionCard extends StatelessWidget {
  final ProfileSectionEntity section;
  final bool isDark;
  final bool isArabic;

  const ProfileSectionCard({
    super.key,
    required this.section,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final sectionIcon = _getSectionIcon(section.section);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(sectionIcon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  section.section,
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int index = 0; index < section.items.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                Builder(
                  builder: (context) {
                    final it = section.items[index];
                    final itemIcon = _getItemIcon(it.title);

                    return InkWell(
                      onTap: it.link != null && it.link!.isNotEmpty
                          ? () => UrlHelper.launchExternalUrl(
                                it.link,
                                context: context,
                              )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCardElevated
                                    : AppColors.lightCardElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                itemIcon,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: Text(
                                it.title,
                                style: AppTypography.getBodySmall(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      it.content,
                                      style: AppTypography.getBodyMedium(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ).copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: it.link != null
                                            ? AppColors.primary
                                            : null,
                                      ),
                                      textAlign: TextAlign.end,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (it.link != null &&
                                      it.link!.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static IconData _getSectionIcon(String sectionTitle) {
    final lower = sectionTitle.toLowerCase();
    if (lower.contains('بطاقة') || lower.contains('card')) {
      return Icons.badge_outlined;
    }
    if (lower.contains('حكام') || lower.contains('referee')) {
      return Icons.sports_rounded;
    }
    if (lower.contains('معلومات أخرى') || lower.contains('more info')) {
      return Icons.tune_rounded;
    }
    if (lower.contains('استاد') || lower.contains('stadium')) {
      return Icons.stadium_rounded;
    }
    return Icons.info_outline_rounded;
  }

  static IconData _getItemIcon(String itemTitle) {
    final lower = itemTitle.toLowerCase();
    if (lower.contains('قناة') || lower.contains('channel')) {
      return Icons.live_tv_rounded;
    }
    if (lower.contains('دولة') ||
        lower.contains('country') ||
        lower.contains('جنسية') ||
        lower.contains('nationality')) {
      return Icons.public_rounded;
    }
    if (lower.contains('ميلاد') ||
        lower.contains('birth') ||
        lower.contains('عمر') ||
        lower.contains('age')) {
      return Icons.cake_outlined;
    }
    if (lower.contains('لغة') || lower.contains('language')) {
      return Icons.record_voice_over_rounded;
    }
    if (lower.contains('صوت') ||
        lower.contains('voice') ||
        lower.contains('audio')) {
      return Icons.volume_up_rounded;
    }
    if (lower.contains('اسم') || lower.contains('name')) {
      return Icons.person_outline_rounded;
    }
    if (lower.contains('صفة') ||
        lower.contains('role') ||
        lower.contains('مهنة')) {
      return Icons.work_outline_rounded;
    }
    if (lower.contains('ملعب') || lower.contains('stadium')) {
      return Icons.stadium_rounded;
    }
    if (lower.contains('سعة') || lower.contains('capacity')) {
      return Icons.groups_outlined;
    }
    if (lower.contains('مدينة') || lower.contains('city')) {
      return Icons.location_on_outlined;
    }
    if (lower.contains('أرضية') || lower.contains('surface')) {
      return Icons.grass_rounded;
    }
    return Icons.info_outline_rounded;
  }
}

class ProfileResidentTeamsCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const ProfileResidentTeamsCard({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'الأندية والفرق المقيمة' : 'Home Teams & Clubs',
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < p.residentTeams.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                Builder(
                  builder: (context) {
                    final team = p.residentTeams[index];
                    return InkWell(
                      onTap: team.id.isNotEmpty
                          ? () => context.push(
                                '/team/${team.id}?slug=${Uri.encodeComponent(team.name)}',
                              )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: team.logo,
                              width: 32,
                              height: 32,
                              placeholderIcon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                team.fullName ?? team.name,
                                style: AppTypography.getBodyMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileCoachCareerCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isArabic;

  const ProfileCoachCareerCard({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final list = p.career.isNotEmpty ? p.career : p.residentTeams;
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.history_edu_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'المسيرة التدريبية' : 'Managerial Career',
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${list.length}',
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int index = 0; index < list.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                Builder(
                  builder: (context) {
                    final team = list[index];
                    return InkWell(
                      onTap: team.id.isNotEmpty && team.id != '0'
                          ? () => context.push(
                                '/team/${team.id}?slug=${Uri.encodeComponent(team.name)}',
                              )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: team.logo,
                              width: 36,
                              height: 36,
                              placeholderIcon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          team.fullName ?? team.name,
                                          style: AppTypography.getBodyMedium(
                                            isDark: isDark,
                                            isArabic: isArabic,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (team.isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            isArabic ? 'الحالي' : 'Current',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      team.role ??
                                          (isArabic
                                              ? 'المدير الفني'
                                              : 'Head Coach'),
                                      if (team.duration != null &&
                                          team.duration!.isNotEmpty)
                                        team.duration!,
                                    ].join(' • '),
                                    style: AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: isArabic,
                                    ).copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileMatchesSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final bool isDark;
  final bool isArabic;

  const ProfileMatchesSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.count,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.getBodyLarge(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTypography.getBodySmall(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
