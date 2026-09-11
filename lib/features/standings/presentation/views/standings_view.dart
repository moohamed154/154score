import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../leagues/presentation/views/league_view.dart';

enum ChampionshipFilter { all, favorites, featured, leagues, cups }

class ChampionshipInfo {
  final String id;
  final String? seasonId;
  final String name;
  final String? slug;
  final String logo;
  final bool hasStandings;
  final bool isFeatured;
  final int? type;
  final bool hasScorers;

  const ChampionshipInfo({
    required this.id,
    this.seasonId,
    required this.name,
    this.slug,
    required this.logo,
    this.hasStandings = true,
    this.isFeatured = false,
    this.type,
    this.hasScorers = true,
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
    final type = json['type'] is int
        ? json['type'] as int
        : int.tryParse(json['type']?.toString() ?? '');
    final hasScorers = json['has_scorers'] as bool? ?? true;

    return ChampionshipInfo(
      id: leagueId.isNotEmpty ? leagueId : (seasonId ?? ''),
      seasonId: seasonId,
      name: name,
      slug: slug,
      logo: logo,
      hasStandings: hasStandings,
      isFeatured: isFeatured,
      type: type,
      hasScorers: hasScorers,
    );
  }

  Map<String, dynamic> toJson() => {
    'league_id': id,
    'season_id': seasonId,
    'name': name,
    'slug': slug,
    'logo': logo,
    'has_standings': hasStandings,
    'is_featured': isFeatured,
    'type': type,
    'has_scorers': hasScorers,
  };
}

const List<ChampionshipInfo> kDefaultFallbackChampionships = [
  ChampionshipInfo(
    id: '12048',
    seasonId: '943230',
    name: 'دوري أبطال أوروبا',
    slug: 'UEFA-Champions-League',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    isFeatured: true,
    type: 4,
  ),
  ChampionshipInfo(
    id: '6811',
    seasonId: '937599',
    name: 'الدوري الإنجليزي الممتاز',
    slug: 'Premier-League',
    logo: 'https://imgs.ysscores.com/championship/128/3411694791422.png',
    isFeatured: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '88013',
    seasonId: '59771441',
    name: 'كأس السوبر الإسباني',
    slug: 'Supercopa-de-España',
    logo: 'https://imgs.ysscores.com/championship/128/5481703687014.png',
    isFeatured: true,
    type: 2,
    hasStandings: false,
  ),
  ChampionshipInfo(
    id: '1933',
    seasonId: '938652',
    name: 'الدوري الإسباني',
    slug: 'LaLiga',
    logo: 'https://imgs.ysscores.com/championship/128/8641690196626.png',
    isFeatured: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '3734',
    seasonId: '936357',
    name: 'الدوري الإيطالي',
    slug: 'Serie-A',
    logo: 'https://imgs.ysscores.com/championship/128/6281692568873.png',
    isFeatured: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '2606',
    seasonId: '938769',
    name: 'الدوري الألماني',
    slug: 'Bundesliga',
    logo: 'https://imgs.ysscores.com/championship/128/6171690288722.png',
    isFeatured: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '1985',
    seasonId: '937873',
    name: 'الدوري الفرنسي',
    slug: 'Ligue-1',
    logo: 'https://imgs.ysscores.com/championship/128/9551719862665.png',
    isFeatured: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '7167',
    seasonId: '941825',
    name: 'الدوري السعودي للمحترفين',
    slug: 'Saudi-Pro-League',
    logo: 'https://imgs.ysscores.com/championship/128/5111703719091.png',
    isFeatured: true,
    type: 1,
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
  ChampionshipFilter _activeFilter = ChampionshipFilter.all;

  List<ChampionshipInfo> _featuredLeagues = [];
  List<ChampionshipInfo> _allLeagues = [];

  @override
  void initState() {
    super.initState();

    final storage = sl<LocalStorageService>();
    _isTipDismissed = storage.isReorderTipDismissed();

    // 1. Instant startup: try loading cached rankings from storage
    final cachedData = storage.getCachedRankings();
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedData);
        if (decoded is Map) {
          final featuredRaw = decoded['featured'] as List? ?? [];
          final leaguesRaw = decoded['leagues'] as List? ?? [];

          final cachedFeatured = <ChampionshipInfo>[];
          for (final item in featuredRaw) {
            if (item is Map) {
              cachedFeatured.add(
                ChampionshipInfo.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }

          final cachedAll = <ChampionshipInfo>[];
          for (final item in leaguesRaw) {
            if (item is Map) {
              cachedAll.add(
                ChampionshipInfo.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }

          if (cachedAll.isNotEmpty || cachedFeatured.isNotEmpty) {
            _featuredLeagues = cachedFeatured;
            _allLeagues = cachedAll.isNotEmpty ? cachedAll : cachedFeatured;
            _isLoading = false;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback if no cache found yet
    if (_allLeagues.isEmpty) {
      _featuredLeagues = List<ChampionshipInfo>.from(
        kDefaultFallbackChampionships,
      );
      _allLeagues = List<ChampionshipInfo>.from(kDefaultFallbackChampionships);
    }

    _searchController.addListener(_onSearchChanged);

    // 3. Guaranteed fresh network fetch on first open (safe from initState InheritedWidget restrictions)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRankings();
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchRankings(search: _searchController.text.trim());
    });
  }

  Future<void> _fetchRankings({String search = ''}) async {
    try {
      // Safe language retrieval from LocalStorageService without BuildContext dependency
      final lang = sl<LocalStorageService>().getLanguage();

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
      if (response is Map) {
        resMap = Map<String, dynamic>.from(response);
      }

      if (resMap != null && resMap['data'] != null && resMap['data'] is Map) {
        final data = Map<String, dynamic>.from(resMap['data'] as Map);

        final featuredRaw = data['featured'] as List? ?? [];
        final leaguesRaw = data['leagues'] as List? ?? [];

        final fetchedFeatured = <ChampionshipInfo>[];
        for (final item in featuredRaw) {
          if (item is Map) {
            fetchedFeatured.add(
              ChampionshipInfo.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }

        final fetchedAll = <ChampionshipInfo>[];
        for (final item in leaguesRaw) {
          if (item is Map) {
            fetchedAll.add(
              ChampionshipInfo.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }

        // Cache the remote data if this is not a search query
        if (search.isEmpty &&
            (fetchedAll.isNotEmpty || fetchedFeatured.isNotEmpty)) {
          try {
            sl<LocalStorageService>().setCachedRankings(
              jsonEncode({
                'featured': fetchedFeatured.map((e) => e.toJson()).toList(),
                'leagues': fetchedAll.map((e) => e.toJson()).toList(),
              }),
            );
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _featuredLeagues = fetchedFeatured;
            _allLeagues = fetchedAll.isNotEmpty ? fetchedAll : fetchedFeatured;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_allLeagues.isEmpty) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  void _dismissTip() {
    setState(() => _isTipDismissed = true);
    sl<LocalStorageService>().setReorderTipDismissed(true);
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

          // Resolve user's actual favorite championships in user's saved order
          final List<ChampionshipInfo> favoriteCards = [];
          for (final favName in favoriteNames) {
            ChampionshipInfo? matched;
            for (final league in _allLeagues) {
              if (league.name == favName ||
                  league.id == favName ||
                  league.slug == favName) {
                matched = league;
                break;
              }
            }
            if (matched == null) {
              for (final league in _featuredLeagues) {
                if (league.name == favName ||
                    league.id == favName ||
                    league.slug == favName) {
                  matched = league;
                  break;
                }
              }
            }
            if (matched != null &&
                !favoriteCards.any((c) => c.id == matched!.id)) {
              favoriteCards.add(matched);
            }
          }

          // Featured leagues that are not already in favorites (to avoid duplicates in UI)
          final nonFavoriteFeatured = _featuredLeagues.where((item) {
            return !favoriteCards.any((f) => f.id == item.id);
          }).toList();

          // All other leagues excluding favorites
          final allOtherCards = _allLeagues.where((item) {
            return !favoriteCards.any((f) => f.id == item.id);
          }).toList();

          // Filter according to active category filter
          final filteredAllCards = _applyFilter(allOtherCards, _activeFilter);
          final isSearching = _searchController.text.trim().isNotEmpty;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              try {
                await _fetchRankings(search: _searchController.text.trim())
                    .timeout(const Duration(milliseconds: 3500));
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // 1. Search Bar
                _buildSearchBar(context, isDark: isDark, l10n: l10n),
                const SizedBox(height: 12),

                // 2. Filter Chips Row
                if (!isSearching) ...[
                  _buildFilterChips(
                    context,
                    favoriteCount: favoriteCards.length,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 14),
                ],

                // 3. Reorder Hint Banner (only if user has favorites and hasn't dismissed it)
                if (!_isTipDismissed &&
                    favoriteCards.length > 1 &&
                    (_activeFilter == ChampionshipFilter.all ||
                        _activeFilter == ChampionshipFilter.favorites) &&
                    !isSearching) ...[
                  _buildReorderTip(context, isDark: isDark, l10n: l10n),
                  const SizedBox(height: 16),
                ],

                // 4. Content Loading & Error States
                if (_isLoading && _allLeagues.isEmpty)
                  _buildLoadingSkeletons(isDark)
                else if (_errorMessage != null && _allLeagues.isEmpty)
                  ErrorView(
                    message: _errorMessage!,
                    onRetry: () => _fetchRankings(),
                  )
                else ...[
                  // If Searching: show combined filtered results
                  if (isSearching) ...[
                    _buildSearchResultsSection(
                      context,
                      favoriteNames: favoriteNames,
                      isDark: isDark,
                      isArabic: isArabic,
                      l10n: l10n,
                    ),
                  ] else ...[
                    // A. Favorite Championships Section
                    if ((_activeFilter == ChampionshipFilter.all ||
                            _activeFilter == ChampionshipFilter.favorites) &&
                        favoriteCards.isNotEmpty) ...[
                      _buildSectionTitle(
                        l10n.translate('favorite_championships'),
                        count: favoriteCards.length,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 8),
                      _buildReorderableFavoritesList(
                        context,
                        favoriteCards,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Empty state if user selected "Favorites" tab but has no favorites
                    if (_activeFilter == ChampionshipFilter.favorites &&
                        favoriteCards.isEmpty) ...[
                      _buildEmptyFavoritesCard(
                        context,
                        isDark: isDark,
                        l10n: l10n,
                        isArabic: isArabic,
                      ),
                    ],

                    // B. Featured Championships Section
                    if ((_activeFilter == ChampionshipFilter.all ||
                            _activeFilter == ChampionshipFilter.featured) &&
                        nonFavoriteFeatured.isNotEmpty) ...[
                      _buildSectionTitle(
                        l10n.translate('featured_championships'),
                        count: nonFavoriteFeatured.length,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 8),
                      ...nonFavoriteFeatured.map(
                        (item) => _buildChampionshipCard(
                          context,
                          item,
                          isFavorite:
                              favoriteNames.contains(item.name) ||
                              favoriteNames.contains(item.id) ||
                              favoriteNames.contains(item.slug),
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // C. All Championships Section
                    if (_activeFilter != ChampionshipFilter.featured &&
                        _activeFilter != ChampionshipFilter.favorites &&
                        filteredAllCards.isNotEmpty) ...[
                      _buildSectionTitle(
                        l10n.translate('all_championships'),
                        count: filteredAllCards.length,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 8),
                      ...filteredAllCards.map(
                        (item) => _buildChampionshipCard(
                          context,
                          item,
                          isFavorite:
                              favoriteNames.contains(item.name) ||
                              favoriteNames.contains(item.id) ||
                              favoriteNames.contains(item.slug),
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                    ],
                  ],
                ],

                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  List<ChampionshipInfo> _applyFilter(
    List<ChampionshipInfo> list,
    ChampionshipFilter filter,
  ) {
    switch (filter) {
      case ChampionshipFilter.all:
        return list;
      case ChampionshipFilter.featured:
        return list.where((item) => item.isFeatured).toList();
      case ChampionshipFilter.leagues:
        return list.where((item) => item.type == 1).toList();
      case ChampionshipFilter.cups:
        return list
            .where(
              (item) => item.type == 2 || item.type == 4 || !item.hasStandings,
            )
            .toList();
      case ChampionshipFilter.favorites:
        return list;
    }
  }

  Widget _buildSearchBar(
    BuildContext context, {
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A26) : const Color(0xFFEFF2F8),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark ? const Color(0xFF242C40) : const Color(0xFFE2E7F0),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: l10n.translate('search_championship'),
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  onPressed: () {
                    _searchController.clear();
                    _fetchRankings();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context, {
    required int favoriteCount,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final filters = [
      (ChampionshipFilter.all, l10n.translate('filter_all'), null),
      (
        ChampionshipFilter.favorites,
        l10n.translate('filter_favorites'),
        favoriteCount > 0 ? favoriteCount.toString() : null,
      ),
      (ChampionshipFilter.featured, l10n.translate('filter_featured'), null),
      (ChampionshipFilter.leagues, l10n.translate('filter_leagues'), null),
      (ChampionshipFilter.cups, l10n.translate('filter_cups'), null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f.$1;
          final countBadge = f.$3;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => _activeFilter = f.$1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? const Color(0xFF161A26)
                            : const Color(0xFFEFF2F8)),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? const Color(0xFF242C40)
                              : const Color.fromARGB(255, 23, 78, 181)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                    if (countBadge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          countBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReorderTip(
    BuildContext context, {
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2338) : const Color(0xFFE8EEFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3758) : const Color(0xFFCCD9F7),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.drag_indicator_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.translate('long_press_reorder_hint'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF9FB2DB)
                    : const Color(0xFF2D4B85),
              ),
            ),
          ),
          GestureDetector(
            onTap: _dismissTip,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark
                    ? const Color(0xFF9FB2DB)
                    : const Color(0xFF2D4B85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    int? count,
    required bool isDark,
    required bool isArabic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.getHeadingMedium(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF22283A)
                    : const Color(0xFFE5E9F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReorderableFavoritesList(
    BuildContext context,
    List<ChampionshipInfo> favorites, {
    required bool isDark,
    required bool isArabic,
  }) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        context.read<FavoritesCubit>().reorderFavoriteCompetitions(
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final item = favorites[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey('fav_${item.id}_$index'),
          index: index,
          child: _buildChampionshipCard(
            context,
            item,
            isFavorite: true,
            isDark: isDark,
            isArabic: isArabic,
            isReorderable: favorites.length > 1,
          ),
        );
      },
    );
  }

  Widget _buildEmptyFavoritesCard(
    BuildContext context, {
    required bool isDark,
    required AppLocalizations l10n,
    required bool isArabic,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF22283A) : const Color(0xFFE5E9F2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 36,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.translate('no_favorite_championships'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.translate('no_favorite_championships_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSection(
    BuildContext context, {
    required List<String> favoriteNames,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    final search = _searchController.text.trim().toLowerCase();
    final results = _allLeagues.where((item) {
      final name = item.name.toLowerCase();
      final slug = (item.slug ?? '').toLowerCase();
      return name.contains(search) || slug.contains(search);
    }).toList();

    if (results.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('no_championships_found'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          l10n.translate('all_championships'),
          count: results.length,
          isDark: isDark,
          isArabic: isArabic,
        ),
        const SizedBox(height: 8),
        ...results.map(
          (item) => _buildChampionshipCard(
            context,
            item,
            isFavorite:
                favoriteNames.contains(item.name) ||
                favoriteNames.contains(item.id) ||
                favoriteNames.contains(item.slug),
            isDark: isDark,
            isArabic: isArabic,
          ),
        ),
      ],
    );
  }

  Widget _buildChampionshipCard(
    BuildContext context,
    ChampionshipInfo item, {
    required bool isFavorite,
    required bool isDark,
    required bool isArabic,
    bool isReorderable = false,
  }) {
    final title = item.name;
    final normalizedLogo = UrlHelper.normalizeImageUrl(item.logo);
    final l10n = AppLocalizations.of(context);

    // Badge label by competition type
    String? typeBadge;
    Color? typeBadgeColor;
    if (item.type == 1) {
      typeBadge = l10n.translate('championship_type_league');
      typeBadgeColor = const Color(0xFF10B981);
    } else if (item.type == 2 || !item.hasStandings) {
      typeBadge = l10n.translate('championship_type_cup');
      typeBadgeColor = const Color(0xFFF59E0B);
    } else if (item.type == 4) {
      typeBadge = l10n.translate('championship_type_continental');
      typeBadgeColor = const Color(0xFF8B5CF6);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF161A26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final targetTab = item.hasStandings ? 2 : 0;
            try {
              context.push(
                '/league/${item.id}?tab=$targetTab',
                extra: {
                  'title': title,
                  'logo': item.logo.isNotEmpty ? item.logo : null,
                  'tab': targetTab,
                },
              );
            } catch (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => sl<LeagueBloc>(
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
                      initialTabIndex: targetTab,
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
                color: isDark
                    ? const Color(0xFF22283A)
                    : const Color(0xFFE5E9F2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // Logo Container with high-contrast badge background for dark mode
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.transparent : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A3447)
                          : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child:
                        (normalizedLogo != null &&
                            UrlHelper.isValidImageUrl(normalizedLogo))
                        ? CachedNetworkImage(
                            imageUrl: normalizedLogo,
                            memCacheWidth: 64,
                            memCacheHeight: 64,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.emoji_events_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            placeholder: (_, __) => const Icon(
                              Icons.sports_soccer_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : const Icon(
                            Icons.emoji_events_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Type Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                      ),
                      if (typeBadge != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: typeBadgeColor!.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Star Button (toggles user favorites)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite
                        ? Colors.amber
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                    size: 24,
                  ),
                  tooltip: isFavorite ? 'Remove Favorite' : 'Add Favorite',
                  onPressed: () {
                    context.read<FavoritesCubit>().toggleCompetition(item.name);
                  },
                ),

                // Reorder indicator (if reorderable in Favorites list)
                if (isReorderable) ...[
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextMuted.withValues(alpha: 0.5)
                        : AppColors.lightTextMuted.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeletons(bool isDark) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(
          6,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161A26) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF22283A) : const Color(0xFFE5E9F2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B2338)
                        : const Color(0xFFE5E9F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2338)
                          : const Color(0xFFE5E9F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
