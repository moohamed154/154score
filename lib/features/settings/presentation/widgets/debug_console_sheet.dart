import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/debug_console.dart';

/// Modal bottom sheet for viewing captured network responses and
/// triggering debug console printing on demand.
class DebugConsoleSheet extends StatefulWidget {
  const DebugConsoleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DebugConsoleSheet(),
    );
  }

  @override
  State<DebugConsoleSheet> createState() => _DebugConsoleSheetState();
}

class _DebugConsoleSheetState extends State<DebugConsoleSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('debug_console_title'),
                      style: AppTypography.getHeadingMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.translate('debug_console_subtitle'),
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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Toolbar & Settings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                // Auto-print Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('debug_console_auto_print'),
                        style: AppTypography.getBodyMedium(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: DebugConsole.autoPrintResponses,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          DebugConsole.autoPrintResponses = val;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                // Actions: Print All & Clear
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.terminal_rounded, size: 18),
                        label: Text(
                          l10n.translate('debug_console_print_all'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          DebugConsole.printAllResponses();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.translate('debug_console_printed_all_notice'),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(l10n.translate('debug_console_clear')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                      onPressed: () {
                        DebugConsole.clear();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Filter by URL or status code...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
          ),

          const SizedBox(height: 12),

          // List of recorded network responses
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: DebugConsole.changeNotifier,
              builder: (context, _, __) {
                final allHistory = DebugConsole.history;
                final history = _searchQuery.isEmpty
                    ? allHistory
                    : allHistory.where((rec) {
                        return rec.url.toLowerCase().contains(_searchQuery) ||
                            (rec.statusCode?.toString().contains(_searchQuery) ??
                                false) ||
                            rec.method.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.data_object_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('debug_console_no_logs'),
                          style: AppTypography.getBodyMedium(
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
                  );
                }

                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return _DebugRecordCard(
                      record: record,
                      isDark: isDark,
                      isArabic: isArabic,
                      l10n: l10n,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugRecordCard extends StatefulWidget {
  final DebugNetworkRecord record;
  final bool isDark;
  final bool isArabic;
  final AppLocalizations l10n;

  const _DebugRecordCard({
    required this.record,
    required this.isDark,
    required this.isArabic,
    required this.l10n,
  });

  @override
  State<_DebugRecordCard> createState() => _DebugRecordCardState();
}

class _DebugRecordCardState extends State<_DebugRecordCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isSuccess = !record.isError &&
        record.statusCode != null &&
        record.statusCode! >= 200 &&
        record.statusCode! < 300;

    final statusColor = isSuccess
        ? AppColors.primary
        : (record.isError ? AppColors.liveRed : Colors.orangeAccent);

    final statusLabel = record.statusCode != null
        ? '${record.statusCode}'
        : (record.isError ? 'ERR' : '???');

    final durationLabel = record.duration != null
        ? '${record.duration!.inMilliseconds}ms'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Method badge
                  Text(
                    record.method,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // URL
                  Expanded(
                    child: Text(
                      record.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Duration
                  if (durationLabel.isNotEmpty)
                    Text(
                      durationLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),

                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full URL
                  Text(
                    'URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  SelectableText(
                    record.url,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),

                  // Timestamp
                  Text(
                    'Time: ${record.requestedAt.toIso8601String()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Action Buttons: Print to Debug Console & Copy
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.terminal_rounded, size: 16),
                        label: Text(widget.l10n.translate('debug_console_print_this')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          DebugConsole.printRecord(record);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.l10n.translate(
                                  'debug_console_printed_notice',
                                ),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(widget.l10n.translate('debug_console_copy')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: record.formattedResponseString),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.l10n.translate('debug_console_copied'),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Response Body preview box
                  Text(
                    'Response Body:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 250),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        record.formattedResponseString,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
