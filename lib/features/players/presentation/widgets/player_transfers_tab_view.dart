import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../domain/entities/player_profile_entity.dart';

class PlayerTransfersTabView extends StatelessWidget {
  final List<PlayerTransferEntity> transfers;
  final bool isDark;
  final bool isArabic;

  const PlayerTransfersTabView({
    super.key,
    required this.transfers,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return EmptyView(
        titleKey: isArabic ? 'لا توجد انتقالات' : 'No Transfers',
        customMessage: isArabic
            ? 'لا تتوفر سجلات انتقالات سابقة لهذا اللاعب'
            : 'No transfer history records available for this player',
        icon: Icons.swap_horiz_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: transfers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tr = transfers[index];
        return _buildTransferCard(context, tr);
      },
    );
  }

  Widget _buildTransferCard(BuildContext context, PlayerTransferEntity tr) {
    final team = tr.team;
    final isActive = tr.active;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: team != null && team.id.isNotEmpty
            ? () {
                context.push(
                  '/team/${team.id}?slug=${Uri.encodeComponent(team.name)}',
                );
              }
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Destination Team Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCardElevated),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: team?.logo != null
                    ? Center(
                        child: AppImage(
                          imageUrl: team!.logo,
                          width: 32,
                          height: 32,
                          placeholderIcon: Icons.shield_rounded,
                        ),
                      )
                    : const Icon(
                        Icons.shield_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
              ),

              const SizedBox(width: 12),

              // Team Name & Date Range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            team?.name.isNotEmpty == true
                                ? team!.name
                                : (isArabic ? 'نادي غير محدد' : 'Unknown Club'),
                            style: AppTypography.getBodyMedium(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isArabic ? 'النادي الحالي' : 'Current Club',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateRange(tr),
                      style:
                          AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Type & Fee Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (tr.type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getTransferTypeColor(tr.type)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getTransferTypeColor(tr.type)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tr.type,
                        style: TextStyle(
                          color: _getTransferTypeColor(tr.type),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (tr.fee.isNotEmpty && tr.fee != tr.type)
                    Text(
                      tr.fee,
                      style:
                          AppTypography.getBodySmall(
                            isDark: isDark,
                            isArabic: isArabic,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(PlayerTransferEntity tr) {
    if (tr.dateFrom != null && tr.dateTo != null) {
      return '${tr.dateFrom} ➔ ${tr.dateTo}';
    }
    if (tr.dateFrom != null) {
      return '${tr.dateFrom}';
    }
    if (tr.season.isNotEmpty) {
      return isArabic ? 'موسم ${tr.season}' : 'Season ${tr.season}';
    }
    return '';
  }

  Color _getTransferTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('حر') || t.contains('free')) return Colors.teal;
    if (t.contains('إعارة') || t.contains('loan')) return Colors.orange;
    if (t.contains('نهاية') || t.contains('end')) return Colors.blueGrey;
    return AppColors.primary;
  }
}
