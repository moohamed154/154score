import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../cubit/live_activity_cubit.dart';
import '../cubit/live_activity_state.dart';

class LiveActivityToggleButton extends StatelessWidget {
  final MatchEntity match;
  final String? liveScore1;
  final String? liveScore2;
  final String? liveMinute;
  final String? liveStatus;
  final String? liveStatusCode;
  final String? livePeriod;
  final bool compact;

  const LiveActivityToggleButton({
    super.key,
    required this.match,
    this.liveScore1,
    this.liveScore2,
    this.liveMinute,
    this.liveStatus,
    this.liveStatusCode,
    this.livePeriod,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanMatchId = match.id.replaceAll('match:', '').trim();

    return BlocBuilder<LiveActivityCubit, LiveActivityState>(
      builder: (context, state) {
        final isTracking = state.isTracking(cleanMatchId);
        final isLoading = state.status == LiveActivityStatus.loading;

        if (compact) {
          return IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    isTracking
                        ? Icons.screen_lock_portrait_rounded
                        : Icons.phone_android_rounded,
                    color: isTracking ? AppColors.primary : null,
                    size: 22,
                  ),
            tooltip: isArabic
                ? (isTracking
                    ? 'إيقاف العرض على شاشة القفل'
                    : 'عرض على شاشة القفل')
                : (isTracking
                    ? 'Stop showing on Lock Screen'
                    : 'Show on Lock Screen'),
            onPressed: () => _handleToggle(context, isTracking, l10n),
          );
        }

        // Full banner button layout
        return InkWell(
          onTap: isLoading
              ? null
              : () => _handleToggle(context, isTracking, l10n),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isTracking
                  ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFFE8F5E9))
                  : (isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isTracking
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                width: isTracking ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 6, right: 6),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (isTracking)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(
                    Icons.screen_lock_portrait_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                const SizedBox(width: 8),
                Text(
                  isTracking
                      ? (isArabic ? 'معروض على شاشة القفل' : 'Live on Lock Screen')
                      : (isArabic ? 'عرض على شاشة القفل' : 'Show on Lock Screen'),
                  style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTracking
                        ? AppColors.primary
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
                if (isTracking) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isArabic ? 'إيقاف' : 'Stop',
                      style: AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleToggle(
    BuildContext context,
    bool isTracking,
    AppLocalizations l10n,
  ) async {
    final cubit = context.read<LiveActivityCubit>();
    final isArabic = l10n.isArabic;

    final success = await cubit.toggleTracking(
      match: match,
      liveScore1: liveScore1,
      liveScore2: liveScore2,
      liveMinute: liveMinute,
      liveStatus: liveStatus,
      liveStatusCode: liveStatusCode,
      livePeriod: livePeriod,
    );

    if (context.mounted) {
      if (!success && !isTracking) {
        final errorMsg = cubit.state.errorMessage ??
            (isArabic
                ? 'تعذر بدء العرض على شاشة القفل. تأكد من تفعيل الأنشطة الحالية في إعدادات الهاتف.'
                : 'Failed to start Live Activity. Check device settings.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final msg = isTracking
          ? (isArabic
              ? 'تم إيقاف عرض المباراة على شاشة القفل'
              : 'Match removed from Lock Screen')
          : (isArabic
              ? 'يتم الآن عرض المباراة مباشرة على شاشة القفل'
              : 'Match is now live on your Lock Screen');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isTracking ? Colors.redAccent : AppColors.primary,
              width: 1,
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
