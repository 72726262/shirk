// lib/data/repositories/user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // الحصول على دور المستخدم الحالي
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

  // التحقق من الصلاحيات
  Future<bool> hasPermission(String requiredRole) async {
    try {
      final userRole = await getCurrentUserRole();

      // ترتيب الصلاحيات
      const roleHierarchy = ['client', 'admin', 'super_admin'];

      final userIndex = roleHierarchy.indexOf(userRole);
      final requiredIndex = roleHierarchy.indexOf(requiredRole);

      return userIndex >= requiredIndex;
    } catch (e) {
      return false;
    }
  }

  // الحصول على بيانات المستخدم الحالي
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

  // الحصول على جميع المستخدمين (للمسؤولين فقط)
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

  // تحديث دور المستخدم (للمسؤولين فقط)
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

      // تسجيل النشاط
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

  // تسجيل النشاط
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
}
