import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/repositories/notification_repository.dart';

// States
abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationsLoaded(this.notifications, this.unreadCount);

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationDetailLoaded extends NotificationsState {
  final NotificationModel notification;

  const NotificationDetailLoaded(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationMarkedAsRead extends NotificationsState {
  final String notificationId;

  const NotificationMarkedAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _notificationRepository;

  NotificationsCubit({NotificationRepository? notificationRepository})
      : _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        super(NotificationsInitial());

  Future<void> loadNotifications(String userId, {bool? isRead}) async {
    emit(NotificationsLoading());
    try {
      final notifications = await _notificationRepository.getNotifications(
        userId: userId,
        isRead: isRead,
      );
      final unreadCount =
          await _notificationRepository.getUnreadCount(userId);
      emit(NotificationsLoaded(notifications, unreadCount));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> refreshNotifications(String userId, {bool? isRead}) async {
    await loadNotifications(userId, isRead: isRead);
  }

  Future<void> loadNotificationDetail(String notificationId) async {
    emit(NotificationsLoading());
    try {
      final notification = await _notificationRepository.getNotificationById(notificationId);
      emit(NotificationDetailLoaded(notification));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      emit(NotificationMarkedAsRead(notificationId));
      await loadNotifications(userId);
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationRepository.markAllAsRead(userId);
      await loadNotifications(userId);
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      await loadNotifications(userId);
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  void subscribeToNotifications(String userId) {
    _notificationRepository.watchNotifications(userId).listen(
      (notifications) {
        // We can either emit loaded directly or just reload to get unread count too
        // For now, let's reload to keep it consistent
        loadNotifications(userId);
      },
      onError: (error) {
        // Silently fail or log, don't emit error to avoid blocking UI
        print('Notification stream error: $error');
      },
    );
  }

  void unsubscribeFromNotifications() {
    // Dispose subscription if needed
  }
}
