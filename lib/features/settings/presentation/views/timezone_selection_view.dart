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

  void _selectOffset(int offset) {
    context.read<TimezoneCubit>().setTimezoneOffset(offset);
    try {
      context.read<MatchesBloc>().add(ChangeTimezoneEvent(offset));
    } catch (_) {}
    Navigator.of(context).pop();
  }

  void _selectAuto(int deviceOffset) {
    context.read<TimezoneCubit>().setAutoTimezone();
    try {
      context.read<MatchesBloc>().add(ChangeTimezoneEvent(deviceOffset));
    } catch (_) {}
    Navigator.of(context).pop();
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
            title: Text(
              l10n.translate('timezone_offset'),
              style: AppTypography.getHeadingMedium(
                isDark: isDark,
                isArabic: isArabic,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            children: [
              // Search Input matching SearchView & TransfersView style
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
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
                    hintStyle: AppTypography.getBodySmall(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: 10,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: Auto (Device Timezone)
              if (showAutoCard) ...[
                _buildSectionHeader(
                  l10n.translate('timezone_auto'),
                  isDark,
                  isArabic,
                ),
                _buildCard(
                  isDark: isDark,
                  child: ListTile(
                    leading: const Icon(Icons.phonelink_setup_rounded),
                    title: Text(
                      l10n.translate('device_detected_timezone'),
                      style: AppTypography.getBodyMedium(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${deviceOffsetInfo.formattedOffset} (${deviceOffsetInfo.title(isArabic)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: _buildRadio(timezoneState.isAuto, isDark),
                    onTap: () => _selectAuto(deviceOffset),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section 2: All UTC Timezones in single grouped Card
              _buildSectionHeader(
                l10n.translate('all_timezones'),
                isDark,
                isArabic,
              ),

              if (filteredOffsets.isEmpty)
                _buildCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 8),
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
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      for (int i = 0; i < filteredOffsets.length; i++) ...[
                        _buildOffsetTile(
                          context: context,
                          isDark: isDark,
                          isArabic: isArabic,
                          offsetInfo: filteredOffsets[i],
                          isSelected: !timezoneState.isAuto &&
                              timezoneState.offset == filteredOffsets[i].offset,
                          isDevice: filteredOffsets[i].offset == deviceOffset,
                          l10n: l10n,
                          onTap: () => _selectOffset(filteredOffsets[i].offset),
                        ),
                        if (i < filteredOffsets.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 32),
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

  Widget _buildCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }

  Widget _buildRadio(bool isSelected, bool isDark) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.lightCardElevated),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.35)
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
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Row(
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isDevice) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.translate('device_tag'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
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
        ),
      ),
      trailing: _buildRadio(isSelected, isDark),
      onTap: onTap,
    );
  }
}
