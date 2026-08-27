import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/transfer_entity.dart';

class TransferCard extends StatelessWidget {
  final TransferEntity transfer;

  const TransferCard({super.key, required this.transfer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: 6,
      ),
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
          // Player Row
          Row(
            children: [
              AppImage(
                imageUrl: transfer.playerImage,
                width: 44,
                height: 44,
                borderRadius: 22,
                placeholderIcon: Icons.person_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.playerName,
                      style: AppTypography.getBodyLarge(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transfer.playerPosition != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        transfer.playerPosition!,
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (transfer.transferPrice != null &&
                  transfer.transferPrice!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    transfer.transferPrice!,
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

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Transfer Clubs Row: From Club -> To Club
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // From Club
              Expanded(
                child: Row(
                  children: [
                    AppImage(
                      imageUrl: transfer.fromTeamImage,
                      width: 26,
                      height: 26,
                      borderRadius: 13,
                      placeholderIcon: Icons.shield_outlined,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        transfer.fromTeamName ?? 'Previous Club',
                        style:
                            AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),

              // To Club
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        transfer.toTeamName ?? 'New Club',
                        style:
                            AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppImage(
                      imageUrl: transfer.toTeamImage,
                      width: 26,
                      height: 26,
                      borderRadius: 13,
                      placeholderIcon: Icons.shield_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (transfer.transferType != null || transfer.date != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transfer.transferType ?? '',
                  style:
                      AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  transfer.date ?? '',
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
