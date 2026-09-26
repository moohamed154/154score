import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = Localizations.localeOf(context).languageCode;
      context.read<NotificationsBloc>().add(LoadNotificationsEvent(lang: lang));
      // Auto-refresh every 3 minutes while screen is visible
      _refreshTimer = Timer.periodic(const Duration(minutes: 3), (_) {
        if (mounted) {
          final l = Localizations.localeOf(context).languageCode;
          context.read<NotificationsBloc>().add(
            LoadNotificationsEvent(lang: l, isRefresh: true),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.goal:
        return Icons.sports_soccer_rounded;
      case NotificationType.redCard:
        return Icons.style_rounded;
      case NotificationType.lineup:
        return Icons.groups_rounded;
      case NotificationType.matchStart:
      case NotificationType.matchHalftime:
      case NotificationType.matchEnd:
        return Icons.sports_rounded;
      case NotificationType.news:
        return Icons.newspaper_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.goal:
        return const Color(0xFF10B981);
      case NotificationType.redCard:
        return const Color(0xFFEF4444);
      case NotificationType.lineup:
        return const Color(0xFF3B82F6);
      case NotificationType.matchStart:
      case NotificationType.matchHalftime:
      case NotificationType.matchEnd:
        return const Color(0xFFF59E0B);
      case NotificationType.news:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      default:
        return AppColors.primary;
    }
  }

  void _onNotificationTap(BuildContext context, AppNotificationEntity item) {
    context.read<NotificationsBloc>().add(MarkNotificationReadEvent(item.id));

    if (item.category == 'news') {
      final articleId = item.data['article_id'] ?? item.id.replaceFirst('news_', '');
      context.push('/news/$articleId');
    } else if (item.category == 'match') {
      final matchId = item.data['match_id'] ?? item.matchId;
      if (matchId != null && matchId.toString().isNotEmpty) {
        context.push('/match/$matchId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('notifications_title'),
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ),
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state.notifications.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.done_all_rounded),
                tooltip: l10n.translate('mark_all_read'),
                onPressed: () {
                  context.read<NotificationsBloc>().add(
                    const MarkAllNotificationsReadEvent(),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.translate('settings_notifications'),
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading && state.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == NotificationsStatus.error && state.notifications.isEmpty) {
            return ErrorView(
              message: state.errorMessage ?? l10n.translate('error_service_unavailable'),
              onRetry: () {
                final lang = Localizations.localeOf(context).languageCode;
                context.read<NotificationsBloc>().add(
                  LoadNotificationsEvent(lang: lang, isRefresh: true),
                );
              },
            );
          }

          if (state.status == NotificationsStatus.empty || state.notifications.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_off_outlined,
              titleKey: 'no_notifications',
              subtitleKey: 'no_notifications_desc',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final lang = Localizations.localeOf(context).languageCode;
              context.read<NotificationsBloc>().add(
                LoadNotificationsEvent(lang: lang, isRefresh: true),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = state.notifications[index];
                final typeColor = _getColorForType(item.type, isDark);
                final typeIcon = _getIconForType(item.type);

                return Material(
                  color: isDark
                      ? (item.isRead ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F).withValues(alpha: 0.4))
                      : (item.isRead ? Colors.white : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _onNotificationTap(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(typeIcon, color: typeColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: AppTypography.getBodyLarge(
                                          isDark: isDark,
                                          isArabic: isArabic,
                                        ).copyWith(
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 6, right: 6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: AppTypography.getBodyMedium(
                                    isDark: isDark,
                                    isArabic: isArabic,
                                  ).copyWith(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

extension NotificationEntityExt on AppNotificationEntity {
  String? get matchId => data['match_id']?.toString();
}
