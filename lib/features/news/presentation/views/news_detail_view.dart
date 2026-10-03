import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/text_direction_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../bloc/news_bloc.dart';

class NewsDetailView extends StatelessWidget {
  final String articleId;
  final String? slug;

  const NewsDetailView({super.key, required this.articleId, this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsBloc(
        repository: sl<NewsRepository>(),
        localStorageService: sl<LocalStorageService>(),
      ),
      child: _NewsDetailBody(articleId: articleId, slug: slug),
    );
  }
}

class _NewsDetailBody extends StatefulWidget {
  final String articleId;
  final String? slug;

  const _NewsDetailBody({required this.articleId, this.slug});

  @override
  State<_NewsDetailBody> createState() => _NewsDetailBodyState();
}

class _NewsDetailBodyState extends State<_NewsDetailBody> {
  final ScreenshotController _screenshotController = ScreenshotController();
  _DetailState _state = _DetailState.loading;
  NewsDetailEntity? _detail;
  String? _error;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _DetailState.loading);
    final lang = sl<LocalStorageService>().getEffectiveNewsLanguage();
    final repo = sl<NewsRepository>();
    final result = await repo.getNewsDetail(
      widget.articleId,
      slug: widget.slug,
      lang: lang,
    );

    result.fold(
      onSuccess: (detail) {
        if (mounted) {
          setState(() {
            _state = _DetailState.success;
            _detail = detail;
          });
        }
      },
      onFailure: (failure) {
        if (mounted) {
          setState(() {
            _state = _DetailState.error;
            _error = failure.message;
          });
        }
      },
    );
  }

  Future<void> _shareNews(
    NewsDetailEntity detail,
    bool isDark,
    bool isArabic,
  ) async {
    if (_isSharing) return;

    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final parentContext = context;

    setState(() => _isSharing = true);

    try {
      // 1. Resolve cached image file if available for instant offline capture
      File? imageFile;
      if (detail.image != null && detail.image!.isNotEmpty) {
        try {
          final cacheManager = DefaultCacheManager();
          final fileInfo = await cacheManager.getFileFromCache(detail.image!);
          if (fileInfo != null && await fileInfo.file.exists()) {
            imageFile = fileInfo.file;
          } else {
            imageFile = await cacheManager.getSingleFile(detail.image!);
          }
        } catch (e) {
          debugPrint('Error getting image from cache: $e');
        }
      }

      // 2. Build the top-part share card (image + title + date + app branding)
      final shareCard = _buildShareCard(
        detail: detail,
        imageFile: imageFile,
        isDark: isDark,
        isArabic: isArabic,
      );

      // 3. Capture widget to high-resolution PNG
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        shareCard,
        delay: const Duration(milliseconds: 250),
        context: mounted ? parentContext : null,
        pixelRatio: 2.5,
      );

      // 4. Save PNG to temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/news_${widget.articleId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // 5. Build share text message
      final shareMessage = _buildShareMessage(detail);

      // 6. Share screenshot file and caption text
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareMessage,
          subject: detail.title,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Error capturing news screenshot: $e');
      final shareMessage = _buildShareMessage(detail);
      await SharePlus.instance.share(
        ShareParams(
          text: shareMessage,
          subject: detail.title,
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  String _buildShareMessage(NewsDetailEntity detail) {
    final buffer = StringBuffer();
    if (detail.title.trim().isNotEmpty) {
      buffer.writeln(detail.title.trim());
      buffer.writeln();
    }
    buffer.writeln('📲 تابع آخر الأخبار عبر تطبيق 154 SCORE');
    buffer.writeln('📲 Follow the latest news on 154 SCORE');
    if (detail.url != null && detail.url!.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(detail.url!.trim());
    }
    return buffer.toString().trim();
  }

  Widget _buildShareCard({
    required NewsDetailEntity detail,
    required File? imageFile,
    required bool isDark,
    required bool isArabic,
  }) {
    final formattedDate = _formatDate(detail.publishedAt);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. News Image
            if (imageFile != null)
              Image.file(
                imageFile,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else if (detail.image != null && detail.image!.isNotEmpty)
              AppImage(
                imageUrl: detail.image,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: 0,
                placeholderIcon: Icons.article_outlined,
              )
            else
              Container(
                height: 180,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),

            // 2. Title & Date & Branding Content
            Builder(
              builder: (context) {
                final isContentArabic =
                    TextDirectionHelper.isArabic(detail.title);
                final effectiveArabic = isContentArabic || isArabic;
                final textDir = isContentArabic
                    ? TextDirection.rtl
                    : (isArabic ? TextDirection.rtl : TextDirection.ltr);

                return Directionality(
                  textDirection: textDir,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: isContentArabic
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detail.title,
                          style: AppTypography.getHeadingMedium(
                            isDark: isDark,
                            isArabic: effectiveArabic,
                          ).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.35,
                          ),
                          textDirection: textDir,
                          textAlign: isContentArabic
                              ? TextAlign.right
                              : TextAlign.start,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: mutedColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                            const Spacer(),
                            // 154 SCORE Branding Capsule
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sports_soccer_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '154 SCORE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return Scaffold(
      body: switch (_state) {
        _DetailState.loading => _buildLoading(isDark),
        _DetailState.error => CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
            ),
            SliverFillRemaining(
              child: ErrorView(message: _error, onRetry: _load),
            ),
          ],
        ),
        _DetailState.success => _buildSuccess(context, isDark, isArabic, l10n),
      },
    );
  }

  Widget _buildLoading(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 240,
            color: isDark
                ? AppColors.darkCardElevated
                : AppColors.lightCardElevated,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                height: 14,
                margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ),
              childCount: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(
    BuildContext context,
    bool isDark,
    bool isArabic,
    AppLocalizations l10n,
  ) {
    final detail = _detail!;
    final isContentArabic = TextDirectionHelper.isArabic(detail.title) ||
        (detail.paragraphs.isNotEmpty &&
            TextDirectionHelper.isArabic(detail.paragraphs.first));
    final effectiveArabic = isContentArabic || isArabic;
    final textDir = isContentArabic
        ? TextDirection.rtl
        : (isArabic ? TextDirection.rtl : TextDirection.ltr);

    return CustomScrollView(
      slivers: [
        // Hero image + back button & share button
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: AppImage(
              imageUrl: detail.image,
              borderRadius: 0,
              placeholderIcon: Icons.article_outlined,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: _isSharing
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: l10n.translate('share_news'),
                        onPressed: () => _shareNews(
                          detail,
                          isDark,
                          effectiveArabic,
                        ),
                      ),
              ),
            ),
          ],
        ),

        // Article content
        SliverToBoxAdapter(
          child: Directionality(
            textDirection: textDir,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: isContentArabic
                    ? CrossAxisAlignment.end
                    : (isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start),
                children: [
                  // Title
                  Text(
                    detail.title,
                    textDirection: textDir,
                    textAlign:
                        isContentArabic ? TextAlign.right : TextAlign.start,
                    style: AppTypography.getHeadingMedium(
                      isDark: isDark,
                      isArabic: effectiveArabic,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // Timestamp
                  if (detail.publishedAt != null)
                    Row(
                      mainAxisAlignment: isContentArabic
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        _buildTimestamp(
                          detail.publishedAt,
                          isDark,
                          effectiveArabic,
                        ),
                      ],
                    ),
                  const SizedBox(height: AppDimensions.lg),

                  Divider(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    thickness: 1,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Paragraphs
                  ...List<Widget>.generate(detail.paragraphs.length, (i) {
                    final para = detail.paragraphs[i];
                    final isParaArabic = TextDirectionHelper.isArabic(para);
                    final effectiveParaArabic = isParaArabic || effectiveArabic;
                    final paraDir = isParaArabic ? TextDirection.rtl : textDir;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.md),
                      child: Text(
                        para,
                        style: AppTypography.getBodyLarge(
                          isDark: isDark,
                          isArabic: effectiveParaArabic,
                        ).copyWith(height: 1.8),
                        textDirection: paraDir,
                        textAlign:
                            isParaArabic ? TextAlign.right : TextAlign.start,
                      ),
                    );
                  }),

                  const SizedBox(height: AppDimensions.xxxl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceAll('.000000', ''));
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '${dt.year}-$month-$day';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildTimestamp(String? raw, bool isDark, bool isArabic) {
    final formatted = _formatDate(raw);
    if (formatted.isEmpty) return const SizedBox.shrink();
    return Text(
      formatted,
      style: AppTypography.getBodyMedium(isDark: isDark, isArabic: isArabic),
    );
  }
}

enum _DetailState { loading, error, success }
