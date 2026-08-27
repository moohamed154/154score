import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/match_details_entity.dart';

class TimelineEventItem extends StatelessWidget {
  final MatchEventEntity event;

  const TimelineEventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final isHome = event.isHomeTeam;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: 8,
      ),
      child: Row(
        children: [
          // Home Side Event
          Expanded(
            child: isHome
                ? _buildEventContent(
                    context,
                    isHome: true,
                    isDark: isDark,
                    isArabic: isArabic,
                  )
                : const SizedBox.shrink(),
          ),

          // Center Minute Badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              event.minute.isNotEmpty ? '${event.minute}\'' : '•',
              style: AppTypography.getBodySmall(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),

          // Away Side Event
          Expanded(
            child: !isHome
                ? _buildEventContent(
                    context,
                    isHome: false,
                    isDark: isDark,
                    isArabic: isArabic,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(
    BuildContext context, {
    required bool isHome,
    required bool isDark,
    required bool isArabic,
  }) {
    final (icon, iconColor) = _getEventIcon(event.type);

    final textWidget = Column(
      crossAxisAlignment: isHome
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          event.playerName,
          style: AppTypography.getBodyMedium(isDark: isDark, isArabic: isArabic)
              .copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
          textAlign: isHome ? TextAlign.end : TextAlign.start,
        ),
        if (event.secondaryPlayerName != null &&
            event.secondaryPlayerName!.isNotEmpty)
          Text(
            event.secondaryPlayerName!,
            style:
                AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
            textAlign: isHome ? TextAlign.end : TextAlign.start,
          ),
      ],
    );

    final iconWidget = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );

    return Row(
      mainAxisAlignment: isHome
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: isHome
          ? [Flexible(child: textWidget), const SizedBox(width: 8), iconWidget]
          : [iconWidget, const SizedBox(width: 8), Flexible(child: textWidget)],
    );
  }

  (IconData, Color) _getEventIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('goal') || lower.contains('هدف')) {
      return (Icons.sports_soccer_rounded, AppColors.primary);
    } else if (lower.contains('yellow') || lower.contains('صفراء')) {
      return (Icons.rectangle_rounded, AppColors.yellowCard);
    } else if (lower.contains('red') || lower.contains('حمراء')) {
      return (Icons.rectangle_rounded, AppColors.redCard);
    } else if (lower.contains('sub') || lower.contains('تبديل')) {
      return (Icons.swap_horiz_rounded, AppColors.substitution);
    } else if (lower.contains('var')) {
      return (Icons.tv_rounded, AppColors.varEvent);
    }
    return (Icons.sports_soccer_rounded, AppColors.primary);
  }
}
