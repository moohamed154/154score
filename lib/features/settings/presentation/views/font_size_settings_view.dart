import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/settings_cubits.dart';

class FontSizeSettingsView extends StatelessWidget {
  const FontSizeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.translate('font_size_title'),
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: BlocBuilder<FontSizeCubit, FontSizeState>(
              builder: (context, state) {
                final cubit = context.read<FontSizeCubit>();

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.md,
                  ),
                  children: [
                    // 1. Auto Option Card
                    _buildOptionCard(
                      context: context,
                      isSelected: state.isAuto,
                      isDark: isDark,
                      isArabic: isArabic,
                      title: l10n.translate('font_size_auto'),
                      subtitle: l10n.translate('font_size_auto_desc'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        cubit.setAuto(true);
                      },
                    ),

                    const SizedBox(height: 16),

                    // 2. Manual Option Card with Sliders (as in screenshots)
                    _buildManualCard(
                      context: context,
                      state: state,
                      cubit: cubit,
                      isDark: isDark,
                      isArabic: isArabic,
                      l10n: l10n,
                    ),

                    const SizedBox(height: 24),

                    // 3. Applied Notice Card
                    _buildNoticeCard(
                      isDark: isDark,
                      isArabic: isArabic,
                      l10n: l10n,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required bool isSelected,
    required bool isDark,
    required bool isArabic,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF161F30) : AppColors.lightCard;
    final borderColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.5)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildRadioCircle(isSelected: isSelected, isDark: isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.getBodyLarge(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualCard({
    required BuildContext context,
    required FontSizeState state,
    required FontSizeCubit cubit,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    final isSelected = !state.isAuto;
    final cardBg = isDark ? const Color(0xFF161F30) : AppColors.lightCard;
    final borderColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.5)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manual Header Row (clickable)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                cubit.setAuto(false);
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildRadioCircle(isSelected: isSelected, isDark: isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.translate('font_size_manual'),
                          style: AppTypography.getBodyLarge(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.translate('font_size_manual_desc'),
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sliders Section (shown when Manual is selected, matching image 1)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isSelected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. App Font Size Section
                    Text(
                      l10n.translate('font_size_app'),
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDiscreteSlider(
                      value: state.appFontSizeScale,
                      isDark: isDark,
                      onChanged: (val) {
                        cubit.setAppFontSizeScale(val);
                      },
                    ),

                    const SizedBox(height: 24),

                    // 2. News Font Size Section
                    Text(
                      l10n.translate('font_size_news'),
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Preview Text for News
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                            : const Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        l10n.translate('font_size_preview_text'),
                        style: TextStyle(
                          fontSize: 15 * state.newsFontSizeScale,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDiscreteSlider(
                      value: state.newsFontSizeScale,
                      isDark: isDark,
                      onChanged: (val) {
                        cubit.setNewsFontSizeScale(val);
                      },
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscreteSlider({
    required double value,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    final clampedValue = value.clamp(0.80, 1.30);
    final mutedLabelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        // Small A
        Text(
          'A',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: mutedLabelColor,
          ),
        ),
        const SizedBox(width: 8),

        // Slider with Discrete Dots
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDark
                  ? const Color(0xFF243242)
                  : const Color(0xFFE2E8F0),
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9.0,
                elevation: 3.0,
              ),
              overlayColor: AppColors.primary.withValues(alpha: 0.16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
              tickMarkShape:
                  const RoundSliderTickMarkShape(tickMarkRadius: 2.2),
              activeTickMarkColor: Colors.black.withValues(alpha: 0.35),
              inactiveTickMarkColor: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFF94A3B8),
            ),
            child: Slider(
              value: clampedValue,
              min: 0.80,
              max: 1.30,
              divisions: 10,
              onChanged: (newVal) {
                HapticFeedback.selectionClick();
                onChanged(newVal);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Large A
        Text(
          'A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: mutedLabelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioCircle({
    required bool isSelected,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8)),
          width: 2.0,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 11 : 0,
          height: isSelected ? 11 : 0,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161F30).withValues(alpha: 0.5)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDark ? AppColors.primary : AppColors.primaryDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('font_size_applied_notice'),
              style: AppTypography.getBodySmall(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
