import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../cubit/diagnostics_cubit.dart';

class DiagnosticsSheet extends StatelessWidget {
  final WebSocketService webSocketService;

  const DiagnosticsSheet({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return BlocProvider<DiagnosticsCubit>(
      create: (_) => sl<DiagnosticsCubit>()..runDiagnostics(),
      child: BlocBuilder<DiagnosticsCubit, DiagnosticsState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(AppDimensions.xxl),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('diag_title'),
                      style: AppTypography.getHeadingMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<WebSocketConnectionHealth>(
                  stream: webSocketService.healthStream,
                  initialData: webSocketService.currentHealth,
                  builder: (context, snapshot) {
                    final health =
                        snapshot.data ?? webSocketService.currentHealth;
                    final wsStatus = health.state.name;
                    final rooms = health.activeSubscriptions.isNotEmpty
                        ? health.activeSubscriptions.join(', ')
                        : webSocketService.activeChannel;

                    return Column(
                      children: [
                        _buildDiagTile(
                          title: l10n.translate('diag_ws_status'),
                          value:
                              '$wsStatus (Transport: ${health.currentTransport}${health.latencyMs != null ? ', ${health.latencyMs}ms' : ''})',
                          isSuccess:
                              health.state == SocketConnectionState.connected,
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 10),
                        _buildDiagTile(
                          title: 'Active Rooms & Events',
                          value:
                              'Rooms: [$rooms]\nEvents: ${health.totalEventsReceived} (Dupes: ${health.duplicateEventsSuppressed}, Stale: ${health.staleEventsSuppressed})',
                          isSuccess: true,
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 10),
                        _buildDiagTile(
                          title: 'REST Fallback Status',
                          value: health.restFallbackActive
                              ? 'ACTIVE (Polling Enabled)'
                              : 'INACTIVE (Realtime Healthy)',
                          isSuccess: !health.restFallbackActive,
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildDiagTile(
                  title: l10n.translate('diag_ping'),
                  value: state.pingResult ?? 'Checking...',
                  isSuccess: state.pingResult?.contains('Error') == false,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 10),
                _buildDiagTile(
                  title: l10n.translate('diag_api_health'),
                  value: state.healthResult ?? 'Checking...',
                  isSuccess: state.healthResult?.contains('Error') == false,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 10),
                _buildDiagTile(
                  title: l10n.translate('diag_metrics'),
                  value: state.metricsResult ?? 'Checking...',
                  isSuccess: state.metricsResult?.contains('Error') == false,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () =>
                            context.read<DiagnosticsCubit>().runDiagnostics(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.translate('check_now')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagTile({
    required String title,
    required String value,
    required bool isSuccess,
    required bool isDark,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(
                    color: isSuccess ? AppColors.primary : AppColors.liveRed,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? AppColors.primary : AppColors.liveRed,
            size: 22,
          ),
        ],
      ),
    );
  }
}
