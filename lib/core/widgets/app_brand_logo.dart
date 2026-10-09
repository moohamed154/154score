import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../utils/url_helper.dart';

/// Reusable application brand logo widget displaying the official 154Score
/// icon with responsive light and dark mode styling, subtle depth, and glow.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool? isDark;
  final bool withBackground;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool useRemoteBrand;

  final double? opacity;
  final Color? color;

  const AppBrandLogo({
    super.key,
    this.size = 40.0,
    this.isDark,
    this.withBackground = true,
    this.borderRadius,
    this.padding,
    this.useRemoteBrand = true,
    this.opacity,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.26);
    final effectivePadding = padding ?? EdgeInsets.all(size * 0.08);

    final localFallback = Image.asset(
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

    final logoUrl = UrlHelper.getBrandLogoUrl(isDark: effectiveIsDark);

    final imageWidget = useRemoteBrand
        ? CachedNetworkImage(
            imageUrl: logoUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            memCacheWidth: (size * 2).toInt(),
            memCacheHeight: (size * 2).toInt(),
            placeholder: (context, url) => localFallback,
            errorWidget: (context, url, error) => localFallback,
          )
        : localFallback;

    final Widget styledImage = color != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
            child: imageWidget,
          )
        : imageWidget;

    final Widget content;
    if (!withBackground) {
      content = SizedBox(width: size, height: size, child: styledImage);
    } else {
      content = Container(
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
        child: styledImage,
      );
    }

    if (opacity != null) {
      return Opacity(opacity: opacity!, child: content);
    }

    return content;
  }
}
