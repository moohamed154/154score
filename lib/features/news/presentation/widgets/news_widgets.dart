import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/news_entity.dart';
import '../bloc/news_bloc.dart';

/// Large hero card for the main featured article.
class NewsHeroCard extends StatelessWidget {
  final NewsArticleEntity article;

  const NewsHeroCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return GestureDetector(
      onTap: () =>
          context.push('/news/${article.id}', extra: {'slug': article.slug}),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    imageUrl: article.image,
                    borderRadius: 0,
                    placeholderIcon: Icons.article_outlined,
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // "Featured" badge
                  Positioned(
                    top: AppDimensions.sm,
                    left: isArabic ? null : AppDimensions.sm,
                    right: isArabic ? AppDimensions.sm : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        isArabic ? 'الأبرز' : 'Featured',
                        style:
                            AppTypography.getBodySmall(
                              isDark: true,
                              isArabic: isArabic,
                            ).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title & timestamp
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.getHeadingSmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                  ),
                  if (article.description != null &&
                      article.description!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      article.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.xs),
                  _RelativeTime(
                    publishedAt: article.publishedAt,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal carousel of important/trending articles.
class NewsImportantCarousel extends StatelessWidget {
  final List<NewsArticleEntity> articles;

  const NewsImportantCarousel({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final article = articles[index];
          return _ImportantCard(
            article: article,
            isDark: isDark,
            isArabic: isArabic,
          );
        },
      ),
    );
  }
}

class _ImportantCard extends StatelessWidget {
  final NewsArticleEntity article;
  final bool isDark;
  final bool isArabic;

  const _ImportantCard({
    required this.article,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('/news/${article.id}', extra: {'slug': article.slug}),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AppImage(
                imageUrl: article.image,
                borderRadius: 0,
                placeholderIcon: Icons.article_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.sm),
              child: Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.getBodyLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of team filter chips.
class NewsTeamFilterBar extends StatelessWidget {
  final List<NewsTeamFilterEntity> teams;
  final String? selectedTeamId;

  const NewsTeamFilterBar({
    super.key,
    required this.teams,
    this.selectedTeamId,
  });

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.xs,
        ),
        itemCount: teams.length + 1, // +1 for "All" chip
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedTeamId == null;
            return GestureDetector(
              onTap: () => context.read<NewsBloc>().add(
                const SelectTeamFilterEvent(null),
              ),
              child: _TeamChip(
                label: l10n.translate('all_clubs'),
                logo: null,
                isSelected: isSelected,
                isDark: isDark,
                isArabic: isArabic,
              ),
            );
          }
          final team = teams[index - 1];
          final isSelected = selectedTeamId == team.id;

          return GestureDetector(
            onTap: () =>
                context.read<NewsBloc>().add(SelectTeamFilterEvent(team.id)),
            child: _TeamChip(
              label: team.name,
              logo: team.logo,
              isSelected: isSelected,
              isDark: isDark,
              isArabic: isArabic,
            ),
          );
        },
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String label;
  final String? logo;
  final bool isSelected;
  final bool isDark;
  final bool isArabic;

  const _TeamChip({
    required this.label,
    required this.logo,
    required this.isSelected,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logo != null) ...[
            AppImage(
              imageUrl: logo,
              width: 22,
              height: 22,
              borderRadius: AppDimensions.radiusFull,
              placeholderIcon: Icons.sports_soccer,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style:
                AppTypography.getBodyMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Single row list item for latest news.
class NewsListItem extends StatelessWidget {
  final NewsArticleEntity article;

  const NewsListItem({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return GestureDetector(
      onTap: () =>
          context.push('/news/${article.id}', extra: {'slug': article.slug}),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.xs,
        ),
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: AppImage(
                imageUrl: article.thumbnail ?? article.image,
                width: 88,
                height: 72,
                borderRadius: AppDimensions.radiusSm,
                placeholderIcon: Icons.article_outlined,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.getBodyLarge(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  _RelativeTime(
                    publishedAt: article.publishedAt,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple relative time display (e.g. "5 minutes ago").
class _RelativeTime extends StatelessWidget {
  final String? publishedAt;
  final bool isDark;
  final bool isArabic;

  const _RelativeTime({
    required this.publishedAt,
    required this.isDark,
    required this.isArabic,
  });

  String _format(String? raw, bool isArabic) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceAll('.000000', ''));
      final diff = DateTime.now().toUtc().difference(dt.toUtc());
      if (diff.inSeconds < 60) {
        return isArabic ? 'منذ لحظات' : 'Just now';
      } else if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return isArabic ? 'منذ $m دقيقة' : '$m min ago';
      } else if (diff.inHours < 24) {
        final h = diff.inHours;
        return isArabic ? 'منذ $h ساعة' : '$h h ago';
      } else {
        final d = diff.inDays;
        return isArabic ? 'منذ $d يوم' : '$d d ago';
      }
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _format(publishedAt, isArabic);
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 11,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic),
        ),
      ],
    );
  }
}
