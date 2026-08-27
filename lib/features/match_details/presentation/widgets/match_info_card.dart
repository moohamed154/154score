import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/match_details_entity.dart';

class MatchInfoCard extends StatelessWidget {
  final MatchInfoSectionEntity section;

  const MatchInfoCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final isSmall = AppDimensions.isSmallScreen(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
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
          // Section Title Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              section.section,
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const Divider(height: 1),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = section.items[index];
              final isClickable = _canNavigate(item);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isClickable
                      ? () => _handleNavigation(context, item)
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: isSmall ? 8 : 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.title,
                            style:
                                AppTypography.getBodySmall(
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
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  item.content,
                                  style:
                                      AppTypography.getBodyMedium(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ).copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isClickable
                                            ? AppColors.primary
                                            : (isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary),
                                      ),
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isClickable) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  isArabic
                                      ? Icons.chevron_left_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _canNavigate(MatchInfoItemEntity item) {
    final titleLower = item.title.toLowerCase();
    return titleLower.contains('referee') ||
        titleLower.contains('stadium') ||
        titleLower.contains('commentator') ||
        titleLower.contains('حكم') ||
        titleLower.contains('ملعب') ||
        titleLower.contains('معلق');
  }

  void _handleNavigation(BuildContext context, MatchInfoItemEntity item) {
    final titleLower = item.title.toLowerCase();
    final id = item.id ?? '1';
    final slug = item.slug ?? item.content.toLowerCase().replaceAll(' ', '-');

    if (titleLower.contains('referee') || titleLower.contains('حكم')) {
      context.push('/referee/$id/$slug');
    } else if (titleLower.contains('stadium') || titleLower.contains('ملعب')) {
      context.push('/stadium/$id/$slug');
    } else if (titleLower.contains('commentator') ||
        titleLower.contains('معلق')) {
      context.push('/commentator/$id/$slug');
    }
  }
}
