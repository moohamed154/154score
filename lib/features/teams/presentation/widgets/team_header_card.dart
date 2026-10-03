import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/url_helper.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/starred_button.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/team_entity.dart';

class TeamHeaderCard extends StatelessWidget {
  final TeamProfileEntity? profile;
  final String fallbackName;
  final String? fallbackLogo;
  final bool isLoading;

  const TeamHeaderCard({
    super.key,
    this.profile,
    required this.fallbackName,
    this.fallbackLogo,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final isSkeleton = isLoading || profile == null;
    final name = (profile?.teamName != null && profile!.teamName.isNotEmpty)
        ? profile!.teamName
        : fallbackName;
    final logo = (profile?.teamLogo != null && profile!.teamLogo!.isNotEmpty)
        ? profile!.teamLogo
        : (fallbackLogo ??
              (profile?.teamId != null && int.tryParse(profile!.teamId) != null
                  ? UrlHelper.resolveTeamLogo(profile!.teamId)
                  : null));
    final rawLeagueName = profile?.leagueName ??
        (isSkeleton ? (isArabic ? 'الدوري الإسباني' : 'League Competition') : null);
    final leagueName = LeagueResolver.resolveTitle(
      rawLeagueName,
      isArabic: isArabic,
      id: profile?.leagueId,
    );
    final leagueId = profile?.leagueId;
    final country = (profile?.country != null && profile!.country!.isNotEmpty)
        ? profile!.country
        : (isSkeleton ? (isArabic ? 'إسبانيا' : 'Country') : null);
    final row = profile?.standingsRow ??
        (isSkeleton
            ? const StandingRowEntity(
                position: 4,
                points: 15,
                teamName: '',
                played: 7,
                wins: 5,
                draws: 0,
                losses: 2,
                goalsFor: 12,
                goalsAgainst: 5,
                goalDiff: 7,
              )
            : null);
    final form = (profile?.form != null && profile!.form.isNotEmpty)
        ? profile!.form
        : (isSkeleton ? const ['L', 'W', 'W', 'W', 'L'] : const <String>[]);

    final card = Container(
      margin: EdgeInsets.all(hMargin),
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Team Logo
              Skeleton.keep(
                keep: logo != null && logo.isNotEmpty,
                child: AppImage(
                  imageUrl: logo,
                  width: isSmall ? 52 : 64,
                  height: isSmall ? 52 : 64,
                  borderRadius: (isSmall ? 52 : 64) / 2,
                  fit: BoxFit.contain,
                  placeholderIcon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 14),

              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.keep(
                      keep: name.isNotEmpty && name != 'Team',
                      child: Text(
                        name,
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: isSmall ? 16 : 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tappable League Badge & Country
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (leagueName.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                            onTap: () {
                              if (leagueId != null && !isSkeleton) {
                                context.push(
                                  '/league/$leagueId',
                                  extra: {'title': leagueName},
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      leagueName,
                                      style: AppTypography.getBodySmall(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ).copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (country != null && country.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (profile?.countryFlag != null &&
                                    profile!.countryFlag!.isNotEmpty) ...[
                                  AppImage(
                                    imageUrl: profile!.countryFlag,
                                    width: 14,
                                    height: 10,
                                    borderRadius: 2,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    country,
                                    style: AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: isArabic,
                                    ).copyWith(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Favorite Star Button
              Skeleton.ignore(
                child: BlocBuilder<FavoritesCubit, FavoritesState>(
                  builder: (context, favState) {
                    final isFav = favState.isFavoriteTeam(
                      id: profile?.teamId,
                      name: name,
                    );
                    return StarredButton(
                      isStarred: isFav,
                      size: isSmall ? 22 : 26,
                      padding: const EdgeInsets.all(6.0),
                      onTap: () {
                        context.read<FavoritesCubit>().toggleTeam(
                          name,
                          id: profile?.teamId,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Standings position & Form pills
          if (row != null || form.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Standing Rank
                if (row != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isArabic ? 'الترتيب: ' : 'Rank: ',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                      Text(
                        '#${row.position} (${row.points} ${isArabic ? "نقطة" : "pts"})',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),

                // Form Pills (W/D/L)
                if (form.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isArabic ? 'النتائج: ' : 'Form: ',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...form.map((res) {
                        final (color, label) = switch (res) {
                          'W' => (AppColors.primary, isArabic ? 'ف' : 'W'),
                          'D' => (
                            const Color(0xFFEAB308),
                            isArabic ? 'ت' : 'D',
                          ),
                          'L' => (AppColors.liveRed, isArabic ? 'خ' : 'L'),
                          _ => (Colors.grey, res),
                        };

                        return Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(left: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (isSkeleton) {
      return Skeletonizer(
        enabled: true,
        child: card,
      );
    }
    return card;
  }
}
