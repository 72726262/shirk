import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/admin_dashboard_stats.dart';

/// Extension methods for AdminRepository to add real-time stream support
/// 
/// Add these methods to your existing AdminRepository class at the end, before the closing brace
/// 
/// USAGE IN CUBIT:
/// Instead of: await _repository.getDashboardStats()
/// Use: _repository.getDashboardStatsStream().listen((stats) { ... })

extension AdminRepositoryStreams on SupabaseClient {
  
  // ========== REAL-TIME STREAMS ==========

  /// Stream for dashboard statistics with real-time updates
  /// Listens to profiles, projects, and installments tables
  Stream<AdminDashboardStats> getDashboardStatsStream(SupabaseClient client) async* {
    try {
      // Listen to profiles table for client count changes
      final profilesStream = client
          .from('profiles')
          .stream(primaryKey: ['id']);

      // Listen to projects table for active projects changes  
      final projectsStream = client
          .from('projects')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((p) => p['status'] == 'in_progress').length);

      // Listen to installments table for pending payments
      final installmentsStream = client
          .from('installments')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((i) => i['status'] == 'pending').length);

      // Combine all streams and emit stats
      await for (final profiles in profilesStream) {
        final activeProjects = await projectsStream.first;
        final pendingPayments = await installmentsStream.first;

        yield AdminDashboardStats(
          totalClients: profiles.length,
          activeProjects: activeProjects,
          totalRevenue: 0.0, // TODO: Calculate from transactions table
          pendingPayments: pendingPayments,
        );
      }
    } catch (e) {
      throw Exception('خطأ في البث المباشر لإحصائيات لوحة التحكم: ${e.toString()}');
    }
  }

  /// Stream for transactions with real-time updates and filtering
  Stream<List<Map<String, dynamic>>> getTransactionsStream(
    SupabaseClient client, {
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    return client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      var filtered = data;

      // Apply filters
      if (status != null) {
        filtered = filtered.where((t) => t['status'] == status).toList();
      }
      if (type != null) {
        filtered = filtered.where((t) => t['type'] == type).toList();
      }
      if (startDate != null) {
        filtered = filtered.where((t) {
          final createdAt = DateTime.parse(t['created_at']);
          return createdAt.isAfter(startDate) || createdAt.isAtSameMomentAs(startDate);
        }).toList();
      }
      if (endDate != null) {
        filtered = filtered.where((t) {
          final createdAt = DateTime.parse(t['created_at']);
          return createdAt.isBefore(endDate) || createdAt.isAtSameMomentAs(endDate);
        }).toList();
      }

      // Apply limit
      return filtered.length > limit ? filtered.take(limit).toList() : filtered;
    });
  }

  /// Stream for payments with real-time updates
  /// (Payments are stored in transactions table)
  Stream<List<Map<String, dynamic>>> getPaymentsStream(
    SupabaseClient client, {
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    return getTransactionsStream(
      client,
      status: status,
      type: type,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Stream for activity logs with real-time updates and filtering
  Stream<List<Map<String, dynamic>>> getActivityLogsStream(
    SupabaseClient client, {
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    return client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      var filtered = data;

      // Apply filters
      if (userId != null) {
        filtered = filtered.where((log) => log['user_id'] == userId).toList();
      }
      if (action != null) {
        filtered = filtered.where((log) => log['action'] == action).toList();
      }
      if (startDate != null) {
        filtered = filtered.where((log) {
          final createdAt = DateTime.parse(log['created_at']);
          return createdAt.isAfter(startDate) || createdAt.isAtSameMomentAs(startDate);
        }).toList();
      }
      if (endDate != null) {
        filtered = filtered.where((log) {
          final createdAt = DateTime.parse(log['created_at']);
          return createdAt.isBefore(endDate) || createdAt.isAtSameMomentAs(endDate);
        }).toList();
      }

      // Apply limit
      return filtered.length > limit ? filtered.take(limit).toList() : filtered;
    });
  }
}

/// COPY THESE METHODS TO AdminRepository CLASS:
/// 
/// Add the following methods directly to the AdminRepository class
/// (Remove the "SupabaseClient client" parameter and use _client instead)
///
/// // ========== REAL-TIME STREAMS ==========
///
/// Stream<AdminDashboardStats> getDashboardStatsStream() async* {
///   // Copy implementation from getDashboardStatsStream above
///   // Replace "client" with "_client"
/// }
///
/// Stream<List<Map<String, dynamic>>> getTransactionsStream({...}) {
///   // Copy implementation from getTransactionsStream above
///   // Replace "client" with "_client"
/// }
///
/// Stream<List<Map<String, dynamic>>> getPaymentsStream({...}) {
///   // Copy implementation from getPaymentsStream above
///   // Replace "client" with "_client"
/// }
///
/// Stream<List<Map<String, dynamic>>> getActivityLogsStream({...}) {
///   // Copy implementation from getActivityLogsStream above
///   // Replace "client" with "_client"
/// }
