import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/video_entity.dart';
import 'video_thumbnail_placeholder.dart';

class VideoCard extends StatelessWidget {
  final VideoItemEntity video;
  final bool isHorizontal;

  const VideoCard({super.key, required this.video, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hasValidImage =
        video.image != null && UrlHelper.isValidImageUrl(video.image);

    if (isHorizontal) {
      return Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () => _openVideo(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    if (hasValidImage)
                      AppImage(
                        imageUrl: video.image,
                        width: 220,
                        height: 120,
                        borderRadius: AppDimensions.radiusMd,
                        placeholderIcon: Icons.play_circle_outline_rounded,
                      )
                    else
                      VideoThumbnailPlaceholder(
                        width: 220,
                        height: 120,
                        borderRadius: AppDimensions.radiusMd,
                        isDark: isDark,
                        showBadge: false,
                      ),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    video.title,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          onTap: () => _openVideo(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (hasValidImage)
                    AppImage(
                      imageUrl: video.image,
                      width: double.infinity,
                      height: 180,
                      borderRadius: AppDimensions.radiusMd,
                      placeholderIcon: Icons.play_circle_outline_rounded,
                    )
                  else
                    VideoThumbnailPlaceholder(
                      width: double.infinity,
                      height: 180,
                      borderRadius: AppDimensions.radiusMd,
                      isDark: isDark,
                    ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: AppTypography.getBodyLarge(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.date != null && video.date!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        video.date!,
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideo(BuildContext context) {
    final safeId = video.id.trim().isNotEmpty ? video.id.trim() : 'highlight';
    context.push('/video/${Uri.encodeComponent(safeId)}', extra: video);
  }
}
