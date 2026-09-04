import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/datasources/videos_remote_datasource.dart';
import '../../domain/entities/video_entity.dart';
import '../widgets/video_card.dart';

class VideoDetailsView extends StatefulWidget {
  final String videoId;
  final VideoItemEntity? initialVideo;

  const VideoDetailsView({super.key, required this.videoId, this.initialVideo});

  @override
  State<VideoDetailsView> createState() => _VideoDetailsViewState();
}

class _VideoDetailsViewState extends State<VideoDetailsView> {
  bool _isLoading = true;
  String? _errorMessage;
  VideoDetailEntity? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final lang = sl<LocalStorageService>().getLanguage();

    try {
      final dataSource = sl<VideosRemoteDataSource>();
      final detail = await dataSource.getVideoDetail(
        widget.videoId,
        lang: lang,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onWatchVideo() async {
    final l10n = AppLocalizations.of(context);
    final targetUrl =
        _detail?.videoUrl ??
        _detail?.embedUrl ??
        widget.initialVideo?.link ??
        _detail?.id;
    final thumb = _detail?.image ?? widget.initialVideo?.image;

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

    final title =
        _detail?.title ??
        widget.initialVideo?.title ??
        (isArabic ? 'ملخص المباراة' : 'Video Highlight');
    final imageUrl = _detail?.image ?? widget.initialVideo?.image;

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? ErrorView(message: _errorMessage, onRetry: _loadDetail)
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
                        onTap: _onWatchVideo,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            children: [
                              AppImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: AppDimensions.radiusLg,
                                placeholderIcon:
                                    Icons.play_circle_outline_rounded,
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
                                        color: AppColors.primary.withValues(
                                          alpha: 0.9,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.4,
                                            ),
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
                        onPressed: _onWatchVideo,
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
                          style:
                              AppTypography.getBodyLarge(
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
                      ).copyWith(fontSize: isSmall ? 16 : 18, height: 1.4),
                    ),

                    // Match info badge
                    if (_detail?.matchInfo != null &&
                        _detail!.matchInfo!.isNotEmpty) ...[
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
                                _detail!.matchInfo!,
                                style:
                                    AppTypography.getBodySmall(
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
                    if (_detail?.tags.isNotEmpty == true) ...[
                      const SizedBox(height: AppDimensions.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _detail!.tags.map((tag) {
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
                    if (_detail?.description != null &&
                        _detail!.description!.isNotEmpty) ...[
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
                          _detail!.description!,
                          style: AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(height: 1.6),
                        ),
                      ),
                    ],

                    // Related Highlights
                    if (_detail?.relatedVideos.isNotEmpty == true) ...[
                      const SizedBox(height: AppDimensions.xl),
                      Text(
                        isArabic ? 'فيديوهات ذات صلة' : 'Related Highlights',
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      ..._detail!.relatedVideos.map(
                        (rv) => VideoCard(video: rv),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
