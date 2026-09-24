import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/team_entity.dart';

class TeamHeaderCard extends StatelessWidget {
  final TeamProfileEntity? profile;
  final String fallbackName;
  final String? fallbackLogo;

  const TeamHeaderCard({
    super.key,
    this.profile,
    required this.fallbackName,
    this.fallbackLogo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final name = profile?.teamName ?? fallbackName;
    final logo = profile?.teamLogo ?? fallbackLogo;
    final leagueName = profile?.leagueName;
    final leagueId = profile?.leagueId;
    final row = profile?.standingsRow;
    final form = profile?.form ?? [];

    return Container(
      margin: EdgeInsets.all(hMargin),
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Team Logo
              AppImage(
                imageUrl: logo,
                width: isSmall ? 52 : 64,
                height: isSmall ? 52 : 64,
                borderRadius: (isSmall ? 52 : 64) / 2,
                fit: BoxFit.contain,
                placeholderIcon: Icons.shield_outlined,
              ),
              const SizedBox(width: 14),

              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          AppTypography.getHeadingMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: isSmall ? 16 : 18,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Tappable League Badge & Country
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (leagueName != null && leagueName.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                            onTap: () {
                              if (leagueId != null) {
                                context.push(
                                  '/league/$leagueId',
                                  extra: {'title': leagueName},
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    leagueName,
                                    style:
                                        AppTypography.getBodySmall(
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        ).copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (profile?.country != null &&
                            profile!.country!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (profile?.countryFlag != null &&
                                    profile!.countryFlag!.isNotEmpty) ...[
                                  AppImage(
                                    imageUrl: profile!.countryFlag,
                                    width: 14,
                                    height: 10,
                                    borderRadius: 2,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  profile!.country!,
                                  style:
                                      AppTypography.getBodySmall(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ).copyWith(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Standings position & Form pills
          if (row != null || form.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Standing Rank
                if (row != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isArabic ? 'الترتيب: ' : 'Rank: ',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                      Text(
                        '#${row.position} (${row.points} ${isArabic ? "نقطة" : "pts"})',
                        style:
                            AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                      ),
                    ],
                  ),

                // Form Pills (W/D/L)
                if (form.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isArabic ? 'النتائج: ' : 'Form: ',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...form.map((res) {
                        final (color, label) = switch (res) {
                          'W' => (AppColors.primary, isArabic ? 'ف' : 'W'),
                          'D' => (
                            const Color(0xFFEAB308),
                            isArabic ? 'ت' : 'D',
                          ),
                          'L' => (AppColors.liveRed, isArabic ? 'خ' : 'L'),
                          _ => (Colors.grey, res),
                        };

                        return Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(left: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
