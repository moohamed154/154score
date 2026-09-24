import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../../domain/models/utc_offset_info.dart';
import '../cubit/settings_cubits.dart';

class TimezoneSelectionView extends StatefulWidget {
  const TimezoneSelectionView({super.key});

  @override
  State<TimezoneSelectionView> createState() => _TimezoneSelectionViewState();
}

class _TimezoneSelectionViewState extends State<TimezoneSelectionView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return BlocBuilder<TimezoneCubit, TimezoneState>(
      builder: (context, timezoneState) {
        final deviceOffset = timezoneState.deviceOffset;
        final deviceOffsetInfo = UtcOffsetInfo.findByOffset(deviceOffset);

        // Filter list based on user search query
        final filteredOffsets = UtcOffsetInfo.allOffsets.where((offsetInfo) {
          return offsetInfo.matches(_searchQuery);
        }).toList();

        final showAutoCard = _searchQuery.isEmpty ||
            deviceOffsetInfo.matches(_searchQuery) ||
            'auto'.contains(_searchQuery.toLowerCase()) ||
            'تلقائي'.contains(_searchQuery);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('timezone_offset')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // Search input box
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.md,
                  AppDimensions.lg,
                  AppDimensions.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_timezone'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Offset list with Auto/Device detected card at top
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.sm,
                  ),
                  children: [
                    // Auto Device Card
                    if (showAutoCard) ...[
                      _buildSectionHeader(
                        l10n.translate('timezone_auto'),
                        isDark,
                        isArabic,
                      ),
                      _buildAutoDeviceTile(
                        context: context,
                        isDark: isDark,
                        isArabic: isArabic,
                        isAutoSelected: timezoneState.isAuto,
                        deviceOffsetInfo: deviceOffsetInfo,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Header for All UTC Offsets
                    _buildSectionHeader(
                      l10n.translate('all_timezones'),
                      isDark,
                      isArabic,
                    ),

                    if (filteredOffsets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.translate('no_timezones_found'),
                                style: AppTypography.getBodyMedium(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredOffsets.map((offsetInfo) {
                        final isSelected = !timezoneState.isAuto &&
                            timezoneState.offset == offsetInfo.offset;
                        final isDevice = offsetInfo.offset == deviceOffset;

                        return _buildOffsetTile(
                          context: context,
                          isDark: isDark,
                          isArabic: isArabic,
                          offsetInfo: offsetInfo,
                          isSelected: isSelected,
                          isDevice: isDevice,
                          l10n: l10n,
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildAutoDeviceTile({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required bool isAutoSelected,
    required UtcOffsetInfo deviceOffsetInfo,
    required AppLocalizations l10n,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isAutoSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isAutoSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          final cubit = context.read<TimezoneCubit>();
          cubit.setAutoTimezone();
          try {
            context.read<MatchesBloc>().add(
                  ChangeTimezoneEvent(deviceOffsetInfo.offset),
                );
          } catch (_) {}
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAutoSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark
                          ? AppColors.darkSurface
                          : AppColors.lightBackground),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phonelink_setup_rounded,
                  color: isAutoSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.translate('device_detected_timezone'),
                          style: AppTypography.getBodyMedium(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            deviceOffsetInfo.formattedOffset,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${deviceOffsetInfo.title(isArabic)} (${deviceOffsetInfo.citiesText(isArabic)})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isAutoSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isAutoSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffsetTile({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required UtcOffsetInfo offsetInfo,
    required bool isSelected,
    required bool isDevice,
    required AppLocalizations l10n,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: () {
            final cubit = context.read<TimezoneCubit>();
            cubit.setTimezoneOffset(offsetInfo.offset);
            try {
              context.read<MatchesBloc>().add(
                    ChangeTimezoneEvent(offsetInfo.offset),
                  );
            } catch (_) {}
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // UTC Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightCardElevated),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    offsetInfo.formattedOffset,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title and Representative Cities
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offsetInfo.title(isArabic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isDevice) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.translate('device_tag'),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        offsetInfo.citiesText(isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.getBodySmall(
                          isDark: isDark,
                          isArabic: isArabic,
                        ).copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Radio / Check
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
