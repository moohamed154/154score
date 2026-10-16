import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/onboarding_catalog.dart';

/// Max content width so the flow stays readable on tablets / landscape.
const double kOnboardingMaxWidth = 560;

/// Shared page layout: brand-gradient icon, title, subtitle and scrollable
/// content. Centered with a max width for responsive layouts.
class OnboardingPageScaffold extends StatelessWidget {
  const OnboardingPageScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.isArabic,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool isArabic;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kOnboardingMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDimensions.xxl,
            AppDimensions.lg,
            AppDimensions.xxl,
            AppDimensions.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryVariant, AppColors.primaryDark],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              Text(
                title,
                style: AppTypography.getHeadingLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                subtitle,
                style: AppTypography.getBodyMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Large selectable card used for language / theme choices.
class OnboardingChoiceCard extends StatelessWidget {
  const OnboardingChoiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.isArabic,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color:
                  selected ? AppColors.primary.withValues(alpha: 0.12) : card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: selected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.getBodyLarge(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-select chips for teams / leagues.
class OnboardingChips extends StatelessWidget {
  const OnboardingChips({
    super.key,
    required this.items,
    required this.selected,
    required this.isArabic,
    required this.isDark,
    required this.onToggle,
    this.isLeague = false,
  });

  final List<OnboardingItem> items;
  final Set<String> selected;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<OnboardingItem> onToggle;
  final bool isLeague;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: items.map((item) {
        final isSelected = selected.contains(item.ar);
        final logoUrl = isLeague
            ? UrlHelper.resolveChampionshipLogo(
                item.id ?? LeagueResolver.resolveId(item.ar),
                isDark: isDark,
              )
            : UrlHelper.resolveTeamLogo(
                item.id,
                teamName: item.ar,
              );

        Widget? avatar;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          avatar = ClipRRect(
            borderRadius: BorderRadius.circular(isLeague ? 4 : 10),
            child: AppImage(
              imageUrl: logoUrl,
              width: 20,
              height: 20,
              borderRadius: isLeague ? 4 : 10,
              fit: BoxFit.contain,
              placeholderIcon: isLeague
                  ? Icons.emoji_events_outlined
                  : Icons.shield_outlined,
            ),
          );
        }

        return FilterChip(
          avatar: avatar,
          label: Text(item.nameFor(isArabic: isArabic)),
          selected: isSelected,
          showCheckmark: isSelected,
          checkmarkColor: Colors.white,
          selectedColor: AppColors.primary,
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          labelStyle: AppTypography.getBodyMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.xs,
            vertical: AppDimensions.sm,
          ),
          onSelected: (_) => onToggle(item),
        );
      }).toList(),
    );
  }
}

/// Progress dot with animated width.
class OnboardingDot extends StatelessWidget {
  const OnboardingDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
    );
  }
}
