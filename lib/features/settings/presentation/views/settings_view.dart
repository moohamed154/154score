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
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../cubit/settings_cubits.dart';
import '../widgets/debug_console_sheet.dart';
import '../widgets/diagnostics_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final storage = sl<LocalStorageService>();
    final ws = sl<WebSocketService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings_title')),
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
              return _buildCard(
                isDark: isDark,
                child: RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      context.read<ThemeCubit>().setThemeMode(mode);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.translate('theme_dark')),
                        secondary: const Icon(Icons.dark_mode_rounded),
                        value: ThemeMode.dark,
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.translate('theme_light')),
                        secondary: const Icon(Icons.light_mode_rounded),
                        value: ThemeMode.light,
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.translate('theme_system')),
                        secondary: const Icon(
                          Icons.settings_system_daydream_rounded,
                        ),
                        value: ThemeMode.system,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSectionHeader(
                        l10n.translate('settings_language'),
                        isDark,
                        isArabic,
                      ),
                      if (localeState.showIndicator) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  _buildCard(
                    isDark: isDark,
                    child: RadioGroup<String>(
                      groupValue: localeState.locale.languageCode,
                      onChanged: (lang) {
                        if (lang != null) {
                          context.read<LocaleCubit>().setLocale(Locale(lang));
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(l10n.translate('lang_arabic')),
                            secondary: const Text(
                              '🇸🇦',
                              style: TextStyle(fontSize: 22),
                            ),
                            value: 'ar',
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: Text(l10n.translate('lang_english')),
                            secondary: const Text(
                              '🇬🇧',
                              style: TextStyle(fontSize: 22),
                            ),
                            value: 'en',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                  trailing: DropdownButton<String>(
                    value: storage.getTimeFormat(),
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: '12h',
                        child: Text(l10n.translate('time_12h')),
                      ),
                      DropdownMenuItem(
                        value: '24h',
                        child: Text(l10n.translate('time_24h')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        storage.setTimeFormat(val);
                        setState(() {});
                        try {
                          context.read<MatchesBloc>().add(
                            ChangeTimeFormatEvent(val),
                          );
                        } catch (_) {}
                      }
                    },
                  ),
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
                            isArabic
                                ? Icons.arrow_back_ios_new_rounded
                                : Icons.arrow_forward_ios_rounded,
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

          // Section: Diagnostics & Health
          _buildSectionHeader(
            l10n.translate('settings_diagnostics'),
            isDark,
            isArabic,
          ),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(l10n.translate('diag_title')),
                  subtitle: Text(l10n.translate('settings_diagnostics')),
                  trailing: Icon(
                    isArabic
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
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
                    isArabic
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    DebugConsoleSheet.show(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                Row(
                  children: [
                    AppBrandLogo(size: 40, isDark: isDark),
                    const SizedBox(width: 12),
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
                          'Powered by 154score API & WebSocket',
                          style: AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ),
                        ),
                      ],
                    ),
                  ],
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
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }
}
