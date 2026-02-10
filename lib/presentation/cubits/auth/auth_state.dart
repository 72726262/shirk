part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  final String role;

  const Authenticated({required this.user, required this.role});

  @override
  List<Object> get props => [user, role];
}

class Unauthenticated extends AuthState {}

class PhoneVerified extends AuthState {}

class CodeResent extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}
