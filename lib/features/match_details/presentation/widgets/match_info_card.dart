import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/commentator_resolver.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/match_details_entity.dart';

class MatchInfoCard extends StatelessWidget {
  final MatchInfoSectionEntity section;
  final bool? isDark;
  final bool? isArabic;

  const MatchInfoCard({
    super.key,
    required this.section,
    this.isDark,
    this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final arabic = isArabic ?? l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final isSmall = AppDimensions.isSmallScreen(context);

    if (section.items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header with icon
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(section.section),
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resolveSectionTitle(section.section, arabic),
                    style: AppTypography.getBodyLarge(
                      isDark: dark,
                      isArabic: arabic,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: dark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: dark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            itemBuilder: (context, index) {
              final item = section.items[index];
              final isClickable = _canNavigate(item);
              final displayTitle = _resolveItemTitle(item.title, arabic);
              final displayContent =
                  _resolveItemContent(item.title, item.content, arabic);
              final itemIcon = _getItemIcon(displayTitle);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isClickable
                      ? () => _handleNavigation(context, item)
                      : null,
                  borderRadius: index == section.items.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(AppDimensions.radiusMd),
                        )
                      : BorderRadius.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: isSmall ? 9 : 11,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Item leading icon
                        Icon(
                          itemIcon,
                          size: 16,
                          color: isClickable
                              ? AppColors.primary
                              : (dark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                        ),
                        const SizedBox(width: 8),

                        // Title (e.g. الملعب, الحكم, المعلق, البطولة)
                        Expanded(
                          flex: 2,
                          child: Text(
                            displayTitle,
                            style: AppTypography.getBodySmall(
                              isDark: dark,
                              isArabic: arabic,
                            ).copyWith(
                              color: dark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Content (e.g. Stadium Name, Referee Name, Channel Name)
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  displayContent,
                                  style: AppTypography.getBodyMedium(
                                    isDark: dark,
                                    isArabic: arabic,
                                  ).copyWith(
                                    fontWeight: isClickable
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isClickable
                                        ? AppColors.primary
                                        : (dark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                  ),
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isClickable) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  arabic
                                      ? Icons.chevron_left_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _canNavigate(MatchInfoItemEntity item) {
    return item.canNavigate;
  }

  void _handleNavigation(BuildContext context, MatchInfoItemEntity item) {
    if (!item.canNavigate) return;

    var id = (item.entityId != null &&
            item.entityId!.isNotEmpty &&
            item.entityId != 'null')
        ? item.entityId!
        : '0';

    final isCommentator = item.entityType?.toLowerCase() == 'commentator' ||
        item.title.toLowerCase().contains('commentator') ||
        item.title.contains('معلق');

    if (isCommentator && (id == '0' || id.isEmpty)) {
      final resolvedId = CommentatorResolver.resolveId(item.content) ??
          CommentatorResolver.resolveId(item.slug);
      if (resolvedId != null) {
        id = resolvedId;
      }
    }

    final isChampionship = item.entityType?.toLowerCase() == 'championship' ||
        item.title.toLowerCase().contains('championship') ||
        item.title.toLowerCase().contains('league') ||
        item.title.contains('بطولة') ||
        item.title.contains('دوري') ||
        item.title.contains('كأس');

    if (isChampionship && (id == '0' || id.isEmpty)) {
      final resolvedId = LeagueResolver.resolveId(item.content) ??
          LeagueResolver.resolveId(item.slug);
      if (resolvedId != null) {
        id = resolvedId;
      }
    }

    final rawSlug = (item.slug != null && item.slug!.isNotEmpty)
        ? item.slug!
        : item.content.trim().replaceAll(RegExp(r'\s+'), '-');
    final cleanSlug = UrlHelper.safeDecodeComponent(rawSlug);
    final slug = Uri.encodeComponent(cleanSlug);

    final type = item.entityType?.toLowerCase();
    String finalRoute = '';
    Map<String, dynamic>? extra;

    if (type == 'referee') {
      finalRoute = '/referee/$id/$slug';
    } else if (type == 'stadium') {
      finalRoute = '/stadium/$id/$slug';
    } else if (type == 'commentator') {
      finalRoute = '/commentator/$id/$slug';
    } else if (type == 'championship' || isChampionship) {
      finalRoute = '/league/$id/$slug';
      extra = {'title': item.content, 'slug': slug};
    } else if (type == 'team') {
      finalRoute = '/team/$id/$slug';
      extra = {'name': item.content, 'slug': slug};
    } else if (type == 'match') {
      finalRoute = '/match/$id';
    } else {
      final titleLower = item.title.toLowerCase();
      if (titleLower.contains('referee') || titleLower.contains('حكم')) {
        finalRoute = '/referee/$id/$slug';
      } else if (titleLower.contains('stadium') ||
          titleLower.contains('ملعب') ||
          titleLower.contains('استاد')) {
        finalRoute = '/stadium/$id/$slug';
      } else if (titleLower.contains('commentator') ||
          titleLower.contains('معلق')) {
        finalRoute = '/commentator/$id/$slug';
      } else if (titleLower.contains('بطولة') ||
          titleLower.contains('دوري') ||
          titleLower.contains('league')) {
        finalRoute = '/league/$id/$slug';
        extra = {'title': item.content, 'slug': slug};
      } else if (titleLower.contains('ذهاب') ||
          titleLower.contains('إياب') ||
          titleLower.contains('match')) {
        finalRoute = '/match/$id';
      }
    }

    if (finalRoute.isNotEmpty) {
      context.push(finalRoute, extra: extra);
    }
  }

  IconData _getSectionIcon(String sectionTitle) {
    final lower = sectionTitle.toLowerCase();
    if (lower.contains('حكام') || lower.contains('referee')) {
      return Icons.sports_rounded;
    }
    if (lower.contains('قنوات') ||
        lower.contains('معلق') ||
        lower.contains('broadcast')) {
      return Icons.live_tv_rounded;
    }
    if (lower.contains('مواجهات') ||
        lower.contains('h2h') ||
        lower.contains('head-to-head')) {
      return Icons.history_rounded;
    }
    if (lower.contains('آخر المباريات') || lower.contains('form')) {
      return Icons.trending_up_rounded;
    }
    if (lower.contains('إحصائيات') ||
        lower.contains('statistics') ||
        lower.contains('stats')) {
      return Icons.bar_chart_rounded;
    }
    return Icons.info_outline_rounded;
  }

  IconData _getItemIcon(String itemTitle) {
    final lower = itemTitle.toLowerCase();
    if (lower.contains('ملعب') ||
        lower.contains('stadium') ||
        lower.contains('venue')) {
      return Icons.stadium_outlined;
    }
    if (lower.contains('حكم') || lower.contains('referee')) {
      return Icons.sports_rounded;
    }
    if (lower.contains('معلق') || lower.contains('commentator')) {
      return Icons.mic_none_rounded;
    }
    if (lower.contains('قناة') ||
        lower.contains('channel') ||
        lower.contains('mbc') ||
        lower.contains('bein') ||
        lower.contains('sport')) {
      return Icons.tv_rounded;
    }
    if (lower.contains('بطولة') ||
        lower.contains('دوري') ||
        lower.contains('كأس') ||
        lower.contains('competition') ||
        lower.contains('league')) {
      return Icons.emoji_events_outlined;
    }
    if (lower.contains('تاريخ') || lower.contains('date')) {
      return Icons.calendar_today_rounded;
    }
    if (lower.contains('وقت') ||
        lower.contains('time') ||
        lower.contains('موعد')) {
      return Icons.access_time_rounded;
    }
    if (lower.contains('جولة') ||
        lower.contains('round') ||
        lower.contains('stage')) {
      return Icons.format_list_numbered_rounded;
    }
    if (lower.contains('ذهاب') || lower.contains('leg')) {
      return Icons.swap_horiz_rounded;
    }
    if (lower.contains('إجمالي') || lower.contains('aggregate')) {
      return Icons.layers_outlined;
    }
    if (lower.contains('ترجيح') ||
        lower.contains('penalty') ||
        lower.contains('penalties')) {
      return Icons.sports_soccer_rounded;
    }
    if (lower.contains('استحواذ') || lower.contains('possession')) {
      return Icons.pie_chart_outline_rounded;
    }
    if (lower.contains('تسديد') || lower.contains('shot')) {
      return Icons.gps_fixed_rounded;
    }
    if (lower.contains('خطأ') ||
        lower.contains('أخطاء') ||
        lower.contains('foul')) {
      return Icons.pan_tool_outlined;
    }
    if (lower.contains('تسلل') || lower.contains('offside')) {
      return Icons.flag_outlined;
    }
    if (lower.contains('فوز') || lower.contains('win')) {
      return Icons.check_circle_outline_rounded;
    }
    if (lower.contains('تعادل') || lower.contains('draw')) {
      return Icons.remove_circle_outline_rounded;
    }
    if (lower.contains('خسارة') ||
        lower.contains('lose') ||
        lower.contains('loss')) {
      return Icons.highlight_off_rounded;
    }
    if (lower.contains('حالة') || lower.contains('status')) {
      return Icons.info_outline_rounded;
    }
    return Icons.info_outline_rounded;
  }

  String _resolveSectionTitle(String rawTitle, bool isArabic) {
    final lower = rawTitle.toLowerCase().trim();
    if (lower == 'معلومات اللقاء' ||
        lower == 'معلومات المباراة' ||
        lower == 'match info' ||
        lower == 'match information') {
      return isArabic ? 'معلومات اللقاء' : 'Match Info';
    }
    if (lower == 'القنوات والمعلقين' ||
        lower == 'القنوات والمعلقون' ||
        lower == 'channels and commentators' ||
        lower == 'channels & commentators') {
      return isArabic ? 'القنوات والمعلقين' : 'Channels and Commentators';
    }
    if (lower == 'حكام المباراة' ||
        lower == 'الحكام' ||
        lower == 'referees' ||
        lower == 'match referees') {
      return isArabic ? 'حكام المباراة' : 'Referees';
    }
    return rawTitle;
  }

  String _resolveItemTitle(String rawTitle, bool isArabic) {
    final lower = rawTitle.toLowerCase().trim();
    if (lower == 'حالة المباراة' || lower == 'match status') {
      return isArabic ? 'حالة المباراة' : 'Match Status';
    }
    if (lower == 'البطولة' || lower == 'competition') {
      return isArabic ? 'البطولة' : 'Competition';
    }
    if (lower == 'تاريخ المباراة' || lower == 'match date') {
      return isArabic ? 'تاريخ المباراة' : 'Match Date';
    }
    if (lower == 'وقت المباراة' || lower == 'match time') {
      return isArabic ? 'وقت المباراة' : 'Match Time';
    }
    if (lower == 'صاحب الأرض' || lower == 'home team') {
      return isArabic ? 'صاحب الأرض' : 'Home Team';
    }
    if (lower == 'الضيف' || lower == 'away team') {
      return isArabic ? 'الضيف' : 'Away Team';
    }
    if (lower == 'النتيجة الحالية' || lower == 'current score') {
      return isArabic ? 'النتيجة الحالية' : 'Current Score';
    }
    if (lower == 'نتيجة الشوط الأول' || lower == 'half-time score') {
      return isArabic ? 'نتيجة الشوط الأول' : 'Half-time Score';
    }
    if (lower == 'الملعب' || lower == 'stadium' || lower == 'venue') {
      return isArabic ? 'الملعب' : 'Stadium';
    }
    if (lower == 'الحكم' || lower == 'حكم الساحة' || lower == 'referee') {
      return isArabic ? 'الحكم' : 'Referee';
    }
    if (lower == 'المعلق' || lower == 'commentator') {
      return isArabic ? 'المعلق' : 'Commentator';
    }
    if (lower == 'القناة' || lower == 'channel') {
      return isArabic ? 'القناة' : 'Channel';
    }
    if (lower == 'الجولة' || lower == 'round') {
      return isArabic ? 'الجولة' : 'Round';
    }
    return rawTitle;
  }

  String _resolveItemContent(
    String rawTitle,
    String rawContent,
    bool isArabic,
  ) {
    final titleLower = rawTitle.toLowerCase().trim();
    final isStatusItem = titleLower == 'حالة المباراة' ||
        titleLower == 'match status' ||
        titleLower.contains('حالة') ||
        titleLower.contains('status');

    if (isStatusItem) {
      return MatchStatusHelper.localizeStatus(rawContent, isArabic: isArabic);
    }

    final isTimeItem = titleLower == 'وقت المباراة' ||
        titleLower == 'match time' ||
        titleLower == 'الوقت' ||
        titleLower == 'time';

    if (isTimeItem && rawContent.trim().isNotEmpty && rawContent != '-') {
      String timeFormat = '24h';
      try {
        if (sl.isRegistered<LocalStorageService>()) {
          timeFormat = sl<LocalStorageService>().getTimeFormat();
        }
      } catch (_) {}
      final formatted = DateFormatter.formatDisplayTime(
        rawContent,
        timeFormat: timeFormat,
        isArabic: isArabic,
      );
      if (formatted != '-') {
        return formatted;
      }
    }

    return rawContent;
  }
}

