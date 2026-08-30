import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../leagues/presentation/views/league_view.dart';

class ChampionshipInfo {
  final String id;
  final String? seasonId;
  final String name;
  final String? slug;
  final String logo;
  final bool hasStandings;
  final bool isFeatured;

  const ChampionshipInfo({
    required this.id,
    this.seasonId,
    required this.name,
    this.slug,
    required this.logo,
    this.hasStandings = true,
    this.isFeatured = false,
  });

  factory ChampionshipInfo.fromJson(Map<String, dynamic> json) {
    final leagueId =
        json['league_id']?.toString() ?? json['id']?.toString() ?? '';
    final seasonId = json['season_id']?.toString();
    final name = json['name']?.toString() ?? json['title']?.toString() ?? '';
    final slug = json['slug']?.toString();
    final logo = json['logo']?.toString() ?? '';
    final hasStandings = json['has_standings'] as bool? ?? true;
    final isFeatured = json['is_featured'] as bool? ?? false;

    return ChampionshipInfo(
      id: leagueId.isNotEmpty ? leagueId : (seasonId ?? ''),
      seasonId: seasonId,
      name: name,
      slug: slug,
      logo: logo,
      hasStandings: hasStandings,
      isFeatured: isFeatured,
    );
  }
}

const List<ChampionshipInfo> kDefaultFallbackChampionships = [
  ChampionshipInfo(
    id: '12048',
    seasonId: '943230',
    name: 'دوري أبطال أوروبا',
    slug: 'UEFA-Champions-League',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '6811',
    seasonId: '937599',
    name: 'الدوري الإنجليزي الممتاز',
    slug: 'Premier-League',
    logo: 'https://imgs.ysscores.com/championship/128/3411694791422.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '88013',
    seasonId: '59771441',
    name: 'كأس السوبر الإسباني',
    slug: 'Supercopa-de-España',
    logo: 'https://imgs.ysscores.com/championship/128/5481703687014.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '1933',
    seasonId: '938652',
    name: 'الدوري الإسباني',
    slug: 'LaLiga',
    logo: 'https://imgs.ysscores.com/championship/128/8641690196626.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '3734',
    seasonId: '936357',
    name: 'الدوري الإيطالي',
    slug: 'Serie-A',
    logo: 'https://imgs.ysscores.com/championship/128/6281692568873.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '2606',
    seasonId: '938769',
    name: 'الدوري الألماني',
    slug: 'Bundesliga',
    logo: 'https://imgs.ysscores.com/championship/128/6171690288722.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '1985',
    seasonId: '937873',
    name: 'الدوري الفرنسي',
    slug: 'Ligue-1',
    logo: 'https://imgs.ysscores.com/championship/128/9551719862665.png',
    isFeatured: true,
  ),
  ChampionshipInfo(
    id: '7167',
    seasonId: '941825',
    name: 'الدوري السعودي للمحترفين',
    slug: 'Saudi-Pro-League',
    logo: 'https://imgs.ysscores.com/championship/128/5111703719091.png',
    isFeatured: true,
  ),
];

class StandingsView extends StatefulWidget {
  final String? initialLeagueId;

  const StandingsView({super.key, this.initialLeagueId});

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isTipDismissed = false;
  bool _isLoading = true;
  String? _errorMessage;

  List<ChampionshipInfo> _featuredLeagues = [];
  List<ChampionshipInfo> _allLeagues = [];

  @override
  void initState() {
    super.initState();
    _featuredLeagues = List<ChampionshipInfo>.from(
      kDefaultFallbackChampionships,
    );
    _allLeagues = List<ChampionshipInfo>.from(kDefaultFallbackChampionships);
    _searchController.addListener(_onSearchChanged);
    _fetchRankings();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchRankings(search: _searchController.text.trim());
    });
  }

  Future<void> _fetchRankings({String search = ''}) async {
    try {
      final isArabic =
          mounted ? AppLocalizations.of(context).isArabic : true;
      final lang = isArabic ? 'ar' : 'en';

      final queryParams = <String, dynamic>{'lang': lang};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final apiClient = sl<ApiClient>();
      final dynamic response = await apiClient.get(
        ApiEndpoints.rank,
        queryParameters: queryParams,
      );

      Map<String, dynamic>? resMap;
      if (response is Map<String, dynamic>) {
        resMap = response;
      } else if (response != null && response.data is Map<String, dynamic>) {
        resMap = response.data as Map<String, dynamic>;
      }

      if (resMap != null && resMap['data'] != null) {
        final data = resMap['data'] as Map<String, dynamic>;

        final featuredRaw = data['featured'] as List<dynamic>? ?? [];
        final leaguesRaw = data['leagues'] as List<dynamic>? ?? [];

        final fetchedFeatured =
            featuredRaw
                .map(
                  (item) =>
                      ChampionshipInfo.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        final fetchedAll =
            leaguesRaw
                .map(
                  (item) =>
                      ChampionshipInfo.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _featuredLeagues = fetchedFeatured;
            _allLeagues = fetchedAll.isNotEmpty ? fetchedAll : fetchedFeatured;
          });
        }
      }
    } catch (e) {
      if (mounted && _allLeagues.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_soccer_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '154SCORE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, favState) {
          final favoriteNames = favState.favoriteCompetitions;

          final List<ChampionshipInfo> favoriteCards = [];
          final Map<String, ChampionshipInfo> favMap = {};

          for (final item in _featuredLeagues) {
            favMap[item.id] = item;
          }

          for (final item in _allLeagues) {
            if (favoriteNames.contains(item.name) ||
                favoriteNames.contains(item.id) ||
                favoriteNames.contains(item.slug)) {
              favMap[item.id] = item;
            }
          }

          favoriteCards.addAll(favMap.values);

          final allOtherCards =
              _allLeagues.where((item) => !favMap.containsKey(item.id)).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _fetchRankings(search: _searchController.text.trim()),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF161A26)
                            : const Color(0xFFEFF2F8),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(
                      color:
                          isDark
                              ? const Color(0xFF242C40)
                              : const Color(0xFFE2E7F0),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.translate('search_championship'),
                      hintStyle: TextStyle(
                        color:
                            isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color:
                            isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                        size: 20,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                ),
                                color:
                                    isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchRankings();
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (!_isTipDismissed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF1B2338)
                              : const Color(0xFFE8EEFC),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(0xFF2A3758)
                                : const Color(0xFFCCD9F7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.translate('long_press_reorder_hint'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? const Color(0xFF9FB2DB)
                                      : const Color(0xFF2D4B85),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isTipDismissed = true),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color:
                                isDark
                                    ? const Color(0xFF9FB2DB)
                                    : const Color(0xFF2D4B85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_isLoading && _allLeagues.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_errorMessage != null && _allLeagues.isEmpty)
                  ErrorView(
                    message: _errorMessage!,
                    onRetry: () => _fetchRankings(),
                  )
                else ...[
                  if (favoriteCards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.translate('favorite_championships'),
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    ...favoriteCards.map(
                      (item) => _buildChampionshipCard(
                        context,
                        item,
                        isFavorite: true,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (allOtherCards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.translate('all_championships'),
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    ...allOtherCards.map(
                      (item) => _buildChampionshipCard(
                        context,
                        item,
                        isFavorite: false,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChampionshipCard(
    BuildContext context,
    ChampionshipInfo item, {
    required bool isFavorite,
    required bool isDark,
    required bool isArabic,
  }) {
    final title = item.name;
    final normalizedLogo = UrlHelper.normalizeImageUrl(item.logo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF161A26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            try {
              context.push(
                '/league/${item.id}?tab=2',
                extra: {
                  'title': title,
                  'logo': item.logo.isNotEmpty ? item.logo : null,
                  'tab': 2,
                },
              );
            } catch (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BlocProvider(
                        create:
                            (_) => sl<LeagueBloc>(
                              param1: item.id,
                              param2: {
                                'title': title,
                                'logo': item.logo.isNotEmpty ? item.logo : null,
                              },
                            ),
                        child: LeagueView(
                          leagueId: item.id,
                          initialTitle: title,
                          initialLogo: item.logo.isNotEmpty ? item.logo : null,
                          initialTabIndex: 2,
                        ),
                      ),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF22283A) : const Color(0xFFE5E9F2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    color:
                        isDark
                            ? const Color(0xFF0F121C)
                            : const Color(0xFFF1F3F7),
                    padding: const EdgeInsets.all(4),
                    child:
                        (normalizedLogo != null && normalizedLogo.isNotEmpty)
                            ? CachedNetworkImage(
                              imageUrl: normalizedLogo,
                              memCacheWidth: 64,
                              memCacheHeight: 64,
                              fit: BoxFit.contain,
                              errorWidget:
                                  (_, __, ___) => Icon(
                                    Icons.emoji_events_rounded,
                                    size: 20,
                                    color:
                                        isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                  ),
                              placeholder:
                                  (_, __) => Icon(
                                    Icons.sports_soccer_rounded,
                                    size: 18,
                                    color:
                                        isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                  ),
                            )
                            : Icon(
                              Icons.emoji_events_rounded,
                              size: 20,
                              color:
                                  isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                            ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.getBodyMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color:
                        isFavorite
                            ? Colors.amber
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                    size: 24,
                  ),
                  onPressed: () {
                    context.read<FavoritesCubit>().toggleCompetition(item.name);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
