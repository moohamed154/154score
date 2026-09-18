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
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../domain/entities/match_entity.dart';
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import 'match_card.dart';

class LeagueSectionWidget extends StatefulWidget {
  final LeagueGroupEntity league;
  final Function(String matchId)? onFavoriteMatchTap;
  final bool isTimeSorted;

  const LeagueSectionWidget({
    super.key,
    required this.league,
    this.onFavoriteMatchTap,
    this.isTimeSorted = false,
  });

  @override
  State<LeagueSectionWidget> createState() => _LeagueSectionWidgetState();
}

class _LeagueSectionWidgetState extends State<LeagueSectionWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final liveMatches = widget.league.matches.where((m) {
      final phase = MatchStatusHelper.parseStatus(
        m.status,
        minute: m.minute,
        extraTime: m.extraTime,
        time: m.time,
        date: m.date,
        score1: m.score1,
        score2: m.score2,
      );
      return MatchStatusHelper.isLive(phase);
    }).length;

    final isTimeSlot = widget.isTimeSorted ||
        (widget.league.leagueId == null &&
            RegExp(r'^\d{1,2}:\d{2}').hasMatch(widget.league.leagueTitle));

    if (isTimeSlot) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final match in widget.league.matches)
            MatchCard(
              key: ValueKey(match.id),
              match: match,
              showLeague: true,
              onFavoriteTap: widget.onFavoriteMatchTap != null
                  ? () => widget.onFavoriteMatchTap!(match.id)
                  : null,
            ),
        ],
      );
    }

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
                // League Identity (Clickable to open LeagueView)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    onTap: () {
                      final lId = widget.league.leagueId ??
                          LeagueResolver.resolveId(widget.league.leagueTitle);
                      if (lId != null && lId.isNotEmpty) {
                        final logo = widget.league.leagueLogo ??
                            UrlHelper.resolveChampionshipLogo(lId);
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
                        AppImage(
                          imageUrl: widget.league.leagueLogo,
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
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // League Favorite Star Button
                BlocBuilder<FavoritesCubit, FavoritesState>(
                  builder: (context, favState) {
                    final isFav =
                        favState.favoriteCompetitions.contains(
                          widget.league.leagueTitle,
                        ) ||
                        (widget.league.leagueId != null &&
                            favState.favoriteCompetitions.contains(
                              widget.league.leagueId,
                            ));

                    return InkWell(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      onTap: () {
                        context.read<FavoritesCubit>().toggleCompetition(
                          widget.league.leagueTitle,
                        );
                        try {
                          context.read<MatchesBloc>().add(
                            const RefreshFavoritesEvent(),
                          );
                        } catch (_) {}
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isFav
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 18,
                          color: isFav
                              ? AppColors.yellowCard
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                        ),
                      ),
                    );
                  },
                ),
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.league.matches.length,
              itemBuilder: (context, index) {
                final match = widget.league.matches[index];
                return MatchCard(
                  key: ValueKey(match.id),
                  match: match,
                  showLeague: isTimeSlot,
                  onFavoriteTap: widget.onFavoriteMatchTap != null
                      ? () => widget.onFavoriteMatchTap!(match.id)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
