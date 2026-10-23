import 'package:material_ui/material_ui.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/match_status_helper.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../matches/domain/entities/match_entity.dart';
import '../../../domain/entities/match_details_entity.dart';
import '../../bloc/match_details_state.dart';
import '../match_form_card.dart';
import '../match_h2h_card.dart';
import '../match_info_card.dart';
import '../match_quick_stats_card.dart';
import '../match_return_leg_card.dart';
import 'match_details_skeletons.dart';

class MatchInfoTab extends StatelessWidget {
  final MatchDetailsState state;
  final MatchEntity match;
  final MatchEntity? initialMatch;
  final bool isDark;
  final bool isArabic;
  final Future<void> Function() onRefresh;

  const MatchInfoTab({
    super.key,
    required this.state,
    required this.match,
    this.initialMatch,
    required this.isDark,
    required this.isArabic,
    required this.onRefresh,
  });

  static String? extractTeamNameFromDetails(
    List<MatchInfoSectionEntity> sections, {
    required bool isHome,
  }) {
    for (final sec in sections) {
      for (final it in sec.items) {
        final t = it.title.trim().toLowerCase();
        if (isHome) {
          if (t.contains('صاحب الأرض') ||
              t.contains('صاحب الارض') ||
              t.contains('المضيف') ||
              t.contains('الفريق الأول') ||
              t.contains('home')) {
            final content = it.content.trim();
            if (content.isNotEmpty && content != '-' && content != 'المضيف') {
              return content;
            }
          }
        } else {
          if (t == 'الضيف' ||
              t.contains('الفريق الضيف') ||
              t.contains('الفريق الثاني') ||
              t.contains('away')) {
            final content = it.content.trim();
            if (content.isNotEmpty && content != '-' && content != 'الضيف') {
              return content;
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (state.status == MatchDetailsStatus.loading ||
        state.status == MatchDetailsStatus.initial) {
      if ((match.team1.isEmpty || match.team1 == 'Home Team') &&
          initialMatch == null) {
        return MatchDetailsSkeletons.buildDetailsSkeleton(
          context,
          isDark: isDark,
          isArabic: isArabic,
        );
      }
    }

    final overview = state.overview;
    final detailsList = List<MatchInfoSectionEntity>.from(state.details);

    final m = (match.team1 != 'Home Team' && match.team1.isNotEmpty)
        ? match
        : (initialMatch ?? match);

    if (m.team1 != 'Home Team' || initialMatch != null) {
      final fallbackItems = <MatchInfoItemEntity>[];
      if (m.leagueTitle != null && m.leagueTitle!.isNotEmpty) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'البطولة' : 'Competition',
            content: m.leagueTitle!,
          ),
        );
      }
      if (m.date != null && m.date!.isNotEmpty) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'تاريخ المباراة' : 'Match Date',
            content: m.date!,
          ),
        );
      }
      if (m.time != null &&
          m.time!.trim().isNotEmpty &&
          m.time!.trim() != '-' &&
          m.time != 'null') {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'وقت المباراة' : 'Match Time',
            content: m.time!,
          ),
        );
      }
      if (m.status != null &&
          m.status!.trim().isNotEmpty &&
          m.status != '-' &&
          m.status != 'null') {
        final statusContent = MatchStatusHelper.localizeStatus(
          m.status,
          isArabic: isArabic,
          minute: m.minute,
        );
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'حالة المباراة' : 'Match Status',
            content: statusContent,
          ),
        );
      }
      fallbackItems.add(
        MatchInfoItemEntity(
          title: isArabic ? 'صاحب الأرض' : 'Home Team',
          content: m.team1,
        ),
      );
      fallbackItems.add(
        MatchInfoItemEntity(
          title: isArabic ? 'الضيف' : 'Away Team',
          content: m.team2,
        ),
      );
      if (m.score1 != null && m.score2 != null && m.score1!.isNotEmpty) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'النتيجة الحالية' : 'Current Score',
            content: '${m.score1} : ${m.score2}',
          ),
        );
      }
      if (m.hasHalfTimeScore) {
        fallbackItems.add(
          MatchInfoItemEntity(
            title: isArabic ? 'نتيجة الشوط الأول' : 'Half-time Score',
            content: '${m.halfTimeScore1} : ${m.halfTimeScore2}',
          ),
        );
      }

      final existingInfoIndex = detailsList.indexWhere(
        (s) =>
            s.section.contains('معلومات') ||
            s.section.toLowerCase().contains('info'),
      );

      if (existingInfoIndex >= 0) {
        final existingSection = detailsList[existingInfoIndex];
        final mergedItems = List<MatchInfoItemEntity>.from(
          existingSection.items,
        );
        for (final item in fallbackItems) {
          if (!mergedItems.any((it) => it.title == item.title)) {
            mergedItems.add(item);
          }
        }
        detailsList[existingInfoIndex] = MatchInfoSectionEntity(
          section: existingSection.section,
          items: mergedItems,
        );
      } else {
        detailsList.insert(
          0,
          MatchInfoSectionEntity(
            section: isArabic ? 'معلومات اللقاء' : 'Match Information',
            items: fallbackItems,
          ),
        );
      }
    }

    if (detailsList.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyView(
              titleKey: 'tab_overview',
              icon: Icons.info_outline_rounded,
            ),
          ],
        ),
      );
    }

    final homeTeamName = (match.team1.isNotEmpty && match.team1 != 'Home Team')
        ? match.team1
        : (initialMatch?.team1 ??
            extractTeamNameFromDetails(detailsList, isHome: true));
    final awayTeamName = (match.team2.isNotEmpty && match.team2 != 'Away Team')
        ? match.team2
        : (initialMatch?.team2 ??
            extractTeamNameFromDetails(detailsList, isHome: false));

    String? noticeText =
        state.alert ?? overview?.note ?? match.note ?? initialMatch?.note;
    if (noticeText == null || noticeText.trim().isEmpty) {
      for (final sec in detailsList) {
        final lowerTitle = sec.section.toLowerCase();
        if (lowerTitle.contains('alert') ||
            lowerTitle.contains('notice') ||
            lowerTitle.contains('hint') ||
            lowerTitle.contains('تنبيه') ||
            lowerTitle.contains('ملاحظة') ||
            lowerTitle.contains('إلغاء') ||
            lowerTitle.contains('تأجيل')) {
          if (sec.items.isNotEmpty) {
            final c = sec.items.first.content.trim();
            if (c.isNotEmpty) {
              noticeText = c;
              break;
            }
          }
        }
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('details_tab_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 0. Cancellation / Postponement / Special Notice Card
          if (noticeText != null && noticeText.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: MatchDetailsSkeletons.buildAlertCard(
                noticeText,
                isDark: isDark,
              ),
            ),

          // 1. First Leg / Return Leg
          if (overview?.returnLeg case final returnLeg?)
            MatchReturnLegCard(
              returnLeg: returnLeg,
              homeTeamFallback: homeTeamName,
              awayTeamFallback: awayTeamName,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 2. Head-to-Head Record
          if (overview?.h2hSummary case final h2hSummary?)
            MatchH2HCard(
              summary: h2hSummary,
              homeTeamFallback: homeTeamName,
              awayTeamFallback: awayTeamName,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 3. Recent Form (Last 5 matches)
          if (overview?.recentForm case final recentForm?)
            MatchFormCard(
              recentForm: recentForm,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 4. Quick Match Statistics
          if (overview?.quickStats case final quickStats?
              when !quickStats.isEmpty)
            MatchQuickStatsCard(
              stats: quickStats,
              isDark: isDark,
              isArabic: isArabic,
            ),

          // 5. Enriched Info Sections
          ...detailsList.where((sec) {
            if (overview != null) {
              if (overview.h2hSummary != null &&
                  (sec.section.contains('المواجهات المباشرة') ||
                      sec.section.toLowerCase().contains('head-to-head'))) {
                return false;
              }
              if (overview.recentForm != null &&
                  (sec.section.contains('آخر المباريات') ||
                      sec.section.toLowerCase().contains('recent form'))) {
                return false;
              }
              if (overview.quickStats != null &&
                  (sec.section.contains('إحصائيات سريعة') ||
                      sec.section.toLowerCase().contains(
                            'quick statistics',
                          ))) {
                return false;
              }
            }
            final lowerTitle = sec.section.toLowerCase();
            if (lowerTitle.contains('alert') ||
                lowerTitle.contains('notice') ||
                lowerTitle.contains('hint') ||
                lowerTitle.contains('تنبيه') ||
                lowerTitle.contains('ملاحظة') ||
                lowerTitle.contains('إلغاء') ||
                lowerTitle.contains('تأجيل')) {
              return false;
            }
            return true;
          }).map(
            (sec) => MatchInfoCard(
              section: sec,
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),
        ],
      ),
    );
  }
}
