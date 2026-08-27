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

  const StandingsTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final cellWidth = isSmall ? 24.0 : 28.0;

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
              horizontal: isSmall ? 8 : 12,
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
                  width: isSmall ? 20 : 24,
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
                SizedBox(width: isSmall ? 4 : 8),
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

          // Table Rows
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
      child: Text(
        label,
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
            .copyWith(
              fontWeight: FontWeight.w700,
              fontSize: isSmall ? 10 : 12,
              color: isHighlight ? AppColors.primary : null,
            ),
        textAlign: TextAlign.center,
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
  }) {
    Color? indicatorColor;
    if (row.rankColor != null && row.rankColor!.isNotEmpty) {
      try {
        final hex = row.rankColor!.replaceFirst('#', '');
        if (hex.length == 6) {
          indicatorColor = Color(int.parse('0xFF$hex'));
        }
      } catch (_) {}
    }

    if (indicatorColor == null) {
      if (row.position <= 4) {
        indicatorColor = AppColors.uclGreen;
      } else if (row.position == 5) {
        indicatorColor = AppColors.uelBlue;
      } else if (row.position >= 18) {
        indicatorColor = AppColors.relegationRed;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final tId = Uri.encodeComponent(row.teamName);
          context.push(
            '/team/$tId',
            extra: {'name': row.teamName, 'logo': row.teamLogo},
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Pos Indicator + Number
              SizedBox(
                width: isSmall ? 20 : 24,
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
                      ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        row.position.toString(),
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
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 4 : 8),

              // Team Logo & Name
              Expanded(
                child: Row(
                  children: [
                    AppImage(
                      imageUrl: row.teamLogo,
                      width: isSmall ? 18 : 20,
                      height: isSmall ? 18 : 20,
                      borderRadius: (isSmall ? 18 : 20) / 2,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.shield_outlined,
                    ),
                    SizedBox(width: isSmall ? 6 : 8),
                    Expanded(
                      child: Text(
                        row.teamName,
                        style:
                            AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall ? 12 : 14,
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
      child: Text(
        text,
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
            .copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isSmall ? 11 : 12,
              color: isHighlight
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
