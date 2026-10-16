import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  final String lang;
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadNotificationsEvent(
      {this.lang = 'ar', this.isRefresh = false, this.completer});

  @override
  List<Object?> get props => [lang, isRefresh];
}

class MarkNotificationReadEvent extends NotificationsEvent {
  final String id;

  const MarkNotificationReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsReadEvent extends NotificationsEvent {
  const MarkAllNotificationsReadEvent();
}

// State
enum NotificationsStatus { initial, loading, success, empty, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<AppNotificationEntity> notifications;
  final String? errorMessage;
  final String lang;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.errorMessage,
    this.lang = 'ar',
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotificationEntity>? notifications,
    String? errorMessage,
    String? lang,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
      lang: lang ?? this.lang,
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage, lang];
}

// Bloc
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc({required this.repository})
      : super(const NotificationsState()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!event.isRefresh && state.status != NotificationsStatus.success) {
      emit(state.copyWith(
          status: NotificationsStatus.loading, lang: event.lang));
    }

    final result = await repository.getNotifications(lang: event.lang);

    result.fold(
      onSuccess: (items) {
        if (items.isEmpty) {
          emit(state.copyWith(
            status: NotificationsStatus.empty,
            notifications: const [],
            lang: event.lang,
          ));
        } else {
          emit(state.copyWith(
            status: NotificationsStatus.success,
            notifications: items,
            lang: event.lang,
          ));
        }
        event.completer?.complete();
      },
      onFailure: (failure) {
        emit(state.copyWith(
          status: state.notifications.isNotEmpty
              ? NotificationsStatus.success
              : NotificationsStatus.error,
          errorMessage: failure.message,
          lang: event.lang,
        ));
        event.completer?.complete();
      },
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    await repository.markAsRead(event.id);
    final updated = state.notifications.map((n) {
      if (n.id == event.id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final ids = state.notifications.map((n) => n.id).toList();
    await repository.markAllAsRead(ids);
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
  }
}
