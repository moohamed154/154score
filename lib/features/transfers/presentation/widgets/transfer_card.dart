import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/transfer_entity.dart';

class TransferCard extends StatelessWidget {
  final TransferEntity transfer;

  const TransferCard({super.key, required this.transfer});

  void _navigateToPlayer(BuildContext context) {
    if (transfer.playerName.trim().isEmpty) return;
    final pId = transfer.effectivePlayerId;
    final slug = Uri.encodeComponent(
      transfer.playerName.trim().replaceAll(RegExp(r'\s+'), '-'),
    );
    context.push(
      '/player/$pId?slug=$slug',
      extra: {
        'name': transfer.playerName,
        if (transfer.playerImage != null) 'photo': transfer.playerImage,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 5),
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Player Row (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              onTap: () => _navigateToPlayer(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  children: [
                    AppImage(
                      imageUrl: transfer.playerImage,
                      width: isSmall ? 36 : 44,
                      height: isSmall ? 36 : 44,
                      borderRadius: (isSmall ? 36 : 44) / 2,
                      placeholderIcon: Icons.person_rounded,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transfer.playerName,
                            style: AppTypography.getBodyLarge(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: isSmall ? 13 : 15,
                            ),
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
                              ).copyWith(fontSize: isSmall ? 11 : 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (transfer.transferPrice != null &&
                        transfer.transferPrice!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 6 : 8,
                          vertical: isSmall ? 3 : 4,
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
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 11 : 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Transfer Clubs Row: From Club -> To Club
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // From Club
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      onTap: () {
                        if (transfer.fromTeamName != null) {
                          final tId = Uri.encodeComponent(transfer.fromTeamName!);
                          context.push(
                            '/team/$tId',
                            extra: {
                              'name': transfer.fromTeamName,
                              'logo': transfer.fromTeamImage,
                            },
                          );
                        }
                      },
                      child: Row(
                        children: [
                          AppImage(
                            imageUrl: transfer.fromTeamImage,
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.shield_outlined,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              transfer.fromTeamName ??
                                  (isArabic ? 'النادي السابق' : 'Previous Club'),
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontSize: isSmall ? 12 : 13,
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
                  ),
                ),

                // Directional Arrow (From Club -> To Club)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),

                // To Club
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      onTap: () {
                        if (transfer.toTeamName != null) {
                          final tId = Uri.encodeComponent(transfer.toTeamName!);
                          context.push(
                            '/team/$tId',
                            extra: {
                              'name': transfer.toTeamName,
                              'logo': transfer.toTeamImage,
                            },
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              transfer.toTeamName ??
                                  (isArabic ? 'النادي الجديد' : 'New Club'),
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmall ? 12 : 13,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppImage(
                            imageUrl: transfer.toTeamImage,
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (transfer.transferType != null || transfer.date != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    transfer.transferType ?? '',
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontSize: isSmall ? 10 : 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (transfer.date != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    transfer.date!,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontSize: isSmall ? 10 : 11),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
