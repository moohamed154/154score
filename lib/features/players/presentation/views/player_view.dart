import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/player_profile_entity.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_state.dart';
import '../widgets/player_bio_card.dart';
import '../widgets/player_hero_header.dart';
import '../widgets/player_stats_tab_view.dart';
import '../widgets/player_transfers_tab_view.dart';

class PlayerView extends StatefulWidget {
  final String playerId;
  final String? initialName;
  final String? initialPhoto;
  final String? initialSlug;

  const PlayerView({
    super.key,
    required this.playerId,
    this.initialName,
    this.initialPhoto,
    this.initialSlug,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Statistics, Transfers, Overview
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<PlayerBloc>().add(ChangePlayerTabEvent(_tabController.index));
      }
    });

    context.read<PlayerBloc>().add(
      LoadPlayerProfileEvent(
        widget.playerId,
        slug: widget.initialSlug,
        fallbackName: widget.initialName,
        fallbackPhoto: widget.initialPhoto,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerId != widget.playerId) {
      context.read<PlayerBloc>().add(
        LoadPlayerProfileEvent(
          widget.playerId,
          slug: widget.initialSlug,
          fallbackName: widget.initialName,
          fallbackPhoto: widget.initialPhoto,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final displayName = state.profile?.name ??
            state.playerName ??
            widget.initialName ??
            (isArabic ? 'اللاعب' : 'Player');

        return Scaffold(
          appBar: AppBar(
            title: Text(
              displayName,
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: _buildBody(context, state, isDark, isArabic),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    PlayerState state,
    bool isDark,
    bool isArabic,
  ) {
    if (state.status == PlayerStatus.loading && state.profile == null) {
      return _buildSkeleton(context);
    }

    if (state.status == PlayerStatus.error && state.profile == null) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () {
          context.read<PlayerBloc>().add(
            LoadPlayerProfileEvent(
              widget.playerId,
              slug: widget.initialSlug,
              fallbackName: widget.initialName,
              fallbackPhoto: widget.initialPhoto,
            ),
          );
        },
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final isGoalkeeper = (profile.position ?? '').toUpperCase() == 'GK' ||
        profile.positionName.contains('حارس');

    final hMargin = AppDimensions.getHorizontalMargin(context);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final completer = Completer<void>();
        context.read<PlayerBloc>().add(const RefreshPlayerProfileEvent());
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!completer.isCompleted) completer.complete();
        });
        return completer.future;
      },
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
        children: [
          // Hero Header Card (Cover, Avatar, Jersey #, Name, Position, Club chip, Flag chip)
          PlayerHeroHeader(
            profile: profile,
            isDark: isDark,
            isArabic: isArabic,
          ),

          const SizedBox(height: AppDimensions.md),

          // Physical & Biographical Highlights Card
          PlayerBioCard(
            profile: profile,
            isDark: isDark,
            isArabic: isArabic,
          ),

          const SizedBox(height: AppDimensions.md),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(isArabic ? 'الإحصائيات' : 'Statistics'),
                      if (profile.statistics.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _buildTabCountBadge(profile.statistics.length, isDark),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(isArabic ? 'الانتقالات' : 'Transfers'),
                      if (profile.transfers.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _buildTabCountBadge(profile.transfers.length, isDark),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(isArabic ? 'معلومات' : 'Overview'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Active Tab Content
          IndexedStack(
            index: state.selectedTab.clamp(0, 2),
            children: [
              // 1. Statistics Tab
              PlayerStatsTabView(
                statistics: profile.statistics,
                isGoalkeeper: isGoalkeeper,
                isDark: isDark,
                isArabic: isArabic,
              ),

              // 2. Transfers Tab
              PlayerTransfersTabView(
                transfers: profile.transfers,
                isDark: isDark,
                isArabic: isArabic,
              ),

              // 3. Overview / Additional Information
              _buildOverviewTab(profile, isDark, isArabic),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }

  Widget _buildTabCountBadge(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    PlayerProfileEntity profile,
    bool isDark,
    bool isArabic,
  ) {
    if (profile.metadata.isEmpty &&
        profile.city == null &&
        profile.footName == null) {
      return EmptyView(
        titleKey: isArabic ? 'لا توجد معلومات إضافية' : 'No Information',
        customMessage: isArabic
            ? 'لا تتوفر تفاصيل إضافية لهذا اللاعب'
            : 'No additional details available for this player',
        icon: Icons.info_outline_rounded,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: profile.metadata.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = profile.metadata[index];
          final title = m['title'] ?? '';
          final content = m['content'] ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    title,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Text(
                    content,
                    style: AppTypography.getBodyMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
