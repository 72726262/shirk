import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/repositories/notification_repository.dart';

/// Notification Service - Handles notification business logic
class NotificationService {
  final NotificationRepository _notificationRepository;

  NotificationService({NotificationRepository? notificationRepository})
      : _notificationRepository =
            notificationRepository ?? NotificationRepository();

  // Get all notifications with optional filter
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    bool? isRead,
    String? type,
  }) async {
    try {
      NotificationType? notificationType;
      if (type != null) {
        try {
          notificationType = NotificationType.values.firstWhere((e) => e.name == type);
        } catch (_) {
          // invalid type string, ignore filter
        }
      }

      return await _notificationRepository.getNotifications(
        userId: userId,
        isRead: isRead,
        type: notificationType,
      );
    } catch (e) {
      throw Exception('فشل تحميل الإشعارات: ${e.toString()}');
    }
  }

  // Get unread notifications only
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      return await _notificationRepository.getNotifications(
        userId: userId,
        isRead: false,
      );
    } catch (e) {
      throw Exception('فشل تحميل الإشعارات غير المقروءة: ${e.toString()}');
    }
  }

  // Get unread count (for badge)
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _notificationRepository.getUnreadCount(userId);
    } catch (e) {
      throw Exception('فشل تحميل عدد الإشعارات: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
    } catch (e) {
      throw Exception('فشل تحديث الإشعار: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationRepository.markAllAsRead(userId);
    } catch (e) {
      throw Exception('فشل تحديث الإشعارات: ${e.toString()}');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      throw Exception('فشل حذف الإشعار: ${e.toString()}');
    }
  }

  // Real-time notification stream
  Stream<NotificationModel> watchNotifications(String userId) {
    try {
      return _notificationRepository.watchNotifications(userId);
    } catch (e) {
      throw Exception('فشل الاشتراك في الإشعارات: ${e.toString()}');
    }
  }

  // Get notification statistics by type
  Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    try {
      return await _notificationRepository.getNotificationsByType(userId);
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات الإشعارات: ${e.toString()}');
    }
  }

  // Admin: Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? titleAr,
    String? bodyAr,
    String? type,
    String? actionUrl,
    String? projectId,
  }) async {
    try {
      NotificationType? notificationType;
      if (type != null) {
        try {
          notificationType = NotificationType.values.firstWhere((e) => e.name == type);
        } catch (_) {
          notificationType = NotificationType.info;
        }
      }

      await _notificationRepository.createNotification(
        userId: userId,
        title: title,
        titleAr: titleAr ?? title,
        body: body,
        bodyAr: bodyAr ?? body,
        type: notificationType ?? NotificationType.info,
        actionUrl: actionUrl,
        projectId: projectId,
      );
    } catch (e) {
      throw Exception('فشل إرسال الإشعار: ${e.toString()}');
    }
  }
}
