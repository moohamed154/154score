import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';

class EmptyView extends StatelessWidget {
  final String titleKey;
  final String? customMessage;
  final IconData icon;
  final Widget? actionWidget;

  const EmptyView({
    super.key,
    required this.titleKey,
    this.customMessage,
    this.icon = Icons.sports_soccer_rounded,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCardElevated,
              ),
              child: Icon(
                icon,
                size: 44,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              customMessage ?? l10n.translate(titleKey),
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionWidget != null) ...[
              const SizedBox(height: AppDimensions.lg),
              actionWidget!,
            ],
          ],
        ),
      ),
    );
  }
}
