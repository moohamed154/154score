import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../domain/entities/maintenance_info.dart';
import '../viewmodels/maintenance_cubit.dart';

class MaintenanceView extends StatefulWidget {
  final MaintenanceInfo? initialInfo;

  const MaintenanceView({
    super.key,
    this.initialInfo,
  });

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.initialInfo != null) {
      context.read<MaintenanceCubit>().setInitialInfo(widget.initialInfo!);
    } else {
      context.read<MaintenanceCubit>().checkStatus();
    }

    // Auto-check every 20 seconds so user automatically resumes when admin ends maintenance
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        context.read<MaintenanceCubit>().checkStatus();
      }
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onRetry(BuildContext context) async {
    final cubit = context.read<MaintenanceCubit>();
    final resolved = await cubit.checkStatus();

    if (!context.mounted) return;

    if (resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم استعادة الخدمة بنجاح! مرحباً بك مجدداً.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/');
    } else {
      final isArabic =
          AppLocalizations.of(context).locale.languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'ما زالت أعمال الصيانة والتطوير مستمرة. سنعود قريباً جداً!'
                : 'Maintenance is still ongoing. We will be back shortly!',
          ),
          backgroundColor: Colors.amber.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = AppLocalizations.of(context).locale.languageCode == 'ar';

    return BlocConsumer<MaintenanceCubit, MaintenanceState>(
      listener: (context, state) {
        if (state.status == MaintenanceStatus.resolved) {
          context.go('/');
        }
      },
      builder: (context, state) {
        final displayMessage = state.info?.getDisplayMessage(isArabic) ??
            (isArabic
                ? 'الخوادم تخضع لأعمال الصيانة والتطوير حالياً لتحسين الخدمة. يرجى المحاولة لاحقاً.'
                : 'Servers are currently undergoing scheduled maintenance. Please try again shortly.');

        final isChecking = state.status == MaintenanceStatus.checking;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0B0E14)
                : const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Brand Logo with Theme Switching
                        RepaintBoundary(
                          child: AppBrandLogo(
                            size: 64,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 2. Animated Maintenance Badge Icon
                        RepaintBoundary(
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.amber.withValues(alpha: 0.12)
                                    : Colors.amber.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.40),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(
                                      alpha: isDark ? 0.25 : 0.15,
                                    ),
                                    blurRadius: 28,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.engineering_rounded,
                                  size: 52,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 3. Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isArabic ? 'تحت الصيانة' : 'Under Maintenance',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Main Headline
                        Text(
                          isArabic
                              ? 'النظام تحت أعمال الصيانة والتطوير'
                              : 'Scheduled Maintenance in Progress',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5. Explanatory Message Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131A26)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF222F40)
                                  : const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                displayMessage,
                                textAlign: TextAlign.center,
                                style: AppTypography.getBodyMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  height: 1.6,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              if (state.info?.updatedAt != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  isArabic
                                      ? 'آخر تحديث للحالة: ${state.info!.updatedAt!.toLocal().toString().split('.').first}'
                                      : 'Status updated: ${state.info!.updatedAt!.toLocal().toString().split('.').first}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 6. Primary Action: Try Again Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                isChecking ? null : () => _onRetry(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isChecking
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isArabic
                                            ? 'إعادة المحاولة الآن'
                                            : 'Try Again Now',
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 7. Auto-refresh notice
                        Text(
                          isArabic
                              ? 'سيتم التحقق من عودة الخوادم تلقائياً كل 20 ثانية'
                              : 'Auto-checking server status every 20 seconds',
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
