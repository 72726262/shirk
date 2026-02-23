// lib/presentation/cubits/auth/auth_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/enums/user_role.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  // Persistence for rate limiting
  DateTime? _rateLimitExpiry;
  DateTime? get rateLimitExpiry => _rateLimitExpiry;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  final AuthRepository authRepository;

  Future<void> initialize() async {
    await _checkInitialAuth();
    
    // Listen for password recovery event
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        emit(AuthPasswordRecovery());
      }
    });
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
      final message = e.toString();
      if (message.contains('Email not confirmed') || message.contains('البريد الإلكتروني غير مؤكد')) {
        emit(AuthEmailNotConfirmed(email: email));
      } else {
        print(e.toString());
        emit(AuthError(message: 'فشل تسجيل الدخول: ${message.replaceAll('Exception: ', '')}'));
      }
    }
  }

  Future<void> _saveRateLimit(DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rate_limit_expiry', expiry.toIso8601String());
  }

  Future<void> _clearRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rate_limit_expiry');
    _rateLimitExpiry = null;
  }

  Future<void> checkSavedRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString('rate_limit_expiry');
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (expiry.isAfter(DateTime.now())) {
        _rateLimitExpiry = expiry;
        final seconds = expiry.difference(DateTime.now()).inSeconds;
        emit(AuthRateLimitExceeded(retryAfterSeconds: seconds));
      } else {
        await _clearRateLimit();
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'client',
  }) async {
    // Check if rate limited first
    if (_rateLimitExpiry != null && _rateLimitExpiry!.isAfter(DateTime.now())) {
      final seconds = _rateLimitExpiry!.difference(DateTime.now()).inSeconds;
      emit(AuthRateLimitExceeded(retryAfterSeconds: seconds));
      return;
    }

    try {
      emit(AuthLoading());
      final user = await authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        emailRedirectTo: 'io.supabase.sharik://login-callback/',
      );
      
      // If successful, clear any limit
      await _clearRateLimit();

      // Use the actual role from the user object
      emit(Authenticated(user: user, role: user.role));
    } catch (e) {
      final message = e.toString();
      if (message.contains('RATE_LIMIT_EXCEEDED')) {
        int seconds = int.tryParse(message.split(':')[1]) ?? 600; // Default to 10 min
        
        if (seconds == 0) seconds = 600;

        final expiry = DateTime.now().add(Duration(seconds: seconds));
        _rateLimitExpiry = expiry;
        await _saveRateLimit(expiry);
        
        emit(AuthRateLimitExceeded(retryAfterSeconds: seconds));
      } else {
        emit(AuthError(message: message.replaceAll('Exception: ', '')));
      }
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
      final message = e.toString();
      if (message.contains('RATE_LIMIT_EXCEEDED')) {
        final seconds = int.tryParse(message.split(':')[1]) ?? 60;
        final expiry = DateTime.now().add(Duration(seconds: seconds));
        _rateLimitExpiry = expiry;
        await _saveRateLimit(expiry);
        emit(AuthRateLimitExceeded(retryAfterSeconds: seconds));
      } else {
        emit(AuthError(message: message.replaceAll('Exception: ', '')));
      }
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

  Future<void> resetPassword(String email) async {
    try {
      emit(AuthLoading());
      await authRepository.resetPassword(email);
      emit(PasswordResetEmailSent());
      // Reset to unauthenticated (or previous state) after showing success to allow further actions
      // But for now, the UI will likely handle the navigation/success message based on this state.
    } catch (e) {
      emit(AuthError(message: 'فشل إرسال رابط الاستعادة'));
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      emit(AuthLoading());
      await authRepository.resendConfirmationEmail(email);
      emit(CodeResent()); // Using CodeResent as a success state for this too
    } catch (e) {
      emit(AuthError(message: 'فشل إعادة إرسال رابط التفعيل'));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      emit(AuthLoading());
      await authRepository.updatePassword(newPassword);
      emit(AuthPasswordUpdated());
    } catch (e) {
      emit(AuthError(message: 'فشل تحديث كلمة المرور: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  // Removed social login methods as per user request
}
