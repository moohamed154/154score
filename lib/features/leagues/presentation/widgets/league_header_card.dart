import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';

class LeagueHeaderCard extends StatelessWidget {
  final String title;
  final String? logo;
  final String? country;
  final String? season;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const LeagueHeaderCard({
    super.key,
    required this.title,
    this.logo,
    this.country,
    this.season,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

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
      child: Row(
        children: [
          // League Logo with high-contrast badge background
          Container(
            width: isSmall ? 52 : 64,
            height: isSmall ? 52 : 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A3447)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppImage(
              imageUrl: logo,
              fit: BoxFit.contain,
              placeholderIcon: Icons.emoji_events_outlined,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Country/Season Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
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
                if (country != null || season != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (country != null && country!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Text(
                            country!,
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (season != null && season!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Text(
                            season!,
                            style:
                                AppTypography.getBodySmall(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Favorite Button
          if (onFavoriteTap != null) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              onTap: onFavoriteTap,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: isFavorite
                      ? AppColors.yellowCard
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                  size: isSmall ? 22 : 26,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
