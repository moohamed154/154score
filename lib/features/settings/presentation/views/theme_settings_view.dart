import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../cubit/settings_cubits.dart';

class ThemeSettingsView extends StatelessWidget {
  const ThemeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('theme_settings_title'),
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, currentMode) {
              return ListView(
                padding: const EdgeInsets.all(AppDimensions.lg),
                children: [
                  // 1. Intro Card
                  _buildIntroCard(
                    isDark: isDark,
                    isArabic: isArabic,
                    l10n: l10n,
                  ),

                  const SizedBox(height: 24),

                  // 2. Interactive Live Preview
                  _buildLivePreviewCard(
                    isDark: isDark,
                    isArabic: isArabic,
                    l10n: l10n,
                    currentMode: currentMode,
                  ),

                  const SizedBox(height: 28),

                  // 3. Section Title
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                    child: Text(
                      l10n.translate('settings_theme_mode'),
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // 4. Options Group Card
                  _buildOptionsCard(
                    context: context,
                    currentMode: currentMode,
                    isDark: isDark,
                    isArabic: isArabic,
                    l10n: l10n,
                  ),

                  const SizedBox(height: 24),

                  // 5. Applied Notice Card
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
    );
  }

  Widget _buildIntroCard({
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
              isDark ? AppColors.darkCard : AppColors.lightCard,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('theme_intro_title'),
                    style: AppTypography.getHeadingSmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.translate('theme_intro_desc'),
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard({
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
    required ThemeMode currentMode,
  }) {
    final modeLabel = switch (currentMode) {
      ThemeMode.dark => l10n.translate('theme_dark_title'),
      ThemeMode.light => l10n.translate('theme_light_title'),
      ThemeMode.system => l10n.translate('theme_system_title'),
    };

    final isPreviewDark = switch (currentMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => isDark,
    };

    final previewBg =
        isPreviewDark ? const Color(0xFF111726) : const Color(0xFFF8FAFC);
    final previewCardBg =
        isPreviewDark ? const Color(0xFF1E293B) : Colors.white;
    final previewBorder =
        isPreviewDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final previewText = isPreviewDark ? Colors.white : const Color(0xFF0F172A);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.remove_red_eye_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('theme_preview'),
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    modeLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.translate('theme_preview_desc'),
              style: AppTypography.getBodySmall(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Realistic 154Score Mockup Mini-Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: previewBorder, width: 1),
              ),
              child: Column(
                children: [
                  // App Bar Mini
                  Row(
                    children: [
                      AppBrandLogo(size: 24, isDark: isPreviewDark),
                      const SizedBox(width: 8),
                      Text(
                        '154Score',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: previewText,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE 78\'',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Match Card Mini
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: previewCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: previewBorder, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        // Home Team
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.shield_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isArabic ? 'ريال مدريد' : 'Real Madrid',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: previewText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPreviewDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '2 - 1',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: previewText,
                            ),
                          ),
                        ),
                        // Away Team
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  isArabic ? 'برشلونة' : 'Barcelona',
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: previewText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.shield_outlined,
                                  size: 16, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard({
    required BuildContext context,
    required ThemeMode currentMode,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            _buildThemeOptionTile(
              context: context,
              mode: ThemeMode.dark,
              currentMode: currentMode,
              icon: Icons.dark_mode_rounded,
              title: l10n.translate('theme_dark_title'),
              description: l10n.translate('theme_dark_desc'),
              badge: isArabic ? 'الأكثر طلباً' : 'Popular',
              isDark: isDark,
              isArabic: isArabic,
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            _buildThemeOptionTile(
              context: context,
              mode: ThemeMode.light,
              currentMode: currentMode,
              icon: Icons.light_mode_rounded,
              title: l10n.translate('theme_light_title'),
              description: l10n.translate('theme_light_desc'),
              badge: null,
              isDark: isDark,
              isArabic: isArabic,
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            _buildThemeOptionTile(
              context: context,
              mode: ThemeMode.system,
              currentMode: currentMode,
              icon: Icons.settings_system_daydream_rounded,
              title: l10n.translate('theme_system_title'),
              description: l10n.translate('theme_system_desc'),
              badge: isArabic ? 'تلقائي' : 'Auto',
              isDark: isDark,
              isArabic: isArabic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String title,
    required String description,
    required String? badge,
    required bool isDark,
    required bool isArabic,
  }) {
    final isSelected = mode == currentMode;
    const primary = AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            context.read<ThemeCubit>().setThemeMode(mode);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.12 : 0.06)
              : Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box with Spring Bounce Animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.22 : 0.14)
                      : (isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primary.withValues(alpha: 0.6)
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, anim, _) {
                    return Transform.scale(
                      scale: 0.95 + (anim * 0.18),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.getBodyLarge(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary)
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary.withValues(alpha: 0.18)
                                  : (isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                              border: Border.all(
                                color: isSelected
                                    ? primary.withValues(alpha: 0.4)
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              ),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? primary
                                    : (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Animated Radio Selector Circle
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ],
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
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('theme_applied_notice'),
                style: AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
