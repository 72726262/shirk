import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class AuthRepository {
  final SupabaseService _supabaseService;

  AuthRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ==================== AUTHENTICATION ====================

  // Sign in with email and password
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      // Get user profile
      final profile = await _getUserProfile(response.user!.id);
      return profile;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول: ${e.toString()}');
    }
  }

  // Sign up with email, password and full name
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('فشل إنشاء الحساب');
      }

      // Create profile
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': 'client',
        'kyc_status': 'pending',
      });

      // Create wallet for user
      await _client.from('wallets').insert({
        'user_id': response.user!.id,
        'balance': 0.0,
        'reserved_balance': 0.0,
      });

      final profile = await _getUserProfile(response.user!.id);
      return profile;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('خطأ في إنشاء الحساب: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('خطأ في تسجيل الخروج: ${e.toString()}');
    }
  }

  // ==================== USER MANAGEMENT ====================

  // Get current user - الدالة المطلوبة لـ ProfileCubit
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      return await _getUserProfile(user.id);
    } catch (e) {
      return null;
    }
  }

  // Update profile - الدالة المطلوبة لـ ProfileCubit
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarPath != null) updates['avatar_url'] = avatarPath;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('profiles').update(updates).eq('id', userId);

      return await _getUserProfile(userId);
    } catch (e) {
      throw Exception('خطأ في تحديث الملف الشخصي: ${e.toString()}');
    }
  }

  // Change password - الدالة الجديدة المطلوبة لـ ProfileCubit
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First, verify current password by signing in
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('المستخدم غير موجود');
      }

      // Sign in with current password to verify
      await signIn(currentUser.email, currentPassword);

      // Update password
      await _client.auth.updateUser(UserAttributes(password: newPassword));

      // Re-authenticate with new password
      await signIn(currentUser.email, newPassword);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('خطأ في تغيير كلمة المرور: ${e.toString()}');
    }
  }

  // Get user profile from database
  Future<UserModel> _getUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  // ==================== PASSWORD MANAGEMENT ====================

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('خطأ في إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  // ==================== AVATAR MANAGEMENT ====================

  // Upload avatar
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final file = await _supabaseService.uploadFile(
        bucketName: 'avatars',
        path:
            'users/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        filePath: filePath,
      );

      return file;
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: ${e.toString()}');
    }
  }

  // ==================== KYC MANAGEMENT ====================

  // Submit KYC documents
  Future<void> submitKyc({
    required String userId,
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
    String? incomeProofPath,
  }) async {
    try {
      // Upload documents
      final idFrontUrl = await _supabaseService.uploadFile(
        bucketName: 'kyc_documents',
        path: 'users/$userId/id_front.jpg',
        filePath: idFrontPath,
      );

      final idBackUrl = await _supabaseService.uploadFile(
        bucketName: 'kyc_documents',
        path: 'users/$userId/id_back.jpg',
        filePath: idBackPath,
      );

      final selfieUrl = await _supabaseService.uploadFile(
        bucketName: 'kyc_documents',
        path: 'users/$userId/selfie.jpg',
        filePath: selfiePath,
      );

      String? incomeProofUrl;
      if (incomeProofPath != null) {
        incomeProofUrl = await _supabaseService.uploadFile(
          bucketName: 'kyc_documents',
          path: 'users/$userId/income_proof.pdf',
          filePath: incomeProofPath,
        );
      }

      // Update profile with KYC documents
      await _client
          .from('profiles')
          .update({
            'id_front_url': idFrontUrl,
            'id_back_url': idBackUrl,
            'selfie_url': selfieUrl,
            'income_proof_url': incomeProofUrl,
            'kyc_status': 'under_review',
            'kyc_submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('خطأ في رفع مستندات التحقق: ${e.toString()}');
    }
  }

  // Check KYC status
  Future<String> getKycStatus(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('kyc_status')
          .eq('id', userId)
          .single();

      return response['kyc_status'] as String;
    } catch (e) {
      throw Exception('خطأ في قراءة حالة التحقق: ${e.toString()}');
    }
  }

  // ==================== UTILITIES ====================

  // Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // Handle auth exceptions
  String _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case '422':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case '500':
        return 'خطأ في الخادم، يرجى المحاولة لاحقاً';
      default:
        return e.message;
    }
  }

  // Auth state stream
  Stream<AppAuthState> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      return data.event == AuthChangeEvent.signedIn
          ? AppAuthState.authenticated
          : AppAuthState.unauthenticated;
    });
  }

  // Get user by ID (for admin purposes)
  Future<UserModel> getUserById(String userId) async {
    try {
      return await _getUserProfile(userId);
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المستخدم: ${e.toString()}');
    }
  }

  // Get all users (for admin purposes)
  Future<List<UserModel>> getAllUsers({String? role}) async {
    try {
      var query = _client.from('profiles').select('*');

      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query;

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب قائمة المستخدمين: ${e.toString()}');
    }
  }

  // Update user role (for admin purposes)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _client
          .from('profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('خطأ في تحديث صلاحية المستخدم: ${e.toString()}');
    }
  }
}

enum AppAuthState { authenticated, unauthenticated }
