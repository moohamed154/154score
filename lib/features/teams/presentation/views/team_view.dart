import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../bloc/team_bloc.dart';
import '../bloc/team_event.dart';
import '../bloc/team_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../widgets/team_header_card.dart';
import '../widgets/tabs/team_info_tab.dart';
import '../widgets/tabs/team_matches_tab.dart';
import '../widgets/tabs/team_news_tab.dart';
import '../widgets/tabs/team_players_tab.dart';
import '../widgets/tabs/team_standings_tab.dart';
import '../widgets/tabs/team_transfers_tab.dart';

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

  bool _isNotificationActive(String? id, String? name,
      [FavoritesState? favState]) {
    try {
      final storage = sl<LocalStorageService>();
      final cleanId = id?.trim();
      final cleanName = name?.trim();

      if (cleanId != null &&
          cleanId.isNotEmpty &&
          storage.isTeamNotificationMuted(cleanId)) {
        return false;
      }
      if (cleanName != null &&
          cleanName.isNotEmpty &&
          storage.isTeamNotificationMuted(cleanName)) {
        return false;
      }

      // If team is starred, notification is enabled!
      final isStarred = favState != null
          ? favState.isFavoriteTeam(id: cleanId, name: cleanName)
          : storage.isFavoriteTeam(cleanName ?? '', id: cleanId);
      if (isStarred) {
        return true;
      }

      if (cleanId != null &&
          cleanId.isNotEmpty &&
          storage.isTeamNotificationEnabled(cleanId)) {
        return true;
      }
      if (cleanName != null &&
          cleanName.isNotEmpty &&
          storage.isTeamNotificationEnabled(cleanName)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _toggleNotification(
      String? id, String name, bool isArabic) async {
    try {
      final storage = sl<LocalStorageService>();
      final keyToToggle =
          (id != null && id.trim().isNotEmpty) ? id.trim() : name.trim();
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
                  const Icon(Icons.notifications_off_rounded,
                      color: Color(0xFFF59E0B), size: 20),
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

      if (name.trim().isNotEmpty &&
          name.trim().toLowerCase() != keyToToggle.toLowerCase()) {
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
                  newStatus
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color:
                      newStatus ? AppColors.primary : const Color(0xFF94A3B8),
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
        final displayName = state.profile?.teamName ??
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
                                    team2:
                                        isArabic ? 'نادي منافس' : 'Opponent FC',
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
                                TeamMatchesTab(
                                  state: state,
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ),
                                TeamNewsTab(
                                  state: state,
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ),
                                TeamStandingsTab(
                                  state: state,
                                  isDark: isDark,
                                  isArabic: isArabic,
                                  displayName: displayName,
                                ),
                                TeamPlayersTab(
                                  state: state,
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ),
                                TeamInfoTab(
                                  state: state,
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ),
                                TeamTransfersTab(
                                  state: state,
                                  isDark: isDark,
                                  isArabic: isArabic,
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
}
