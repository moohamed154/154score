import 'package:material_ui/material_ui.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../domain/entities/team_entity.dart';
import '../../bloc/team_state.dart';

class TeamInfoTab extends StatelessWidget {
  final TeamState state;
  final bool isDark;
  final bool isArabic;

  const TeamInfoTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final cups = profile?.cups ?? [];
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      children: [
        // 1. Trophies & Achievements (Horizontal Carousel)
        if (cups.isNotEmpty) ...[
          SectionHeader(
            title: isArabic ? 'البطولات والإنجازات' : 'Trophies & Honors',
          ),
          SizedBox(
            height: 125,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cup = cups[index];

                return InkWell(
                  onTap: cup.years.isNotEmpty
                      ? () => _showCupYearsModal(context, cup)
                      : null,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cup / Trophy image
                        Builder(
                          builder: (context) {
                            final trophyUrl =
                                (cup.logo != null && cup.logo!.isNotEmpty)
                                    ? cup.logo
                                    : (cup.cupImage != null &&
                                            !cup.cupImage!.contains('/cups/')
                                        ? cup.cupImage
                                        : null);
                            if (trophyUrl != null && trophyUrl.isNotEmpty) {
                              return AppImage(
                                imageUrl: trophyUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.emoji_events_rounded,
                              );
                            }
                            return const Icon(
                              Icons.emoji_events_rounded,
                              size: 40,
                              color: Color(0xFFEAB308),
                            );
                          },
                        ),
                        const SizedBox(height: 6),

                        Text(
                          cup.title,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),

                        Text(
                          '${cup.count} ${isArabic ? "بطولة" : "Titles"}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. Team Information Details Card
        SectionHeader(title: isArabic ? 'معلومات الفريق' : 'Team Details'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              if (profile?.country != null && profile!.country!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الدولة' : 'Country',
                  profile.country!,
                  icon: Icons.flag_outlined,
                  flagUrl: profile.countryFlag,
                ),
                const Divider(height: 16),
              ],
              if (profile?.federation != null &&
                  profile!.federation!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الاتحاد' : 'Federation',
                  profile.federation!,
                  icon: Icons.account_balance_outlined,
                ),
                const Divider(height: 16),
              ],
              if (profile?.stadiumName != null &&
                  profile!.stadiumName!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الملعب' : 'Stadium',
                  profile.stadiumName!,
                  icon: Icons.stadium_outlined,
                ),
                const Divider(height: 16),
              ],
              if (profile?.division != null &&
                  profile!.division!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الدرجة' : 'Division',
                  profile.division!,
                  icon: Icons.military_tech_outlined,
                ),
                const Divider(height: 16),
              ],
              if (profile?.worldRanking != null &&
                  profile!.worldRanking! > 0) ...[
                _buildInfoRow(
                  isArabic ? 'التصنيف العالمي' : 'World Ranking',
                  '#${profile.worldRanking}',
                  icon: Icons.public_rounded,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Team Biography / About Card
        if (profile?.about != null && profile!.about!.trim().isNotEmpty) ...[
          SectionHeader(title: isArabic ? 'نبذة عن الفريق' : 'About the Club'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              profile.about!.trim(),
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    required IconData icon,
    String? flagUrl,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
              .copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const Spacer(),
        if (flagUrl != null && flagUrl.isNotEmpty) ...[
          AppImage(
            imageUrl: flagUrl,
            width: 16,
            height: 12,
            borderRadius: 2,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          style: AppTypography.getBodyMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _showCupYearsModal(BuildContext context, TeamCupEntity cup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      final trophyUrl =
                          (cup.logo != null && cup.logo!.isNotEmpty)
                              ? cup.logo
                              : (cup.cupImage != null &&
                                      !cup.cupImage!.contains('/cups/')
                                  ? cup.cupImage
                                  : null);
                      if (trophyUrl != null && trophyUrl.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 10),
                          child: AppImage(
                            imageUrl: trophyUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.emoji_events_rounded,
                          ),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsetsDirectional.only(end: 10),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 30,
                          color: Color(0xFFEAB308),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${cup.title} (${cup.count} ${isArabic ? "ألقاب" : "titles"})',
                      style: AppTypography.getHeadingSmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cup.years.map((y) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      y,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
