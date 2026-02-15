// lib/data/repositories/user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ========== FUTURE-BASED METHODS (Original) ==========

  Future<String> getCurrentUserRole() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      return response['role'] as String;
    } catch (e) {
      throw Exception('فشل الحصول على دور المستخدم: ${e.toString()}');
    }
  }

  Future<bool> hasPermission(String requiredRole) async {
    try {
      final userRole = await getCurrentUserRole();

      const roleHierarchy = ['client', 'admin', 'super_admin'];

      final userIndex = roleHierarchy.indexOf(userRole);
      final requiredIndex = roleHierarchy.indexOf(requiredRole);

      return userIndex >= requiredIndex;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('فشل الحصول على بيانات المستخدم: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (!await hasPermission('admin')) {
        throw Exception('غير مصرح لك بالوصول');
      }

      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل الحصول على المستخدمين: ${e.toString()}');
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      if (!await hasPermission('admin')) {
        throw Exception('غير مصرح لك بتغيير الأدوار');
      }

      await _client
          .from('profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _logActivity(
        userId: _client.auth.currentUser!.id,
        action: 'UPDATE_USER_ROLE',
        description: 'تم تحديث دور المستخدم $userId إلى $newRole',
        metadata: {'target_user_id': userId, 'new_role': newRole},
      );
    } catch (e) {
      throw Exception('فشل تحديث دور المستخدم: ${e.toString()}');
    }
  }

  Future<void> _logActivity({
    required String userId,
    required String action,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('activity_logs').insert({
        'user_id': userId,
        'action': action,
        'description': description,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ خطأ في تسجيل النشاط: $e');
    }
  }

  // ========== STREAM-BASED METHODS (Real-time) ==========

  /// Get current user data with real-time updates
  Stream<Map<String, dynamic>> getCurrentUserDataStream() {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('لم يتم تسجيل الدخول');
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((data) {
      final profile = data.firstWhere(
        (p) => p['id'] == currentUser.id,
        orElse: () => throw Exception('المستخدم غير موجود'),
      );
      return Map<String, dynamic>.from(profile);
    });
  }

  /// Get all users with real-time updates (Admin only)
  Stream<List<Map<String, dynamic>>> getAllUsersStream() async* {
    if (!await hasPermission('admin')) {
      throw Exception('غير مصرح لك بالوصول');
    }

    yield* _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      return data.map((profile) => Map<String, dynamic>.from(profile)).toList();
    });
  }

  /// Get user by ID with real-time updates
  Stream<Map<String, dynamic>> getUserByIdStream(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((data) {
      final profile = data.firstWhere(
        (p) => p['id'] == userId,
        orElse: () => throw Exception('المستخدم غير موجود'),
      );
      return Map<String, dynamic>.from(profile);
    });
  }

  /// Get current user role with real-time updates
  Stream<String> getCurrentUserRoleStream() {
    return getCurrentUserDataStream().map((data) => data['role'] as String);
  }
}
