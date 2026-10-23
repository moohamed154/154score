import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/storage/local_storage_service.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/text_direction_helper.dart';
import '../../../../../core/utils/url_helper.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../settings/presentation/cubit/settings_cubits.dart';
import '../../bloc/match_details_state.dart';
import 'match_details_skeletons.dart';

class MatchNewsTab extends StatelessWidget {
  final MatchDetailsState state;
  final bool isDark;
  final bool isArabic;
  final Future<void> Function() onRefresh;

  const MatchNewsTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final timeFormat = sl<LocalStorageService>().getTimeFormat();

    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      return MatchDetailsSkeletons.buildNewsSkeleton(
        context,
        isDark: isDark,
        isArabic: isArabic,
      );
    }

    if (state.news.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyView(
              titleKey: 'tab_news',
              icon: Icons.article_rounded,
              customMessage: isArabic
                  ? 'لا توجد أخبار متعلقة بهذه المباراة حالياً'
                  : 'No news articles available for this match at the moment',
            ),
          ],
        ),
      );
    }

    return BlocBuilder<FontSizeCubit, FontSizeState>(
      builder: (context, fontState) {
        final mq = MediaQuery.of(context);
        final newsScaler = fontState.isAuto
            ? mq.textScaler
            : TextScaler.linear(fontState.newsFontSizeScale);

        return MediaQuery(
          data: mq.copyWith(textScaler: newsScaler),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: ListView.separated(
              key: const PageStorageKey('news_tab_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(hMargin),
              itemCount: state.news.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.sm),
              itemBuilder: (context, index) {
                final item = state.news[index];
                final isItemArabic = TextDirectionHelper.isArabic(item.title) ||
                    (item.description != null &&
                        TextDirectionHelper.isArabic(item.description!));
                final effectiveItemArabic = isItemArabic || isArabic;
                final itemDir = isItemArabic
                    ? TextDirection.rtl
                    : (isArabic ? TextDirection.rtl : TextDirection.ltr);

                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.xs,
                    ),
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXs),
                      child: AppImage(
                        imageUrl: item.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.article_rounded,
                      ),
                    ),
                    title: Directionality(
                      textDirection: itemDir,
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: itemDir,
                        textAlign:
                            isItemArabic ? TextAlign.right : TextAlign.start,
                        style: AppTypography.getBodyMedium(
                          isDark: isDark,
                          isArabic: effectiveItemArabic,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    subtitle: (item.description != null &&
                                item.description!.isNotEmpty) ||
                            (item.date != null && item.date!.isNotEmpty)
                        ? Directionality(
                            textDirection: itemDir,
                            child: Column(
                              crossAxisAlignment: isItemArabic
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (item.description != null &&
                                    item.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: itemDir,
                                      textAlign: isItemArabic
                                          ? TextAlign.right
                                          : TextAlign.start,
                                      style: AppTypography.getBodySmall(
                                        isDark: isDark,
                                        isArabic: effectiveItemArabic,
                                      ).copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (item.date != null && item.date!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 11,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormatter.formatDateTime(
                                            item.date,
                                            isArabic: isArabic,
                                            timeFormat: timeFormat,
                                          ),
                                          style: AppTypography.getBodySmall(
                                            isDark: isDark,
                                            isArabic: effectiveItemArabic,
                                          ).copyWith(
                                            color: isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : null,
                    onTap: () {
                      final articleId = item.articleId ??
                          UrlHelper.parseNewsUrl(item.link).id;
                      final slug =
                          item.slug ?? UrlHelper.parseNewsUrl(item.link).slug;
                      if (articleId != null && articleId.isNotEmpty) {
                        context.push('/news/$articleId', extra: {'slug': slug});
                      } else if (item.link != null && item.link!.isNotEmpty) {
                        UrlHelper.launchExternalUrl(
                          item.link,
                          context: context,
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
