import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../news/presentation/bloc/news_bloc.dart';
import '../cubit/settings_cubits.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('settings_language'),
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              if (!localeState.showIndicator) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          final currentAppLang = localeState.locale.languageCode;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            children: [
              // Header description card
              _buildIntroCard(isDark: isDark, isArabic: isArabic, l10n: l10n),

              const SizedBox(height: 24),

              // Section 1: App Interface Language
              _buildSectionHeader(
                icon: Icons.language_rounded,
                title: l10n.translate('settings_app_language'),
                subtitle: l10n.translate('settings_app_language_desc'),
                isDark: isDark,
                isArabic: isArabic,
              ),
              _buildCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildLanguageItem(
                      flag: '🇸🇦',
                      title: 'العربية',
                      subtitle: 'Arabic',
                      isSelected: currentAppLang == 'ar',
                      isDark: isDark,
                      onTap: () {
                        context.read<LocaleCubit>().setLocale(const Locale('ar'));
                      },
                    ),
                    const Divider(height: 1),
                    _buildLanguageItem(
                      flag: '🇬🇧',
                      title: 'English',
                      subtitle: 'الإنجليزية',
                      isSelected: currentAppLang == 'en',
                      isDark: isDark,
                      onTap: () {
                        context.read<LocaleCubit>().setLocale(const Locale('en'));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Section 2: News & Articles Language
              _buildSectionHeader(
                icon: Icons.newspaper_rounded,
                title: l10n.translate('settings_news_language'),
                subtitle: l10n.translate('settings_news_language_desc'),
                isDark: isDark,
                isArabic: isArabic,
              ),
              BlocBuilder<NewsLanguageCubit, String>(
                builder: (context, newsLang) {
                  return _buildCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildLanguageItem(
                          icon: Icons.sync_rounded,
                          title: l10n.translate('news_lang_same_as_app'),
                          subtitle: currentAppLang == 'ar'
                              ? 'العربية 🇸🇦 (تلقائي)'
                              : 'English 🇬🇧 (Auto)',
                          isSelected: newsLang == 'app',
                          isDark: isDark,
                          onTap: () {
                            context.read<NewsLanguageCubit>().setNewsLanguage('app');
                            context.read<NewsBloc>().add(
                              ChangeNewsLanguageEvent(currentAppLang),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildLanguageItem(
                          flag: '🇸🇦',
                          title: l10n.translate('news_lang_arabic'),
                          subtitle: isArabic
                              ? 'عرض وتحديث جميع الأخبار باللغة العربية دائماً'
                              : 'Always display articles in Arabic',
                          isSelected: newsLang == 'ar',
                          isDark: isDark,
                          onTap: () {
                            context.read<NewsLanguageCubit>().setNewsLanguage('ar');
                            context.read<NewsBloc>().add(
                              const ChangeNewsLanguageEvent('ar'),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildLanguageItem(
                          flag: '🇬🇧',
                          title: l10n.translate('news_lang_english'),
                          subtitle: isArabic
                              ? 'عرض وتحديث جميع الأخبار باللغة الإنجليزية دائماً'
                              : 'Always display articles in English',
                          isSelected: newsLang == 'en',
                          isDark: isDark,
                          onTap: () {
                            context.read<NewsLanguageCubit>().setNewsLanguage('en');
                            context.read<NewsBloc>().add(
                              const ChangeNewsLanguageEvent('en'),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntroCard({
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withAlpha(20)
            : AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تخصيص كامل للغات' : 'Complete Language Control',
                  style: AppTypography.getBodyMedium(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'يمكنك فصل لغة واجهة التطبيق عن لغة الأخبار والمقالات، لتصفح التطبيق وإشعاراته بالشكل الذي يناسبك.'
                      : 'You can customize your app interface language and your news feed language separately.',
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isArabic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.getBodyLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.getBodySmall(
              isDark: isDark,
              isArabic: isArabic,
            ).copyWith(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem({
    String? flag,
    IconData? icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (flag != null)
                Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                )
              else if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha(30)
                        : (isDark ? Colors.white10 : Colors.black.withAlpha(10)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withAlpha(120),
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Widget child,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}
