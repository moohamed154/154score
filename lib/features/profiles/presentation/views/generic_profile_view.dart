import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profiles_repository.dart';

enum ProfileType { stadium, referee, commentator, player }

class GenericProfileView extends StatefulWidget {
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
  State<GenericProfileView> createState() => _GenericProfileViewState();
}

class _GenericProfileViewState extends State<GenericProfileView> {
  bool _isLoading = true;
  String? _errorMessage;
  ProfileEntity? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant GenericProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.slug != widget.slug ||
        oldWidget.type != widget.type) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lang = sl<LocalStorageService>().getLanguage();
      final repo = sl<ProfilesRepository>();

      final result = await switch (widget.type) {
        ProfileType.stadium => repo.getStadiumProfile(
          widget.id,
          widget.slug,
          lang: lang,
        ),
        ProfileType.referee => repo.getRefereeProfile(
          widget.id,
          widget.slug,
          lang: lang,
        ),
        ProfileType.commentator => repo.getCommentatorProfile(
          widget.id,
          widget.slug,
          lang: lang,
        ),
        ProfileType.player => repo.getPlayerProfile(
          widget.id,
          widget.slug,
          lang: lang,
        ),
      };

      if (!mounted) return;

      result.fold(
        onSuccess: (p) {
          setState(() {
            _profile = p;
            _isLoading = false;
          });
        },
        onFailure: (f) {
          setState(() {
            _errorMessage = f.message;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final typeTitle = switch (widget.type) {
      ProfileType.stadium => l10n.translate('info_stadium'),
      ProfileType.referee => l10n.translate('info_referee'),
      ProfileType.commentator => l10n.translate('info_commentator'),
      ProfileType.player => isArabic ? 'لاعب' : 'Player',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _profile?.name ?? typeTitle,
          style: AppTypography.getBodyLarge(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? Skeletonizer(
              enabled: true,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.getHorizontalMargin(context),
                  vertical: 16,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 160,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(
                    4,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? ErrorView(message: _errorMessage, onRetry: _loadProfile)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadProfile,
              child: _buildContent(context, isDark, isArabic),
            ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, bool isArabic) {
    final p = _profile!;
    final hMargin = AppDimensions.getHorizontalMargin(context);
    final hasHighlights = _hasHighlights(p);

    // Exclude redundant sections ("معلومات البطاقة" and "معلومات أخرى") when their items
    // are already prominently presented in the Hero, Voice Player, and Highlights Grid.
    final visibleSections = p.sections.map((sec) {
      final sLower = sec.section.toLowerCase();
      final isRedundantSection = sLower.contains('بطاقة') ||
          sLower.contains('card') ||
          sLower.contains('أخرى') ||
          sLower.contains('more info') ||
          sLower.contains('معلومات المعلق') ||
          sLower.contains('commentator information');

      if (hasHighlights && isRedundantSection) {
        return const ProfileSectionEntity(section: '', items: []);
      }

      // Filter out items already showcased in hero or highlights grid
      final cleanItems = sec.items.where((it) {
        if (it.content.isEmpty) return false;
        final t = it.title.toLowerCase();
        if (t == 'الاسم' || t == 'name') return false;
        if (t.contains('الانجليزي') || t.contains('english')) return false;
        if (hasHighlights) {
          if (t.contains('القناة') || t.contains('channel')) return false;
          if (t.contains('الدولة') || t.contains('country') || t.contains('جنسية')) return false;
          if (t.contains('الميلاد') || t.contains('birth') || t.contains('عمر') || t.contains('age')) return false;
          if (t.contains('لغة') || t.contains('language')) return false;
        }
        if (p.voiceUrl != null && (t.contains('صوت') || t.contains('voice') || t.contains('audio'))) {
          return false;
        }
        return true;
      }).toList();

      return ProfileSectionEntity(section: sec.section, items: cleanItems);
    }).where((sec) => sec.section.isNotEmpty && sec.items.isNotEmpty).toList();

    return ListView(
      padding: EdgeInsets.all(hMargin),
      children: [
        // Header Hero Card
        if (widget.type == ProfileType.stadium)
          _buildStadiumHero(context, p, isDark, isArabic)
        else
          _buildPersonHero(context, p, isDark, isArabic),

        const SizedBox(height: AppDimensions.md),

        // Voice Clip Player (for commentators with voice sample)
        if (p.voiceUrl != null && p.voiceUrl!.isNotEmpty) ...[
          _buildVoiceSampleCard(context, p, isDark, isArabic),
          const SizedBox(height: AppDimensions.md),
        ],

        // Quick Highlights Grid (Channel, Country, Age, Language)
        if (hasHighlights) ...[
          _buildHighlightsGrid(context, p, isDark, isArabic),
          const SizedBox(height: AppDimensions.md),
        ],

        // Detail Sections (only if any unique non-redundant sections exist)
        if (visibleSections.isEmpty && !hasHighlights)
          const EmptyView(
            titleKey: 'tab_info',
            customMessage: 'No further details available',
            icon: Icons.info_outline_rounded,
          )
        else
          ...visibleSections.map((sec) {
            return _buildSectionCard(context, sec, isDark, isArabic);
          }),

        const SizedBox(height: AppDimensions.lg),
      ],
    );
  }

  bool _hasHighlights(ProfileEntity p) {
    int count = 0;
    if (p.channel != null && p.channel!.isNotEmpty) count++;
    if (p.country != null && p.country!.isNotEmpty) count++;
    if (p.birthDate != null && p.birthDate!.isNotEmpty) count++;
    if (p.commentaryLanguage != null && p.commentaryLanguage!.isNotEmpty) count++;
    return count >= 2;
  }

  Widget _buildHighlightsGrid(
    BuildContext context,
    ProfileEntity p,
    bool isDark,
    bool isArabic,
  ) {
    final items = <_HighlightItem>[];

    if (p.channel != null && p.channel!.isNotEmpty) {
      items.add(
        _HighlightItem(
          label: isArabic ? 'القناة الناقلة' : 'Channel',
          value: p.channel!,
          icon: Icons.live_tv_rounded,
          color: Colors.blueAccent,
        ),
      );
    }

    if (p.country != null && p.country!.isNotEmpty) {
      items.add(
        _HighlightItem(
          label: isArabic ? 'الدولة / الجنسية' : 'Country',
          value: p.country!,
          icon: Icons.public_rounded,
          flagUrl: p.countryFlag,
          color: AppColors.primary,
        ),
      );
    }

    if (p.birthDate != null && p.birthDate!.isNotEmpty) {
      items.add(
        _HighlightItem(
          label: isArabic ? 'العمر والميلاد' : 'Birth & Age',
          value: p.birthDate!,
          icon: Icons.cake_outlined,
          color: Colors.amber,
        ),
      );
    }

    if (p.commentaryLanguage != null && p.commentaryLanguage!.isNotEmpty) {
      items.add(
        _HighlightItem(
          label: isArabic ? 'لغة التعليق' : 'Language',
          value: p.commentaryLanguage!,
          icon: Icons.translate_rounded,
          color: Colors.purpleAccent,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.flagUrl != null
                    ? Center(
                        child: AppImage(
                          imageUrl: item.flagUrl,
                          width: 22,
                          height: 15,
                          borderRadius: 2,
                        ),
                      )
                    : Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceSampleCard(
    BuildContext context,
    ProfileEntity p,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            isDark ? AppColors.darkCard : AppColors.lightCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'صوت المعلق' : 'Commentator Voice Sample',
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'استمع إلى عينة ونبرة التعليق الصوتي'
                      : 'Listen to commentary voice sample',
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              UrlHelper.launchExternalUrl(
                p.voiceUrl,
                context: context,
                fallbackErrorMessage: isArabic
                    ? 'تعذر فتح البث الصوتي'
                    : 'Failed to open audio link',
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              isArabic ? 'استماع' : 'Listen',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    ProfileSectionEntity sec,
    bool isDark,
    bool isArabic,
  ) {
    final sectionIcon = _getSectionIcon(sec.section);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(sectionIcon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  sec.section,
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sec.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final it = sec.items[index];
              final itemIcon = _getItemIcon(it.title);

              return InkWell(
                onTap: it.link != null && it.link!.isNotEmpty
                    ? () => UrlHelper.launchExternalUrl(it.link, context: context)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightCardElevated),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          itemIcon,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Text(
                          it.title,
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                it.content,
                                style: AppTypography.getBodyMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: it.link != null
                                      ? AppColors.primary
                                      : null,
                                ),
                                textAlign: TextAlign.end,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (it.link != null && it.link!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStadiumHero(
    BuildContext context,
    ProfileEntity p,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (p.image != null && p.image!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AppImage(
                imageUrl: p.image,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                placeholderIcon: Icons.stadium_rounded,
              ),
            )
          else
            Container(
              height: 140,
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              child: const Center(
                child: Icon(
                  Icons.stadium_rounded,
                  size: 58,
                  color: AppColors.primary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (p.countryFlag != null) ...[
                      const SizedBox(width: 8),
                      AppImage(
                        imageUrl: p.countryFlag,
                        width: 22,
                        height: 16,
                        borderRadius: 2,
                      ),
                    ],
                  ],
                ),
                if (p.englishName != null &&
                    p.englishName!.isNotEmpty &&
                    p.englishName != p.name) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.englishName!,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: false,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                _buildBadge(
                  icon: Icons.stadium_rounded,
                  label: p.role ?? (isArabic ? 'استاد كرة قدم' : 'Football Stadium'),
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonHero(
    BuildContext context,
    ProfileEntity p,
    bool isDark,
    bool isArabic,
  ) {
    final roleText = p.role ??
        (widget.type == ProfileType.referee
            ? (isArabic ? 'حكم كرة قدم' : 'Football Referee')
            : widget.type == ProfileType.player
            ? (isArabic ? 'لاعب كرة قدم' : 'Football Player')
            : (isArabic ? 'معلق رياضي' : 'Sports Commentator'));

    final placeholderIcon = widget.type == ProfileType.referee
        ? Icons.sports_rounded
        : widget.type == ProfileType.player
        ? Icons.person_rounded
        : Icons.mic_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            isDark ? AppColors.darkCard : AppColors.lightCard,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Circular Avatar with Glow & Ring
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: AppImage(
                imageUrl: p.image,
                width: 100,
                height: 100,
                placeholderIcon: placeholderIcon,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Primary Name
          Text(
            p.name,
            style: AppTypography.getHeadingLarge(
              isDark: isDark,
              isArabic: isArabic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtitle / English Name
          if (p.englishName != null &&
              p.englishName!.isNotEmpty &&
              p.englishName != p.name) ...[
            const SizedBox(height: 4),
            Text(
              p.englishName!,
              style: AppTypography.getBodyMedium(
                isDark: isDark,
                isArabic: false,
              ).copyWith(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 14),

          // Badges Wrap
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Role Badge
              _buildBadge(
                icon: placeholderIcon,
                label: roleText,
                color: AppColors.primary,
                isDark: isDark,
              ),

              // Channel Badge
              if (p.channel != null && p.channel!.isNotEmpty)
                _buildBadge(
                  icon: Icons.live_tv_rounded,
                  label: p.channel!,
                  color: Colors.blueAccent,
                  isDark: isDark,
                ),

              // Country Badge
              if (p.country != null && p.country!.isNotEmpty)
                _buildBadge(
                  flagUrl: p.countryFlag,
                  icon: Icons.public_rounded,
                  label: p.country!,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    IconData? icon,
    String? flagUrl,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flagUrl != null && flagUrl.isNotEmpty) ...[
            AppImage(
              imageUrl: flagUrl,
              width: 16,
              height: 11,
              borderRadius: 2,
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String sectionTitle) {
    final lower = sectionTitle.toLowerCase();
    if (lower.contains('بطاقة') || lower.contains('card')) {
      return Icons.badge_outlined;
    }
    if (lower.contains('حكام') || lower.contains('referee')) {
      return Icons.sports_rounded;
    }
    if (lower.contains('معلومات أخرى') || lower.contains('more info')) {
      return Icons.tune_rounded;
    }
    if (lower.contains('استاد') || lower.contains('stadium')) {
      return Icons.stadium_rounded;
    }
    return Icons.info_outline_rounded;
  }

  IconData _getItemIcon(String itemTitle) {
    final lower = itemTitle.toLowerCase();
    if (lower.contains('قناة') || lower.contains('channel')) {
      return Icons.live_tv_rounded;
    }
    if (lower.contains('دولة') ||
        lower.contains('country') ||
        lower.contains('جنسية') ||
        lower.contains('nationality')) {
      return Icons.public_rounded;
    }
    if (lower.contains('ميلاد') ||
        lower.contains('birth') ||
        lower.contains('عمر') ||
        lower.contains('age')) {
      return Icons.cake_outlined;
    }
    if (lower.contains('لغة') || lower.contains('language')) {
      return Icons.record_voice_over_rounded;
    }
    if (lower.contains('صوت') ||
        lower.contains('voice') ||
        lower.contains('audio')) {
      return Icons.volume_up_rounded;
    }
    if (lower.contains('اسم') || lower.contains('name')) {
      return Icons.person_outline_rounded;
    }
    if (lower.contains('صفة') ||
        lower.contains('role') ||
        lower.contains('مهنة')) {
      return Icons.work_outline_rounded;
    }
    if (lower.contains('ملعب') || lower.contains('stadium')) {
      return Icons.stadium_rounded;
    }
    if (lower.contains('سعة') || lower.contains('capacity')) {
      return Icons.groups_outlined;
    }
    if (lower.contains('مدينة') || lower.contains('city')) {
      return Icons.location_on_outlined;
    }
    if (lower.contains('أرضية') || lower.contains('surface')) {
      return Icons.grass_rounded;
    }
    return Icons.info_outline_rounded;
  }
}

class _HighlightItem {
  final String label;
  final String value;
  final IconData icon;
  final String? flagUrl;
  final Color color;

  const _HighlightItem({
    required this.label,
    required this.value,
    required this.icon,
    this.flagUrl,
    required this.color,
  });
}
