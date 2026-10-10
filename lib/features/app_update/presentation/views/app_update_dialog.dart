import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/app_update_cubit.dart';
import '../viewmodels/app_update_state.dart';

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key});

  static bool _isShowing = false;

  /// Helper to display update dialog smoothly
  static Future<void> show(BuildContext context) async {
    if (_isShowing) return;
    final cubit = context.read<AppUpdateCubit>();
    if (!cubit.state.hasUpdate) return;

    _isShowing = true;
    final isCompulsory = cubit.state.isCompulsory;
    final targetContext = AppRouter.rootNavigatorKey.currentContext ?? context;

    try {
      await showDialog<void>(
        context: targetContext,
        barrierDismissible: !isCompulsory,
        useRootNavigator: true,
        builder: (dialogContext) {
          return BlocProvider.value(
            value: cubit,
            child: const AppUpdateDialog(),
          );
        },
      );
    } catch (e, st) {
      debugPrint('[AppUpdateDialog] showDialog error: $e\n$st');
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final cubit = context.read<AppUpdateCubit>();
        final updateInfo = state.updateInfo;
        final isCompulsory = state.isCompulsory;
        final isDownloading = state.isDownloading;

        final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final textColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
        final mutedColor = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

        return PopScope(
          canPop: !isCompulsory && !isDownloading,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              type: MaterialType.transparency,
              child: Dialog(
                backgroundColor: cardBg,
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header with Badge & Icon
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getStatusColor(state).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(state),
                            color: _getStatusColor(state),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCompulsory
                                    ? 'تحديث إجباري مطلوب'
                                    : 'تحديث جديد متوفر',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'الإصدار ${updateInfo?.latestVersion ?? ''} (الحالي: ${state.currentAppVersion})',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 2. Release Notes
                    if ((updateInfo?.releaseNotes.isNotEmpty ?? false) &&
                        !isDownloading &&
                        state.status != AppUpdateStatus.downloadFailed) ...[
                      Text(
                        'ما الجديد في هذا التحديث:',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 130),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            updateInfo!.releaseNotes,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 3. Live Download Progress
                    if (isDownloading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: state.progress > 0 ? state.progress : null,
                          minHeight: 10,
                          backgroundColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(state.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatProgressBytes(state.receivedBytes, state.totalBytes),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 4. Error Alert View
                    if (state.hasError && state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.liveRed.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.liveRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.liveRed,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 5. Action Buttons
                    Row(
                      children: [
                        // Later button (only if optional and not actively downloading)
                        if (!isCompulsory && !isDownloading) ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'لاحقاً',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],

                        // Main Action Button (Update / Retry / Install)
                        Expanded(
                          flex: isCompulsory ? 1 : 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (isDownloading) {
                                // Active downloading, ignore or let user wait
                                return;
                              }

                              if (state.status == AppUpdateStatus.readyToInstall ||
                                  state.status == AppUpdateStatus.installFailed) {
                                cubit.installApk();
                              } else {
                                cubit.startDownload();
                              }
                            },
                            child: Text(
                              _getActionTitle(state),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    );
  }

  static IconData _getStatusIcon(AppUpdateState state) {
    if (state.hasError) return Icons.warning_amber_rounded;
    if (state.status == AppUpdateStatus.readyToInstall) return Icons.check_circle_rounded;
    if (state.isDownloading) return Icons.downloading_rounded;
    return Icons.system_update_rounded;
  }

  static Color _getStatusColor(AppUpdateState state) {
    if (state.hasError) return AppColors.liveRed;
    if (state.status == AppUpdateStatus.readyToInstall) return AppColors.primary;
    if (state.isDownloading) return AppColors.accent;
    return AppColors.primary;
  }

  static String _getActionTitle(AppUpdateState state) {
    if (state.isDownloading) return 'جاري التحميل...';
    if (state.status == AppUpdateStatus.readyToInstall) return 'تثبيت الآن';
    if (state.status == AppUpdateStatus.installFailed) return 'إعادة محاولة التثبيت';
    if (state.status == AppUpdateStatus.downloadFailed) return 'إعادة المحاولة';
    return 'تحديث الآن';
  }

  static String _formatProgressBytes(int received, int total) {
    if (total <= 0) {
      final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
      return '$receivedMb ميجابايت';
    }
    final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
    return '$receivedMb / $totalMb ميجابايت';
  }
}
