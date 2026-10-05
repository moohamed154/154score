import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';

class PenaltyShootoutWidget extends StatelessWidget {
  final String penaltyScore1;
  final String penaltyScore2;
  final List<bool>? attempts1;
  final List<bool>? attempts2;
  final bool isCompact;
  final bool isCardBanner;

  const PenaltyShootoutWidget({
    super.key,
    required this.penaltyScore1,
    required this.penaltyScore2,
    this.attempts1,
    this.attempts2,
    this.isCompact = false,
    this.isCardBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final hasDetailedAttempts =
        attempts1 != null &&
        attempts2 != null &&
        (attempts1!.isNotEmpty || attempts2!.isNotEmpty);

    // ── 1. Match Card Banner Layout (Yalla Shoot style) ───────────────────
    if (isCardBanner) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isArabic ? 'ركلات الترجيح' : 'Penalty Kicks',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          // Balanced Row with symmetrical Expanded anchors so the score is strictly centered
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: (attempts1 != null && attempts1!.isNotEmpty)
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: _buildAttemptSoccerBalls(attempts1!),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$penaltyScore1 - $penaltyScore2',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: (attempts2 != null && attempts2!.isNotEmpty)
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: _buildAttemptSoccerBalls(attempts2!),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final title = isCompact
        ? (isArabic ? 'ر.ت' : 'PEN')
        : (isArabic ? 'ركلات الترجيح' : 'Penalty Shootout');

    // ── 2. Full Shootout Pill with Dots ──────────────────────────────────
    if (hasDetailedAttempts && !isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardElevated : const Color(0xFFEBF5FF),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFB9DCFE),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sports_soccer_rounded,
                  size: 13,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.accent : const Color(0xFF0070BA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: _buildAttemptSoccerBalls(attempts1!),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$penaltyScore1 : $penaltyScore2',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: _buildAttemptSoccerBalls(attempts2!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── 3. Compact Pill ──────────────────────────────────────────────────
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.accent : const Color(0xFF0070BA),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$penaltyScore1 - $penaltyScore2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 5),
            // Symmetry spacer with identical width so the score itself is in the exact center
            Opacity(
              opacity: 0.0,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── 4. Standard Capsule ──────────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFB9DCFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_soccer_rounded,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Text(
            '$title: ',
            style: AppTypography.getBodySmall(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: isDark ? AppColors.accent : const Color(0xFF0070BA),
            ),
          ),
          Text(
            '$penaltyScore1 : $penaltyScore2',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptSoccerBalls(List<bool> attempts) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: attempts.map((success) {
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            border: Border.all(
              color: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
              width: 0.6,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.sports_soccer_rounded,
            size: 9.5,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }
}
