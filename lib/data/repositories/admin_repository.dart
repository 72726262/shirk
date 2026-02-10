import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/services/supabase_service.dart';
import 'package:mmm/data/models/user_model.dart';

class AdminRepository {
  final SupabaseService _supabaseService;
  
  AdminRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ========== Dashboard Statistics ==========
  
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Total clients
      final totalClients = await _client
          .from('profiles')
          .select()
          .eq('role', 'client')
          .count();

      // KYC pending
      final kycPending = await _client
          .from('profiles')
          .select()
          .eq('kyc_status', 'pending')
          .count();

      // Total projects
      final totalProjects = await _client
          .from('projects')
          .select()
          .count();

      // Active projects
      final activeProjects = await _client
          .from('projects')
          .select()
          .eq('status', 'in_progress')
          .count();

      // Total revenue (sum of all completed transactions)
      final revenueResult = await _client
          .rpc('get_total_revenue');

      // Recent transactions
      final recentTransactions = await _client
          .from('transactions')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(10);

      return {
        'total_clients': totalClients.count,
        'kyc_pending': kycPending.count,
        'total_projects': totalProjects.count,
        'active_projects': activeProjects.count,
        'total_revenue': revenueResult ?? 0,
        'recent_transactions': recentTransactions,
      };
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات اللوحة: ${e.toString()}');
    }
  }

  // Get monthly revenue (for chart)
  Future<List<Map<String, dynamic>>> getMonthlyRevenue({int months = 6}) async {
    try {
      final result = await _client
          .rpc('get_monthly_revenue', params: {'months_count': months});

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
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('profiles')
          .select();

      if (role != null) {
        query = query.eq('role', role);
      }

      if (kycStatus != null) {
        query = query.eq('kyc_status', kycStatus);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false).limit(limit);
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('خطأ في تحميل العملاء: ${e.toString()}');
    }
  }

  // Approve KYC
  Future<UserModel> approveKYC(String userId) async { // Renamed to upper case KYC and return UserModel
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
  Future<UserModel> rejectKYC({required String userId, required String reason}) async { // Renamed and named args
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

      final response = await query.order('created_at', ascending: false).limit(limit);
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

      final response = await query.order('created_at', ascending: false).limit(limit);
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
      final totalUnits = await _client
          .from('units')
          .select()
          .count();

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
        ...stats,
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
