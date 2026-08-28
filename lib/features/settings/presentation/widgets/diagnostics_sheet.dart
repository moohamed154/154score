import 'package:flutter/material.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';

class DiagnosticsSheet extends StatefulWidget {
  final WebSocketService webSocketService;

  const DiagnosticsSheet({super.key, required this.webSocketService});

  @override
  State<DiagnosticsSheet> createState() => _DiagnosticsSheetState();
}

class _DiagnosticsSheetState extends State<DiagnosticsSheet> {
  bool _isLoading = false;
  String? _pingResult;
  String? _healthResult;
  String? _metricsResult;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    final client = ApiClient();

    try {
      final ping = await client.get(ApiEndpoints.ping);
      _pingResult = ping.toString();
    } catch (e) {
      _pingResult = 'Error: $e';
    }

    try {
      final health = await client.get(ApiEndpoints.serverHealth);
      _healthResult = health.toString();
    } catch (e) {
      _healthResult = 'Error: $e';
    }

    try {
      final metrics = await client.get(ApiEndpoints.metrics);
      _metricsResult = 'Metrics Online (${(metrics as Map).length} metrics)';
    } catch (e) {
      _metricsResult = 'Error: $e';
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

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
            stream: widget.webSocketService.healthStream,
            initialData: widget.webSocketService.currentHealth,
            builder: (context, snapshot) {
              final health =
                  snapshot.data ?? widget.webSocketService.currentHealth;
              final wsStatus = health.state.name;
              final rooms = health.activeSubscriptions.isNotEmpty
                  ? health.activeSubscriptions.join(', ')
                  : widget.webSocketService.activeChannel;

              return _buildDiagTile(
                title: l10n.translate('diag_ws_status'),
                value:
                    '$wsStatus | Rooms: [$rooms] | Events: ${health.totalEventsReceived}',
                isSuccess: health.state == SocketConnectionState.connected,
                isDark: isDark,
                isArabic: isArabic,
              );
            },
          ),
          const SizedBox(height: 10),

          _buildDiagTile(
            title: l10n.translate('diag_ping'),
            value: _pingResult ?? 'Checking...',
            isSuccess: _pingResult?.contains('Error') == false,
            isDark: isDark,
            isArabic: isArabic,
          ),
          const SizedBox(height: 10),

          _buildDiagTile(
            title: l10n.translate('diag_api_health'),
            value: _healthResult ?? 'Checking...',
            isSuccess: _healthResult?.contains('Error') == false,
            isDark: isDark,
            isArabic: isArabic,
          ),
          const SizedBox(height: 10),

          _buildDiagTile(
            title: l10n.translate('diag_metrics'),
            value: _metricsResult ?? 'Checking...',
            isSuccess: _metricsResult?.contains('Error') == false,
            isDark: isDark,
            isArabic: isArabic,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _runDiagnostics,
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
                  style:
                      AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isSuccess
                            ? AppColors.primary
                            : AppColors.liveRed,
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
