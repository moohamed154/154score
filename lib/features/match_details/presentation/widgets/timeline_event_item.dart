import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/match_event_helper.dart';
import '../../domain/entities/match_details_entity.dart';

class TimelineEventItem extends StatelessWidget {
  final MatchEventEntity event;

  const TimelineEventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hPadding = isSmall ? AppDimensions.sm : AppDimensions.lg;

    final isHome = event.isHomeTeam;
    final isPeriodEvent = _isPeriodEvent(event.type, event.playerName);

    if (isPeriodEvent) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardElevated
              : AppColors.lightCardElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                event.playerName.isNotEmpty
                    ? event.playerName
                    : _localizeEventType(event.type, l10n),
                style:
                    AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.minute.isNotEmpty &&
                !event.minute.contains('-') &&
                event.minute != '0') ...[
              const SizedBox(width: 6),
              Text(
                '(${MatchEventHelper.sanitizeMinute(event.minute)}\')',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final sanitizedMinute = MatchEventHelper.sanitizeMinute(event.minute);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home Side Event
          Expanded(
            child: isHome
                ? _buildEventContent(
                    context,
                    isHome: true,
                    isDark: isDark,
                    isArabic: isArabic,
                    isSmall: isSmall,
                    l10n: l10n,
                  )
                : const SizedBox.shrink(),
          ),

          // Center Minute Badge
          Container(
            margin: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
              sanitizedMinute.isNotEmpty ? '$sanitizedMinute\'' : '•',
              style:
                  AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 10 : 12,
                    color: AppColors.primary,
                  ),
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
                    isSmall: isSmall,
                    l10n: l10n,
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
    required bool isSmall,
    required AppLocalizations l10n,
  }) {
    final (icon, iconColor, eventLabel) = _getEventConfig(
      event.type,
      event.secondaryPlayerName,
      l10n,
    );

    final textWidget = Column(
      crossAxisAlignment: isHome
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player Name & Score
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isHome
              ? [
                  if (event.score != null && event.score!.isNotEmpty) ...[
                    _buildScorePill(event.score!, isDark),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      event.playerName,
                      style:
                          AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmall ? 12 : 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              : [
                  Flexible(
                    child: Text(
                      event.playerName,
                      style:
                          AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmall ? 12 : 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.score != null && event.score!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildScorePill(event.score!, isDark),
                  ],
                ],
        ),

        // Event Type / Secondary Player / Substitution In-Out
        if (event.type.toLowerCase().contains('sub') &&
            event.secondaryPlayerName != null &&
            event.secondaryPlayerName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isHome
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: isHome
                ? [
                    Flexible(
                      child: Text(
                        event.secondaryPlayerName!,
                        style: TextStyle(
                          fontSize: isSmall ? 10 : 11,
                          color: AppColors.redCard,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 11,
                      color: AppColors.redCard,
                    ),
                  ]
                : [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 11,
                      color: AppColors.redCard,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        event.secondaryPlayerName!,
                        style: TextStyle(
                          fontSize: isSmall ? 10 : 11,
                          color: AppColors.redCard,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
          ),
        ] else if (event.secondaryPlayerName != null &&
            event.secondaryPlayerName!.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            event.secondaryPlayerName!,
            style:
                AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontSize: isSmall ? 10 : 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
            textAlign: isHome ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ] else if (eventLabel != null) ...[
          const SizedBox(height: 1),
          Text(
            eventLabel,
            style: TextStyle(
              fontSize: isSmall ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
            textAlign: isHome ? TextAlign.end : TextAlign.start,
          ),
        ],
      ],
    );

    final iconWidget = Container(
      padding: EdgeInsets.all(isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: isSmall ? 14 : 16, color: iconColor),
    );

    return Row(
      mainAxisAlignment: isHome
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: isHome
          ? [
              Flexible(child: textWidget),
              SizedBox(width: isSmall ? 6 : 8),
              iconWidget,
            ]
          : [
              iconWidget,
              SizedBox(width: isSmall ? 6 : 8),
              Flexible(child: textWidget),
            ],
    );
  }

  Widget _buildScorePill(String score, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        score,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  bool _isPeriodEvent(String type, String text) {
    final lower = '$type $text'.toLowerCase();
    return lower.contains('start-end-match') ||
        lower.contains('start_end') ||
        lower.contains('whistle') ||
        lower.contains('period') ||
        lower.contains('match-start') ||
        lower.contains('half-time') ||
        lower.contains('full-time') ||
        lower.contains('منتصف المباراة') ||
        lower.contains('بدأت المباراة') ||
        lower.contains('انتهت المباراة') ||
        lower == 'ht' ||
        lower == 'ft';
  }

  String _localizeEventType(String type, AppLocalizations l10n) {
    final lower = type.toLowerCase();
    if (lower.contains('half-time') || lower == 'ht') {
      return l10n.translate('status_half_time');
    }
    if (lower.contains('full-time') || lower == 'ft') {
      return l10n.translate('status_ended');
    }
    return type;
  }

  (IconData, Color, String?) _getEventConfig(
    String type,
    String? subtitle,
    AppLocalizations l10n,
  ) {
    final lower = '$type ${subtitle ?? ''}'.toLowerCase();

    if (lower.contains('own_goal') ||
        lower.contains('own-goal') ||
        lower.contains('هدف عكسي')) {
      return (
        Icons.sports_soccer_rounded,
        AppColors.redCard,
        l10n.isArabic ? 'هدف في مرماه' : 'Own Goal',
      );
    } else if (lower.contains('goal-x') ||
        lower.contains('تسلل') ||
        lower.contains('إلغاء') ||
        lower.contains('disallowed')) {
      return (
        Icons.sports_soccer_rounded,
        AppColors.redCard,
        l10n.isArabic ? 'هدف ملغى' : 'Disallowed Goal',
      );
    } else if (lower.contains('penalty_goal') ||
        lower.contains('penalty-goal') ||
        lower.contains('ضربة جزاء') ||
        lower.contains('ركلة جزاء ناجحة')) {
      return (
        Icons.sports_soccer_rounded,
        AppColors.primary,
        l10n.isArabic ? 'ركلة جزاء' : 'Penalty Goal',
      );
    } else if (lower.contains('missed_penalty') ||
        lower.contains('missed-penalty') ||
        lower.contains('ركلة جزاء ضائعة')) {
      return (
        Icons.close_rounded,
        AppColors.redCard,
        l10n.isArabic ? 'ركلة جزاء ضائعة' : 'Missed Penalty',
      );
    } else if (lower.contains('goal') || lower.contains('هدف')) {
      return (Icons.sports_soccer_rounded, AppColors.primary, null);
    } else if (lower.contains('second_yellow') ||
        lower.contains('second-yellow') ||
        lower.contains('صفراء ثانية')) {
      return (
        Icons.rectangle_rounded,
        AppColors.redCard,
        l10n.isArabic ? 'إنذار ثانٍ / طرد' : '2nd Yellow / Red',
      );
    } else if (lower.contains('yellow') ||
        lower.contains('صفراء') ||
        lower.contains('إنذار')) {
      return (Icons.rectangle_rounded, AppColors.yellowCard, null);
    } else if (lower.contains('red') ||
        lower.contains('حمراء') ||
        lower.contains('طرد')) {
      return (Icons.rectangle_rounded, AppColors.redCard, null);
    } else if (lower.contains('sub') || lower.contains('تبديل')) {
      return (Icons.swap_horiz_rounded, AppColors.substitution, null);
    } else if (lower.contains('var')) {
      return (
        Icons.tv_rounded,
        AppColors.varEvent,
        l10n.translate('event_var'),
      );
    } else if (lower.contains('injury') || lower.contains('added')) {
      return (Icons.more_time_rounded, AppColors.accent, null);
    }
    return (Icons.sports_soccer_rounded, AppColors.primary, null);
  }
}
