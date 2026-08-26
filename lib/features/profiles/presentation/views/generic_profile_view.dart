import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/datasources/profiles_remote_datasource.dart';
import '../../data/repositories/profiles_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';

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

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ProfilesRepositoryImpl(ProfilesRemoteDataSourceImpl(ApiClient()));
    final result = await switch (widget.type) {
      ProfileType.stadium => repo.getStadiumProfile(widget.id, widget.slug, lang: 'en'),
      ProfileType.referee => repo.getRefereeProfile(widget.id, widget.slug, lang: 'en'),
      ProfileType.commentator => repo.getCommentatorProfile(widget.id, widget.slug, lang: 'en'),
    };

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
          style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? ErrorView(message: _errorMessage, onRetry: _loadProfile)
              : _buildContent(context, isDark, isArabic),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, bool isArabic) {
    final p = _profile!;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        // Header Hero Card
        Center(
          child: Column(
            children: [
              AppImage(
                imageUrl: p.image,
                width: 90,
                height: 90,
                borderRadius: 45,
                placeholderIcon: widget.type == ProfileType.stadium
                    ? Icons.stadium_rounded
                    : (widget.type == ProfileType.referee ? Icons.sports_rounded : Icons.mic_rounded),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.name,
                    style: AppTypography.getHeadingMedium(isDark: isDark, isArabic: isArabic),
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
        ),

        const SizedBox(height: 24),

        // Detail Sections
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
                    style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
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
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      title: Text(
                        it.title,
                        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      trailing: Text(
                        it.content,
                        style: AppTypography.getBodyMedium(isDark: isDark, isArabic: isArabic).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
}
