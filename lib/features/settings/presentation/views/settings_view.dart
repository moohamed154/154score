import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../cubit/settings_cubits.dart';
import '../widgets/debug_console_sheet.dart';
import '../widgets/developer_tools_sheet.dart';
import '../widgets/diagnostics_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _logoTapCount = 0;
  Timer? _tapResetTimer;
  late bool _isDeveloperModeUnlocked;

  @override
  void initState() {
    super.initState();
    _isDeveloperModeUnlocked = sl<LocalStorageService>().isDeveloperModeEnabled();
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    super.dispose();
  }

  void _onLogoTap(BuildContext context) {
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      _logoTapCount = 0;
    });

    _logoTapCount++;
    final remaining = 10 - _logoTapCount;

    if (_logoTapCount >= 5 && _logoTapCount < 10) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).isArabic
                ? 'باقي $remaining نقرات لتفعيل أدوات المطور والتشخيص 🛠️'
                : '$remaining more taps to activate Developer Mode 🛠️',
          ),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_logoTapCount >= 10) {
      _logoTapCount = 0;
      _tapResetTimer?.cancel();
      HapticFeedback.heavyImpact();
      setState(() {
        _isDeveloperModeUnlocked = true;
      });
      sl<LocalStorageService>().setDeveloperModeEnabled(true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).isArabic
                ? '🎉 تم تفعيل أدوات المطور والتشخيص بنجاح!'
                : '🎉 Developer Tools unlocked successfully!',
          ),
          backgroundColor: AppColors.uclGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      DeveloperToolsSheet.show(
        context,
        onLockDeveloperMode: () {
          if (mounted) {
            setState(() {
              _isDeveloperModeUnlocked = false;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final storage = sl<LocalStorageService>();
    final ws = sl<WebSocketService>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _onLogoTap(context),
              child: AppBrandLogo(size: 40, isDark: isDark),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _onLogoTap(context),
              child: Text(
                '154Score',
                style: AppTypography.getHeadingLarge(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          // Section: Appearance
          _buildSectionHeader(
            l10n.translate('settings_appearance'),
            isDark,
            isArabic,
          ),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final modeDesc = switch (themeMode) {
                ThemeMode.dark => l10n.translate('theme_dark_title'),
                ThemeMode.light => l10n.translate('theme_light_title'),
                ThemeMode.system => l10n.translate('theme_system_title'),
              };

              final badgeText = switch (themeMode) {
                ThemeMode.dark => isArabic ? 'داكن' : 'Dark',
                ThemeMode.light => isArabic ? 'فاتح' : 'Light',
                ThemeMode.system => isArabic ? 'تلقائي' : 'Auto',
              };

              final modeIcon = switch (themeMode) {
                ThemeMode.dark => Icons.dark_mode_rounded,
                ThemeMode.light => Icons.light_mode_rounded,
                ThemeMode.system => Icons.settings_system_daydream_rounded,
              };

              return _buildCard(
                isDark: isDark,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      modeIcon,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    l10n.translate('settings_appearance'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    modeDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/settings/theme');
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section: Language
          _buildSectionHeader(
            l10n.translate('settings_language'),
            isDark,
            isArabic,
          ),
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              final appLang = localeState.locale.languageCode;
              return BlocBuilder<NewsLanguageCubit, String>(
                builder: (context, newsLang) {
                  final newsLangDesc = switch (newsLang) {
                    'ar' => l10n.translate('news_lang_arabic'),
                    'en' => l10n.translate('news_lang_english'),
                    _ => l10n.translate('news_lang_same_as_app'),
                  };

                  return _buildCard(
                    isDark: isDark,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        l10n.translate('settings_language'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${appLang == 'ar' ? 'العربية 🇸🇦' : 'English 🇬🇧'} • ${l10n.translate('settings_news_language')}: $newsLangDesc',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (localeState.showIndicator) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              appLang == 'ar' ? 'العربية 🇸🇦' : 'English 🇬🇧',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/settings/language');
                      },
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Section: Time & Timezone
          _buildSectionHeader(
            l10n.translate('settings_time'),
            isDark,
            isArabic,
          ),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(l10n.translate('time_format')),
                  subtitle: Text(
                    storage.getTimeFormat() == '12h'
                        ? l10n.translate('time_12h')
                        : l10n.translate('time_24h'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          storage.getTimeFormat().toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ],
                  ),
                  onTap: () async {
                    await context.push('/settings/time-format');
                    if (mounted) setState(() {});
                  },
                ),
                const Divider(height: 1),
                BlocBuilder<TimezoneCubit, TimezoneState>(
                  builder: (context, tzState) {
                    final info = tzState.isAuto
                        ? tzState.deviceOffsetInfo
                        : tzState.currentOffsetInfo;
                    final subtitleText = tzState.isAuto
                        ? '${l10n.translate('timezone_auto')} (${info.formattedOffset})'
                        : info.title(isArabic);

                    return ListTile(
                      leading: const Icon(Icons.public_rounded),
                      title: Text(l10n.translate('timezone_offset')),
                      subtitle: Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              info.formattedOffset,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/settings/timezone');
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Notifications
          _buildSectionHeader(
            l10n.translate('settings_notifications'),
            isDark,
            isArabic,
          ),
          _buildCard(
            isDark: isDark,
            child: ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              title: Text(l10n.translate('settings_notifications')),
              subtitle: Text(
                storage.getMatchNotificationScope() == LocalStorageService.matchNotifScopeStarred
                    ? l10n.translate('notif_scope_starred_title')
                    : l10n.translate('notif_scope_all_title'),
                style: AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              onTap: () async {
                await context.push('/settings/notifications');
                if (mounted) setState(() {});
              },
            ),
          ),

          const SizedBox(height: 24),

          // Section: Developer & Debugging Tools (Hidden by default - unlocked via 10 logo taps)
          if (_isDeveloperModeUnlocked) ...[
            _buildSectionHeader(
              isArabic
                  ? '🛠️ أدوات المطور والتشخيص (Developer Tools)'
                  : '🛠️ Developer & Debugging Tools',
              isDark,
              isArabic,
            ),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.dashboard_customize_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      isArabic
                          ? 'لوحة أدوات المطور الشاملة'
                          : 'Developer Tools Dashboard',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isArabic
                          ? 'تصفير Onboarding، فحص الشبكة، واختبار الإشعارات'
                          : 'Reset Onboarding, test alerts & system diagnostics',
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    onTap: () {
                      DeveloperToolsSheet.show(
                        context,
                        onLockDeveloperMode: () {
                          if (mounted) {
                            setState(() {
                              _isDeveloperModeUnlocked = false;
                            });
                          }
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.accent,
                    ),
                    title: Text(
                      isArabic
                          ? 'تصفير شاشة الترحيب (Reset Onboarding)'
                          : 'Reset Onboarding Flow',
                    ),
                    subtitle: Text(
                      isArabic
                          ? 'مسح علامة الإتمام لتظهر شاشة الترحيب مجدداً'
                          : 'Clear completed flag so onboarding shows on launch',
                    ),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        await sl<OnboardingRepository>().resetOnboarding();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ تم تصفير شاشة الترحيب بنجاح!',
                              ),
                              backgroundColor: AppColors.uclGreen,
                              action: SnackBarAction(
                                label: 'فتح الآن',
                                textColor: Colors.white,
                                onPressed: () => context.push('/onboarding'),
                              ),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                      ),
                      child: Text(isArabic ? 'تصفير' : 'Reset'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.health_and_safety_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.translate('diag_title')),
                    subtitle: Text(l10n.translate('settings_diagnostics')),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => DiagnosticsSheet(webSocketService: ws),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.terminal_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.translate('debug_console_title')),
                    subtitle: Text(l10n.translate('debug_console_subtitle')),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    onTap: () {
                      DebugConsoleSheet.show(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.liveRed,
                    ),
                    title: Text(
                      isArabic
                          ? 'قفل وإخفاء أدوات المطور'
                          : 'Lock Developer Mode',
                      style: const TextStyle(color: AppColors.liveRed),
                    ),
                    subtitle: Text(
                      isArabic
                          ? 'إعادة إخفاء هذه القائمة حتى النقر 10 مرات مجدداً'
                          : 'Hide this section until logo is tapped 10 times again',
                    ),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      storage.setDeveloperModeEnabled(false);
                      setState(() {
                        _isDeveloperModeUnlocked = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔒 تم قفل وإخفاء أدوات المطور.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Section: About
          _buildSectionHeader(
            l10n.translate('settings_about'),
            isDark,
            isArabic,
          ),
          _buildCard(
            isDark: isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _onLogoTap(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      AppBrandLogo(size: 48, isDark: isDark),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '154Score v1.0.0',
                            style: AppTypography.getBodyLarge(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Powered by 154Dev',
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate('about_description'),
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Text(
        title,
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic)
            .copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }


  Widget _buildCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child:
              padding != null ? Padding(padding: padding, child: child) : child,
        ),
      ),
    );
  }
}
