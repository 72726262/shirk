// lib/presentation/cubits/auth/auth_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.authRepository}) : super(AuthInitial());

  final AuthRepository authRepository;

  Future<void> initialize() async {
    await _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      emit(AuthLoading());
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        // Use the actual role from the user object
        emit(Authenticated(user: user, role: user.role));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'فشل تحميل حالة المستخدم'));
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      emit(AuthLoading());
      final user = await authRepository.signIn(email, password);
      // Use the actual role from the user object
      emit(Authenticated(user: user, role: user.role));
    } catch (e) {
      emit(AuthError(message: 'فشل تسجيل الدخول: ${e.toString()}'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'client',
  }) async {
    try {
      emit(AuthLoading());
      final user = await authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      // Use the actual role from the user object
      emit(Authenticated(user: user, role: user.role));
    } catch (e) {
      emit(AuthError(message: 'فشل إنشاء الحساب: ${e.toString()}'));
    }
  }

  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'فشل تسجيل الخروج'));
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      if (state is! Authenticated) return;

      final currentUser = (state as Authenticated).user;
      emit(AuthLoading());

      final updatedUser = await authRepository.updateProfile(
        userId: currentUser.id,
        fullName: fullName,
        phone: phone,
        avatarPath: avatarPath,
      );

      emit(
        Authenticated(user: updatedUser, role: (state as Authenticated).role),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> verifyPhone(String code) async {
    try {
      emit(AuthLoading());
      await authRepository.verifyPhone(code);
      emit(PhoneVerified());
    } catch (e) {
      emit(AuthError(message: 'فشل التحقق من رقم الهاتف'));
    }
  }

  // Refresh user data from database
  Future<void> refreshUser() async {
    try {
      if (state is! Authenticated) return;

      final currentUser = (state as Authenticated).user;
      final user = await authRepository.getUserProfile(currentUser.id);
      
      if (user != null) {
        emit(Authenticated(user: user, role: user.role));
      }
    } catch (e) {
      // Don't emit error, just keep current state
      print('Failed to refresh user: $e');
    }
  }

  Future<void> resendPhoneVerificationCode() async {
    try {
      emit(AuthLoading());
      await authRepository.resendPhoneVerificationCode();
      emit(CodeResent());
    } catch (e) {
      emit(AuthError(message: 'فشل إعادة إرسال الرمز'));
    }
  }
}
