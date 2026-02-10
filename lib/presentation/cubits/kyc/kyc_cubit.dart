import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/services/auth_service.dart';

// States
abstract class KYCState extends Equatable {
  const KYCState();

  @override
  List<Object?> get props => [];
}

class KYCInitial extends KYCState {}

class KYCLoading extends KYCState {}

class KYCSubmitted extends KYCState {
  final UserModel user;

  const KYCSubmitted(this.user);

  @override
  List<Object?> get props => [user];
}

class KYCApproved extends KYCState {
  final UserModel user;

  const KYCApproved(this.user);

  @override
  List<Object?> get props => [user];
}

class KYCRejected extends KYCState {
  final String reason;

  const KYCRejected(this.reason);

  @override
  List<Object?> get props => [reason];
}

class KYCError extends KYCState {
  final String message;

  const KYCError(this.message);

  @override
  List<Object?> get props => [message];
}

// ALIASES FOR SCREEN COMPATIBILITY
class KYCPending extends KYCState {}
class KYCUnderReview extends KYCState {}
class KYCSubmitting extends KYCState {}

// Cubit
class KYCCubit extends Cubit<KYCState> {
  final AuthService _authService;

  KYCCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(KYCInitial());

  // Alias for backward compatibility
  Future<void> loadKYCStatus(String userId) => checkKYCStatus(userId);

  Future<void> submitKYC({
    required String userId,
    required String nationalId,
    required DateTime dateOfBirth,
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
    String? incomeProofPath,
  }) async {
    emit(KYCLoading());
    try {
      await _authService.submitKYC(
        userId: userId,
        nationalId: nationalId,
        dateOfBirth: dateOfBirth,
        idFrontPath: idFrontPath,
        idBackPath: idBackPath,
        selfiePath: selfiePath,
        incomeProofPath: incomeProofPath,
      );

      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(KYCSubmitted(user));
      } else {
        emit(KYCError('Failed to retrieve user after KYC submission'));
      }
    } catch (e) {
      emit(KYCError(e.toString()));
    }
  }

  Future<void> checkKYCStatus(String userId) async {
    emit(KYCLoading());
    try {
      final user = await _authService.getCurrentUser();
      
      if (user == null) {
        emit(const KYCError('المستخدم غير موجود'));
        return;
      }

      switch (user.kycStatus) {
        case KycStatus.pending:
        case KycStatus.underReview:
          emit(KYCSubmitted(user));
          break;
        case KycStatus.approved:
          emit(KYCApproved(user));
          break;
        case KycStatus.rejected:
          emit(KYCRejected(user.kycRejectionReason ?? 'تم رفض الطلب'));
          break;
      }
    } catch (e) {
      emit(KYCError(e.toString()));
    }
  }
}
