import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/match_minute_parser.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/match_details_entity.dart';
import 'match_event_visual_icon.dart';

class TimelineEventItem extends StatelessWidget {
  final MatchEventEntity event;

  const TimelineEventItem({super.key, required this.event});

  void _navigateToPlayer(
    BuildContext context,
    String? name, {
    String? id,
    String? photo,
  }) {
    if (name == null ||
        name.trim().isEmpty ||
        name.trim() == '-' ||
        name.trim() == 'غير محدد') {
      return;
    }
    final cleanName = name.trim();
    final slug = Uri.encodeComponent(cleanName.replaceAll(RegExp(r'\s+'), '-'));
    final effectiveId = (id != null && id.isNotEmpty && id != '0') ? id : '0';
    context.push(
      '/player/$effectiveId/$slug',
      extra: {
        'name': cleanName,
        if (photo != null && photo.isNotEmpty) 'photo': photo,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final isSmall = AppDimensions.isSmallScreen(context);
    final hPadding = isSmall ? 6.0 : 8.0;

    final isHome = event.isHomeTeam;
    final isPeriodEvent = _isPeriodEvent(event.type, event.playerName);

    if (isPeriodEvent) {
      final scoreStr = (event.score != null &&
              event.score!.trim().isNotEmpty &&
              event.score != '-')
          ? event.score!.trim()
          : null;
      final label = _getPeriodLabel(event, l10n, isArabic);

      final periodWidget = Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (scoreStr != null) ...[
              Text(
                scoreStr,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 3),
            ] else ...[
              const MatchEventVisualIcon(
                type: MatchVisualEventType.whistle,
                isSmall: false,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (event.hasVideo) ...[
              const SizedBox(height: 4),
              _buildVideoBadge(context, isDark, isArabic, isSmall),
            ],
          ],
        ),
      );

      if (event.hasVideo) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () => _handleVideoNavigation(context),
            child: periodWidget,
          ),
        );
      }

      return periodWidget;
    }

    final (visualType, iconColor, eventLabel) = _getVisualEventConfig(
      event.type,
      event.secondaryPlayerName,
      l10n,
      isDark,
    );

    final eventRow = Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 4.5),
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
                    visualType: visualType,
                    iconColor: iconColor,
                    eventLabel: eventLabel,
                  )
                : const SizedBox.shrink(),
          ),

          // Center Minute Badge (Goal inside circle, others plain text)
          _buildCenterMinute(
            rawMinute: event.minute,
            visualType: visualType,
            isDark: isDark,
            isArabic: isArabic,
            isSmall: isSmall,
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
                    visualType: visualType,
                    iconColor: iconColor,
                    eventLabel: eventLabel,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );

    if (event.hasVideo) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          onTap: () => _handleVideoNavigation(context),
          child: eventRow,
        ),
      );
    }

    return eventRow;
  }

  Widget _buildCenterMinute({
    required String rawMinute,
    required MatchVisualEventType visualType,
    required bool isDark,
    required bool isArabic,
    required bool isSmall,
  }) {
    final parsed = MatchMinuteParser.parse(rawMinute);
    final isGoal = visualType == MatchVisualEventType.goal ||
        visualType == MatchVisualEventType.ownGoal ||
        visualType == MatchVisualEventType.successPenalty;
    final isOwnGoal = visualType == MatchVisualEventType.ownGoal;
    final size = isSmall ? 28.0 : 32.0;
    final hasExtra = parsed.extraMinute > 0;
    final mainMinStr = parsed.mainMinute > 0
        ? '${parsed.mainMinute}\''
        : (parsed.formatted.isNotEmpty ? '${parsed.formatted}\'' : '•');

    if (isGoal) {
      final ringColor = isOwnGoal ? AppColors.redCard : AppColors.primary;
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ringColor.withValues(alpha: isDark ? 0.12 : 0.08),
          border: Border.all(
            color: ringColor,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: hasExtra
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+${parsed.extraMinute}',
                    style: TextStyle(
                      fontSize: isSmall ? 8.0 : 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.redCard,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${parsed.mainMinute}\'',
                    style: TextStyle(
                      fontFamily: isArabic ? 'Cairo' : 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: isSmall ? 9.5 : 10.5,
                      color: isDark ? Colors.white : ringColor,
                      height: 1.0,
                    ),
                  ),
                ],
              )
            : Text(
                mainMinStr,
                style: TextStyle(
                  fontFamily: isArabic ? 'Cairo' : 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 10.0 : 11.5,
                  color: isDark ? Colors.white : ringColor,
                ),
              ),
      );
    }

    if (hasExtra) {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+${parsed.extraMinute}',
              style: TextStyle(
                fontSize: isSmall ? 8.5 : 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.redCard,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${parsed.mainMinute}\'',
              style: TextStyle(
                fontFamily: isArabic ? 'Cairo' : 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 9.5 : 10.5,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        mainMinStr,
        style: TextStyle(
          fontFamily: isArabic ? 'Cairo' : 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 10.5 : 11.5,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
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
    required MatchVisualEventType visualType,
    required Color iconColor,
    required String? eventLabel,
  }) {
    final isLeftColumn = isArabic ? !isHome : isHome;
    final isSub = visualType == MatchVisualEventType.substitution;
    final hasSecondary = event.secondaryPlayerName != null &&
        event.secondaryPlayerName!.trim().isNotEmpty;

    final mainPlayerName =
        (isSub && hasSecondary) ? event.secondaryPlayerName! : event.playerName;
    final subPlayerOutName =
        (isSub && hasSecondary) ? event.playerName : event.secondaryPlayerName;

    final iconWidget = MatchEventVisualIcon(
      type: visualType,
      isSmall: isSmall,
      isDark: isDark,
    );

    Widget wrapWithAlignment(Widget innerContent) {
      final directionalityWrapped = Directionality(
        textDirection: isLeftColumn ? TextDirection.rtl : TextDirection.ltr,
        child: innerContent,
      );

      if (!event.hasVideo) {
        return Align(
          alignment:
              isLeftColumn ? Alignment.centerRight : Alignment.centerLeft,
          child: directionalityWrapped,
        );
      }

      final videoBadge = _buildVideoBadge(context, isDark, isArabic, isSmall);

      return Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLeftColumn) ...[
            videoBadge,
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: directionalityWrapped,
              ),
            ),
          ] else ...[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: directionalityWrapped,
              ),
            ),
            const SizedBox(width: 6),
            videoBadge,
          ],
        ],
      );
    }

    // Substitution events: two distinct players, each aligned to the same grid
    if (isSub && subPlayerOutName != null && subPlayerOutName.isNotEmpty) {
      final isInjuredSub = subPlayerOutName.contains('+') ||
          subPlayerOutName.contains('إصابة') ||
          event.type.toLowerCase().contains('injury');
      final cleanOutName = subPlayerOutName
          .replaceAll('+', '')
          .replaceAll('(إصابة)', '')
          .replaceAll('إصابة', '')
          .trim();

      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: Player IN
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 18,
                alignment: Alignment.center,
                child: Icon(
                  isLeftColumn ? Icons.west_rounded : Icons.east_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                alignment: Alignment.center,
                child: _buildPlayerAvatar(
                  event.playerPhoto,
                  event.playerNumber,
                  isDark,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _navigateToPlayer(
                    context,
                    mainPlayerName,
                    id: event.playerId,
                    photo: event.playerPhoto,
                  ),
                  child: Text(
                    mainPlayerName,
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 11.0 : 12.0,
                      height: 1.2,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (event.score != null && event.score!.isNotEmpty) ...[
                const SizedBox(width: 4),
                _buildScorePill(event.score!, isDark),
              ],
            ],
          ),
          const SizedBox(height: 2),
          // Line 2: Player OUT
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 18,
                alignment: Alignment.center,
                child: Icon(
                  isLeftColumn ? Icons.east_rounded : Icons.west_rounded,
                  size: 13,
                  color: AppColors.redCard,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                alignment: Alignment.center,
                child: _buildPlayerAvatar(
                  event.secondaryPlayerPhoto,
                  event.secondaryPlayerNumber,
                  isDark,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _navigateToPlayer(
                    context,
                    cleanOutName,
                    id: event.secondaryPlayerId,
                    photo: event.secondaryPlayerPhoto,
                  ),
                  child: Text(
                    cleanOutName,
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: isSmall ? 9.5 : 10.5,
                      color: AppColors.redCard,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (isInjuredSub) _buildInjuryBadge(),
            ],
          ),
        ],
      );

      return wrapWithAlignment(content);
    }

    // Standard events (Goal, Card, Penalty, VAR, Crossbar, Miss Chance, etc.)
    final isAssist = visualType == MatchVisualEventType.goal &&
        event.secondaryPlayerName != null &&
        event.secondaryPlayerName!.isNotEmpty &&
        event.secondaryPlayerId != null &&
        event.secondaryPlayerId != '0';

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          child: iconWidget,
        ),
        const SizedBox(width: 4),
        Container(
          width: 20,
          alignment: Alignment.center,
          child: _buildPlayerAvatar(
            event.playerPhoto,
            event.playerNumber,
            isDark,
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player Name & Score
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _navigateToPlayer(
                        context,
                        mainPlayerName,
                        id: event.playerId,
                        photo: event.playerPhoto,
                      ),
                      child: Text(
                        mainPlayerName,
                        style:
                            (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmall ? 11.0 : 12.0,
                          height: 1.2,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (event.score != null && event.score!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildScorePill(event.score!, isDark),
                  ],
                ],
              ),

              // Subtitle / Event Label / Assist Player
              if (isAssist) ...[
                const SizedBox(height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _navigateToPlayer(
                    context,
                    event.secondaryPlayerName,
                    id: event.secondaryPlayerId,
                    photo: event.secondaryPlayerPhoto,
                  ),
                  child: Text(
                    event.secondaryPlayerName!,
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: isSmall ? 9.5 : 10.0,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (eventLabel != null ||
                  (event.secondaryPlayerName != null &&
                      event.secondaryPlayerName!.isNotEmpty)) ...[
                const SizedBox(height: 1),
                Text(
                  eventLabel ?? event.secondaryPlayerName!,
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: isSmall ? 9.0 : 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return wrapWithAlignment(content);
  }

  void _handleVideoNavigation(BuildContext context) {
    if (!event.hasVideo) return;
    UrlHelper.navigateToVideo(
      context,
      url: event.videoUrl,
      fallbackErrorMessage: AppLocalizations.of(context).isArabic
          ? 'تعذر تشغيل مقطع الفيديو'
          : 'Unable to open video',
    );
  }

  Widget _buildVideoBadge(
    BuildContext context,
    bool isDark,
    bool isArabic,
    bool isSmall,
  ) {
    final size = isSmall ? 18.0 : 20.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleVideoNavigation(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: isSmall ? 12 : 13.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInjuryBadge() {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: const BoxDecoration(
        color: AppColors.redCard,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.add_rounded,
        size: 9.0,
        color: Colors.white,
      ),
    );
  }

  Widget _buildScorePill(String score, bool isDark) {
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 0.6,
        ),
      ),
      child: Text(
        score,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(
    String? photo,
    int? number,
    bool isDark, {
    double size = 20,
  }) {
    final normalizedPhoto = UrlHelper.normalizePlayerPhotoUrl(photo);
    if (normalizedPhoto != null &&
        normalizedPhoto.isNotEmpty &&
        UrlHelper.isValidImageUrl(normalizedPhoto)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: ClipOval(
          child: AppImage(
            imageUrl: normalizedPhoto,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholderIcon: Icons.person,
          ),
        ),
      );
    }
    if (number != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          '$number',
          style: GoogleFonts.outfit(
            fontSize: size <= 16 ? 8.0 : 9.5,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  bool _isPeriodEvent(String type, String text) {
    if (event.isPeriodMarker) return true;
    final lower = '$type $text'.toLowerCase();
    return lower.contains('start-end-match') ||
        lower.contains('start_end') ||
        lower.contains('period_marker') ||
        lower.contains('whistle') ||
        lower.contains('period') ||
        lower.contains('match-start') ||
        lower.contains('half-time') ||
        lower.contains('full-time') ||
        lower.contains('منتصف المباراة') ||
        lower.contains('بدأت المباراة') ||
        lower.contains('انتهت المباراة') ||
        lower.contains('بداية الشوط') ||
        lower.contains('نهاية الشوط') ||
        lower.contains('نهاية المباراة') ||
        lower == 'ht' ||
        lower == 'ft';
  }

  String _getPeriodLabel(
    MatchEventEntity event,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final name = event.playerName;
    if (name.contains('بداية الشوط الأول') ||
        name.toLowerCase().contains('first half start')) {
      return isArabic ? 'بداية الشوط الأول' : 'First Half Start';
    }
    if (name.contains('نهاية الشوط الأول') ||
        name.toLowerCase().contains('first half end')) {
      return isArabic ? 'نهاية الشوط الأول' : 'First Half End';
    }
    if (name.contains('بداية الشوط الثاني') ||
        name.toLowerCase().contains('second half start')) {
      return isArabic ? 'بداية الشوط الثاني' : 'Second Half Start';
    }
    if (name.contains('نهاية المباراة') ||
        name.toLowerCase().contains('full time') ||
        name.contains('انتهت المباراة')) {
      return isArabic ? 'نهاية المباراة' : 'Full Time';
    }
    if (name.contains('بداية الشوط الإضافي الأول')) {
      return isArabic
          ? 'بداية الشوط الإضافي الأول'
          : 'Extra Time 1st Half Start';
    }
    if (name.contains('نهاية الشوط الإضافي الأول')) {
      return isArabic ? 'نهاية الشوط الإضافي الأول' : 'Extra Time 1st Half End';
    }
    if (name.contains('بداية الشوط الإضافي الثاني')) {
      return isArabic
          ? 'بداية الشوط الإضافي الثاني'
          : 'Extra Time 2nd Half Start';
    }
    if (name.contains('نهاية الشوط الإضافي الثاني')) {
      return isArabic
          ? 'نهاية الشوط الإضافي الثاني'
          : 'Extra Time 2nd Half End';
    }
    if (name.contains('ركلات الترجيح')) {
      return isArabic ? 'ركلات الترجيح' : 'Penalty Shootout';
    }
    if (name.isNotEmpty) return name;
    return _localizeEventType(event.type, l10n);
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

  (MatchVisualEventType, Color, String?) _getVisualEventConfig(
    String type,
    String? subtitle,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final lower = '$type ${subtitle ?? ''}'.toLowerCase();
    final redColor = isDark ? AppColors.redCard : const Color(0xFFDC2626);
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF16A34A);
    final yellowColor = isDark ? AppColors.yellowCard : const Color(0xFFCA8A04);

    if (lower.contains('own_goal') ||
        lower.contains('own-goal') ||
        lower.contains('هدف عكسي')) {
      return (
        MatchVisualEventType.ownGoal,
        redColor,
        l10n.isArabic ? 'هدف في مرماه' : 'Own Goal',
      );
    } else if (lower.contains('goal-x') ||
        lower.contains('تسلل') ||
        lower.contains('إلغاء') ||
        lower.contains('disallowed')) {
      return (
        MatchVisualEventType.disallowedGoal,
        redColor,
        l10n.isArabic ? 'هدف ملغى' : 'Disallowed Goal',
      );
    } else if (lower.contains('missed_penalty') ||
        lower.contains('missed-penalty') ||
        lower.contains('penalty_miss') ||
        lower.contains('penalty-miss') ||
        lower.contains('ركلة جزاء ضائعة') ||
        lower.contains('ضربة جزاء ضائعة') ||
        lower.contains('ضائعة') ||
        lower.contains('مهدرة')) {
      return (
        MatchVisualEventType.missedPenalty,
        redColor,
        l10n.isArabic ? 'ضربة جزاء ضائعة' : 'Missed Penalty',
      );
    } else if (lower.contains('penalty_goal') ||
        lower.contains('penalty-goal') ||
        lower.contains('penalty scored') ||
        lower.contains('penalty_scored') ||
        lower.contains('ركلة جزاء ناجحة') ||
        lower.contains('ضربة جزاء ناجحة') ||
        lower.contains('ركلة جزاء مسجلة') ||
        lower.contains('success_penalty') ||
        lower.contains('ضربة جزاء') ||
        lower.contains('ركلة جزاء') ||
        lower.contains('penalty')) {
      return (
        MatchVisualEventType.successPenalty,
        primaryColor,
        l10n.isArabic ? 'ضربة جزاء' : 'Penalty Scored',
      );
    } else if (lower.contains('crossbar') ||
        lower.contains('shoot_crossbar') ||
        lower.contains('post') ||
        lower.contains('عارضة') ||
        lower.contains('قائم')) {
      return (
        MatchVisualEventType.shootCrossbar,
        isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C),
        l10n.isArabic ? 'في القائم / العارضة' : 'Crossbar / Post',
      );
    } else if (lower.contains('miss_chance') ||
        lower.contains('missed_chance') ||
        lower.contains('فرصة ضائعة')) {
      return (
        MatchVisualEventType.missChance,
        isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
        l10n.isArabic ? 'فرصة ضائعة' : 'Missed Chance',
      );
    } else if (lower.contains('second_yellow') ||
        lower.contains('second-yellow') ||
        lower.contains('yellow_red_card') ||
        lower.contains('صفراء ثانية') ||
        lower.contains('إنذار ثان')) {
      return (
        MatchVisualEventType.yellowRedCard,
        redColor,
        l10n.isArabic ? 'إنذار ثانٍ / طرد' : '2nd Yellow / Red',
      );
    } else if (lower.contains('yellow') ||
        lower.contains('صفراء') ||
        lower.contains('إنذار')) {
      return (MatchVisualEventType.yellowCard, yellowColor, null);
    } else if (lower.contains('red') ||
        lower.contains('حمراء') ||
        lower.contains('طرد')) {
      return (MatchVisualEventType.redCard, redColor, null);
    } else if (lower.contains('sub') || lower.contains('تبديل')) {
      return (
        MatchVisualEventType.substitution,
        isDark ? AppColors.substitution : const Color(0xFF0891B2),
        null,
      );
    } else if (lower.contains('var')) {
      return (
        MatchVisualEventType.varDecision,
        isDark ? AppColors.varEvent : const Color(0xFF2563EB),
        l10n.translate('event_var'),
      );
    } else if (lower.contains('goal') || lower.contains('هدف')) {
      return (MatchVisualEventType.goal, primaryColor, null);
    } else if (lower.contains('paused') ||
        lower.contains('interrupted') ||
        lower.contains('توقف')) {
      return (
        MatchVisualEventType.paused,
        isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
        l10n.isArabic ? 'توقف مؤقت' : 'Paused',
      );
    }
    return (MatchVisualEventType.goal, primaryColor, null);
  }
}
