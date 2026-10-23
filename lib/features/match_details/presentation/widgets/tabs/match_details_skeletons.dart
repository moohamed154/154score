import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../leagues/domain/entities/top_scorer_entity.dart';
import '../../../../leagues/presentation/widgets/top_scorers_table.dart';
import '../../../domain/entities/match_details_entity.dart';
import '../timeline_event_item.dart';

class MatchDetailsSkeletons {
  const MatchDetailsSkeletons._();

  static Widget buildAlertCard(String text, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.trim(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildEventsSkeleton(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required Widget filterSelector,
  }) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    const dummyEvents = [
      MatchEventEntity(
        minute: "89'",
        playerName: 'بابلو مافيو',
        secondaryPlayerName: 'بطاقة صفراء',
        type: 'yellow_card',
        isHomeTeam: true,
      ),
      MatchEventEntity(
        minute: "84'",
        playerName: 'خوليو دياز',
        secondaryPlayerName: 'كوريا',
        type: 'substitution',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "83'",
        playerName: 'هوغو دورو',
        secondaryPlayerName: 'غيرا',
        type: 'substitution',
        isHomeTeam: true,
      ),
      MatchEventEntity(
        minute: "83'",
        playerName: 'خيسوس فاسكيز',
        secondaryPlayerName: 'غايا',
        type: 'substitution',
        isHomeTeam: true,
      ),
      MatchEventEntity(
        minute: "83'",
        playerName: 'جون غوريدي',
        secondaryPlayerName: 'ستاسين',
        type: 'substitution',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "81'",
        playerName: 'خوان إغليسياس',
        type: 'goal',
        score: '0 - 1',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "71'",
        playerName: 'جيورجي كوشوراشفيلي',
        secondaryPlayerName: 'فوفانا',
        type: 'substitution',
        isHomeTeam: false,
      ),
      MatchEventEntity(
        minute: "67'",
        playerName: 'تشيديرا إيجوكي',
        secondaryPlayerName: 'بطاقة صفراء',
        type: 'yellow_card',
        isHomeTeam: true,
      ),
    ];

    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // 1. Video Highlights Summary Button Preview
          Align(
            alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'ملخص المباراة' : 'Match Highlights',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // 2. Section Header: "الأحداث" + [ الأبرز | كل الأحداث ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'الأحداث' : 'Events',
                style: AppTypography.getHeadingMedium(
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              filterSelector,
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // 3. Events Timeline Container matching real UI
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children:
                  dummyEvents.map((e) => TimelineEventItem(event: e)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDetailsSkeleton(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
  }) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: [
          // Section 1: Match Information Card
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'معلومات اللقاء' : 'Match Information',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...List.generate(
                  6,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isArabic ? 'وقت المباراة' : 'Match Time'),
                        const Bone.text(words: 2, fontSize: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section 2: Channels & Commentators Card
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tv_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? 'القنوات الناقلة والمعلقين'
                          : 'Broadcast & Commentators',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('beIN Sports HD 1'),
                      Bone.text(words: 2, fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildStatsSkeleton(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
  }) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        children: List.generate(
          7,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('55%'),
                    Text(
                      isArabic ? 'الاستحواذ على الكرة' : 'Ball Possession',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text('45%'),
                  ],
                ),
                const SizedBox(height: 10),
                Skeleton.leaf(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildNewsSkeleton(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
  }) {
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(hMargin),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              leading: Bone.square(
                size: 56,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              title: const Text('عنوان الخبر الرياضي التمهيدي للمباراة المهمة'),
              subtitle: const Text('منذ ساعتين • 154Score'),
            ),
          );
        },
      ),
    );
  }

  static Widget buildScorersSkeleton({
    required bool isDark,
    required bool isArabic,
  }) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: AppDimensions.xxxl),
        children: [
          TopScorersTable(
            scorers: List.generate(
              8,
              (index) => TopScorerEntity(
                rank: index + 1,
                playerName: isArabic ? 'كيليان مبابي' : 'Kylian Mbappe',
                teamName: isArabic ? 'ريال مدريد' : 'Real Madrid',
                goals: 20 - index,
                penaltyGoals: 2,
                matchesPlayed: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
