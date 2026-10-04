import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/notifications/live_match_foreground_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final LocalStorageService _storage = sl<LocalStorageService>();

  late String _matchScope;
  late bool _liveMatchModeEnabled;
  late bool _goalsEnabled;
  late bool _lineupEnabled;
  late bool _startEndEnabled;
  late bool _newsEnabled;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _matchScope = _storage.getMatchNotificationScope();
    _liveMatchModeEnabled = _storage.isLiveMatchModeEnabled();
    _goalsEnabled = _storage.isMatchGoalsNotificationEnabled();
    _lineupEnabled = _storage.isMatchLineupNotificationEnabled();
    _startEndEnabled = _storage.isMatchStartEndNotificationEnabled();
    _newsEnabled = _storage.isNewsNotificationEnabled();
  }

  Future<void> _toggleLiveMatchMode(bool val) async {
    setState(() => _liveMatchModeEnabled = val);
    await _storage.setLiveMatchModeEnabled(val);
    if (Platform.isAndroid) {
      if (val) {
        await LiveMatchForegroundService.startService();
      } else {
        await LiveMatchForegroundService.stopService();
      }
    }
  }

  Future<void> _setScope(String scope) async {
    setState(() => _matchScope = scope);
    await _storage.setMatchNotificationScope(scope);
  }

  Future<void> _toggleGoals(bool val) async {
    setState(() => _goalsEnabled = val);
    await _storage.setMatchGoalsNotificationEnabled(val);
    if (val) unawaited(NotificationService.instance.requestPermissions());
  }

  Future<void> _toggleLineup(bool val) async {
    setState(() => _lineupEnabled = val);
    await _storage.setMatchLineupNotificationEnabled(val);
    if (val) unawaited(NotificationService.instance.requestPermissions());
  }

  Future<void> _toggleStartEnd(bool val) async {
    setState(() => _startEndEnabled = val);
    await _storage.setMatchStartEndNotificationEnabled(val);
    if (val) unawaited(NotificationService.instance.requestPermissions());
  }

  Future<void> _toggleNews(bool val) async {
    setState(() => _newsEnabled = val);
    await _storage.setNewsNotificationEnabled(val);
    if (val) unawaited(NotificationService.instance.requestPermissions());
  }

  Future<void> _sendTestAlert(BuildContext context) async {
    if (_isSendingTest) return;
    setState(() => _isSendingTest = true);

    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    try {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'يرجى تفعيل إذن الإشعارات من إعدادات الهاتف لتلقي التنبيهات'
                        : 'Please enable notifications in device settings to receive alerts',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      await NotificationService.instance.showGoalNotification(
        matchId: 'preview_demo',
        title: isArabic
            ? '⚽ هدف! ريال مدريد 1 - 0 مانشستر سيتي'
            : '⚽ GOAL! Real Madrid 1 - 0 Manchester City',
        body: isArabic
            ? 'فينيسيوس جونيور (34\') - تسديدة صاروخية'
            : 'Vinicius Jr (34\') - Spectacular strike!',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.translate('notif_test_sent'))),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSendingTest = false);
    }
  }

  Widget _buildCard({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: AppTypography.getHeadingSmall(isDark: isDark, isArabic: isArabic).copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('settings_notifications'),
          style: AppTypography.getHeadingMedium(isDark: isDark, isArabic: isArabic),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          // Header Hero Banner
          _buildCard(
            isDark: isDark,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('notifications_title'),
                        style: AppTypography.getHeadingSmall(isDark: isDark, isArabic: isArabic).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('notif_settings_header_desc'),
                        style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section 0: Zero-Delay Live Match Mode ────────────────────────
          _buildSectionHeader(l10n.translate('notif_live_match_mode_title'), isDark, isArabic),
          Text(
            l10n.translate('notif_live_match_mode_subtitle'),
            style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.translate('notif_live_match_service_status'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _liveMatchModeEnabled
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _liveMatchModeEnabled
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.grey.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _liveMatchModeEnabled ? 'Zero Delay' : 'OFF',
                          style: TextStyle(
                            color: _liveMatchModeEnabled ? Colors.green : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      Platform.isIOS
                          ? l10n.translate('notif_live_match_service_desc_ios')
                          : l10n.translate('notif_live_match_service_desc_android'),
                      style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  value: _liveMatchModeEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleLiveMatchMode,
                ),
                if (Platform.isAndroid && _liveMatchModeEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.battery_charging_full_rounded, color: Colors.teal, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.translate('notif_battery_opt_button'),
                            style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic),
                          ),
                        ),
                        TextButton(
                          onPressed: () => LiveMatchForegroundService.requestBatteryExemption(),
                          child: const Text('تفعيل / Allow'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section 1: Match Notification Scope ──────────────────────────
          _buildSectionHeader(l10n.translate('notif_scope_title'), isDark, isArabic),
          Text(
            l10n.translate('notif_scope_subtitle'),
            style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          _buildCard(
            isDark: isDark,
            child: RadioGroup<String>(
              groupValue: _matchScope,
              onChanged: (val) {
                if (val != null) _setScope(val);
              },
              child: Column(
                children: [
                  // Option 1: Starred / Subscribed teams only (Recommended)
                  InkWell(
                    onTap: () => _setScope(LocalStorageService.matchNotifScopeStarred),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusMd)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Radio<String>(
                            value: LocalStorageService.matchNotifScopeStarred,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        l10n.translate('notif_scope_starred_title'),
                                        style: AppTypography.getBodyMedium(
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.translate('notif_scope_recommended_badge'),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.translate('notif_scope_starred_desc'),
                                  style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Option 2: All Matches
                  InkWell(
                    onTap: () => _setScope(LocalStorageService.matchNotifScopeAll),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusMd)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Radio<String>(
                            value: LocalStorageService.matchNotifScopeAll,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.public_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        l10n.translate('notif_scope_all_title'),
                                        style: AppTypography.getBodyMedium(
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.translate('notif_scope_all_desc'),
                                  style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Section 2: Alert Types ───────────────────────────────────────
          _buildSectionHeader(l10n.translate('notif_events_title'), isDark, isArabic),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.sports_soccer_rounded, color: Colors.green),
                  title: Text(l10n.translate('notif_match_goals')),
                  subtitle: Text(l10n.translate('notif_match_goals_desc')),
                  value: _goalsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleGoals,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.groups_rounded, color: Colors.blue),
                  title: Text(l10n.translate('notif_match_lineup')),
                  subtitle: Text(l10n.translate('notif_match_lineup_desc')),
                  value: _lineupEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleLineup,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.alarm_rounded, color: Colors.orange),
                  title: Text(l10n.translate('notif_match_start_end')),
                  subtitle: Text(l10n.translate('notif_match_start_end_desc')),
                  value: _startEndEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleStartEnd,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.newspaper_rounded, color: Colors.deepPurple),
                  title: Text(l10n.translate('notif_news')),
                  subtitle: Text(l10n.translate('notif_news_desc')),
                  value: _newsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleNews,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section 3: Favorite Teams Management ─────────────────────────
          _buildSectionHeader(l10n.translate('notif_favorite_teams_section'), isDark, isArabic),
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              final count = favState.favoriteTeams.length;
              final countText = l10n.translate('notif_starred_teams_count').replaceAll(
                    '{count}',
                    '$count',
                  );

              return _buildCard(
                isDark: isDark,
                child: ListTile(
                  leading: const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 28),
                  title: Text(
                    l10n.translate('notif_manage_favorites'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(countText),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  onTap: () => context.push('/favorites'),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section 4: Test Alert ────────────────────────────────────────
          _buildSectionHeader(l10n.translate('notif_test_title'), isDark, isArabic),
          _buildCard(
            isDark: isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('notif_test_subtitle'),
                  style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSendingTest ? null : () => _sendTestAlert(context),
                    icon: _isSendingTest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(l10n.translate('notif_test_button')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
