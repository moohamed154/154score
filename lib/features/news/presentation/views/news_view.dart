import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../settings/presentation/cubit/settings_cubits.dart';
import '../../domain/entities/news_entity.dart';
import '../bloc/news_bloc.dart';
import '../widgets/news_widgets.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return MultiBlocListener(
      listeners: [
        BlocListener<LocaleCubit, LocaleState>(
          listenWhen: (prev, curr) => prev.locale != curr.locale,
          listener: (context, localeState) {
            final newsLangSetting = sl<LocalStorageService>().getNewsLanguage();
            if (newsLangSetting == 'app') {
              context.read<NewsBloc>().add(
                ChangeNewsLanguageEvent(localeState.locale.languageCode),
              );
            }
          },
        ),
        BlocListener<NewsLanguageCubit, String>(
          listener: (context, newsLang) {
            final appLang = context.read<LocaleCubit>().state.locale.languageCode;
            final targetLang = newsLang == 'app' ? appLang : newsLang;
            context.read<NewsBloc>().add(ChangeNewsLanguageEvent(targetLang));
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: AppDimensions.lg,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBrandLogo(size: 40, isDark: isDark),
              const SizedBox(width: 10),
              Text(
                '154Score',
                style: AppTypography.getHeadingLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        body: BlocBuilder<NewsBloc, NewsState>(
          builder: (context, state) {
            if (state.status == NewsStatus.error && state.feed == null) {
              return ErrorView(
                message: state.errorMessage,
                onRetry: () =>
                    context.read<NewsBloc>().add(const LoadNewsFeedEvent()),
              );
            }

            final isLoading =
                state.status == NewsStatus.loading && state.feed == null;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () {
                final completer = Completer<void>();
                context.read<NewsBloc>().add(
                  LoadNewsFeedEvent(isRefresh: true, completer: completer),
                );
                return completer.future;
              },
              child: _NewsBody(
                isLoading: isLoading,
                state: state,
                isDark: isDark,
                isArabic: isArabic,
                l10n: l10n,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewsBody extends StatelessWidget {
  final bool isLoading;
  final NewsState state;
  final bool isDark;
  final bool isArabic;
  final AppLocalizations l10n;

  const _NewsBody({
    required this.isLoading,
    required this.state,
    required this.isDark,
    required this.isArabic,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Build a fake feed for skeleton loading
    final skeletonFeed = isLoading
        ? NewsFeedEntity(
            main: const NewsArticleEntity(
              id: '0',
              title: '─────────────────────────────',
              description: '──────────────────────',
              publishedAt: '2024-01-01',
            ),
            important: List.generate(
              4,
              (i) =>
                  NewsArticleEntity(id: '$i', title: '─────────────────────'),
            ),
            teams: List.generate(
              6,
              (i) => NewsTeamFilterEntity(id: '$i', name: '────'),
            ),
            latest: List.generate(
              5,
              (i) => NewsArticleEntity(
                id: '$i',
                title: '──────────────────────────────',
              ),
            ),
          )
        : state.feed;

    final displayFeed = skeletonFeed;
    if (displayFeed == null) {
      return Center(
        child: Text(
          state.lang == 'ar'
              ? 'لا توجد أخبار متاحة حالياً'
              : l10n.translate('no_news_available'),
          style: AppTypography.getBodyMedium(
            isDark: isDark,
            isArabic: state.lang == 'ar',
          ),
        ),
      );
    }

    final isNewsArabic = state.lang == 'ar';

    final isTeamFilterLoading =
        state.status == NewsStatus.loading && state.feed != null;

    return Directionality(
      textDirection: isNewsArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Skeletonizer(
        enabled: isLoading,
        containersColor: isDark
            ? AppColors.darkCardElevated
            : AppColors.lightCardElevated,
        child: CustomScrollView(
          slivers: [
            // Section label: Latest News
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.md,
                  AppDimensions.lg,
                  AppDimensions.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      margin: EdgeInsets.only(
                        right: isNewsArabic ? 0 : AppDimensions.xs,
                        left: isNewsArabic ? AppDimensions.xs : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Text(
                      isNewsArabic
                          ? 'أحدث الأخبار'
                          : l10n.translate('latest_news'),
                      style: AppTypography.getHeadingSmall(
                        isDark: isDark,
                        isArabic: isNewsArabic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero card (main)
            if (displayFeed.main != null)
              SliverToBoxAdapter(
                child: NewsHeroCard(article: displayFeed.main!),
              ),

            // Section label: Trending
            if (displayFeed.important.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.lg,
                    AppDimensions.md,
                    AppDimensions.lg,
                    AppDimensions.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.liveRed,
                        size: 18,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        isNewsArabic
                            ? 'الأخبار الرائجة'
                            : l10n.translate('important_news'),
                        style: AppTypography.getHeadingSmall(
                          isDark: isDark,
                          isArabic: isNewsArabic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Important carousel
            if (displayFeed.important.isNotEmpty)
              SliverToBoxAdapter(
                child: NewsImportantCarousel(articles: displayFeed.important),
              ),

            // Team filter bar
            if (displayFeed.teams.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.sm),
                  child: NewsTeamFilterBar(
                    teams: displayFeed.teams,
                    selectedTeamId: state.selectedTeamId,
                  ),
                ),
              ),

            // Divider + "Latest" header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.md,
                  AppDimensions.lg,
                  AppDimensions.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      margin: EdgeInsets.only(
                        right: isNewsArabic ? 0 : AppDimensions.xs,
                        left: isNewsArabic ? AppDimensions.xs : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Text(
                      isNewsArabic ? 'كل الأخبار' : 'All News',
                      style: AppTypography.getHeadingSmall(
                        isDark: isDark,
                        isArabic: isNewsArabic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Latest news list (with Skeletonizer for team filter loading)
            if (isTeamFilterLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Skeletonizer(
                      enabled: true,
                      containersColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      child: NewsListItem(
                        key: ValueKey('skeleton_$index'),
                        article: NewsArticleEntity(
                          id: 'skeleton_$index',
                          title: isNewsArabic
                              ? 'تحميل تفاصيل وأخبار الفريق الرياضية بشكل كامل'
                              : '────────────────────────────────────',
                          publishedAt: '2024-01-01',
                        ),
                      ),
                    );
                  },
                  childCount: 5,
                ),
              )
            else if (state.filteredLatest.isEmpty && !isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.xl,
                    horizontal: AppDimensions.lg,
                  ),
                  child: Center(
                    child: Text(
                      isNewsArabic
                          ? 'لا توجد أخبار لهذا النادي حالياً'
                          : l10n.translate('no_news_available'),
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isNewsArabic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final articles =
                        isLoading ? displayFeed.latest : state.filteredLatest;
                    if (index >= articles.length) return null;
                    final art = articles[index];
                    return NewsListItem(
                      key: ValueKey('news_${art.id}'),
                      article: art,
                    );
                  },
                  childCount: isLoading
                      ? displayFeed.latest.length
                      : state.filteredLatest.length,
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.xxxl),
            ),
          ],
        ),
      ),
    );
  }
}
