import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profiles_repository.dart';

enum ProfileType { stadium, referee, commentator }

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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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

    return ListView(
      padding: EdgeInsets.all(hMargin),
      children: [
        // Header Hero Card
        if (widget.type == ProfileType.stadium)
          _buildStadiumHero(context, p, isDark, isArabic)
        else
          _buildPersonHero(context, p, isDark, isArabic),

        const SizedBox(height: 20),

        // Detail Sections
        if (p.sections.isEmpty)
          const EmptyView(
            titleKey: 'tab_info',
            customMessage: 'No further details available',
            icon: Icons.info_outline_rounded,
          )
        else
          ...p.sections.map((sec) {
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
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Text(
                      sec.section,
                      style:
                          AppTypography.getBodyLarge(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                it.title,
                                style:
                                    AppTypography.getBodySmall(
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
                              flex: 3,
                              child: Text(
                                it.content,
                                style: AppTypography.getBodyMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.end,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
      ],
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
              height: 120,
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              child: const Center(
                child: Icon(
                  Icons.stadium_rounded,
                  size: 54,
                  color: AppColors.primary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
    return Center(
      child: Column(
        children: [
          AppImage(
            imageUrl: p.image,
            width: 90,
            height: 90,
            borderRadius: 45,
            placeholderIcon: widget.type == ProfileType.referee
                ? Icons.sports_rounded
                : Icons.mic_rounded,
          ),
          const SizedBox(height: 12),
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
                  width: 20,
                  height: 15,
                  borderRadius: 2,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
