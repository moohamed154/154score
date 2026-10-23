import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/video_entity.dart';
import '../bloc/videos_bloc.dart';
import '../widgets/video_card.dart';
import '../widgets/video_thumbnail_placeholder.dart';

class VideoDetailsView extends StatelessWidget {
  final String videoId;
  final VideoItemEntity? initialVideo;

  const VideoDetailsView({super.key, required this.videoId, this.initialVideo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoDetailCubit>(
      create: (_) => sl<VideoDetailCubit>()
        ..loadDetail(videoId: videoId, initialVideo: initialVideo),
      child: _VideoDetailsBody(videoId: videoId, initialVideo: initialVideo),
    );
  }
}

class _VideoDetailsBody extends StatelessWidget {
  final String videoId;
  final VideoItemEntity? initialVideo;

  const _VideoDetailsBody({required this.videoId, this.initialVideo});

  Future<void> _onWatchVideo(
    BuildContext context,
    VideoDetailEntity? detail,
  ) async {
    final l10n = AppLocalizations.of(context);
    final targetUrl = detail?.videoUrl ??
        detail?.embedUrl ??
        initialVideo?.link ??
        detail?.id;
    final thumb = detail?.image ?? initialVideo?.image;

    await UrlHelper.launchVideoUrl(
      targetUrl,
      thumbnail: thumb,
      context: context,
      fallbackErrorMessage: l10n.isArabic
          ? 'تعذر تشغيل هذا المقطع حالياً'
          : 'Unable to open this video highlight',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hPadding = AppDimensions.getHorizontalMargin(context);
    final isSmall = AppDimensions.isSmallScreen(context);

    return BlocBuilder<VideoDetailCubit, VideoDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final isLoading = state.isLoading;
        final errorMessage = state.errorMessage;

        final title = detail?.title ??
            initialVideo?.title ??
            (isArabic ? 'ملخص المباراة' : 'Video Highlight');
        final imageUrl = detail?.image ?? initialVideo?.image;

        final hasValidImage =
            imageUrl != null && UrlHelper.isValidImageUrl(imageUrl);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: isLoading
              ? Skeletonizer(
                  enabled: true,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPadding,
                          vertical: AppDimensions.md,
                        ),
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Skeleton.leaf(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusLg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Skeleton.leaf(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Bone.multiText(lines: 2, fontSize: 18),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              Bone.icon(size: 16),
                              SizedBox(width: 6),
                              Bone.text(words: 2, fontSize: 12),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              3,
                              (_) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Bone.text(words: 2, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : errorMessage != null
                  ? ErrorView(
                      message: errorMessage,
                      onRetry: () => context
                          .read<VideoDetailCubit>()
                          .loadDetail(
                            videoId: videoId,
                            initialVideo: initialVideo,
                          ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPadding,
                            vertical: AppDimensions.md,
                          ),
                          children: [
                            // Video Thumbnail / Player Preview with Play Action
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                              child: InkWell(
                                onTap: () => _onWatchVideo(context, detail),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    children: [
                                      if (hasValidImage)
                                        AppImage(
                                          imageUrl: imageUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          borderRadius: AppDimensions.radiusLg,
                                          placeholderIcon:
                                              Icons.play_circle_outline_rounded,
                                        )
                                      else
                                        VideoThumbnailPlaceholder(
                                          width: double.infinity,
                                          height: double.infinity,
                                          borderRadius: AppDimensions.radiusLg,
                                          isDark: isDark,
                                        ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusLg,
                                            ),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Color(0x88000000),
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                isSmall ? 12 : 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 16,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: isSmall ? 36 : 44,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppDimensions.md),

                            // Primary Action Button: "Watch Video" / "مشاهدة الفيديو"
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _onWatchVideo(context, detail),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMd,
                                    ),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 22,
                                ),
                                label: Text(
                                  l10n.translate('watch_video'),
                                  style: AppTypography.getBodyLarge(
                                    isDark: false,
                                    isArabic: isArabic,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppDimensions.lg),

                            // Title
                            Text(
                              title,
                              style: AppTypography.getHeadingMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontSize: isSmall ? 16 : 18,
                                height: 1.4,
                              ),
                            ),

                            // Match info badge
                            if (detail?.matchInfo != null &&
                                detail!.matchInfo!.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardElevated
                                      : AppColors.lightCardElevated,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_soccer_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        detail.matchInfo!,
                                        style: AppTypography.getBodySmall(
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        ).copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Tags
                            if (detail?.tags.isNotEmpty == true) ...[
                              const SizedBox(height: AppDimensions.sm),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: detail!.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightCard,
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusSm,
                                      ),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: AppTypography.getBodySmall(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            // Description
                            if (detail?.description != null &&
                                detail!.description!.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.md),
                              Container(
                                padding: const EdgeInsets.all(AppDimensions.md),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Text(
                                  detail.description!,
                                  style: AppTypography.getBodyMedium(
                                    isDark: isDark,
                                    isArabic: isArabic,
                                  ).copyWith(height: 1.6),
                                ),
                              ),
                            ],

                            // Related Highlights
                            if (detail?.relatedVideos.isNotEmpty == true) ...[
                              const SizedBox(height: AppDimensions.xl),
                              Text(
                                isArabic
                                    ? 'فيديوهات ذات صلة'
                                    : 'Related Highlights',
                                style: AppTypography.getHeadingMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: AppDimensions.sm),
                              ...detail!.relatedVideos.map(
                                (rv) => VideoCard(video: rv),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }
}
