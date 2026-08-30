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
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../leagues/presentation/views/league_view.dart';

class ChampionshipInfo {
  final String id;
  final String englishName;
  final String arabicName;
  final String logo;
  final String? country;

  const ChampionshipInfo({
    required this.id,
    required this.englishName,
    required this.arabicName,
    required this.logo,
    this.country,
  });
}

const List<ChampionshipInfo> kAllChampionships = [
  ChampionshipInfo(
    id: '12048',
    englishName: 'UEFA Champions League',
    arabicName: 'دوري أبطال أوروبا',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    country: 'Europe',
  ),
  ChampionshipInfo(
    id: '6811',
    englishName: 'Premier League',
    arabicName: 'الدوري الإنجليزي الممتاز',
    logo: 'https://imgs.ysscores.com/championship/128/3411694791422.png',
    country: 'England',
  ),
  ChampionshipInfo(
    id: '1934',
    englishName: 'Supercopa de España',
    arabicName: 'كأس السوبر الإسباني',
    logo: 'https://imgs.ysscores.com/championship/128/8641690196626.png',
    country: 'Spain',
  ),
  ChampionshipInfo(
    id: '1933',
    englishName: 'LaLiga',
    arabicName: 'الدوري الإسباني',
    logo: 'https://imgs.ysscores.com/championship/128/8641690196626.png',
    country: 'Spain',
  ),
  ChampionshipInfo(
    id: '3734',
    englishName: 'Serie A',
    arabicName: 'الدوري الإيطالي',
    logo: 'https://imgs.ysscores.com/championship/128/6281692568873.png',
    country: 'Italy',
  ),
  ChampionshipInfo(
    id: '2607',
    englishName: 'DFL-Supercup',
    arabicName: 'كأس السوبر الألماني',
    logo: 'https://imgs.ysscores.com/championship/128/6171690288722.png',
    country: 'Germany',
  ),
  ChampionshipInfo(
    id: '2606',
    englishName: 'Bundesliga',
    arabicName: 'الدوري الألماني',
    logo: 'https://imgs.ysscores.com/championship/128/6171690288722.png',
    country: 'Germany',
  ),
  ChampionshipInfo(
    id: '34',
    englishName: 'Ligue 1',
    arabicName: 'الدوري الفرنسي',
    logo: 'https://imgs.ysscores.com/championship/128/9551719862665.png',
    country: 'France',
  ),
  ChampionshipInfo(
    id: '12049',
    englishName: 'UEFA Europa League',
    arabicName: 'الدوري الأوروبي',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    country: 'Europe',
  ),
  ChampionshipInfo(
    id: '941825',
    englishName: 'Saudi Pro League',
    arabicName: 'دوري روشن السعودي',
    logo: 'https://imgs.ysscores.com/championship/128/5111703719091.png',
    country: 'Saudi Arabia',
  ),
  ChampionshipInfo(
    id: '943009',
    englishName: 'Egyptian Premier League',
    arabicName: 'الدوري المصري الممتاز',
    logo: 'https://imgs.ysscores.com/championship/128/4021690823908.png',
    country: 'Egypt',
  ),
  ChampionshipInfo(
    id: '939779',
    englishName: 'Turkish Super Lig',
    arabicName: 'الدوري التركي الممتاز',
    logo: 'https://imgs.ysscores.com/championship/128/1191723239247.png',
    country: 'Turkey',
  ),
  ChampionshipInfo(
    id: '913550',
    englishName: 'MLS',
    arabicName: 'الدوري الأمريكي',
    logo: 'https://imgs.ysscores.com/championship/128/671691408606.png',
    country: 'USA',
  ),
  ChampionshipInfo(
    id: '937276',
    englishName: 'Eredivisie',
    arabicName: 'الدوري الهولندي الممتاز',
    logo: 'https://imgs.ysscores.com/championship/128/2571696547488.png',
    country: 'Netherlands',
  ),
  ChampionshipInfo(
    id: '938823',
    englishName: 'Liga Portugal',
    arabicName: 'الدوري البرتغالي الممتاز',
    logo: 'https://imgs.ysscores.com/championship/128/7301690383928.png',
    country: 'Portugal',
  ),
  ChampionshipInfo(
    id: '937988',
    englishName: 'Belgian Pro League',
    arabicName: 'الدوري البلجيكي',
    logo: 'https://imgs.ysscores.com/championship/128/9251692797287.png',
    country: 'Belgium',
  ),
  ChampionshipInfo(
    id: '3680601',
    englishName: 'Iraqi Premier League',
    arabicName: 'الدوري العراقي',
    logo: 'https://imgs.ysscores.com/championship/128/4931702381720.png',
    country: 'Iraq',
  ),
  ChampionshipInfo(
    id: '935487',
    englishName: 'Danish Superliga',
    arabicName: 'دوري السوبر الدنماركي',
    logo: 'https://imgs.ysscores.com/championship/128/6601696547585.png',
    country: 'Denmark',
  ),
  ChampionshipInfo(
    id: '943010',
    englishName: 'CAF Champions League',
    arabicName: 'دوري أبطال أفريقيا',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    country: 'Africa',
  ),
  ChampionshipInfo(
    id: '943011',
    englishName: 'AFC Champions League',
    arabicName: 'دوري أبطال آسيا',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    country: 'Asia',
  ),
  ChampionshipInfo(
    id: '12050',
    englishName: 'FIFA World Cup',
    arabicName: 'كأس العالم',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    country: 'World',
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
  String _searchQuery = '';
  List<ChampionshipInfo> _apiSearchResults = [];
  late List<ChampionshipInfo> _orderedChampionships;

  @override
  void initState() {
    super.initState();
    _orderedChampionships = List<ChampionshipInfo>.from(kAllChampionships);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query.toLowerCase();
    });

    _debounceTimer?.cancel();
    if (query.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        final lang = AppLocalizations.of(context).isArabic ? 'ar' : 'en';
        _performApiSearch(query, lang);
      });
    } else {
      setState(() {
        _apiSearchResults = [];
      });
    }
  }

  Future<void> _performApiSearch(String query, String lang) async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query, 'lang': lang},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final championships = data['championships'] as List<dynamic>? ?? [];

        final results = championships.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id'].toString();
          final title = map['title']?.toString() ?? '';
          final logo = map['logo']?.toString() ?? '';
          final link = map['link']?.toString() ?? '';

          String tournamentId = id;
          final match = RegExp(r'/championship/(\d+)').firstMatch(link);
          if (match != null) {
            tournamentId = match.group(1)!;
          }

          return ChampionshipInfo(
            id: tournamentId,
            englishName: title,
            arabicName: title,
            logo: logo,
          );
        }).toList();

        if (mounted && _searchQuery == query.toLowerCase()) {
          setState(() {
            _apiSearchResults = results;
          });
        }
      }
    } catch (_) {}
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
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

          final Map<String, ChampionshipInfo> combinedMap = {};
          for (final item in _orderedChampionships) {
            if (_searchQuery.isEmpty ||
                item.englishName.toLowerCase().contains(_searchQuery) ||
                item.arabicName.toLowerCase().contains(_searchQuery) ||
                (item.country?.toLowerCase().contains(_searchQuery) ?? false)) {
              combinedMap[item.id] = item;
            }
          }
          for (final apiItem in _apiSearchResults) {
            if (!combinedMap.containsKey(apiItem.id)) {
              combinedMap[apiItem.id] = apiItem;
            }
          }
          final filteredList = combinedMap.values.toList();

          final favorites = filteredList.where((item) {
            return favoriteNames.contains(item.englishName) ||
                favoriteNames.contains(item.arabicName) ||
                favoriteNames.contains(item.id);
          }).toList();

          final allOther = filteredList.where((item) {
            return !favorites.contains(item);
          }).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Search Bar
              Container(
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
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Long Press Tip Banner
              if (!_isTipDismissed) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2338) : const Color(0xFFE8EEFC),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A3758) : const Color(0xFFCCD9F7),
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
                            color: isDark ? const Color(0xFF9FB2DB) : const Color(0xFF2D4B85),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isTipDismissed = true),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF9FB2DB) : const Color(0xFF2D4B85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Favorite Championships Section
              if (favorites.isNotEmpty) ...[
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
                ...favorites.map(
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

              // 4. All Championships Section
              if (allOther.isNotEmpty) ...[
                if (favorites.isNotEmpty)
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
                ...allOther.map(
                  (item) => _buildChampionshipCard(
                    context,
                    item,
                    isFavorite: false,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
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
    final title = isArabic ? item.arabicName : item.englishName;
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
                color: isDark ? const Color(0xFF22283A) : const Color(0xFFE5E9F2),
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
                    color: isDark ? const Color(0xFF0F121C) : const Color(0xFFF1F3F7),
                    padding: const EdgeInsets.all(4),
                    child: (normalizedLogo != null && normalizedLogo.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: normalizedLogo,
                            memCacheWidth: 64,
                            memCacheHeight: 64,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.emoji_events_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            placeholder: (_, __) => Icon(
                              Icons.sports_soccer_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          )
                        : Icon(
                            Icons.emoji_events_rounded,
                            size: 20,
                            color: isDark
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
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
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
                  onPressed: () {
                    context.read<FavoritesCubit>().toggleCompetition(
                          isArabic ? item.arabicName : item.englishName,
                        );
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
