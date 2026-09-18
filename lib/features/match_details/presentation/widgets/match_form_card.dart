import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/match_details_entity.dart';

class MatchFormCard extends StatefulWidget {
  final MatchRecentFormEntity recentForm;

  const MatchFormCard({super.key, required this.recentForm});

  @override
  State<MatchFormCard> createState() => _MatchFormCardState();
}

class _MatchFormCardState extends State<MatchFormCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final homeMatches = widget.recentForm.homeMatches;
    final awayMatches = widget.recentForm.awayMatches;

    if (homeMatches.isEmpty && awayMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with expand toggle
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'آخر المباريات' : 'Recent Form',
                    style: AppTypography.getBodyLarge(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
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
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Home Team Form Row
            if (homeMatches.isNotEmpty) ...[
              _buildTeamFormRow(
                teamName: widget.recentForm.homeTeamName ??
                    (isArabic ? 'صاحب الأرض' : 'Home Team'),
                matches: homeMatches,
                isDark: isDark,
                isArabic: isArabic,
              ),
            ],

            if (homeMatches.isNotEmpty && awayMatches.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],

            // Away Team Form Row
            if (awayMatches.isNotEmpty) ...[
              _buildTeamFormRow(
                teamName: widget.recentForm.awayTeamName ??
                    (isArabic ? 'الضيف' : 'Away Team'),
                matches: awayMatches,
                isDark: isDark,
                isArabic: isArabic,
              ),
            ],

            // Expanded Match List
            if (_expanded) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (homeMatches.isNotEmpty) ...[
                Text(
                  widget.recentForm.homeTeamName ??
                      (isArabic ? 'مباريات المضيف' : 'Home Matches'),
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                ...homeMatches.map(
                  (m) => _buildDetailedMatchTile(
                    m,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
              ],
              if (awayMatches.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.recentForm.awayTeamName ??
                      (isArabic ? 'مباريات الضيف' : 'Away Matches'),
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                ...awayMatches.map(
                  (m) => _buildDetailedMatchTile(
                    m,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamFormRow({
    required String teamName,
    required List<MatchFormItemEntity> matches,
    required bool isDark,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: AppTypography.getBodyMedium(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: matches.map((m) => _buildBadge(m, isArabic)).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(MatchFormItemEntity match, bool isArabic) {
    Color bg;
    String letter;

    if (match.isWin) {
      bg = AppColors.uclGreen;
      letter = isArabic ? 'ف' : 'W';
    } else if (match.isLoss) {
      bg = AppColors.relegationRed;
      letter = isArabic ? 'خ' : 'L';
    } else {
      bg = Colors.grey.shade600;
      letter = isArabic ? 'ت' : 'D';
    }

    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDetailedMatchTile(
    MatchFormItemEntity match, {
    required bool isDark,
    required bool isArabic,
  }) {
    final canNav = match.matchId.trim().isNotEmpty && match.matchId != '0';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canNav ? () => context.push('/match/${match.matchId}') : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              _buildBadge(match, isArabic),
              const SizedBox(width: 8),
              if (match.opponentLogo != null &&
                  match.opponentLogo!.isNotEmpty) ...[
                AppImage(
                  imageUrl: match.opponentLogo!,
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  match.opponentName,
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                match.score,
                style: AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  color: match.isWin
                      ? AppColors.uclGreen
                      : (match.isLoss
                          ? AppColors.relegationRed
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                ),
              ),
              if (canNav) ...[
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
    );
  }
}
