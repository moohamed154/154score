import 'package:flutter/material.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: 8,
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  width: 24,
                  child: Text(
                    l10n.translate('standings_pos'),
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.translate('standings_team'),
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _buildHeaderCell(
                  l10n.translate('standings_played'),
                  isDark,
                  isArabic,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_wins'),
                  isDark,
                  isArabic,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_draws'),
                  isDark,
                  isArabic,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_losses'),
                  isDark,
                  isArabic,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_gd'),
                  isDark,
                  isArabic,
                ),
                _buildHeaderCell(
                  l10n.translate('standings_points'),
                  isDark,
                  isArabic,
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
              return _buildRow(context, row, isDark, isArabic);
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
    bool isHighlight = false,
  }) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
            .copyWith(
              fontWeight: FontWeight.w700,
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
    bool isArabic,
  ) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Pos Indicator + Number
          SizedBox(
            width: 24,
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
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    row.position.toString(),
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Team Logo & Name
          Expanded(
            child: Row(
              children: [
                AppImage(
                  imageUrl: row.teamLogo,
                  width: 20,
                  height: 20,
                  borderRadius: 10,
                  placeholderIcon: Icons.shield_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.teamName,
                    style: AppTypography.getBodyMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Stats Columns
          _buildDataCell(row.played.toString(), isDark, isArabic),
          _buildDataCell(row.wins.toString(), isDark, isArabic),
          _buildDataCell(row.draws.toString(), isDark, isArabic),
          _buildDataCell(row.losses.toString(), isDark, isArabic),
          _buildDataCell(
            '${row.goalDiff >= 0 ? "+" : ""}${row.goalDiff}',
            isDark,
            isArabic,
          ),
          _buildDataCell(
            row.points.toString(),
            isDark,
            isArabic,
            isBold: true,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    String text,
    bool isDark,
    bool isArabic, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
            .copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
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
