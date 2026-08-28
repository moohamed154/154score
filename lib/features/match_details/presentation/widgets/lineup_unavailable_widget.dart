import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';

/// Displayed when lineup data is not available from the API.
///
/// ## API Limitation (documented for future developers)
///
/// As of V4.7.3, the production API (`https://moohamed154-154score-api.hf.space`)
/// does NOT expose a lineup endpoint. The following endpoints were checked and
/// confirmed to contain NO lineup/player data:
///
///   - `GET /api/matches/{id}/details`  → venue, referee, commentator, channel only
///   - `GET /api/matches/{id}/events`   → goals, cards, substitutions timeline only
///   - `GET /api/matches/{id}/stats`    → possession, shots, fouls, passes only
///
/// When the API adds lineup support, implement:
///   - `GET /api/matches/{id}/lineup`   (expected future endpoint)
///   - Expected response fields:
///       - `home.formation` (e.g., "4-3-3")
///       - `away.formation`
///       - `home.starting_xi[]` → `{number, name, position, x, y}`
///       - `away.starting_xi[]` → `{number, name, position, x, y}`
///       - `home.bench[]`       → `{number, name, position}`
///       - `away.bench[]`       → `{number, name, position}`
///       - `home.coach`         → `{name, photo?}`
///       - `away.coach`         → `{name, photo?}`
///
/// See `MatchDetailsRemoteDataSource` to add the new method.
/// See `MatchDetailsRepository` (domain) to add the interface.
/// See `MatchDetailsRepositoryImpl` (data) to implement.
/// See `MatchDetailsState` to add lineup fields.
/// See `MatchDetailsBloc._onLoadMatchDetails` to fetch in parallel.
class LineupUnavailableWidget extends StatelessWidget {
  const LineupUnavailableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 32),
      child: Column(
        children: [
          // Pitch illustration
          _buildPitchIllustration(isDark),

          const SizedBox(height: 28),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            isArabic ? 'التشكيلات غير متاحة حالياً' : 'Lineups Not Available',
            style: AppTypography.getHeadingMedium(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Text(
            isArabic
                ? 'بيانات التشكيلة غير متوفرة حالياً من مصدر البيانات.\nسيتم إضافتها عند توفرها من واجهة البرمجة.'
                : 'Lineup data is not yet available from the data source.\nIt will be added when the API supports it.',
            style: AppTypography.getBodyMedium(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPitchIllustration(bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A3A2A)
            : const Color(0xFF2D7A4F),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Centre circle
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
            ),
          ),

          // Centre line
          Center(
            child: Container(
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),

          // Placeholder player dots — home side
          ..._buildPlayerDots(isHome: true),

          // Placeholder player dots — away side
          ..._buildPlayerDots(isHome: false),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerDots({required bool isHome}) {
    // Represent a 4-4-2-like abstract pattern without real data
    final positions = isHome
        ? [
            const Offset(0.5, 0.85),
            const Offset(0.2, 0.70),
            const Offset(0.4, 0.70),
            const Offset(0.6, 0.70),
            const Offset(0.8, 0.70),
            const Offset(0.3, 0.57),
            const Offset(0.5, 0.57),
            const Offset(0.7, 0.57),
            const Offset(0.35, 0.44),
            const Offset(0.65, 0.44),
            const Offset(0.5, 0.31),
          ]
        : [
            const Offset(0.5, 0.15),
            const Offset(0.2, 0.30),
            const Offset(0.4, 0.30),
            const Offset(0.6, 0.30),
            const Offset(0.8, 0.30),
            const Offset(0.3, 0.43),
            const Offset(0.5, 0.43),
            const Offset(0.7, 0.43),
            const Offset(0.35, 0.56),
            const Offset(0.65, 0.56),
            const Offset(0.5, 0.69),
          ];

    return positions.map((pos) {
      return Positioned.fill(
        child: Align(
          alignment: Alignment(pos.dx * 2 - 1, pos.dy * 2 - 1),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
