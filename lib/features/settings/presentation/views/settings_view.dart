import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../cubit/settings_cubits.dart';
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          // Section: Appearance
          _buildSectionHeader(l10n.translate('settings_appearance'), isDark, isArabic),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Container(
                decoration: _cardDecoration(isDark),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.translate('theme_dark')),
                      secondary: const Icon(Icons.dark_mode_rounded),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (mode) {
                        if (mode != null) context.read<ThemeCubit>().setThemeMode(mode);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.translate('theme_light')),
                      secondary: const Icon(Icons.light_mode_rounded),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (mode) {
                        if (mode != null) context.read<ThemeCubit>().setThemeMode(mode);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.translate('theme_system')),
                      secondary: const Icon(Icons.settings_system_daydream_rounded),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (mode) {
                        if (mode != null) context.read<ThemeCubit>().setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section: Language
          _buildSectionHeader(l10n.translate('settings_language'), isDark, isArabic),
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, currentLocale) {
              return Container(
                decoration: _cardDecoration(isDark),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(l10n.translate('lang_arabic')),
                      secondary: const Text('🇸🇦', style: TextStyle(fontSize: 22)),
                      value: 'ar',
                      groupValue: currentLocale.languageCode,
                      onChanged: (lang) {
                        if (lang != null) context.read<LocaleCubit>().setLocale(Locale(lang));
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Text(l10n.translate('lang_english')),
                      secondary: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                      value: 'en',
                      groupValue: currentLocale.languageCode,
                      onChanged: (lang) {
                        if (lang != null) context.read<LocaleCubit>().setLocale(Locale(lang));
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section: Time & Timezone
          _buildSectionHeader(l10n.translate('settings_time'), isDark, isArabic),
          Container(
            decoration: _cardDecoration(isDark),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(l10n.translate('time_format')),
                  trailing: DropdownButton<String>(
                    value: storage.getTimeFormat(),
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: '12h', child: Text(l10n.translate('time_12h'))),
                      DropdownMenuItem(value: '24h', child: Text(l10n.translate('time_24h'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        storage.setTimeFormat(val);
                        setState(() {});
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: Text(l10n.translate('timezone_offset')),
                  trailing: DropdownButton<int>(
                    value: storage.getTimezoneOffset(),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('UTC +0')),
                      DropdownMenuItem(value: 1, child: Text('UTC +1')),
                      DropdownMenuItem(value: 2, child: Text('UTC +2 (Cairo/Jerusalem)')),
                      DropdownMenuItem(value: 3, child: Text('UTC +3 (Riyadh/Kuwait/Doha)')),
                      DropdownMenuItem(value: 4, child: Text('UTC +4 (Dubai)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        storage.setTimezoneOffset(val);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Diagnostics & Health
          _buildSectionHeader(l10n.translate('settings_diagnostics'), isDark, isArabic),
          Container(
            decoration: _cardDecoration(isDark),
            child: ListTile(
              leading: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary),
              title: Text(l10n.translate('diag_title')),
              subtitle: Text(l10n.translate('settings_diagnostics')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => DiagnosticsSheet(webSocketService: ws),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Section: About
          _buildSectionHeader(l10n.translate('settings_about'), isDark, isArabic),
          Container(
            decoration: _cardDecoration(isDark),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sports_soccer_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '154Score v1.0.0',
                          style: AppTypography.getBodyLarge(isDark: isDark, isArabic: isArabic).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Powered by 154score API & WebSocket',
                          style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate('about_description'),
                  style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                    height: 1.4,
                  ),
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
        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    );
  }
}
