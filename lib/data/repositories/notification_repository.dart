import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class NotificationRepository {
  final SupabaseService _supabaseService;

  NotificationRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // Get user notifications
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

  // Get notification by ID
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

  // Mark notification as read
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

  // Mark all as read
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

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('خطأ في حذف الإشعار: ${e.toString()}');
    }
  }

  // Get unread count
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

  // Subscribe to real-time notifications
  Stream<NotificationModel> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('No notifications');
          }
          return NotificationModel.fromJson(data.first);
        });
  }

  // Create notification (Admin/System)
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

  // Get notifications by type count
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
}
