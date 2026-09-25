import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:score154/features/news/presentation/bloc/news_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/repositories/news_repository.dart';

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
  _DetailState _state = _DetailState.loading;
  dynamic _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _DetailState.loading);
    final lang = sl<LocalStorageService>().getLanguage();
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

    return CustomScrollView(
      slivers: [
        // Hero image + back button
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          flexibleSpace: FlexibleSpaceBar(
            background: AppImage(
              imageUrl: detail.image,
              borderRadius: 0,
              placeholderIcon: Icons.article_outlined,
            ),
          ),
          actions: [
            if (detail.url != null)
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: l10n.translate('share_news'),
                onPressed: () =>
                    SharePlus.instance.share(ShareParams(text: detail.url!)),
              ),
            const SizedBox(width: AppDimensions.xs),
          ],
        ),

        // Article content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  detail.title ?? '',
                  style: AppTypography.getHeadingMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                // Timestamp
                if (detail.publishedAt != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      // Use the relative time widget
                      _buildTimestamp(detail.publishedAt, isDark, isArabic),
                    ],
                  ),
                const SizedBox(height: AppDimensions.lg),

                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  thickness: 1,
                ),
                const SizedBox(height: AppDimensions.md),

                // Paragraphs
                ...List<Widget>.generate((detail.paragraphs as List).length, (
                  i,
                ) {
                  final para = (detail.paragraphs as List)[i] as String;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.md),
                    child: Text(
                      para,
                      style: AppTypography.getBodyLarge(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(height: 1.8),
                      textDirection: isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                  );
                }),

                const SizedBox(height: AppDimensions.xxxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(String? raw, bool isDark, bool isArabic) {
    if (raw == null) return const SizedBox.shrink();
    try {
      final dt = DateTime.parse(raw.replaceAll('.000000', ''));
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final formatted = '${dt.year}-$month-$day';
      return Text(
        formatted,
        style: AppTypography.getBodyMedium(isDark: isDark, isArabic: isArabic),
      );
    } catch (_) {
      return Text(
        raw,
        style: AppTypography.getBodyMedium(isDark: isDark, isArabic: isArabic),
      );
    }
  }
}

enum _DetailState { loading, error, success }
