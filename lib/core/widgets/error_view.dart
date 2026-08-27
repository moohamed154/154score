import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';

class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
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
                color: AppColors.liveRed.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 48, color: AppColors.liveRed),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              l10n.translate('error_title'),
              style: AppTypography.getHeadingMedium(
                isDark: isDark,
                isArabic: isArabic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              message ?? l10n.translate('error_network'),
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.translate('try_again')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
