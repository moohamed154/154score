import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/search_result_entity.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';

class GlobalSearchView extends StatelessWidget {
  const GlobalSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => sl<SearchCubit>(),
      child: const _GlobalSearchContent(),
    );
  }
}

class _GlobalSearchContent extends StatefulWidget {
  const _GlobalSearchContent();

  @override
  State<_GlobalSearchContent> createState() => _GlobalSearchContentState();
}

class _GlobalSearchContentState extends State<_GlobalSearchContent> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex =
      0; // 0: All, 1: Championships, 2: Teams, 3: Players

  static const List<(String, String, String, String)> _popularCompetitions = [
    (
      '6811',
      'Premier League',
      'الدوري الإنجليزي الممتاز',
      'https://imgs.ysscores.com/championship/128/3411694791422.png',
    ),
    (
      '1933',
      'LaLiga',
      'الدوري الإسباني - لا ليغا',
      'https://imgs.ysscores.com/championship/128/8641690196626.png',
    ),
    (
      '3734',
      'Serie A',
      'الدوري الإيطالي',
      'https://imgs.ysscores.com/championship/128/6281692568873.png',
    ),
    (
      '2606',
      'Bundesliga',
      'الدوري الألماني',
      'https://imgs.ysscores.com/championship/128/6171690288722.png',
    ),
    (
      '2847',
      'Ligue 1',
      'الدوري الفرنسي',
      'https://imgs.ysscores.com/championship/128/9551719862665.png',
    ),
    (
      '12048',
      'UEFA Champions League',
      'دوري أبطال أوروبا',
      'https://imgs.ysscores.com/championship/128/5171696546919.png',
    ),
    (
      '3894',
      'Egyptian League',
      'الدوري المصري الممتاز',
      'https://imgs.ysscores.com/championship/128/451723403406.png',
    ),
    (
      '4750',
      'Saudi Pro League',
      'دوري روشن السعودي للمحترفين',
      'https://imgs.ysscores.com/championship/128/5111703719091.png',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, bool isArabic) {
    context.read<SearchCubit>().onQueryChanged(
      value,
      lang: isArabic ? 'ar' : 'en',
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchCubit>().clear();
    setState(() => _selectedCategoryIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppDimensions.md),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.translate('search_placeholder'),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: 10,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        onPressed: _clearSearch,
                      )
                    : null,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontSize: 14,
                ),
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 14,
              ),
              onChanged: (val) {
                setState(() {});
                _onSearchChanged(val, isArabic);
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state.query.isEmpty || state.status == SearchStatus.idle) {
            return _buildPopularSuggestions(context, isDark, isArabic);
          }

          if (state.status == SearchStatus.loading) {
            return _buildLoadingSkeleton(isDark);
          }

          if (state.status == SearchStatus.error) {
            return ErrorView(
              message: state.errorMessage,
              onRetry: () => _onSearchChanged(state.query, isArabic),
            );
          }

          if (state.status == SearchStatus.empty ||
              (state.results != null && state.results!.totalResults == 0)) {
            return const EmptyView(
              titleKey: 'search_no_results',
              icon: Icons.search_off_rounded,
            );
          }

          final results = state.results;
          if (results == null) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              _buildCategoryChips(context, results, isDark, isArabic),
              Expanded(
                child: _buildResultsList(context, results, isDark, isArabic),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    SearchResultsEntity results,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    final categories = [
      (0, l10n.translate('search_all'), results.totalResults),
      (1, l10n.translate('search_championships'), results.championships.length),
      (2, l10n.translate('search_teams'), results.teams.length),
      (3, l10n.translate('search_players'), results.players.length),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategoryIndex == cat.$1;
          final count = cat.$3;

          return Center(
            child: ChoiceChip(
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              onSelected: (_) {
                setState(() => _selectedCategoryIndex = cat.$1);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    SearchResultsEntity results,
    bool isDark,
    bool isArabic,
  ) {
    switch (_selectedCategoryIndex) {
      case 1:
        return _buildSectionList(
          context,
          items: results.championships,
          emptyTitle: 'search_no_results',
          isDark: isDark,
          isArabic: isArabic,
        );
      case 2:
        return _buildSectionList(
          context,
          items: results.teams,
          emptyTitle: 'search_no_results',
          isDark: isDark,
          isArabic: isArabic,
        );
      case 3:
        return _buildSectionList(
          context,
          items: results.players,
          emptyTitle: 'search_no_results',
          isDark: isDark,
          isArabic: isArabic,
        );
      case 0:
      default:
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          children: [
            if (results.championships.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                title: AppLocalizations.of(context)
                    .translate('search_championships'),
                count: results.championships.length,
                isDark: isDark,
                isArabic: isArabic,
              ),
              ...results.championships.map(
                (item) => _buildResultCard(context, item, isDark, isArabic),
              ),
              const SizedBox(height: 12),
            ],
            if (results.teams.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                title: AppLocalizations.of(context).translate('search_teams'),
                count: results.teams.length,
                isDark: isDark,
                isArabic: isArabic,
              ),
              ...results.teams.map(
                (item) => _buildResultCard(context, item, isDark, isArabic),
              ),
              const SizedBox(height: 12),
            ],
            if (results.players.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                title: AppLocalizations.of(context).translate('search_players'),
                count: results.players.length,
                isDark: isDark,
                isArabic: isArabic,
              ),
              ...results.players.map(
                (item) => _buildResultCard(context, item, isDark, isArabic),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
    }
  }

  Widget _buildSectionList(
    BuildContext context, {
    required List<SearchResultEntity> items,
    required String emptyTitle,
    required bool isDark,
    required bool isArabic,
  }) {
    if (items.isEmpty) {
      return EmptyView(titleKey: emptyTitle, icon: Icons.search_off_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildResultCard(context, items[index], isDark, isArabic);
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required bool isDark,
    required bool isArabic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.getHeadingSmall(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    SearchResultEntity item,
    bool isDark,
    bool isArabic,
  ) {
    final isPlayer = item.type == 'player';
    final isTeam = item.type == 'team';
    final isChampionship = item.type == 'championship';

    IconData fallbackIcon = Icons.sports_soccer;
    if (isChampionship) fallbackIcon = Icons.emoji_events_outlined;
    if (isTeam) fallbackIcon = Icons.shield_outlined;
    if (isPlayer) fallbackIcon = Icons.person_rounded;

    final effectiveLogo = isChampionship
        ? (UrlHelper.resolveChampionshipLogo(
              item.id,
              currentLogo: item.logo,
              isDark: isDark,
            ) ??
            item.logo)
        : (isTeam
            ? (((item.logo != null && UrlHelper.isValidImageUrl(item.logo))
                    ? item.logo
                    : UrlHelper.resolveTeamLogo(item.id, teamName: item.title)) ??
                item.logo)
            : item.logo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToResult(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Logo / Photo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: isPlayer ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isPlayer
                        ? null
                        : BorderRadius.circular(AppDimensions.radiusSm),
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCardElevated,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppImage(
                    imageUrl: effectiveLogo,
                    width: 44,
                    height: 44,
                    borderRadius: isPlayer ? 22 : AppDimensions.radiusSm,
                    placeholderIcon: fallbackIcon,
                  ),
                ),
                const SizedBox(width: 12),

                // Info: Title & Subtitle/Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (item.fullTitle != null &&
                          item.fullTitle!.isNotEmpty &&
                          item.fullTitle != item.title) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.fullTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                      if (item.position != null &&
                          item.position!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Text(
                            item.position!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      if (item.country != null && item.country!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.country!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing Chevron
                Icon(
                  isArabic
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToResult(BuildContext context, SearchResultEntity item) {
    if (item.id.isEmpty) return;

    switch (item.type) {
      case 'championship':
        context.push(
          '/league/${item.id}',
          extra: {'title': item.title, 'logo': item.logo},
        );
        break;
      case 'team':
        context.push(
          '/team/${item.id}',
          extra: {'name': item.title, 'logo': item.logo},
        );
        break;
      case 'player':
        context.push(
          '/player/${item.id}',
          extra: {'name': item.title, 'photo': item.logo},
        );
        break;
    }
  }

  Widget _buildPopularSuggestions(
    BuildContext context,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        Text(
          l10n.translate('popular_competitions'),
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ),
        ),
        const SizedBox(height: 12),
        ..._popularCompetitions.map((comp) {
          final title = isArabic ? comp.$3 : comp.$2;
          final logoUrl = comp.$4;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : AppColors.lightBorder.withValues(alpha: 0.7),
                      width: 0.8,
                    ),
                  ),
                  child: AppImage(
                    imageUrl: logoUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    placeholderIcon: Icons.emoji_events_outlined,
                  ),
                ),
                title: Text(
                  title,
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  isArabic
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                onTap: () {
                  context.push(
                    '/league/${comp.$1}',
                    extra: {'title': title, 'logo': logoUrl},
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const ListTile(
                leading: CircleAvatar(radius: 20),
                title: Bone.text(words: 2),
                subtitle: Bone.text(words: 1),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
          );
        },
      ),
    );
  }
}
