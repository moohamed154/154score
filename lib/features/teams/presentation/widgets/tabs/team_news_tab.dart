import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/storage/local_storage_service.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../settings/presentation/cubit/settings_cubits.dart';
import '../../bloc/team_state.dart';

class TeamNewsTab extends StatelessWidget {
  final TeamState state;
  final bool isDark;
  final bool isArabic;

  const TeamNewsTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final news = state.profile?.news ?? [];

    if (news.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد أخبار منشورة لهذا الفريق حالياً'
            : 'No news published for this team at the moment',
        icon: Icons.newspaper_rounded,
      );
    }

    final hMargin = AppDimensions.getHorizontalMargin(context);
    final timeFormat = sl<LocalStorageService>().getTimeFormat();

    return BlocBuilder<FontSizeCubit, FontSizeState>(
      builder: (context, fontState) {
        final mq = MediaQuery.of(context);
        final newsScaler = fontState.isAuto
            ? mq.textScaler
            : TextScaler.linear(fontState.newsFontSizeScale);

        return MediaQuery(
          data: mq.copyWith(textScaler: newsScaler),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 12),
            itemCount: news.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = news[index];

              return InkWell(
                onTap: () {
                  if (item.id.isNotEmpty) {
                    context.push('/news/${item.id}', extra: {'slug': item.slug});
                  }
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      if (item.image != null && item.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppImage(
                            imageUrl: item.image,
                            width: 90,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.image_outlined,
                          ),
                        )
                      else
                        Container(
                          width: 90,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.newspaper_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      const SizedBox(width: 12),

                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (item.description != null &&
                                item.description!.isNotEmpty) ...[
                              Text(
                                item.description!,
                                style: AppTypography.getBodySmall(
                                  isDark: isDark,
                                  isArabic: isArabic,
                                ).copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (item.createdAt != null &&
                                item.createdAt!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormatter.formatDateTime(
                                      item.createdAt,
                                      isArabic: isArabic,
                                      timeFormat: timeFormat,
                                    ),
                                    style: AppTypography.getBodySmall(
                                      isDark: isDark,
                                      isArabic: isArabic,
                                    ).copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
