import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/starred_button.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../domain/entities/match_entity.dart';
import 'match_card.dart';

class LeagueSectionWidget extends StatefulWidget {
  final LeagueGroupEntity league;
  final Function(String matchId)? onFavoriteMatchTap;
  final bool isTimeSorted;
  final String? timeFormat;

  const LeagueSectionWidget({
    super.key,
    required this.league,
    this.onFavoriteMatchTap,
    this.isTimeSorted = false,
    this.timeFormat,
  });

  @override
  State<LeagueSectionWidget> createState() => _LeagueSectionWidgetState();
}

class _LeagueSectionWidgetState extends State<LeagueSectionWidget> {
  bool _isExpanded = true;
  int _liveMatchesCount = 0;

  @override
  void initState() {
    super.initState();
    _computeLiveCount();
  }

  @override
  void didUpdateWidget(covariant LeagueSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.league != widget.league) {
      _computeLiveCount();
    }
  }

  void _computeLiveCount() {
    _liveMatchesCount = widget.league.matches.where((m) {
      final phase = MatchStatusHelper.parseMatch(m);
      return MatchStatusHelper.isLive(phase);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final liveMatches = _liveMatchesCount;

    final isTimeSlot =
        widget.isTimeSorted ||
        (widget.league.leagueId == null &&
            RegExp(r'^\d{1,2}:\d{2}').hasMatch(widget.league.leagueTitle));

    if (isTimeSlot) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final match in widget.league.matches)
            MatchCard(
              key: ValueKey('${match.id}_${widget.timeFormat ?? ""}'),
              match: match,
              showLeague: true,
              timeFormat: widget.timeFormat,
              onFavoriteTap: widget.onFavoriteMatchTap != null
                  ? () => widget.onFavoriteMatchTap!(match.id)
                  : null,
            ),
        ],
      );
    }

    final isFavoritesSection = widget.league.leagueTitle == 'Favorites' ||
        widget.league.leagueTitle == 'المفضلة';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League Header Accordion Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: 8,
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Row(
              children: [
                // League Identity (Clickable to open LeagueView or toggle if favorites)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    onTap: () {
                      if (isFavoritesSection) {
                        setState(() => _isExpanded = !_isExpanded);
                        return;
                      }
                      final lId =
                          widget.league.leagueId ??
                          LeagueResolver.resolveId(widget.league.leagueTitle);
                      if (lId != null && lId.isNotEmpty) {
                        final logo =
                            UrlHelper.resolveChampionshipLogo(
                              lId,
                              currentLogo: widget.league.leagueLogo,
                              isDark: isDark,
                            );
                        context.push(
                          '/league/$lId',
                          extra: {
                            'title': widget.league.leagueTitle,
                            'logo': logo,
                          },
                        );
                      }
                    },
                    child: Row(
                      children: [
                        if (isFavoritesSection)
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.yellowCard,
                            size: 24,
                          )
                        else
                          AppImage(
                            imageUrl: UrlHelper.resolveChampionshipLogo(
                              widget.league.leagueId ??
                                  LeagueResolver.resolveId(widget.league.leagueTitle),
                              currentLogo: widget.league.leagueLogo,
                              isDark: isDark,
                            ),
                            width: 24,
                            height: 24,
                            borderRadius: 4,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.emoji_events_outlined,
                          ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Text(
                            widget.league.leagueTitle,
                            style: AppTypography.getBodyLarge(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isFavoritesSection) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isArabic
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isFavoritesSection) ...[
                  const SizedBox(width: 6),

                  // League Favorite Star Button
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    buildWhen: (prev, curr) {
                      final prevFav = prev.isFavoriteCompetition(
                        id: widget.league.leagueId,
                        name: widget.league.leagueTitle,
                      );
                      final currFav = curr.isFavoriteCompetition(
                        id: widget.league.leagueId,
                        name: widget.league.leagueTitle,
                      );
                      return prevFav != currFav;
                    },
                    builder: (context, favState) {
                      final isFav = favState.isFavoriteCompetition(
                        id: widget.league.leagueId,
                        name: widget.league.leagueTitle,
                      );

                      return StarredButton(
                        key: ValueKey('comp_star_${widget.league.leagueId ?? widget.league.leagueTitle}'),
                        isStarred: isFav,
                        size: 20,
                        padding: const EdgeInsets.all(4.0),
                        onTap: () {
                          context.read<FavoritesCubit>().toggleCompetition(
                            id: widget.league.leagueId,
                            name: widget.league.leagueTitle,
                            logo: widget.league.leagueLogo,
                          );
                        },
                      );
                    },
                  ),
                ],
                const SizedBox(width: 6),

                // Match count & Live count & Expand/Collapse Trigger
                InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (liveMatches > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: EdgeInsets.only(
                              left: isArabic ? 0 : 4,
                              right: isArabic ? 4 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.liveRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.liveRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$liveMatches ${isArabic ? "مباشر" : "Live"}',
                                  style: const TextStyle(
                                    color: AppColors.liveRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.league.matches.length.toString(),
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Matches in this League
          if (_isExpanded)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.league.matches.length,
                (index) {
                  final match = widget.league.matches[index];
                  return MatchCard(
                    key: ValueKey('${match.id}_${widget.timeFormat ?? ""}'),
                    match: match,
                    showLeague: isTimeSlot,
                    timeFormat: widget.timeFormat,
                    onFavoriteTap: widget.onFavoriteMatchTap != null
                        ? () => widget.onFavoriteMatchTap!(match.id)
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
