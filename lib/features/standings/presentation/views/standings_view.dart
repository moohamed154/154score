import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/starred_button.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../leagues/presentation/views/league_view.dart';
import '../../../settings/presentation/cubit/settings_cubits.dart';

enum StandingsTab { favorites, hidden }

class ChampionshipInfo {
  final String id;
  final String? seasonId;
  final String name;
  final String? slug;
  final String logo;
  final String? logoLight;
  final bool hasStandings;
  final bool isFeatured;
  final bool isFavorite;
  final int? type;
  final String? typeName;
  final bool hasScorers;
  final bool hasCups;
  final int? rank;

  const ChampionshipInfo({
    required this.id,
    this.seasonId,
    required this.name,
    this.slug,
    required this.logo,
    this.logoLight,
    this.hasStandings = true,
    this.isFeatured = false,
    this.isFavorite = false,
    this.type,
    this.typeName,
    this.hasScorers = true,
    this.hasCups = false,
    this.rank,
  });

  factory ChampionshipInfo.fromJson(Map<String, dynamic> json) {
    final leagueId =
        json['league_id']?.toString() ?? json['id']?.toString() ?? '';
    final seasonId =
        json['season_id']?.toString() ?? json['url_id']?.toString();
    final name =
        json['name']?.toString() ??
        json['title2']?.toString() ??
        json['title']?.toString() ??
        '';
    final slug = json['slug']?.toString();
    final rawImage = json['image']?.toString();
    final logo =
        json['logo']?.toString() ??
        (rawImage != null && rawImage.isNotEmpty
            ? 'https://imgs.ysscores.com/championship/128/$rawImage'
            : '');
    final rawImageLight = json['image_light']?.toString();
    final logoLight =
        json['logo_light']?.toString() ??
        (rawImageLight != null && rawImageLight.isNotEmpty
            ? 'https://imgs.ysscores.com/championship/128/$rawImageLight'
            : null);
    final hasStandings =
        json['has_standings'] as bool? ?? (json['standings'] == 1);
    final isFeatured = json['is_featured'] as bool? ?? (json['followed'] == 1);
    final isFavorite = json['is_favorite'] as bool? ?? (json['followed'] == 1);
    final type = json['type'] is int
        ? json['type'] as int
        : int.tryParse(json['type']?.toString() ?? '');
    final typeName = json['type_name']?.toString();
    final hasScorers =
        json['has_scorers'] as bool? ?? (json['players_st'] == 1);
    final hasCups = json['has_cups'] as bool? ?? (json['cups'] != null);
    final rank = json['rank'] is int
        ? json['rank'] as int
        : int.tryParse(json['rank']?.toString() ?? '');

    return ChampionshipInfo(
      id: leagueId.isNotEmpty ? leagueId : (seasonId ?? ''),
      seasonId: seasonId,
      name: name,
      slug: slug,
      logo: logo,
      logoLight: logoLight,
      hasStandings: hasStandings,
      isFeatured: isFeatured,
      isFavorite: isFavorite,
      type: type,
      typeName: typeName,
      hasScorers: hasScorers,
      hasCups: hasCups,
      rank: rank,
    );
  }

  Map<String, dynamic> toJson() => {
    'league_id': id,
    'season_id': seasonId,
    'name': name,
    'slug': slug,
    'logo': logo,
    'logo_light': logoLight,
    'has_standings': hasStandings,
    'is_featured': isFeatured,
    'is_favorite': isFavorite,
    'type': type,
    'type_name': typeName,
    'has_scorers': hasScorers,
    'has_cups': hasCups,
    'rank': rank,
  };
}

const List<ChampionshipInfo> kDefaultFallbackChampionshipsAr = [
  ChampionshipInfo(
    id: '12048',
    seasonId: '943230',
    name: 'دوري أبطال أوروبا',
    slug: 'UEFA-Champions-League',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    isFeatured: true,
    isFavorite: true,
    type: 4,
  ),
  ChampionshipInfo(
    id: '6811',
    seasonId: '937599',
    name: 'الدوري الإنجليزي الممتاز',
    slug: 'Premier-League',
    logo: 'https://imgs.ysscores.com/championship/128/3411694791422.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '88013',
    seasonId: '59771441',
    name: 'كأس السوبر الإسباني',
    slug: 'Supercopa-de-España',
    logo: 'https://imgs.ysscores.com/championship/128/5481703687014.png',
    isFeatured: true,
    isFavorite: true,
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
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '3734',
    seasonId: '936357',
    name: 'الدوري الإيطالي',
    slug: 'Serie-A',
    logo: 'https://imgs.ysscores.com/championship/128/6281692568873.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '2606',
    seasonId: '938769',
    name: 'الدوري الألماني',
    slug: 'Bundesliga',
    logo: 'https://imgs.ysscores.com/championship/128/6171690288722.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '1985',
    seasonId: '937873',
    name: 'الدوري الفرنسي',
    slug: 'Ligue-1',
    logo: 'https://imgs.ysscores.com/championship/128/9551719862665.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '7167',
    seasonId: '941825',
    name: 'الدوري السعودي للمحترفين',
    slug: 'Saudi-Pro-League',
    logo: 'https://imgs.ysscores.com/championship/128/5111703719091.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
];

const List<ChampionshipInfo> kDefaultFallbackChampionshipsEn = [
  ChampionshipInfo(
    id: '12048',
    seasonId: '943230',
    name: 'UEFA Champions League',
    slug: 'UEFA-Champions-League',
    logo: 'https://imgs.ysscores.com/championship/128/5171696546919.png',
    isFeatured: true,
    isFavorite: true,
    type: 4,
  ),
  ChampionshipInfo(
    id: '6811',
    seasonId: '937599',
    name: 'Premier League',
    slug: 'Premier-League',
    logo: 'https://imgs.ysscores.com/championship/128/3411694791422.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '88013',
    seasonId: '59771441',
    name: 'Supercopa de España',
    slug: 'Supercopa-de-España',
    logo: 'https://imgs.ysscores.com/championship/128/5481703687014.png',
    isFeatured: true,
    isFavorite: true,
    type: 2,
    hasStandings: false,
  ),
  ChampionshipInfo(
    id: '1933',
    seasonId: '938652',
    name: 'LaLiga',
    slug: 'LaLiga',
    logo: 'https://imgs.ysscores.com/championship/128/8641690196626.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '3734',
    seasonId: '936357',
    name: 'Serie A',
    slug: 'Serie-A',
    logo: 'https://imgs.ysscores.com/championship/128/6281692568873.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '2606',
    seasonId: '938769',
    name: 'Bundesliga',
    slug: 'Bundesliga',
    logo: 'https://imgs.ysscores.com/championship/128/6171690288722.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '1985',
    seasonId: '937873',
    name: 'Ligue 1',
    slug: 'Ligue-1',
    logo: 'https://imgs.ysscores.com/championship/128/9551719862665.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
  ChampionshipInfo(
    id: '7167',
    seasonId: '941825',
    name: 'Saudi Pro League',
    slug: 'Saudi-Pro-League',
    logo: 'https://imgs.ysscores.com/championship/128/5111703719091.png',
    isFeatured: true,
    isFavorite: true,
    type: 1,
  ),
];

List<ChampionshipInfo> getDefaultFallbackChampionships(String lang) {
  return lang == 'en'
      ? kDefaultFallbackChampionshipsEn
      : kDefaultFallbackChampionshipsAr;
}

const List<ChampionshipInfo> kDefaultFallbackChampionships =
    kDefaultFallbackChampionshipsAr;

class StandingsView extends StatefulWidget {
  final String? initialLeagueId;

  const StandingsView({super.key, this.initialLeagueId});

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isLoading = true;
  String? _errorMessage;
  StandingsTab _activeTab = StandingsTab.favorites;
  List<ChampionshipInfo>? _tabHiddenBaseline;
  List<ChampionshipInfo>? _tabFavoritesBaseline;

  List<ChampionshipInfo> _featuredLeagues = [];
  List<ChampionshipInfo> _allLeagues = [];

  // Cached partitioned lists to avoid O(N * M) calculations in build()
  List<ChampionshipInfo> _memoizedFavorites = [];
  List<ChampionshipInfo> _memoizedHidden = [];
  List<String> _lastPartitionFavKeys = [];
  int _lastPartitionAllLeaguesCount = -1;
  String _lastPartitionLang = '';

  void _switchTab(StandingsTab tab) {
    if (_activeTab != tab) {
      setState(() {
        _activeTab = tab;
        _tabFavoritesBaseline = List<ChampionshipInfo>.from(_memoizedFavorites);
        _tabHiddenBaseline = List<ChampionshipInfo>.from(_memoizedHidden);
      });
    }
  }

  void _updatePartitionedLists(
    List<String> currentFavKeys,
    FavoritesState favState,
  ) {
    final currentLang = sl<LocalStorageService>().getLanguage();
    final bool favKeysChanged =
        _lastPartitionFavKeys.length != currentFavKeys.length ||
        !_lastPartitionFavKeys.every((k) => currentFavKeys.contains(k));
    final bool leaguesChanged =
        _lastPartitionAllLeaguesCount != _allLeagues.length;
    final bool langChanged = _lastPartitionLang != currentLang;

    if (!favKeysChanged &&
        !leaguesChanged &&
        !langChanged &&
        _memoizedFavorites.isNotEmpty) {
      return;
    }

    _lastPartitionFavKeys = List<String>.from(currentFavKeys);
    _lastPartitionAllLeaguesCount = _allLeagues.length;
    _lastPartitionLang = currentLang;

    // 1. Build fast lookup sets - O(M) once
    final favSet = <String>{};
    final favCanonicalSet = <String>{};
    for (final key in currentFavKeys) {
      final clean = key.trim().toLowerCase();
      favSet.add(clean);
      final rId = LeagueResolver.resolveId(key);
      if (rId != null && rId.isNotEmpty) favCanonicalSet.add(rId);
      final norm = LeagueResolver.normalize(key);
      if (norm.isNotEmpty) favCanonicalSet.add(norm);
    }

    // 2. Pre-index available leagues for fast O(1) matching
    final Map<String, ChampionshipInfo> leagueById = {};
    final Map<String, ChampionshipInfo> leagueByCanonical = {};
    final Map<String, ChampionshipInfo> leagueByName = {};

    for (final l in _allLeagues) {
      if (l.id.isNotEmpty) leagueById[l.id] = l;
      if (l.seasonId != null && l.seasonId!.isNotEmpty) {
        leagueById[l.seasonId!] = l;
      }
      final cleanName = l.name.trim().toLowerCase();
      leagueByName[cleanName] = l;
      final rId =
          LeagueResolver.resolveId(l.name) ??
          (l.id.isNotEmpty ? LeagueResolver.resolveId(l.id) : null);
      if (rId != null && rId.isNotEmpty) leagueByCanonical[rId] = l;
      final norm = LeagueResolver.normalize(l.name);
      if (norm.isNotEmpty) leagueByCanonical[norm] = l;
    }
    for (final l in _featuredLeagues) {
      if (l.id.isNotEmpty && !leagueById.containsKey(l.id)) {
        leagueById[l.id] = l;
      }
      final cleanName = l.name.trim().toLowerCase();
      if (!leagueByName.containsKey(cleanName)) {
        leagueByName[cleanName] = l;
      }
      final rId =
          LeagueResolver.resolveId(l.name) ??
          (l.id.isNotEmpty ? LeagueResolver.resolveId(l.id) : null);
      if (rId != null &&
          rId.isNotEmpty &&
          !leagueByCanonical.containsKey(rId)) {
        leagueByCanonical[rId] = l;
      }
      final norm = LeagueResolver.normalize(l.name);
      if (norm.isNotEmpty && !leagueByCanonical.containsKey(norm)) {
        leagueByCanonical[norm] = l;
      }
    }

    // 3. Match favorite cards in user order in O(1) per key
    final List<ChampionshipInfo> favoriteCards = [];
    final Set<String> addedFavIds = {};

    for (final key in currentFavKeys) {
      final cleanKey = key.trim().toLowerCase();
      final rKey = LeagueResolver.resolveId(key);
      final normKey = LeagueResolver.normalize(key);

      ChampionshipInfo? matched =
          leagueById[key] ??
          leagueByName[cleanKey] ??
          (rKey != null ? leagueByCanonical[rKey] : null) ??
          (normKey.isNotEmpty ? leagueByCanonical[normKey] : null);

      if (matched != null && addedFavIds.add(matched.id)) {
        favoriteCards.add(matched);
      }
    }

    // Also include any league marked favorite directly in favState
    for (final l in _allLeagues) {
      if (!addedFavIds.contains(l.id)) {
        final rId = LeagueResolver.resolveId(l.name);
        final norm = LeagueResolver.normalize(l.name);
        if (favSet.contains(l.id) ||
            favSet.contains(l.name.trim().toLowerCase()) ||
            (rId != null && favCanonicalSet.contains(rId)) ||
            (norm.isNotEmpty && favCanonicalSet.contains(norm)) ||
            favState.isFavoriteCompetition(
              id: l.id,
              name: l.name,
              slug: l.slug,
            )) {
          addedFavIds.add(l.id);
          favoriteCards.add(l);
        }
      }
    }

    // 4. Hidden cards are the rest of _allLeagues
    final List<ChampionshipInfo> hiddenCards = [];
    for (final l in _allLeagues) {
      if (!addedFavIds.contains(l.id)) {
        hiddenCards.add(l);
      }
    }

    _memoizedFavorites = favoriteCards;
    _memoizedHidden = hiddenCards;
    // Retain active baseline while user is in tab to prevent jarring shifts & allow star animations to complete
    _tabFavoritesBaseline ??= List<ChampionshipInfo>.from(favoriteCards);
    _tabHiddenBaseline ??= List<ChampionshipInfo>.from(hiddenCards);
  }

  @override
  void initState() {
    super.initState();

    final storage = sl<LocalStorageService>();
    final currentLang = storage.getLanguage();

    // 1. Startup: Load fallback championships instantly for 0ms initial frame
    final fallbacks = getDefaultFallbackChampionships(currentLang);
    _featuredLeagues = List<ChampionshipInfo>.from(fallbacks);
    _allLeagues = List<ChampionshipInfo>.from(fallbacks);

    _searchController.addListener(_onSearchChanged);

    // 2. Load cached full directory asynchronously & fetch fresh network data post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCachedRankingsAsync(currentLang).then((_) {
        if (mounted) {
          _fetchRankings(lang: currentLang);
        }
      });
    });
  }

  Future<void> _loadCachedRankingsAsync(String lang) async {
    final storage = sl<LocalStorageService>();
    final cachedData = storage.getCachedRankings(lang: lang);
    if (cachedData == null || cachedData.isEmpty) return;

    try {
      final decoded = await Future.microtask(() => jsonDecode(cachedData));
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

        if (!mounted) return;
        if (cachedAll.isNotEmpty || cachedFeatured.isNotEmpty) {
          setState(() {
            _featuredLeagues = cachedFeatured;
            _allLeagues = cachedAll.isNotEmpty ? cachedAll : cachedFeatured;
            _isLoading = false;
            // Update baseline with full cached catalog
            _tabFavoritesBaseline = null;
            _tabHiddenBaseline = null;
            _lastPartitionFavKeys.clear();
          });
        }
      }
    } catch (_) {}
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchRankings({String search = '', String? lang}) async {
    final effectiveLang = lang ?? sl<LocalStorageService>().getLanguage();
    try {
      final queryParams = <String, dynamic>{'lang': effectiveLang};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final apiClient = sl<ApiClient>();
      final dynamic response = await apiClient.get(
        ApiEndpoints.rank,
        queryParameters: queryParams,
      );

      // Race condition check: make sure user didn't switch language while request was in-flight
      final currentLang = sl<LocalStorageService>().getLanguage();
      if (currentLang != effectiveLang) {
        return;
      }

      Map<String, dynamic>? resMap;
      if (response is Map) {
        resMap = Map<String, dynamic>.from(response);
      }

      if (resMap != null && resMap['data'] != null && resMap['data'] is Map) {
        final data = Map<String, dynamic>.from(resMap['data'] as Map);

        final featuredRaw =
            data['favorites'] as List? ?? (data['featured'] as List? ?? []);
        final leaguesRaw =
            data['all'] as List? ?? (data['leagues'] as List? ?? []);

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

        // Cache the remote data per language
        if (search.isEmpty &&
            (fetchedAll.isNotEmpty || fetchedFeatured.isNotEmpty)) {
          try {
            unawaited(
              sl<LocalStorageService>().setCachedRankings(
                jsonEncode({
                  'featured': fetchedFeatured.map((e) => e.toJson()).toList(),
                  'leagues': fetchedAll.map((e) => e.toJson()).toList(),
                }),
                lang: effectiveLang,
              ),
            );

            final titlesMap = <String, String>{};
            for (final l in [...fetchedFeatured, ...fetchedAll]) {
              if (l.name.isNotEmpty) {
                titlesMap[l.id] = l.name;
                titlesMap[l.name.trim().toLowerCase()] = l.id;
                if (l.seasonId != null && l.seasonId!.isNotEmpty) {
                  titlesMap[l.seasonId!] = l.name;
                }
              }
            }
            if (titlesMap.isNotEmpty) {
              unawaited(
                sl<LocalStorageService>().registerCompetitionTitles(titlesMap),
              );
            }
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavoriteItem(
    BuildContext context,
    ChampionshipInfo item,
    List<ChampionshipInfo> currentFavorites,
  ) {
    context.read<FavoritesCubit>().toggleCompetition(
      id: item.id,
      name: item.name,
      slug: item.slug,
    );
  }

  void _onReorderFavorites(
    BuildContext context,
    int oldIndex,
    int newIndex,
    List<ChampionshipInfo> currentFavorites,
  ) {
    final list = List<ChampionshipInfo>.from(currentFavorites);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    _tabFavoritesBaseline = List<ChampionshipInfo>.from(list);
    _memoizedFavorites = List<ChampionshipInfo>.from(list);
    final identifiers = list
        .map((e) => e.id.isNotEmpty ? e.id : e.name)
        .toList();
    _lastPartitionFavKeys = List<String>.from(identifiers);
    context.read<FavoritesCubit>().setFavoriteCompetitions(identifiers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final storage = sl<LocalStorageService>();

    // Centralized AppColors Tokens
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    const primary = AppColors.primary;

    return BlocListener<LocaleCubit, LocaleState>(
      listenWhen: (prev, curr) => prev.locale != curr.locale,
      listener: (context, localeState) {
        final targetLang = localeState.locale.languageCode;
        final fallbacks = getDefaultFallbackChampionships(targetLang);
        setState(() {
          _featuredLeagues = List<ChampionshipInfo>.from(fallbacks);
          _allLeagues = List<ChampionshipInfo>.from(fallbacks);
          _tabFavoritesBaseline = null;
          _tabHiddenBaseline = null;
          _lastPartitionFavKeys.clear();
        });
        _loadCachedRankingsAsync(targetLang).then((_) {
          if (mounted) _fetchRankings(lang: targetLang);
        });
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              final currentFavKeys = favState.favoriteCompetitions.isNotEmpty
                  ? favState.favoriteCompetitions
                  : (storage.hasCustomFavoriteCompetitions()
                        ? <String>[]
                        : _featuredLeagues.map((e) => e.name).toList());

              // Fast O(1) partitioned list calculation with memoization
              _updatePartitionedLists(currentFavKeys, favState);

              final favoriteCards =
                  _tabFavoritesBaseline ?? _memoizedFavorites;
              final hiddenCards =
                  _tabHiddenBaseline ?? _memoizedHidden;

              final isFavoritesTab = _activeTab == StandingsTab.favorites;

              // Search query filtering
              final searchQuery = _searchController.text.trim().toLowerCase();
              final List<ChampionshipInfo> searchList = searchQuery.isEmpty
                  ? const []
                  : (isFavoritesTab ? favoriteCards : _allLeagues)
                        .where(
                          (c) =>
                              c.name.toLowerCase().contains(searchQuery) ||
                              (c.slug ?? '').toLowerCase().contains(
                                searchQuery,
                              ),
                        )
                        .toList();

              return Column(
                children: [
                  // 1. Top Brand Bar (identical to Home screen style)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        AppBrandLogo(size: 40, isDark: isDark),
                        const SizedBox(width: 10),
                        Text(
                          '154Score',
                          style:
                              AppTypography.getHeadingLarge(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Capsule Search Bar (Pinned)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: _buildSearchBar(
                      context,
                      isDark: isDark,
                      l10n: l10n,
                      surfaceBg: surfaceBg,
                      cardBorder: cardBorder,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. YallaShoot 2-Segment Control Pill with App Brand Colors
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSegmentControl(
                      context,
                      favoritesCount: _memoizedFavorites.length,
                      hiddenCount: _memoizedHidden.length,
                      isDark: isDark,
                      l10n: l10n,
                      primary: primary,
                      surfaceBg: surfaceBg,
                      cardBorder: cardBorder,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Scrollable Content Area with 0ms Tab Switching
                  Expanded(
                    child: RefreshIndicator(
                      color: primary,
                      onRefresh: () async {
                        try {
                          _lastPartitionFavKeys.clear();
                          _lastPartitionAllLeaguesCount = -1;
                          _tabFavoritesBaseline = null;
                          _tabHiddenBaseline = null;
                          await _fetchRankings(
                            search: _searchController.text.trim(),
                          ).timeout(const Duration(milliseconds: 3500));
                        } catch (_) {}
                      },
                      child: _isLoading && _allLeagues.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildLoadingSkeletons(
                                isDark,
                                cardBg,
                                cardBorder,
                              ),
                            )
                          : _errorMessage != null && _allLeagues.isEmpty
                          ? ErrorView(
                              message: _errorMessage!,
                              onRetry: () => _fetchRankings(),
                            )
                          : searchQuery.isNotEmpty
                          ? (searchList.isEmpty
                              ? _buildEmptyState(
                                  isFavorites: isFavoritesTab,
                                  isSearching: true,
                                  isDark: isDark,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  primary: primary,
                                  l10n: l10n,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  itemCount: searchList.length,
                                  itemBuilder: (context, index) {
                                    final item = searchList[index];
                                    final isFav = favState.isFavoriteCompetition(
                                      id: item.id,
                                      name: item.name,
                                      slug: item.slug,
                                    );
                                    return _buildChampionshipCard(
                                      key: ValueKey('search_${item.id}'),
                                      context: context,
                                      item: item,
                                      index: index,
                                      isFavorite: isFav,
                                      isDark: isDark,
                                      isArabic: isArabic,
                                      isSearching: true,
                                      cardBg: cardBg,
                                      cardBorder: cardBorder,
                                      onToggleStar: () => _toggleFavoriteItem(
                                        context,
                                        item,
                                        favoriteCards,
                                      ),
                                    );
                                  },
                                ))
                          : IndexedStack(
                              index: isFavoritesTab ? 0 : 1,
                              children: [
                                // 1. Favorites Tab List
                                favoriteCards.isEmpty
                                    ? _buildEmptyState(
                                        isFavorites: true,
                                        isSearching: false,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        cardBorder: cardBorder,
                                        primary: primary,
                                        l10n: l10n,
                                      )
                                    : ReorderableListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        itemCount: favoriteCards.length,
                                        buildDefaultDragHandles: false,
                                        // ignore: deprecated_member_use
                                        onReorder: (oldIndex, newIndex) {
                                          _onReorderFavorites(
                                            context,
                                            oldIndex,
                                            newIndex,
                                            favoriteCards,
                                          );
                                        },
                                        itemBuilder: (context, index) {
                                          final item = favoriteCards[index];
                                          final isFav = favState
                                              .isFavoriteCompetition(
                                                id: item.id,
                                                name: item.name,
                                                slug: item.slug,
                                              );
                                          return _buildChampionshipCard(
                                            key: ValueKey('fav_${item.id}'),
                                            context: context,
                                            item: item,
                                            index: index,
                                            isFavorite: isFav,
                                            isDark: isDark,
                                            isArabic: isArabic,
                                            isSearching: false,
                                            cardBg: cardBg,
                                            cardBorder: cardBorder,
                                            onToggleStar: () =>
                                                _toggleFavoriteItem(
                                                  context,
                                                  item,
                                                  favoriteCards,
                                                ),
                                          );
                                        },
                                      ),

                                // 2. Hidden Tab List
                                hiddenCards.isEmpty
                                    ? _buildEmptyState(
                                        isFavorites: false,
                                        isSearching: false,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        cardBorder: cardBorder,
                                        primary: primary,
                                        l10n: l10n,
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        itemCount: hiddenCards.length,
                                        itemBuilder: (context, index) {
                                          final item = hiddenCards[index];
                                          final isFav = favState
                                              .isFavoriteCompetition(
                                                id: item.id,
                                                name: item.name,
                                                slug: item.slug,
                                              );
                                          return _buildChampionshipCard(
                                            key: ValueKey('hidden_${item.id}'),
                                            context: context,
                                            item: item,
                                            index: index,
                                            isFavorite: isFav,
                                            isDark: isDark,
                                            isArabic: isArabic,
                                            isSearching: false,
                                            cardBg: cardBg,
                                            cardBorder: cardBorder,
                                            onToggleStar: () =>
                                                _toggleFavoriteItem(
                                                  context,
                                                  item,
                                                  favoriteCards,
                                                ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context, {
    required bool isDark,
    required AppLocalizations l10n,
    required Color surfaceBg,
    required Color cardBorder,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 0.8),
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
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSegmentControl(
    BuildContext context, {
    required int favoritesCount,
    required int hiddenCount,
    required bool isDark,
    required AppLocalizations l10n,
    required Color primary,
    required Color surfaceBg,
    required Color cardBorder,
  }) {
    final isFavoritesActive = _activeTab == StandingsTab.favorites;
    final favTitle = l10n.translate('filter_favorites');
    final hiddenTitle = l10n.translate('filter_hidden');

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 0.8),
      ),
      child: Row(
        children: [
          // 1. Favorites Segment
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _switchTab(StandingsTab.favorites),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isFavoritesActive ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFavoritesActive
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                        color: isFavoritesActive
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        favTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isFavoritesActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isFavoritesActive
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isFavoritesActive
                              ? Colors.black.withValues(alpha: 0.22)
                              : (isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCardElevated),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$favoritesCount',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isFavoritesActive
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Hidden Segment
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _switchTab(StandingsTab.hidden),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !isFavoritesActive ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        !isFavoritesActive
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                        color: !isFavoritesActive
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hiddenTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: !isFavoritesActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: !isFavoritesActive
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: !isFavoritesActive
                              ? Colors.black.withValues(alpha: 0.22)
                              : (isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCardElevated),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$hiddenCount',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: !isFavoritesActive
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionshipCard({
    Key? key,
    required BuildContext context,
    required ChampionshipInfo item,
    required int index,
    required bool isFavorite,
    required bool isDark,
    required bool isArabic,
    required bool isSearching,
    required Color cardBg,
    required Color cardBorder,
    required VoidCallback onToggleStar,
  }) {
    final title = item.name;
    final normalizedLogo = UrlHelper.normalizeImageUrl(item.logo);
    final targetLeagueId = (item.seasonId != null && item.seasonId!.isNotEmpty)
        ? item.seasonId!
        : item.id;

    return RepaintBoundary(
      key: key,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final targetTab = item.hasStandings ? 1 : 0;
            try {
              context.push(
                '/league/$targetLeagueId?tab=$targetTab',
                extra: {
                  'title': title,
                  'logo': item.logo.isNotEmpty ? item.logo : null,
                  'tab': targetTab,
                  'season_id': item.seasonId,
                  'champ_id': item.id,
                },
              );
            } catch (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => sl<LeagueBloc>(
                      param1: targetLeagueId,
                      param2: {
                        'title': title,
                        'logo': item.logo.isNotEmpty ? item.logo : null,
                        'season_id': item.seasonId,
                        'champ_id': item.id,
                      },
                    ),
                    child: LeagueView(
                      leagueId: targetLeagueId,
                      initialTitle: title,
                      initialLogo: item.logo.isNotEmpty ? item.logo : null,
                      initialTabIndex: targetTab,
                    ),
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // 1. Reorder Drag Handle (in Favorites tab when not searching)
                if (isFavorite && !isSearching) ...[
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      color: Colors.transparent,
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],

                // 2. Championship Logo
                SizedBox(
                  width: 34,
                  height: 34,
                  child:
                      (normalizedLogo != null &&
                          UrlHelper.isValidImageUrl(normalizedLogo))
                      ? CachedNetworkImage(
                          imageUrl: normalizedLogo,
                          memCacheWidth: 68,
                          memCacheHeight: 68,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.emoji_events_rounded,
                            size: 22,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          placeholder: (_, __) => Icon(
                            Icons.sports_soccer_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        )
                      : Icon(
                          Icons.emoji_events_rounded,
                          size: 22,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                ),
                const SizedBox(width: 14),

                // 3. Name
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),

                // 4. Star Action Button
                StarredButton(
                  key: ValueKey('star_champ_${item.id}'),
                  isStarred: isFavorite,
                  size: 22,
                  padding: const EdgeInsets.all(4),
                  onTap: onToggleStar,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState({
    required bool isFavorites,
    required bool isSearching,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color primary,
    required AppLocalizations l10n,
  }) {
    if (isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFavorites
                    ? AppColors.yellowCard.withValues(alpha: 0.15)
                    : primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavorites ? Icons.star_rounded : Icons.visibility_off_rounded,
                size: 36,
                color: isFavorites ? AppColors.yellowCard : primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isFavorites
                  ? l10n.translate('no_favorite_championships')
                  : (l10n.isArabic
                        ? 'لا توجد بطولات مخفية'
                        : 'No hidden championships'),
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
              isFavorites
                  ? l10n.translate('no_favorite_championships_hint')
                  : (l10n.isArabic
                        ? 'اضغط على النجمة بجانب أي بطولة لإخفائها'
                        : 'Tap the star on any competition to manage it'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeletons(bool isDark, Color cardBg, Color cardBorder) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(
          8,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 56,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightCardElevated,
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
