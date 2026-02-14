import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/services/supabase_service.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/models/admin_dashboard_stats.dart';

class AdminRepository {
  final SupabaseService _supabaseService;

  AdminRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ========== Dashboard Statistics ==========

  // Get Dashboard Stats
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final totalClientsResponse = await _client.from('profiles').count();

      final activeProjectsResponse = await _client
          .from('projects')
          .select()
          .eq('status', 'in_progress')
          .count();

      // Note: This is a simplified revenue calculation.
      // In a real app, you'd probably have a dedicated 'transactions' or 'payments' table to sum up.
      // For now, let's assume we fetch it from a hypothetical 'stats' view or calculate it.
      // returning dummy revenue for now as per schema limitations or implementing a sum query if table exists.
      const totalRevenue = 0.0;

      final pendingPaymentsResponse = await _client
          .from('installments')
          .select()
          .eq('status', 'pending')
          .count();

      return AdminDashboardStats(
        totalClients: totalClientsResponse,
        activeProjects: activeProjectsResponse.count,
        totalRevenue: totalRevenue,
        pendingPayments: pendingPaymentsResponse.count,
      );
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات لوحة التحكم: ${e.toString()}');
    }
  }

  // Get monthly revenue (for chart)
  Future<List<Map<String, dynamic>>> getMonthlyRevenue({int months = 6}) async {
    try {
      final result = await _client.rpc(
        'get_monthly_revenue',
        params: {'months_count': months},
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('خطأ في تحميل الإيرادات الشهرية: ${e.toString()}');
    }
  }

  // ========== Client Management ==========

  // Get clients with filters
  // Get clients with filters
  Future<List<UserModel>> getClients({
    String? kycStatus,
    String? role, // Added role parameter
    String? searchQuery,
    int limit = 200, // Increased from 50 to 200
  }) async {
    try {
      var query = _client.from('profiles').select();

      if (role != null) {
        query = query.eq('role', role);
      }

      if (kycStatus != null) {
        query = query.eq('kyc_status', kycStatus);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('فشل تحميل العملاء: ${e.toString()}');
    }
  }

  // Get clients stream
  Stream<List<UserModel>> getClientsStream({
    String? kycStatus,
    String? role,
    String? searchQuery,
    int limit = 200,
  }) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) {
          var filtered = data;

          if (role != null) {
            filtered = filtered.where((json) => json['role'] == role).toList();
          }

          if (kycStatus != null) {
            filtered = filtered
                .where((json) => json['kyc_status'] == kycStatus)
                .toList();
          }

          // Search filtering (basic)
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            filtered = filtered.where((json) {
              final name = (json['full_name'] as String?)?.toLowerCase() ?? '';
              final email = (json['email'] as String?)?.toLowerCase() ?? '';
              return name.contains(query) || email.contains(query);
            }).toList();
          }

          return filtered.map((json) => UserModel.fromJson(json)).toList();
        });
  }

  // Update User Role (Super Admin only)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _client.from('profiles').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      throw Exception('فشل تحديث صلاحية المستخدم: ${e.toString()}');
    }
  }

  // Delete Client (Safe Deletion)
  Future<void> deleteClient(String userId) async {
    try {
      // 1. Check for active/in_progress subscriptions
      final activeSubscriptionsCount = await _client
          .from('subscriptions')
          .count()
          .eq('user_id', userId)
          .inFilter('status', ['active', 'in_progress']); // Adjust status values as needed

      if (activeSubscriptionsCount > 0) {
        throw Exception('لا يمكن حذف العميل: لديه مشاريع نشطة. يجب انسحابه أو انتهاء مشاريعه أولاً.');
      }

      // 2. Delete client (Cascade should handle related data like profiles, documents if configured, 
      // but safely Supabase Auth user deletion requires Service Role or Edge Function usually.
      // Here we allow deleting the 'profile' row. If Auth user needs deletion, it's separate.)
      // Assuming deleting profile triggers cascade or we just delete profile for now.
      
      // Note: Deleting from 'users' table (Auth) via Client SDK is not possible with RLS usually.
      // We will delete the PROFILE. 
      // If we need to delete Auth User, we need an Edge Function.
      // For this app context, let's assume deleting profile is sufficient or triggers a trigger.
      
      await _client.from('profiles').delete().eq('id', userId);
      
    } catch (e) {
       // Check if it's our custom exception
       if (e.toString().contains('لا يمكن حذف العميل')) {
         rethrow;
       }
       throw Exception('فشل حذف العميل: ${e.toString()}');
    }
  }

  // Update Client Profile
  Future<void> updateClient({
    required String userId,
    String? fullName,
    String? phone,
    String? nationalId,
    String? avatarPath, // Local path to new avatar image
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (nationalId != null) updates['national_id'] = nationalId;

      // particular logic for avatar upload
      if (avatarPath != null) {
        final extension = avatarPath.split('.').last;
        final path = 'avatars/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        // Upload image
        await _client.storage.from('avatars').upload(
          path,
          File(avatarPath),
          fileOptions: const FileOptions(upsert: true),
        );

        // Get public URL
        final avatarUrl = _client.storage.from('avatars').getPublicUrl(path);
        updates['avatar_url'] = avatarUrl;
      }

      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', userId);
      }
    } catch (e) {
      throw Exception('فشل تحديث بيانات العميل: ${e.toString()}');
    }
  }

  // ========== Payments Management ==========

  Future<List<Map<String, dynamic>>> getTransactions({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('*, profiles!user_id(full_name, email), wallets(user_id)');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (type != null) {
        query = query.eq('type', type);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل تحميل المدفوعات: ${e.toString()}');
    }
  }

  // Approve KYC
  Future<UserModel> approveKYC(String userId) async {
    // Renamed to upper case KYC and return UserModel
    try {
      final response = await _client
          .from('profiles')
          .update({
            'kyc_status': 'approved',
            'kyc_reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      // Send notification to user
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': 'KYC Approval',
        'title_ar': 'تمت الموافقة على التحقق',
        'body': 'Your KYC documents have been approved',
        'body_ar': 'تم الموافقة على مستندات التحقق الخاصة بك',
        'type': 'kyc',
        'priority': 'high',
      });

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في الموافقة على التحقق: ${e.toString()}');
    }
  }

  // Reject KYC
  Future<UserModel> rejectKYC({
    required String userId,
    required String reason,
  }) async {
    // Renamed and named args
    try {
      final response = await _client
          .from('profiles')
          .update({
            'kyc_status': 'rejected',
            'kyc_reviewed_at': DateTime.now().toIso8601String(),
            'kyc_rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      // Send notification to user
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': 'KYC Rejection',
        'title_ar': 'تم رفض التحقق',
        'body': 'Your KYC documents have been rejected. Reason: $reason',
        'body_ar': 'تم رفض مستندات التحقق. السبب: $reason',
        'type': 'kyc',
        'priority': 'high',
      });

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في رفض التحقق: ${e.toString()}');
    }
  }

  // ========== Notifications ==========

  Future<void> sendNotification({
    required String title,
    required String titleAr,
    required String body,
    required String bodyAr,
    String? userId, // specific user (single)
    List<String>? userIds, // specific users (multiple)
    String? projectId, // all users in a project
    bool details = false, // false = simple message
    String priority = 'normal',
  }) async {
    try {
      final createdAt = DateTime.now().toIso8601String();

      // Common notification data
      final baseNotification = {
        'title': title,
        'title_ar': titleAr,
        'body': body,
        'body_ar': bodyAr,
        'type': 'info',
        'priority': priority,
        'created_at': createdAt,
        if (projectId != null) 'project_id': projectId,
      };

      if (userId != null) {
        // Send to specific user (single)
        await _client.from('notifications').insert({
          'user_id': userId,
          ...baseNotification,
        });
      } else if (userIds != null && userIds.isNotEmpty) {
        // Send to multiple users
        final notifications = userIds.map((id) => {
          'user_id': id,
          ...baseNotification,
        }).toList();
        
        await _client.from('notifications').insert(notifications);

      } else if (projectId != null) {
        // Send to all project users
        // For MVP, we'll try to get all users who have an active subscription/unit in this project
        // Since schema is not fully known for units->owner, we'll check subscriptions
        final subscriptions = await _client
            .from('subscriptions')
            .select('user_id')
            .eq('project_id', projectId)
            .filter('status', 'in', ['active', 'completed']); // Include completed subscriptions
        
        final projectUserIds = List<Map<String, dynamic>>.from(subscriptions)
            .map((s) => s['user_id'] as String)
            .toSet() // Unique
            .toList();

        if (projectUserIds.isEmpty) return;

        final notifications = projectUserIds.map((id) => {
          'user_id': id,
          ...baseNotification,
        }).toList();

        await _client.from('notifications').insert(notifications);

      } else {
        // Broadcast to ALL users
        // Warning: This is expensive in client-side loop. Should be Server function.
        // For now, allow it but limit to 500 recent active users or just throw if too risky.
        // Let's implement a batch insert for all profiles.
        
        final profiles = await _client.from('profiles').select('id');
        final allUserIds = List<Map<String, dynamic>>.from(profiles)
            .map((p) => p['id'] as String)
            .toList();
            
        if (allUserIds.isEmpty) return;

        // Batch insert in chunks of 50 to avoid request size limits
        const chunkSize = 50;
        for (var i = 0; i < allUserIds.length; i += chunkSize) {
          final chunk = allUserIds.skip(i).take(chunkSize);
          final notifications = chunk.map((id) => {
            'user_id': id,
            ...baseNotification,
          }).toList();
          
          await _client.from('notifications').insert(notifications);
        }
      }
    } catch (e) {
      throw Exception('خطأ في إرسال الإشعار: ${e.toString()}');
    }
  }

  // ========== Payment Management ==========

  // Get all payments with filters
  Future<List<Map<String, dynamic>>> getPayments({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('*, wallets(user_id), profiles!inner(full_name, email)');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (type != null) {
        query = query.eq('type', type);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطأ في تحميل المدفوعات: ${e.toString()}');
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final totalAmount = await _client.rpc('get_total_payments');

      final pendingPayments = await _client
          .from('transactions')
          .select()
          .eq('status', 'pending')
          .count();

      final completedPayments = await _client
          .from('transactions')
          .select()
          .eq('status', 'completed')
          .count();

      return {
        'total_amount': totalAmount ?? 0,
        'pending_count': pendingPayments.count,
        'completed_count': completedPayments.count,
      };
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات المدفوعات: ${e.toString()}');
    }
  }

  // ========== Activity Logs ==========

  // Log admin activity
  Future<void> logActivity({
    required String action,
    String? userId, // Optional, usually auth user
    String? entityType,
    String? entityId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // If userId is not provided, try to get current user
      final currentUserId = userId ?? _client.auth.currentUser?.id;

      if (currentUserId == null) {
        print('Skipping log activity: No user ID');
        return;
      }

      await _client.from('activity_logs').insert({
        'user_id': currentUserId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'description': description,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // Silently fail - logging shouldn't break the app
      print('Failed to log activity: $e');
    }
  }

  // Get activity logs
  Future<List<Map<String, dynamic>>> getActivityLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from('activity_logs')
          .select('*, profiles(full_name)');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (action != null) {
        query = query.eq('action', action);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطأ في تحميل سجل الأنشطة: ${e.toString()}');
    }
  }

  // ========== Reports ==========

  // Generate platform statistics
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      final stats = await getDashboardStats();

      // Additional stats
      final totalUnits = await _client.from('units').select().count();

      final soldUnits = await _client
          .from('units')
          .select()
          .eq('status', 'sold')
          .count();

      final totalSubscriptions = await _client
          .from('subscriptions')
          .select()
          .count();

      final activeSubscriptions = await _client
          .from('subscriptions')
          .select()
          .eq('status', 'active')
          .count();

      return {
        'total_clients': stats.totalClients,
        'active_projects': stats.activeProjects,
        'total_revenue': stats.totalRevenue,
        'pending_payments': stats.pendingPayments,
        'total_units': totalUnits.count,
        'sold_units': soldUnits.count,
        'total_subscriptions': totalSubscriptions.count,
        'active_subscriptions': activeSubscriptions.count,
      };
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات المنصة: ${e.toString()}');
    }
  }
}
