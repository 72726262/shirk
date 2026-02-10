import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/auth_repository.dart';
import 'package:mmm/data/services/supabase_service.dart';

/// Auth Service - Handles authentication business logic
class AuthService {
  final AuthRepository _authRepository;
  final SupabaseService _supabaseService;

  AuthService({
    AuthRepository? authRepository,
    SupabaseService? supabaseService,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _supabaseService = supabaseService ?? SupabaseService();

  // Get current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      if (!_supabaseService.isAuthenticated) {
        return null;
      }
      return await _authRepository.getCurrentUser();
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  // Sign in
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _authRepository.signIn(email, password);
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: ${e.toString()}');
    }
  }

  // Sign up
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      return await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    } catch (e) {
      throw Exception('فشل التسجيل: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      throw Exception('فشل تسجيل الخروج: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
    } catch (e) {
      throw Exception('فشل إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  // Update profile with avatar upload
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      String? avatarUrl;

      // Upload avatar if provided
      if (avatarPath != null) {
        avatarUrl = await _authRepository.uploadAvatar(userId, avatarPath);
      }

      return await _authRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        avatarPath: avatarUrl,
      );
    } catch (e) {
      throw Exception('فشل تحديث الملف الشخصي: ${e.toString()}');
    }
  }

  // Submit KYC with document uploads
  Future<void> submitKYC({
    required String userId,
    required String nationalId,
    required DateTime dateOfBirth,
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
    String? incomeProofPath,
  }) async {
    try {
      await _authRepository.submitKyc(
        userId: userId,
        idFrontPath: idFrontPath,
        idBackPath: idBackPath,
        selfiePath: selfiePath,
        incomeProofPath: incomeProofPath,
      );
    } catch (e) {
      throw Exception('فشل إرسال طلب التحقق: ${e.toString()}');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  // Get current user ID
  String? get currentUserId => _supabaseService.currentUserId;

  // Auth state stream
  Stream<AppAuthState> get authStateChanges => _authRepository.authStateChanges;
}
