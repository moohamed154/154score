import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/app_colors.dart';
import '../utils/url_helper.dart';

class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.sports_soccer,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBg = isDark
        ? AppColors.darkCardElevated
        : AppColors.lightCardElevated;
    final iconColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final safeWidth =
        (width != null && width!.isFinite && !width!.isNaN && width! > 0)
        ? width
        : null;
    final safeHeight =
        (height != null && height!.isFinite && !height!.isNaN && height! > 0)
        ? height
        : null;

    final safeIconSize = (safeWidth != null)
        ? (safeWidth * 0.5).clamp(14.0, 40.0)
        : (safeHeight != null ? (safeHeight * 0.35).clamp(16.0, 48.0) : 32.0);
    final safePlaceholderIconSize = (safeWidth != null)
        ? (safeWidth * 0.4).clamp(12.0, 36.0)
        : (safeHeight != null ? (safeHeight * 0.25).clamp(14.0, 40.0) : 24.0);

    final cacheW = (safeWidth != null && safeWidth > 0)
        ? (safeWidth * 2).toInt()
        : null;
    final cacheH = (safeHeight != null && safeHeight > 0)
        ? (safeHeight * 2).toInt()
        : null;

    final normalizedUrl = UrlHelper.normalizeImageUrl(imageUrl);

    Widget imageContent;

    if (normalizedUrl == null || !UrlHelper.isValidImageUrl(normalizedUrl)) {
      imageContent = Container(
        width: safeWidth,
        height: safeHeight,
        decoration: BoxDecoration(
          color: backgroundColor ?? fallbackBg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(placeholderIcon, size: safeIconSize, color: iconColor),
        ),
      );
    } else {
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: normalizedUrl,
          width: padding == null ? width : null,
          height: padding == null ? height : null,
          fit: fit,
          memCacheWidth: cacheW,
          memCacheHeight: cacheH,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: backgroundColor ?? fallbackBg,
            child: Center(
              child: Icon(
                placeholderIcon,
                size: safePlaceholderIconSize,
                color: iconColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            color: backgroundColor ?? fallbackBg,
            child: Center(
              child: Icon(
                placeholderIcon,
                size: safeIconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      );
    }

    if (backgroundColor != null || padding != null) {
      return Container(
        width: safeWidth,
        height: safeHeight,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: imageContent,
      );
    }

    return imageContent;
  }
}
