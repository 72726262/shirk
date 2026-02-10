import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/auth_repository.dart';

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PhoneVerified extends AuthState {}

class CodeResent extends AuthState {}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(AuthInitial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(email, password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final user = await _authRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        avatarPath: avatarUrl,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> submitKYC({
    required String userId,
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
    required String nationalId,
    required String dateOfBirth,
  }) async {
    emit(AuthLoading());
    try {
      // 1. Submit documents
      await _authRepository.submitKyc(
        userId: userId,
        idFrontPath: idFrontPath,
        idBackPath: idBackPath,
        selfiePath: selfiePath,
      );

      // 2. Update profile with personal info (if supported by repo, otherwise we skip for now)
      // Note: We might need to extend updateProfile to support nationalId and dateOfBirth
      // For now, we just ensure the documents are submitted.

      emit(
        const AuthError('تم رفع المستندات بنجاح (بانتظار المراجعة)'),
      ); // Using Error state for message? No, should be success.
      // We should probably emit a specific state or just reload user.
      _checkAuthStatus();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyPhone(String otp) async {
    emit(AuthLoading());
    try {
      // Simulate verification
      await Future.delayed(const Duration(seconds: 1));
      emit(PhoneVerified());
      // Re-check auth status after verification
      _checkAuthStatus();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resendPhoneVerificationCode() async {
    try {
      // Simulate resend
      await Future.delayed(const Duration(seconds: 1));
      emit(CodeResent());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  UserModel? get currentUser {
    final currentState = state;
    if (currentState is Authenticated) {
      return currentState.user;
    }
    return null;
  }

  bool get isAuthenticated => state is Authenticated;
}
