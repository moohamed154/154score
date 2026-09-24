import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/match_details_entity.dart';

class MatchReturnLegCard extends StatelessWidget {
  final MatchReturnLegEntity returnLeg;
  final String? homeTeamFallback;
  final String? awayTeamFallback;
  final bool? isDark;
  final bool? isArabic;

  const MatchReturnLegCard({
    super.key,
    required this.returnLeg,
    this.homeTeamFallback,
    this.awayTeamFallback,
    this.isDark,
    this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final arabic = isArabic ?? l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final isNavigable =
        returnLeg.matchId.trim().isNotEmpty && returnLeg.matchId != '0';

    final resolvedHome =
        (returnLeg.homeTeam.isNotEmpty &&
            returnLeg.homeTeam != 'المضيف' &&
            returnLeg.homeTeam != 'Home')
        ? returnLeg.homeTeam
        : (awayTeamFallback?.isNotEmpty == true
              ? awayTeamFallback!
              : (arabic ? 'المضيف' : 'Home'));

    final resolvedAway =
        (returnLeg.awayTeam.isNotEmpty &&
            returnLeg.awayTeam != 'الضيف' &&
            returnLeg.awayTeam != 'Away')
        ? returnLeg.awayTeam
        : (homeTeamFallback?.isNotEmpty == true
              ? homeTeamFallback!
              : (arabic ? 'الضيف' : 'Away'));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isNavigable
              ? () => context.push('/match/${returnLeg.matchId}')
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge
                Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      arabic ? 'مباراة الذهاب' : 'First Leg Match',
                      style:
                          AppTypography.getBodyLarge(
                            isDark: dark,
                            isArabic: arabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                    ),
                    const Spacer(),
                    if (returnLeg.aggResult != null &&
                        returnLeg.aggResult!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          arabic
                              ? 'الإجمالي: ${returnLeg.aggResult}'
                              : 'Agg: ${returnLeg.aggResult}',
                          style:
                              AppTypography.getBodySmall(
                                isDark: dark,
                                isArabic: arabic,
                              ).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: dark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(height: 10),

                // Match Teams and Score Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        resolvedHome,
                        style: AppTypography.getBodyMedium(
                          isDark: dark,
                          isArabic: arabic,
                        ).copyWith(fontWeight: FontWeight.w600),
                        textAlign: arabic ? TextAlign.left : TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: dark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        returnLeg.scoreText,
                        style:
                            AppTypography.getBodyLarge(
                              isDark: dark,
                              isArabic: arabic,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Text(
                        resolvedAway,
                        style: AppTypography.getBodyMedium(
                          isDark: dark,
                          isArabic: arabic,
                        ).copyWith(fontWeight: FontWeight.w600),
                        textAlign: arabic ? TextAlign.right : TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNavigable) ...[
                      const SizedBox(width: 6),
                      Icon(
                        arabic
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),

                if (returnLeg.penalties != null &&
                    returnLeg.penalties!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      arabic
                          ? 'ركلات الترجيح: ${returnLeg.penalties}'
                          : 'Penalties: ${returnLeg.penalties}',
                      style:
                          AppTypography.getBodySmall(
                            isDark: dark,
                            isArabic: arabic,
                          ).copyWith(
                            color: dark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
