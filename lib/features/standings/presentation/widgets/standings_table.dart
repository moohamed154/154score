import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/standings_entity.dart';

class StandingsTable extends StatelessWidget {
  final List<StandingRowEntity> rows;
  final bool showFullStats;
  final List<String>? highlightedTeamNames;
  final String? highlightedTeamName;

  const StandingsTable({
    super.key,
    required this.rows,
    this.showFullStats = true,
    this.highlightedTeamNames,
    this.highlightedTeamName,
  });

  bool _isTeamHighlighted(String name) {
    if (name.isEmpty) return false;

    String normalize(String s) {
      return s
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'^(نادي|فريق|fc|sc|cf)\s+', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+(fc|sc|cf)$', caseSensitive: false), '')
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي')
          .trim();
    }

    final n = normalize(name);

    if (highlightedTeamName != null && highlightedTeamName!.isNotEmpty) {
      if (n == normalize(highlightedTeamName!)) return true;
    }
    if (highlightedTeamNames != null) {
      for (final hName in highlightedTeamNames!) {
        if (hName.trim().isNotEmpty) {
          if (n == normalize(hName)) return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final cellWidth = isSmall ? 20.0 : 26.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 6 : 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightCardElevated,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: isSmall ? 18 : 24,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.translate('standings_pos'),
                      style:
                          AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 11 : 12,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(width: isSmall ? 4 : 6),
                Expanded(
                  child: Text(
                    l10n.translate('standings_team'),
                    style:
                        AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isSmall ? 11 : 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildHeaderCell(
                  l10n.translate('standings_played'),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_wins'),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_draws'),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_losses'),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
                if (showFullStats) ...[
                  _buildHeaderCell(
                    l10n.translate('standings_gf'),
                    isDark,
                    isArabic,
                    width: cellWidth,
                    isSmall: isSmall,
                  ),
                  _buildHeaderCell(
                    l10n.translate('standings_ga'),
                    isDark,
                    isArabic,
                    width: cellWidth,
                    isSmall: isSmall,
                  ),
                ],
                _buildHeaderCell(
                  l10n.translate('standings_gd'),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_points'),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                  isHighlight: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Rows (All rows rendered with proper keys and tap handling)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              return _buildRow(
                context,
                row,
                isDark,
                isArabic,
                cellWidth: cellWidth,
                isSmall: isSmall,
                showFullStats: showFullStats,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    bool isDark,
    bool isArabic, {
    required double width,
    required bool isSmall,
    bool isHighlight = false,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style:
                AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 10 : 11,
                  color: isHighlight ? AppColors.primary : null,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    StandingRowEntity row,
    bool isDark,
    bool isArabic, {
    required double cellWidth,
    required bool isSmall,
    required bool showFullStats,
  }) {
    final isHighlighted = _isTeamHighlighted(row.teamName);

    Color? indicatorColor;
    if (row.rankColor != null && row.rankColor!.isNotEmpty) {
      try {
        final hex = row.rankColor!.replaceFirst('#', '');
        if (hex.length == 6) {
          indicatorColor = Color(int.parse('0xFF$hex'));
        }
      } catch (_) {}
    }

    return Material(
      color: isHighlighted
          ? (isDark
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.primary.withValues(alpha: 0.12))
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          final tId = Uri.encodeComponent(row.teamName);
          context.push(
            '/team/$tId',
            extra: {'name': row.teamName, 'logo': row.teamLogo},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: isHighlighted
                ? Border(
                    right: isArabic
                        ? const BorderSide(color: AppColors.primary, width: 3.5)
                        : BorderSide.none,
                    left: !isArabic
                        ? const BorderSide(color: AppColors.primary, width: 3.5)
                        : BorderSide.none,
                  )
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 6 : 10,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Position Indicator + Position Number
              SizedBox(
                width: isSmall ? 18 : 24,
                child: Row(
                  children: [
                    if (indicatorColor != null)
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else
                      const SizedBox(width: 3),
                    const SizedBox(width: 2),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          row.position.toString(),
                          style:
                              AppTypography.getBodySmall(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: isHighlighted
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: isSmall ? 11 : 12,
                                color: isHighlighted ? AppColors.primary : null,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 4 : 6),

              // Team Logo & Name
              Expanded(
                child: Row(
                  children: [
                    AppImage(
                      imageUrl: row.teamLogo,
                      width: isSmall ? 16 : 20,
                      height: isSmall ? 16 : 20,
                      borderRadius: (isSmall ? 16 : 20) / 2,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.shield_outlined,
                    ),
                    SizedBox(width: isSmall ? 4 : 6),
                    Expanded(
                      child: Text(
                        row.teamName,
                        style:
                            AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: isHighlighted
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: isSmall ? 11 : 13,
                              color: isHighlighted
                                  ? (isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryDark)
                                  : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Columns
              _buildDataCell(
                row.played.toString(),
                isDark,
                isArabic,
                width: cellWidth,
                isSmall: isSmall,
              ),
              _buildDataCell(
                row.wins.toString(),
                isDark,
                isArabic,
                width: cellWidth,
                isSmall: isSmall,
              ),
              _buildDataCell(
                row.draws.toString(),
                isDark,
                isArabic,
                width: cellWidth,
                isSmall: isSmall,
              ),
              _buildDataCell(
                row.losses.toString(),
                isDark,
                isArabic,
                width: cellWidth,
                isSmall: isSmall,
              ),
              if (showFullStats) ...[
                _buildDataCell(
                  row.goalsFor.toString(),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
                _buildDataCell(
                  row.goalsAgainst.toString(),
                  isDark,
                  isArabic,
                  width: cellWidth,
                  isSmall: isSmall,
                ),
              ],
              _buildDataCell(
                '${row.goalDiff >= 0 ? "+" : ""}${row.goalDiff}',
                isDark,
                isArabic,
                width: cellWidth,
                isSmall: isSmall,
              ),
              _buildDataCell(
                row.points.toString(),
                isDark,
                isArabic,
                width: cellWidth,
                isSmall: isSmall,
                isBold: true,
                isHighlight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text,
    bool isDark,
    bool isArabic, {
    required double width,
    required bool isSmall,
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style:
                AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isSmall ? 10 : 12,
                  color: isHighlight
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
