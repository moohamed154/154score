import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hPadding = AppDimensions.getHorizontalMargin(context);

    final title =
        _detail?.title ?? widget.initialVideo?.title ?? 'Video Highlight';

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
          : ListView(
              padding: EdgeInsets.all(hPadding),
              children: [
                // Video Thumbnail / Player Preview
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      AppImage(
                        imageUrl: widget.initialVideo?.image,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: AppDimensions.radiusLg,
                        placeholderIcon: Icons.play_circle_outline_rounded,
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: Color(0x99000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.lg),

                // Title
                Text(
                  title,
                  style: AppTypography.getHeadingMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),

                if (_detail?.matchInfo != null) ...[
                  const SizedBox(height: 8),
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
                    ),
                    child: Text(
                      _detail!.matchInfo!,
                      style:
                          AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ],

                // Tags
                if (_detail?.tags.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detail!.tags.map((tag) {
                      return Chip(
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        label: Text(
                          tag,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Description
                if (_detail?.description != null &&
                    _detail!.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _detail!.description!,
                    style: AppTypography.getBodyMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(height: 1.5),
                  ),
                ],

                // Related Videos
                if (_detail?.relatedVideos.isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Related Highlights',
                    style: AppTypography.getHeadingMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._detail!.relatedVideos.map((rv) => VideoCard(video: rv)),
                ],
              ],
            ),
    );
  }
}
