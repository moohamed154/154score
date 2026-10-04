import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

/// Reusable application brand logo widget displaying the official 154Score
/// icon with responsive light and dark mode styling, subtle depth, and glow.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool? isDark;
  final bool withBackground;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool useRemoteBrand;

  const AppBrandLogo({
    super.key,
    this.size = 40.0,
    this.isDark,
    this.withBackground = true,
    this.borderRadius,
    this.padding,
    this.useRemoteBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.26);
    final effectivePadding = padding ?? EdgeInsets.all(size * 0.08);

    final imageWidget = Image.asset(
      'assets/icons/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: '154Score Logo',
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: effectiveRadius,
        ),
        child: Icon(
          Icons.sports_soccer_rounded,
          size: size * 0.6,
          color: Colors.black,
        ),
      ),
    );

    if (!withBackground) {
      return SizedBox(width: size, height: size, child: imageWidget);
    }

    return Container(
      width: size,
      height: size,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveIsDark ? const Color(0xFF16202C) : Colors.white,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveIsDark
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.primary.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          if (effectiveIsDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: size * 0.25,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: size * 0.20,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: imageWidget,
    );
  }
}
