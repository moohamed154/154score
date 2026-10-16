import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/notifications/notification_sync_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../../../live_activity/presentation/cubit/live_activity_cubit.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import 'debug_console_sheet.dart';
import 'diagnostics_sheet.dart';

/// Hidden developer & debugging tool bottom sheet.
/// Unlocked only by tapping the app logo 10 times in Settings.
class DeveloperToolsSheet extends StatefulWidget {
  final VoidCallback? onLockDeveloperMode;

  const DeveloperToolsSheet({super.key, this.onLockDeveloperMode});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onLockDeveloperMode,
  }) async {
    await HapticFeedback.heavyImpact();
    if (!context.mounted) return;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          DeveloperToolsSheet(onLockDeveloperMode: onLockDeveloperMode),
    );
  }

  @override
  State<DeveloperToolsSheet> createState() => _DeveloperToolsSheetState();
}

class _DeveloperToolsSheetState extends State<DeveloperToolsSheet> {
  bool _isTestingPing = false;
  String? _pingLatency;
  bool _onboardingStatus = false;
  bool _isLiveActivityEnabled = false;

  @override
  void initState() {
    super.initState();
    _refreshOnboardingStatus();
    _isLiveActivityEnabled = sl<LocalStorageService>().isLiveActivityFeatureEnabled();
  }

  void _refreshOnboardingStatus() {
    final repo = sl<OnboardingRepository>();
    setState(() {
      _onboardingStatus = repo.isCompleted();
    });
  }

  Future<void> _resetOnboarding() async {
    final repo = sl<OnboardingRepository>();
    await repo.resetOnboarding();
    _refreshOnboardingStatus();
    await HapticFeedback.mediumImpact();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✅ تم تصفير شاشة الترحيب (Onboarding Reset) بنجاح!',
        ),
        backgroundColor: AppColors.uclGreen,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'فتح الآن',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/onboarding');
          },
        ),
      ),
    );
  }

  Future<void> _testApiPing() async {
    setState(() {
      _isTestingPing = true;
      _pingLatency = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final client = ApiClient();
      await client.get(ApiEndpoints.ping);
      stopwatch.stop();
      setState(() {
        _isTestingPing = false;
        _pingLatency = '${stopwatch.elapsedMilliseconds} ms (OK)';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isTestingPing = false;
        _pingLatency = 'Failed (${stopwatch.elapsedMilliseconds} ms)';
      });
    }
  }

  Future<void> _sendTestNotification() async {
    await HapticFeedback.selectionClick();
    try {
      await NotificationService.instance.showGoalNotification(
        matchId: 'debug_test_${DateTime.now().millisecondsSinceEpoch}',
        title: '⚽ هدف تجريبي (Debug Alert)',
        body: 'ريال مدريد 1 - 0 برشلونة (د 35) - فينيسيوس جونيور',
        payload: jsonEncode({
          'type': 'goal',
          'matchId': '938652',
          'isMatch': true,
        }),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 تم إرسال إشعار هدف تجريبي بنجاح!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال الإشعار: $e'),
          backgroundColor: AppColors.liveRed,
        ),
      );
    }
  }

  Future<void> _clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 تم مسح كاش الصور من الذاكرة بنجاح!'),
        backgroundColor: AppColors.uclGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearMatchesCache() async {
    context.read<MatchesBloc>().add(
      LoadMatchesEvent(date: DateTime.now(), isRefresh: true),
    );
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 تم تفريغ وإعادة جلب كاش المباريات!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _lockDeveloperMode() async {
    await HapticFeedback.heavyImpact();
    final storage = sl<LocalStorageService>();
    await storage.setDeveloperModeEnabled(false);
    widget.onLockDeveloperMode?.call();
    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔒 تم قفل وإخفاء أدوات المطور من الإعدادات.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final storage = sl<LocalStorageService>();
    final ws = sl<WebSocketService>();
    final height = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B26) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.bug_report_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'أدوات المطور والتشخيص 🛠️'
                            : 'Developer & Debugging Tools 🛠️',
                        style: AppTypography.getHeadingMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        isArabic
                            ? 'أدوات سرية للتحكم بالبيانات وفحص النظام'
                            : 'Hidden tools for system inspection and resets',
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Content List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.lg,
                0,
                AppDimensions.lg,
                AppDimensions.xl,
              ),
              children: [
                // 1. Onboarding Management
                _buildSectionTitle(
                  isArabic ? '1. شاشة الترحيب (Onboarding)' : '1. Onboarding',
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _onboardingStatus
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _onboardingStatus
                              ? AppColors.uclGreen
                              : AppColors.accent,
                        ),
                        title: Text(
                          isArabic
                              ? 'حالة إتمام شاشة الترحيب'
                              : 'Onboarding Completed Status',
                        ),
                        subtitle: Text(
                          _onboardingStatus
                              ? (isArabic
                                    ? 'مكتملة (لن تظهر للمستخدم)'
                                    : 'Completed (hidden on launch)')
                              : (isArabic
                                    ? 'غير مكتملة (ستظهر عند فتح التطبيق)'
                                    : 'Not completed (will appear on launch)'),
                          style: TextStyle(
                            color: _onboardingStatus
                                ? AppColors.uclGreen
                                : AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: _resetOnboarding,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.liveRed,
                            side: const BorderSide(color: AppColors.liveRed),
                          ),
                          child: Text(
                            isArabic ? 'تصفير (Reset)' : 'Reset Flag',
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          isArabic
                              ? 'فتح شاشة الترحيب الآن'
                              : 'Launch Onboarding Screen Now',
                        ),
                        subtitle: Text(
                          isArabic
                              ? 'تجربة التدفق واختيار الثيم والأندية والدوريات'
                              : 'Preview theme, language & favorites selection',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/onboarding');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Core Debugging & Logs
                _buildSectionTitle(
                  isArabic
                      ? '2. سجلات التشخيص ووحدة التحكم'
                      : '2. Diagnostics & Debugging Console',
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.terminal_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          isArabic ? 'وحدة تحكم الشبكة (Debug Console)' : 'Debug Console Sheet',
                        ),
                        subtitle: Text(
                          isArabic
                              ? 'سجل الطلبات، الاستجابات، وأوقات التأخير'
                              : 'Inspect API requests, response payloads & times',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.of(context).pop();
                          DebugConsoleSheet.show(context);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          isArabic ? 'فحص تشخيص النظام (System Diagnostics)' : 'System Diagnostics Sheet',
                        ),
                        subtitle: Text(
                          isArabic
                              ? 'فحص حالة السيرفر، المقاييس، وصحة الـ WebSocket'
                              : 'Ping server endpoints, metrics & WS health',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.of(context).pop();
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
                          Icons.speed_rounded,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          isArabic ? 'قياس سرعة استجابة السيرفر (Ping API)' : 'Ping Server Latency',
                        ),
                        subtitle: Text(
                          _pingLatency ?? (isArabic ? 'اضغط للفحص المباشر' : 'Tap to ping'),
                          style: TextStyle(
                            color: _pingLatency != null && _pingLatency!.contains('OK')
                                ? AppColors.uclGreen
                                : (_pingLatency != null ? AppColors.liveRed : null),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: _isTestingPing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : OutlinedButton(
                                onPressed: _testApiPing,
                                child: Text(isArabic ? 'فحص' : 'Ping'),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Notification Diagnostics
                _buildSectionTitle(
                  isArabic ? '3. فحص الإشعارات (Notification Tools)' : '3. Notifications',
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.liveRed,
                        ),
                        title: Text(
                          isArabic ? 'إرسال إشعار تجريبي فوري' : 'Trigger Mock Notification',
                        ),
                        subtitle: Text(
                          isArabic
                              ? 'اختبار صوت الإشعار وتوجيهه عند الضغط'
                              : 'Test heads-up alert sound, banner & tap navigation',
                        ),
                        trailing: ElevatedButton(
                          onPressed: _sendTestNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isArabic ? 'إرسال' : 'Send'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.sync_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          isArabic ? 'مزامنة الاشتراكات (Sync Topics)' : 'Sync FCM Subscriptions',
                        ),
                        subtitle: Text(
                          isArabic
                              ? 'إعادة تسجيل الأندية والبطولات المفضلة مع السيرفر'
                              : 'Force re-sync starred teams and leagues with backend',
                        ),
                        onTap: () async {
                          await HapticFeedback.selectionClick();
                          await NotificationSyncService.instance.syncAllSubscriptions();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تمت مزامنة الاشتراكات بنجاح!'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Cache & Storage Management
                _buildSectionTitle(
                  isArabic ? '4. إدارة الذاكرة والتخزين المؤقت' : '4. Cache & Storage',
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_rounded),
                        title: Text(isArabic ? 'مسح كاش الصور (Clear Images)' : 'Clear Image Cache'),
                        subtitle: Text(
                          isArabic
                              ? 'تفريغ شعارات الأندية وصور الأخبار من الذاكرة'
                              : 'Clear memory and disk cached logos and banners',
                        ),
                        onTap: _clearImageCache,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.refresh_rounded),
                        title: Text(isArabic ? 'تحديث كاش المباريات' : 'Refresh Matches Cache'),
                        subtitle: Text(
                          isArabic
                              ? 'إعادة طلب مباريات اليوم وتحديث الذاكرة'
                              : 'Invalidate matches cache and re-fetch',
                        ),
                        onTap: _clearMatchesCache,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.liveRed),
                        title: Text(
                          isArabic ? 'تصفير المفضلات (Reset Favorites)' : 'Reset Favorites',
                          style: const TextStyle(color: AppColors.liveRed),
                        ),
                        subtitle: Text(
                          isArabic
                              ? 'حذف الأندية والدوريات المفضلة للعودة للوضع الافتراضي'
                              : 'Remove all custom starred teams and competitions',
                        ),
                        onTap: () async {
                          await HapticFeedback.mediumImpact();
                          await storage.setFavoriteCompetitions([]);
                          if (context.mounted) {
                            context.read<FavoritesCubit>().loadFavorites();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🗑️ تم تصفير قائمة المفضلات بنجاح.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Live Activity Feature Control
                _buildSectionTitle(
                  isArabic
                      ? '5. الإشعارات الحية وشاشة القفل (Live Activity)'
                      : '5. Live Activity & Dynamic Island',
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: SwitchListTile(
                    value: _isLiveActivityEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      await HapticFeedback.selectionClick();
                      await storage.setLiveActivityFeatureEnabled(val);
                      setState(() {
                        _isLiveActivityEnabled = val;
                      });
                      try {
                        await sl<LiveActivityCubit>().onFeatureToggle(val);
                      } catch (_) {}
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? (isArabic
                                      ? '✅ تم تفعيل ميزة Live Activity بنجاح'
                                      : '✅ Live Activity enabled successfully')
                                  : (isArabic
                                      ? '🔒 تم إيقاف ميزة Live Activity'
                                      : '🔒 Live Activity disabled'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor:
                                val ? AppColors.uclGreen : const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    title: Text(
                      isArabic
                          ? 'تفعيل خاصية Live Activity'
                          : 'Enable Live Activity Feature',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isArabic
                          ? 'إظهار أزرار تتبع المباراة على شاشة القفل وتحديثها لحظياً'
                          : 'Show lock screen / dynamic island tracking buttons in match details',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    secondary: Icon(
                      Icons.screen_lock_portrait_rounded,
                      color: _isLiveActivityEnabled
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 6. System State Details
                _buildSectionTitle(
                  isArabic ? '6. معلومات بيئة التشغيل' : '6. Environment Info',
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      children: [
                        _buildInfoRow('Platform OS', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'),
                        _buildInfoRow('App Version', '1.0.0 (Production)'),
                        _buildInfoRow('API Endpoint', ApiEndpoints.baseUrl),
                        _buildInfoRow('WS Endpoint', ApiEndpoints.websocketUrl),
                        _buildInfoRow('App Language', storage.getLanguage()),
                        _buildInfoRow('News Language', storage.getEffectiveNewsLanguage()),
                        _buildInfoRow('Theme Mode', storage.getThemeMode()),
                        _buildInfoRow('Timezone Offset', '${storage.getTimezoneOffset()}h (Auto: ${storage.isTimezoneAuto()})'),
                        _buildInfoRow('WS Connection', ws.currentStatus == SocketConnectionState.connected ? 'Connected 🟢' : 'Disconnected 🔴'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Lock & Close Button
                FilledButton.icon(
                  onPressed: _lockDeveloperMode,
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: Text(
                    isArabic
                        ? 'قفل وإخفاء أدوات المطور (Lock Developer Mode)'
                        : 'Lock & Hide Developer Tools',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF243242) : const Color(0xFFE2E8F0),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4, right: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.accent : AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
