import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../standings/presentation/widgets/standings_table.dart';
import '../../domain/entities/team_entity.dart';
import '../bloc/team_bloc.dart';
import '../bloc/team_event.dart';
import '../bloc/team_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../widgets/team_header_card.dart';

class TeamView extends StatefulWidget {
  final String teamId;
  final String? initialName;
  final String? initialLogo;
  final String? leagueId;

  const TeamView({
    super.key,
    required this.teamId,
    this.initialName,
    this.initialLogo,
    this.leagueId,
  });

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _transfersSegmentIndex = 0; // 0: Important, 1: All

  @override
  void initState() {
    super.initState();
    // 6 Tabs: Matches, News, Standings, Players, Information, Transfers
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<TeamBloc>().add(ChangeTeamTabEvent(_tabController.index));
      }
    });

    context.read<TeamBloc>().add(
      LoadTeamProfileEvent(
        widget.teamId,
        teamName: widget.initialName,
        leagueId: widget.leagueId,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isNotificationActive(String? id, String? name, [FavoritesState? favState]) {
    try {
      final storage = sl<LocalStorageService>();
      final cleanId = id?.trim();
      final cleanName = name?.trim();

      if (cleanId != null && cleanId.isNotEmpty && storage.isTeamNotificationMuted(cleanId)) {
        return false;
      }
      if (cleanName != null && cleanName.isNotEmpty && storage.isTeamNotificationMuted(cleanName)) {
        return false;
      }

      // If team is starred, notification is enabled!
      final isStarred = favState != null
          ? favState.isFavoriteTeam(id: cleanId, name: cleanName)
          : storage.isFavoriteTeam(cleanName ?? '', id: cleanId);
      if (isStarred) {
        return true;
      }

      if (cleanId != null && cleanId.isNotEmpty && storage.isTeamNotificationEnabled(cleanId)) {
        return true;
      }
      if (cleanName != null && cleanName.isNotEmpty && storage.isTeamNotificationEnabled(cleanName)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _toggleNotification(String? id, String name, bool isArabic) async {
    try {
      final storage = sl<LocalStorageService>();
      final keyToToggle = (id != null && id.trim().isNotEmpty) ? id.trim() : name.trim();
      if (keyToToggle.isEmpty) return;

      final isCurrentlyActive = _isNotificationActive(id, name);
      final newStatus = !isCurrentlyActive;

      if (newStatus) {
        await storage.setTeamNotificationMuted(keyToToggle, false);
        if (!storage.isTeamNotificationEnabled(keyToToggle)) {
          await storage.toggleTeamNotification(keyToToggle);
        }
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_off_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'يرجى تفعيل إذن الإشعارات من إعدادات الهاتف لتلقي التنبيهات'
                          : 'Please enable notifications in device settings to receive alerts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        await storage.setTeamNotificationMuted(keyToToggle, true);
        if (storage.isTeamNotificationEnabled(keyToToggle)) {
          await storage.toggleTeamNotification(keyToToggle);
        }
      }

      if (name.trim().isNotEmpty && name.trim().toLowerCase() != keyToToggle.toLowerCase()) {
        if (newStatus) {
          await storage.setTeamNotificationMuted(name.trim(), false);
        } else {
          await storage.setTeamNotificationMuted(name.trim(), true);
        }
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: newStatus ? AppColors.primary : const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    newStatus
                        ? (isArabic
                            ? 'تم تفعيل إشعارات مباريات $name'
                            : 'Match notifications enabled for $name')
                        : (isArabic
                            ? 'تم إيقاف إشعارات مباريات $name'
                            : 'Match notifications disabled for $name'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: newStatus
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : const Color(0xFF334155),
                width: 1,
              ),
            ),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return BlocBuilder<TeamBloc, TeamState>(
      builder: (context, state) {
        final displayName =
            state.profile?.teamName ??
            state.teamName ??
            widget.initialName ??
            'Team';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              displayName,
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, favState) {
                  final effectiveTeamId = state.profile?.teamId ?? state.teamId;
                  final isNotifActive = _isNotificationActive(
                    effectiveTeamId,
                    displayName,
                    favState,
                  );
                  return IconButton(
                    icon: Icon(
                      isNotifActive
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: isNotifActive ? AppColors.primary : null,
                      size: 24,
                    ),
                    tooltip: isArabic
                        ? (isNotifActive
                            ? 'إيقاف إشعارات المباريات'
                            : 'تفعيل إشعارات المباريات')
                        : (isNotifActive
                            ? 'Mute match notifications'
                            : 'Enable match notifications'),
                    onPressed: () => _toggleNotification(
                      effectiveTeamId,
                      displayName,
                      isArabic,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Team Header Card
              TeamHeaderCard(
                profile: state.profile,
                fallbackName: displayName,
                fallbackLogo: state.teamLogo ?? widget.initialLogo,
                isLoading:
                    state.status == TeamStatus.loading || state.profile == null,
              ),

              // Tab Bar (6 Tabs)
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  unselectedLabelColor: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  labelStyle: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: isArabic ? 'المباريات' : 'Matches'),
                    Tab(text: isArabic ? 'الأخبار' : 'News'),
                    Tab(text: isArabic ? 'الترتيب' : 'Standings'),
                    Tab(text: isArabic ? 'اللاعبين' : 'Players'),
                    Tab(text: isArabic ? 'معلومات' : 'Information'),
                    Tab(text: isArabic ? 'الانتقالات' : 'Transfers'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tab Body with RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final completer = Completer<void>();
                    context.read<TeamBloc>().add(
                      LoadTeamProfileEvent(
                        widget.teamId,
                        teamName: widget.initialName,
                        leagueId: widget.leagueId,
                        isRefresh: true,
                        completer: completer,
                      ),
                    );
                    try {
                      await completer.future.timeout(
                        const Duration(seconds: 4),
                      );
                    } catch (_) {}
                  },
                  child: state.status == TeamStatus.loading
                      ? Skeletonizer(
                          enabled: true,
                          child: ListView(
                            padding: const EdgeInsets.only(
                              bottom: AppDimensions.xxxl,
                              top: 8,
                            ),
                            children: [
                              Skeleton.ignore(
                                child: SectionHeader(
                                  title: isArabic
                                      ? 'المباريات القادمة'
                                      : 'Upcoming Matches',
                                ),
                              ),
                              ...List.generate(
                                8,
                                (i) => MatchCard(
                                  match: MatchEntity(
                                    id: 'skeleton_$i',
                                    team1: displayName,
                                    team2: isArabic
                                        ? 'نادي منافس'
                                        : 'Opponent FC',
                                    score1: '0',
                                    score2: '0',
                                    status: 'لم تبدأ',
                                    time: '22:00',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : state.status == TeamStatus.error
                      ? ErrorView(
                          message: state.errorMessage,
                          onRetry: () => context.read<TeamBloc>().add(
                            LoadTeamProfileEvent(
                              widget.teamId,
                              teamName: widget.initialName,
                              leagueId: widget.leagueId,
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildMatchesTab(context, state, isDark, isArabic),
                            _buildNewsTab(context, state, isDark, isArabic),
                            _buildStandingsTab(
                              context,
                              state,
                              isDark,
                              isArabic,
                              displayName,
                            ),
                            _buildPlayersTab(context, state, isDark, isArabic),
                            _buildInformationTab(
                              context,
                              state,
                              isDark,
                              isArabic,
                            ),
                            _buildTransfersTab(
                              context,
                              state,
                              isDark,
                              isArabic,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: المباريات (Matches)
  // ==========================================
  Widget _buildMatchesTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    String? timeFormat;
    try {
      timeFormat = context.watch<MatchesBloc>().state.timeFormat;
    } catch (_) {
      try {
        if (sl.isRegistered<LocalStorageService>()) {
          timeFormat = sl<LocalStorageService>().getTimeFormat();
        }
      } catch (_) {}
    }

    final profile = state.profile;
    final online = profile?.onlineMatches ?? [];
    final upcoming = profile?.upcomingMatches ?? [];
    final recent = profile?.recentMatches ?? [];

    if (online.isEmpty && upcoming.isEmpty && recent.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد مباريات مسجلة لهذا الفريق حاليًا'
            : 'No matches currently recorded for this team',
        icon: Icons.sports_soccer_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl, top: 8),
      children: [
        // 1. Live Matches (if any)
        if (online.isNotEmpty) ...[
          SectionHeader(
            title: isArabic ? 'مباريات جارية الآن' : 'Live Matches',
          ),
          ...online.map((m) => MatchCard(match: m, timeFormat: timeFormat)),
          const SizedBox(height: 12),
        ],

        // 2. Upcoming Fixtures
        if (upcoming.isNotEmpty) ...[
          SectionHeader(
            title: isArabic ? 'المباريات القادمة' : 'Upcoming Fixtures',
          ),
          ...upcoming.map((m) => MatchCard(match: m, timeFormat: timeFormat)),
          const SizedBox(height: 12),
        ],

        // 3. Finished Results
        if (recent.isNotEmpty) ...[
          SectionHeader(title: isArabic ? 'النتائج السابقة' : 'Past Results'),
          ...recent.map((m) => MatchCard(match: m, timeFormat: timeFormat)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ==========================================
  // TAB 2: الأخبار (News)
  // ==========================================
  Widget _buildNewsTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final news = state.profile?.news ?? [];

    if (news.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد أخبار منشورة لهذا الفريق حالياً'
            : 'No news published for this team at the moment',
        icon: Icons.newspaper_rounded,
      );
    }

    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      itemCount: news.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = news[index];

        return InkWell(
          onTap: () {
            if (item.id.isNotEmpty) {
              context.push('/news/${item.id}', extra: {'slug': item.slug});
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(12),
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
                if (item.image != null && item.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      imageUrl: item.image,
                      width: 90,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.image_outlined,
                    ),
                  )
                else
                  Container(
                    width: 90,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.newspaper_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(width: 12),

                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.getBodyMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w700, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        Text(
                          item.description!,
                          style:
                              AppTypography.getBodySmall(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (item.createdAt != null && item.createdAt!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.createdAt!.split(' ').first,
                              style:
                                  AppTypography.getBodySmall(
                                    isDark: isDark,
                                    isArabic: isArabic,
                                  ).copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: الترتيب (Standings)
  // ==========================================
  Widget _buildStandingsTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
    String displayName,
  ) {
    final championships = state.profile?.championships ?? [];
    final currentStandings = state.currentStandings;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl, top: 8),
      children: [
        // Championship Selector Pills
        if (championships.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hMargin),
              itemCount: championships.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final champ = championships[index];
                final champKey = champ.urlId ?? champ.id;
                final isSelected =
                    state.selectedChampionshipId == champKey ||
                    (state.selectedChampionshipId == null && index == 0);

                return FilterChip(
                  avatar: champ.logo != null
                      ? AppImage(
                          imageUrl: champ.logo,
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        )
                      : null,
                  label: Text(champ.title),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: isDark
                      ? AppColors.darkCard
                      : AppColors.lightCard,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                    ),
                  ),
                  onSelected: (_) {
                    context.read<TeamBloc>().add(
                      SelectChampionshipStandingsEvent(champKey),
                    );
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 10),

        // Standings Loading or Content
        if (state.isStandingsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (currentStandings != null && currentStandings.rows.isNotEmpty)
          StandingsTable(
            rows: currentStandings.rows,
            highlightedTeamName: displayName,
            showFullStats: true,
          )
        else if (state.profile?.standingsRow != null)
          StandingsTable(
            rows: [state.profile!.standingsRow!],
            highlightedTeamName: displayName,
            showFullStats: true,
          )
        else
          EmptyView(
            titleKey: 'tab_overview',
            customMessage: isArabic
                ? 'لا يتوفر جدول ترتيب لهذه البطولة حالياً'
                : 'No standings table available for this championship',
            icon: Icons.table_chart_outlined,
          ),
      ],
    );
  }

  // ==========================================
  // TAB 4: اللاعبين (Players)
  // ==========================================
  Widget _buildPlayersTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final catSquad = state.profile?.categorizedSquad;
    final flatSquad = state.profile?.squad ?? [];
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (catSquad == null && flatSquad.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات تشكيلة مسجلة لهذا الفريق حالياً'
            : 'No squad roster data available for this team',
        icon: Icons.groups_rounded,
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      children: [
        // 1. Coach Card (if available)
        if (catSquad?.coach != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                AppImage(
                  imageUrl: catSquad!.coach!.photo,
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.sports_rounded,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catSquad.coach!.name,
                        style: AppTypography.getBodyMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'المدير الفني',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // 2. Position Categories
        if (catSquad != null &&
            (catSquad.goalkeepers.isNotEmpty ||
                catSquad.defenders.isNotEmpty ||
                catSquad.midfielders.isNotEmpty ||
                catSquad.attackers.isNotEmpty)) ...[
          if (catSquad.goalkeepers.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'حراس المرمى' : 'Goalkeepers'),
            ...catSquad.goalkeepers.map(
              (p) => _buildPlayerTile(context, p, isDark, isArabic),
            ),
            const SizedBox(height: 12),
          ],
          if (catSquad.defenders.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'المدافعون' : 'Defenders'),
            ...catSquad.defenders.map(
              (p) => _buildPlayerTile(context, p, isDark, isArabic),
            ),
            const SizedBox(height: 12),
          ],
          if (catSquad.midfielders.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'لاعبو الوسط' : 'Midfielders'),
            ...catSquad.midfielders.map(
              (p) => _buildPlayerTile(context, p, isDark, isArabic),
            ),
            const SizedBox(height: 12),
          ],
          if (catSquad.attackers.isNotEmpty) ...[
            SectionHeader(title: isArabic ? 'المهاجمون' : 'Attackers'),
            ...catSquad.attackers.map(
              (p) => _buildPlayerTile(context, p, isDark, isArabic),
            ),
            const SizedBox(height: 12),
          ],
        ] else ...[
          // Fallback to flat list
          ...flatSquad.map(
            (p) => _buildPlayerTile(context, p, isDark, isArabic),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerTile(
    BuildContext context,
    TeamSquadPlayerEntity player,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: player.id.isNotEmpty
            ? () => context.push(
                '/player/${player.id}?slug=${Uri.encodeComponent(player.name)}',
              )
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Shirt Number
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.number?.isNotEmpty == true ? player.number! : '-',
                  style:
                      AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ),
              const SizedBox(width: 12),

              // Player Photo
              AppImage(
                imageUrl: player.photo,
                width: 38,
                height: 38,
                borderRadius: 19,
                fit: BoxFit.cover,
                placeholderIcon: Icons.person_rounded,
              ),
              const SizedBox(width: 12),

              // Name & Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.position != null &&
                        player.position!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        player.position!,
                        style:
                            AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Position Badge
              if (player.position != null && player.position!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    player.position!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 5: معلومات (Information)
  // ==========================================
  Widget _buildInformationTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final profile = state.profile;
    final cups = profile?.cups ?? [];
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      children: [
        // 1. Trophies & Achievements (Horizontal Carousel)
        if (cups.isNotEmpty) ...[
          SectionHeader(
            title: isArabic ? 'البطولات والإنجازات' : 'Trophies & Honors',
          ),
          SizedBox(
            height: 125,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cup = cups[index];

                return InkWell(
                  onTap: cup.years.isNotEmpty
                      ? () => _showCupYearsModal(context, cup, isDark, isArabic)
                      : null,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cup / Trophy image
                        Builder(
                          builder: (context) {
                            final trophyUrl = (cup.logo != null && cup.logo!.isNotEmpty)
                                ? cup.logo
                                : (cup.cupImage != null && !cup.cupImage!.contains('/cups/')
                                    ? cup.cupImage
                                    : null);
                            if (trophyUrl != null && trophyUrl.isNotEmpty) {
                              return AppImage(
                                imageUrl: trophyUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.emoji_events_rounded,
                              );
                            }
                            return const Icon(
                              Icons.emoji_events_rounded,
                              size: 40,
                              color: Color(0xFFEAB308),
                            );
                          },
                        ),
                        const SizedBox(height: 6),

                        Text(
                          cup.title,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),

                        Text(
                          '${cup.count} ${isArabic ? "بطولة" : "Titles"}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. Team Information Details Card
        SectionHeader(title: isArabic ? 'معلومات الفريق' : 'Team Details'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              if (profile?.country != null && profile!.country!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الدولة' : 'Country',
                  profile.country!,
                  icon: Icons.flag_outlined,
                  flagUrl: profile.countryFlag,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const Divider(height: 16),
              ],
              if (profile?.federation != null &&
                  profile!.federation!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الاتحاد' : 'Federation',
                  profile.federation!,
                  icon: Icons.account_balance_outlined,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const Divider(height: 16),
              ],
              if (profile?.stadiumName != null &&
                  profile!.stadiumName!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الملعب' : 'Stadium',
                  profile.stadiumName!,
                  icon: Icons.stadium_outlined,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const Divider(height: 16),
              ],
              if (profile?.division != null &&
                  profile!.division!.isNotEmpty) ...[
                _buildInfoRow(
                  isArabic ? 'الدرجة' : 'Division',
                  profile.division!,
                  icon: Icons.military_tech_outlined,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const Divider(height: 16),
              ],
              if (profile?.worldRanking != null &&
                  profile!.worldRanking! > 0) ...[
                _buildInfoRow(
                  isArabic ? 'التصنيف العالمي' : 'World Ranking',
                  '#${profile.worldRanking}',
                  icon: Icons.public_rounded,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Team Biography / About Card
        if (profile?.about != null && profile!.about!.trim().isNotEmpty) ...[
          SectionHeader(title: isArabic ? 'نبذة عن الفريق' : 'About the Club'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              profile.about!.trim(),
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    required IconData icon,
    String? flagUrl,
    required bool isDark,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
              .copyWith(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
        ),
        const Spacer(),
        if (flagUrl != null && flagUrl.isNotEmpty) ...[
          AppImage(
            imageUrl: flagUrl,
            width: 16,
            height: 12,
            borderRadius: 2,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          style: AppTypography.getBodyMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _showCupYearsModal(
    BuildContext context,
    TeamCupEntity cup,
    bool isDark,
    bool isArabic,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      final trophyUrl = (cup.logo != null && cup.logo!.isNotEmpty)
                          ? cup.logo
                          : (cup.cupImage != null && !cup.cupImage!.contains('/cups/')
                              ? cup.cupImage
                              : null);
                      if (trophyUrl != null && trophyUrl.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 10),
                          child: AppImage(
                            imageUrl: trophyUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.emoji_events_rounded,
                          ),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsetsDirectional.only(end: 10),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 30,
                          color: Color(0xFFEAB308),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${cup.title} (${cup.count} ${isArabic ? "ألقاب" : "titles"})',
                      style: AppTypography.getHeadingSmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cup.years.map((y) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      y,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 6: الانتقالات (Transfers)
  // ==========================================
  Widget _buildTransfersTab(
    BuildContext context,
    TeamState state,
    bool isDark,
    bool isArabic,
  ) {
    final transfers = state.profile?.transfers;
    final important = transfers?.important ?? [];
    final all = transfers?.all ?? [];
    final currentList = _transfersSegmentIndex == 0 ? important : all;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    if (important.isEmpty && all.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد بيانات انتقالات مسجلة لهذا الفريق حالياً'
            : 'No transfer data recorded for this team',
        icon: Icons.swap_horiz_rounded,
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
      children: [
        // Segmented Control
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _transfersSegmentIndex = 0),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _transfersSegmentIndex == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${isArabic ? "انتقالات هامة" : "Key Transfers"} (${important.length})',
                      style: TextStyle(
                        color: _transfersSegmentIndex == 0
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _transfersSegmentIndex = 1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _transfersSegmentIndex == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${isArabic ? "جميع الانتقالات" : "All Transfers"} (${all.length})',
                      style: TextStyle(
                        color: _transfersSegmentIndex == 1
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transfer Items List
        if (currentList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                isArabic
                    ? 'لا توجد بيانات في هذا القسم'
                    : 'No transfers in this section',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
          )
        else
          ...currentList.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  // Player Header Row
                  Row(
                    children: [
                      AppImage(
                        imageUrl: item.player.photo,
                        width: 36,
                        height: 36,
                        borderRadius: 18,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.person_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.player.name,
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (item.player.position != null &&
                                item.player.position!.isNotEmpty)
                              Text(
                                item.player.position!,
                                style:
                                    AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: isArabic,
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
                      // Value or Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          item.value.isNotEmpty ? '${item.value} €' : item.type,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // From Club ➔ To Club
                  Row(
                    children: [
                      // Out Club
                      Expanded(
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: item.teamOut.logo,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              placeholderIcon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.teamOut.name.isNotEmpty
                                    ? item.teamOut.name
                                    : (isArabic ? 'غير محدد' : 'N/A'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow Icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          isArabic
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),

                      // In Club
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                item.teamIn.name.isNotEmpty
                                    ? item.teamIn.name
                                    : (isArabic ? 'غير محدد' : 'N/A'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppImage(
                              imageUrl: item.teamIn.logo,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              placeholderIcon: Icons.shield_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (item.dateFrom != null && item.dateFrom!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: isArabic
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Text(
                        item.dateFrom!,
                        style: TextStyle(
                          fontSize: 10,
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
          }),
      ],
    );
  }
}
