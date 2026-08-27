import 'package:flutter/material.dart';
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

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.sports_soccer,
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

    final safeWidth = (width != null && width!.isFinite && !width!.isNaN)
        ? width
        : null;
    final safeHeight = (height != null && height!.isFinite && !height!.isNaN)
        ? height
        : null;

    final safeIconSize = (safeWidth != null)
        ? (safeWidth * 0.5).clamp(14.0, 40.0)
        : 20.0;
    final safePlaceholderIconSize = (safeWidth != null)
        ? (safeWidth * 0.4).clamp(12.0, 36.0)
        : 16.0;

    final cacheW = (safeWidth != null) ? (safeWidth * 2).toInt() : null;
    final cacheH = (safeHeight != null) ? (safeHeight * 2).toInt() : null;

    final normalizedUrl = UrlHelper.normalizeImageUrl(imageUrl);

    if (normalizedUrl == null || !UrlHelper.isValidImageUrl(normalizedUrl)) {
      return Container(
        width: safeWidth,
        height: safeHeight,
        decoration: BoxDecoration(
          color: fallbackBg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(placeholderIcon, size: safeIconSize, color: iconColor),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: normalizedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: fallbackBg,
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
          color: fallbackBg,
          child: Center(
            child: Icon(placeholderIcon, size: safeIconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
