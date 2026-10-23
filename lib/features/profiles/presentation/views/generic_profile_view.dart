import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../../domain/entities/profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_detail_cards.dart';
import '../widgets/profile_hero_cards.dart';

export '../cubit/profile_cubit.dart' show ProfileType;

class GenericProfileView extends StatelessWidget {
  final String id;
  final String slug;
  final ProfileType type;

  const GenericProfileView({
    super.key,
    required this.id,
    required this.slug,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      key: ValueKey('profile_${type.name}_${id}_$slug'),
      create: (_) => sl<ProfileCubit>()
        ..loadProfile(id: id, slug: slug, type: type),
      child: _GenericProfileBody(id: id, slug: slug, type: type),
    );
  }
}

class _GenericProfileBody extends StatelessWidget {
  final String id;
  final String slug;
  final ProfileType type;

  const _GenericProfileBody({
    required this.id,
    required this.slug,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    String defaultTitle = l10n.translate('tab_info');
    if (type == ProfileType.stadium) {
      defaultTitle = isArabic ? 'الاستاد' : 'Stadium';
    } else if (type == ProfileType.referee) {
      defaultTitle = isArabic ? 'الحكم' : 'Referee';
    } else if (type == ProfileType.coach) {
      defaultTitle = isArabic ? 'المدرب' : 'Coach';
    } else if (type == ProfileType.player) {
      defaultTitle = isArabic ? 'اللاعب' : 'Player';
    } else {
      defaultTitle = isArabic ? 'المعلق' : 'Commentator';
    }

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final isLoading = state.status == ProfileStatus.loading ||
            state.status == ProfileStatus.initial;
        final profile = state.profile;
        final errorMessage = state.errorMessage;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              profile?.name.isNotEmpty == true ? profile!.name : defaultTitle,
              style: AppTypography.getBodyLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: isLoading
              ? Skeletonizer(
                  enabled: true,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.getHorizontalMargin(context),
                      vertical: 16,
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                        child: Column(
                          children: const [
                            Bone.circle(size: 88),
                            SizedBox(height: 14),
                            Bone.text(words: 2, fontSize: 18),
                            SizedBox(height: 8),
                            Bone.text(words: 1, fontSize: 13),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        4,
                        (_) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Bone.square(
                                size: 36,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Bone.text(words: 1, fontSize: 11),
                                    SizedBox(height: 6),
                                    Bone.text(words: 2, fontSize: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : errorMessage != null || profile == null
                  ? ErrorView(
                      message: errorMessage,
                      onRetry: () => context
                          .read<ProfileCubit>()
                          .loadProfile(id: id, slug: slug, type: type),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => context
                          .read<ProfileCubit>()
                          .loadProfile(id: id, slug: slug, type: type),
                      child: _buildContent(context, profile, isDark, isArabic),
                    ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProfileEntity p,
    bool isDark,
    bool isArabic,
  ) {
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final hasHighlights = ProfileHighlightsGrid.hasHighlights(p, type);

    // Exclude redundant sections ("معلومات البطاقة" and "معلومات أخرى") when their items
    // are already prominently presented in the Hero, Voice Player, Highlights Grid, or Career card.
    final visibleSections = p.sections
        .map((sec) {
          final sLower = sec.section.toLowerCase();
          final isRedundantSection = sLower.contains('بطاقة') ||
              sLower.contains('card') ||
              sLower.contains('أخرى') ||
              sLower.contains('more info') ||
              sLower.contains('معلومات المعلق') ||
              sLower.contains('commentator information') ||
              sLower.contains('معلومات المدرب') ||
              sLower.contains('coach information') ||
              sLower.contains('المسيرة') ||
              sLower.contains('career');

          if (hasHighlights && isRedundantSection) {
            return const ProfileSectionEntity(section: '', items: []);
          }

          final cleanItems = sec.items.where((it) {
            if (it.content.isEmpty) return false;
            final t = it.title.toLowerCase();
            if (t == 'الاسم' || t == 'name') return false;
            if (t.contains('الانجليزي') || t.contains('english')) return false;
            if (hasHighlights) {
              if (t.contains('القناة') || t.contains('channel')) return false;
              if (t.contains('الدولة') ||
                  t.contains('country') ||
                  t.contains('جنسية')) {
                return false;
              }
              if (t.contains('الميلاد') ||
                  t.contains('birth') ||
                  t.contains('عمر') ||
                  t.contains('age')) {
                return false;
              }
              if (t.contains('لغة') || t.contains('language')) return false;
              if (t.contains('النادي') ||
                  t.contains('club') ||
                  t.contains('فريق')) {
                return false;
              }
              if (t.contains('المنصب') || t.contains('role')) return false;
            }
            if (p.voiceUrl != null &&
                (t.contains('صوت') ||
                    t.contains('voice') ||
                    t.contains('audio'))) {
              return false;
            }
            return true;
          }).toList();

          return ProfileSectionEntity(section: sec.section, items: cleanItems);
        })
        .where((sec) => sec.section.isNotEmpty && sec.items.isNotEmpty)
        .toList();

    return ListView(
      padding: EdgeInsets.all(hMargin),
      children: [
        if (type == ProfileType.stadium)
          ProfileStadiumHeroCard(
            profile: p,
            isDark: isDark,
            isArabic: isArabic,
          )
        else
          ProfilePersonHeroCard(
            profile: p,
            type: type,
            isDark: isDark,
            isArabic: isArabic,
          ),

        const SizedBox(height: AppDimensions.md),

        if (p.voiceUrl != null && p.voiceUrl!.isNotEmpty) ...[
          ProfileVoiceSampleCard(
            profile: p,
            isDark: isDark,
            isArabic: isArabic,
          ),
          const SizedBox(height: AppDimensions.md),
        ],

        if (hasHighlights) ...[
          ProfileHighlightsGrid(
            profile: p,
            type: type,
            isDark: isDark,
            isArabic: isArabic,
          ),
          const SizedBox(height: AppDimensions.md),
        ],

        if (visibleSections.isEmpty &&
            !hasHighlights &&
            p.upcomingMatches.isEmpty &&
            p.recentMatches.isEmpty &&
            p.residentTeams.isEmpty &&
            p.career.isEmpty)
          const EmptyView(
            titleKey: 'tab_info',
            customMessage: 'No further details available',
            icon: Icons.info_outline_rounded,
          )
        else
          ...visibleSections.map(
            (sec) => ProfileSectionCard(
              section: sec,
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),

        if (type == ProfileType.coach &&
            (p.career.isNotEmpty || p.residentTeams.isNotEmpty)) ...[
          const SizedBox(height: AppDimensions.sm),
          ProfileCoachCareerCard(
            profile: p,
            isDark: isDark,
            isArabic: isArabic,
          ),
        ] else if (p.residentTeams.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          ProfileResidentTeamsCard(
            profile: p,
            isDark: isDark,
            isArabic: isArabic,
          ),
        ],

        if (p.upcomingMatches.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          ProfileMatchesSectionHeader(
            title: isArabic ? 'المباريات القادمة' : 'Upcoming Fixtures',
            icon: Icons.event_available_rounded,
            count: p.upcomingMatches.length,
            isDark: isDark,
            isArabic: isArabic,
          ),
          ...p.upcomingMatches.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MatchCard(match: m),
            ),
          ),
        ],

        if (p.recentMatches.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          ProfileMatchesSectionHeader(
            title: isArabic ? 'المباريات السابقة' : 'Past Matches',
            icon: Icons.history_rounded,
            count: p.recentMatches.length,
            isDark: isDark,
            isArabic: isArabic,
          ),
          ...p.recentMatches.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MatchCard(match: m),
            ),
          ),
        ],

        const SizedBox(height: AppDimensions.lg),
      ],
    );
  }
}
