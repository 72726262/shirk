import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class NotificationRepository {
  final SupabaseService _supabaseService;

  NotificationRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ========== FUTURE-BASED METHODS (Original) ==========

  Future<List<NotificationModel>> getNotifications({
    required String userId,
    bool? isRead,
    NotificationType? type,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (type != null) {
        query = query.eq('type', type.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل الإشعارات: ${e.toString()}');
    }
  }

  Future<NotificationModel> getNotificationById(String notificationId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل الإشعار: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('خطأ في تحديث الإشعار: ${e.toString()}');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('خطأ في تحديث الإشعارات: ${e.toString()}');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('خطأ في حذف الإشعار: ${e.toString()}');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();

      return response.count;
    } catch (e) {
      throw Exception('خطأ في تحميل عدد الإشعارات: ${e.toString()}');
    }
  }

  @Deprecated('Use getNotificationsStream() instead')
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((json) => NotificationModel.fromJson(json)).toList();
        });
  }

  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String body,
    String? titleAr,
    String? bodyAr,
    NotificationType type = NotificationType.general,
    String? projectId,
    String? subscriptionId,
    String? documentId,
    String? actionUrl,
    String? actionLabel,
    String? priority = 'normal',
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'title': title,
        'body': body,
        'title_ar': titleAr ?? title,
        'body_ar': bodyAr ?? body,
        'type': type.name,
        'project_id': projectId,
        'subscription_id': subscriptionId,
        'document_id': documentId,
        'action_url': actionUrl,
        'action_label': actionLabel,
        'priority': priority,
        'is_read': false,
      };

      final response = await _client
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إنشاء الإشعار: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getNotificationsByType(String userId) async {
    try {
      final notifications = await getNotifications(userId: userId);

      final counts = <String, int>{};
      for (var notification in notifications) {
        final type = notification.type.name;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات الإشعارات: ${e.toString()}');
    }
  }

  // ========== STREAM-BASED METHODS (Real-time) ==========

  /// Get notifications with real-time updates
  Stream<List<NotificationModel>> getNotificationsStream({
    required String userId,
    bool? isRead,
    NotificationType? type,
    int limit = 50,
  }) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      var filtered = data.where((n) => n['user_id'] == userId).toList();

      if (isRead != null) {
        filtered = filtered.where((n) => n['is_read'] == isRead).toList();
      }

      if (type != null) {
        filtered = filtered.where((n) => n['type'] == type.name).toList();
      }

      final limited = filtered.length > limit ? filtered.take(limit).toList() : filtered;
      return limited.map((json) => NotificationModel.fromJson(json)).toList();
    });
  }

  /// Get notification by ID with real-time updates
  Stream<NotificationModel> getNotificationByIdStream(String notificationId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) {
      final notification = data.firstWhere(
        (n) => n['id'] == notificationId,
        orElse: () => throw Exception('الإشعار غير موجود'),
      );
      return NotificationModel.fromJson(notification);
    });
  }

  /// Get unread count with real-time updates
  Stream<int> getUnreadCountStream(String userId) {
    return getNotificationsStream(userId: userId, isRead: false)
        .map((notifications) => notifications.length);
  }

  /// Get notifications by type with real-time updates
  Stream<Map<String, int>> getNotificationsByTypeStream(String userId) {
    return getNotificationsStream(userId: userId).map((notifications) {
      final counts = <String, int>{};
      for (var notification in notifications) {
        final type = notification.type.name;
        counts[type] = (counts[type] ?? 0) + 1;
      }
      return counts;
    });
  }
}
