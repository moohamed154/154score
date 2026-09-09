import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../../../matches/presentation/bloc/matches_state.dart';
import '../../../matches/presentation/widgets/horizontal_date_selector.dart';
import '../../../matches/presentation/widgets/league_section_widget.dart';
import '../../../matches/presentation/widgets/live_match_card.dart';
import '../../../transfers/presentation/widgets/transfer_card.dart';
import '../../../videos/presentation/widgets/video_card.dart';
import '../cubit/home_cubit.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    final homeCubit = context.read<HomeCubit>();
    if (homeCubit.state.status == HomeStatus.initial) {
      homeCubit.loadHomeData();
    }
    final matchesBloc = context.read<MatchesBloc>();
    if (matchesBloc.state.status == MatchesStatus.initial) {
      matchesBloc.add(LoadMatchesEvent(date: matchesBloc.state.selectedDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 68 + topPadding),
        child: BlocBuilder<MatchesBloc, MatchesState>(
          builder: (context, matchesState) {
            return Material(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status bar spacer
                  SizedBox(height: topPadding),

                  // Top toolbar row
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        // Logo + Title
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sports_soccer_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '154Score',
                          style: AppTypography.getHeadingLarge(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        // Search Icon
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          tooltip: l10n.translate('nav_search'),
                          onPressed: () => context.push('/search'),
                        ),
                        // Filter Icon
                        IconButton(
                          icon: const Icon(Icons.filter_alt_outlined),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),

                  // Date strip — inline, no background, no border
                  HorizontalDateSelector(
                    selectedDate: matchesState.selectedDate,
                    onDateSelected: (date) {
                      context.read<MatchesBloc>().add(
                        LoadMatchesEvent(date: date),
                      );
                    },
                  ),

                  // Bottom divider
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ],
              ),
            );
          },
        ),
      ),


      body: BlocBuilder<MatchesBloc, MatchesState>(
        builder: (context, matchesState) {
          return BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    homeState.status != HomeStatus.loading
                        ? context.read<HomeCubit>().loadHomeData(
                            isRefresh: true,
                          )
                        : Future.value(),
                    Future.sync(
                      () => context.read<MatchesBloc>().add(
                        LoadMatchesEvent(
                          date: matchesState.selectedDate,
                          isRefresh: true,
                        ),
                      ),
                    ),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
                  children: [
                    const SizedBox(height: 12),

                    // 1. LIVE NOW Section (if any live matches)
                    _buildLiveNowSection(
                      context,
                      matchesState,
                      isDark,
                      isArabic,
                    ),

                    // 2. Matches for Selected Date
                    _buildMatchesSection(
                      context,
                      matchesState,
                      isDark,
                      isArabic,
                    ),

                    const SizedBox(height: 16),

                    // 3. Featured Highlights & Videos
                    _buildVideosSection(context, homeState, isDark, isArabic),

                    const SizedBox(height: 16),

                    // 4. Latest Transfer News
                    _buildTransfersSection(
                      context,
                      homeState,
                      isDark,
                      isArabic,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildLiveNowSection(
    BuildContext context,
    MatchesState matchesState,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    // Extract all live matches from state
    final liveMatches = <dynamic>[];
    for (final league in matchesState.allLeagues) {
      for (final m in league.matches) {
        if (m.status != null &&
            (m.status!.toLowerCase().contains('live') ||
                m.status!.toLowerCase().contains('مباشر') ||
                m.status!.toLowerCase().contains('شوط') ||
                m.status!.toLowerCase().contains('half') ||
                m.status!.toLowerCase().contains('استراحة'))) {
          liveMatches.add(m);
        }
      }
    }

    if (liveMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('live_now'),
          leading: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.liveRed,
            ),
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            itemCount: liveMatches.length,
            itemBuilder: (context, index) {
              return LiveMatchCard(match: liveMatches[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMatchesSection(
    BuildContext context,
    MatchesState state,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('nav_matches'),
          actionText: l10n.translate('view_all'),
          onActionTap: () => context.go('/matches'),
        ),
        if (state.status == MatchesStatus.loading)
          ...List.generate(3, (_) => const MatchCardSkeleton())
        else if (state.status == MatchesStatus.error)
          ErrorView(
            message: state.errorMessage,
            onRetry: () => context.read<MatchesBloc>().add(
              LoadMatchesEvent(date: state.selectedDate),
            ),
          )
        else if (state.allLeagues.isEmpty)
          const EmptyView(
            titleKey: 'no_matches_date',
            icon: Icons.sports_soccer_rounded,
          )
        else
          ...state.allLeagues.take(4).map((league) {
            return LeagueSectionWidget(
              league: league,
              onFavoriteMatchTap: (matchId) {
                context.read<MatchesBloc>().add(
                  ToggleMatchFavoriteEvent(matchId),
                );
              },
            );
          }),
      ],
    );
  }

  Widget _buildVideosSection(
    BuildContext context,
    HomeState state,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    if (state.recentVideos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('latest_videos'),
          actionText: l10n.translate('view_all'),
          onActionTap: () => context.go('/videos'),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            itemCount: state.recentVideos.take(8).length,
            itemBuilder: (context, index) {
              return VideoCard(
                video: state.recentVideos[index],
                isHorizontal: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransfersSection(
    BuildContext context,
    HomeState state,
    bool isDark,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context);
    if (state.recentTransfers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.translate('latest_transfers'),
          actionText: l10n.translate('view_all'),
          onActionTap: () => context.go('/transfers'),
        ),
        ...state.recentTransfers.take(3).map((t) => TransferCard(transfer: t)),
      ],
    );
  }
}
