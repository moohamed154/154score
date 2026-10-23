import 'package:material_ui/material_ui.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../bloc/team_state.dart';

class TeamTransfersTab extends StatefulWidget {
  final TeamState state;
  final bool isDark;
  final bool isArabic;

  const TeamTransfersTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
  });

  @override
  State<TeamTransfersTab> createState() => _TeamTransfersTabState();
}

class _TeamTransfersTabState extends State<TeamTransfersTab> {
  int _transfersSegmentIndex = 0; // 0: Important, 1: All

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isArabic = widget.isArabic;
    final transfers = widget.state.profile?.transfers;
    final important = transfers?.important ?? [];
    final all = transfers?.all ?? [];
    final currentList = _transfersSegmentIndex == 0 ? important : all;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (important.isEmpty && all.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات انتقالات مسجلة لهذا الفريق حالياً'
            : 'No transfer data recorded for this team',
        icon: Icons.swap_horiz_rounded,
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      children: [
        // Segmented Control
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _transfersSegmentIndex = 0),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _transfersSegmentIndex == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${isArabic ? "انتقالات هامة" : "Key Transfers"} (${important.length})',
                      style: TextStyle(
                        color: _transfersSegmentIndex == 0
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _transfersSegmentIndex = 1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _transfersSegmentIndex == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${isArabic ? "جميع الانتقالات" : "All Transfers"} (${all.length})',
                      style: TextStyle(
                        color: _transfersSegmentIndex == 1
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transfer Items List
        if (currentList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                isArabic
                    ? 'لا توجد بيانات في هذا القسم'
                    : 'No transfers in this section',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
          )
        else
          ...currentList.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  // Player Header Row
                  Row(
                    children: [
                      AppImage(
                        imageUrl: item.player.photo,
                        width: 36,
                        height: 36,
                        borderRadius: 18,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.person_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.player.name,
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (item.player.position != null &&
                                item.player.position!.isNotEmpty)
                              Text(
                                item.player.position!,
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
                      // Value or Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          item.value.isNotEmpty ? '${item.value} €' : item.type,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // From Club ➔ To Club
                  Row(
                    children: [
                      // Out Club
                      Expanded(
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: item.teamOut.logo,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              placeholderIcon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.teamOut.name.isNotEmpty
                                    ? item.teamOut.name
                                    : (isArabic ? 'غير محدد' : 'N/A'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow Icon (From Club ➔ To Club, auto-mirrors in RTL)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),

                      // In Club
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                item.teamIn.name.isNotEmpty
                                    ? item.teamIn.name
                                    : (isArabic ? 'غير محدد' : 'N/A'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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
                              imageUrl: item.teamIn.logo,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              placeholderIcon: Icons.shield_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (item.dateFrom != null && item.dateFrom!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: isArabic
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Text(
                        item.dateFrom!,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
