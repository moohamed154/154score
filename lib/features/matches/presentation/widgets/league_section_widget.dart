import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/match_entity.dart';
import 'match_card.dart';

class LeagueSectionWidget extends StatefulWidget {
  final LeagueGroupEntity league;
  final Function(String matchId)? onFavoriteMatchTap;

  const LeagueSectionWidget({
    super.key,
    required this.league,
    this.onFavoriteMatchTap,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League Header Accordion Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 10),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Row(
                children: [
                  AppImage(
                    imageUrl: widget.league.leagueLogo,
                    width: 24,
                    height: 24,
                    borderRadius: 4,
                    placeholderIcon: Icons.emoji_events_outlined,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      widget.league.leagueTitle,
                      style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.league.matches.length.toString(),
                      style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
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
