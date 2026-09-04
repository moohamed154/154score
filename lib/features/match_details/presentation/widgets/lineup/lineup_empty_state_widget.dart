import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/core/constants/app_typography.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_event.dart';

/// Clean, informative empty state displayed when lineups are not yet released by the official organizers.
class LineupEmptyStateWidget extends StatelessWidget {
  final String matchId;

  const LineupEmptyStateWidget({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tactical Board Graphic Container
          Container(
            width: 180,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF143B25) : const Color(0xFF1E663B),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.primary,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Halfway Line
                Center(
                  child: Container(
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                // Center Circle
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Center Clock / Tactical Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            l10n.lineupUnavailableTitle,
            style: AppTypography.getHeadingMedium(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Description
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              l10n.lineupUnavailableDesc,
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Check for Updates Action Button
          ElevatedButton.icon(
            onPressed: () {
              context.read<MatchDetailsBloc>().add(
                    LoadMatchDetailsEvent(matchId, isRefresh: true),
                  );
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              l10n.refreshLineup,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
