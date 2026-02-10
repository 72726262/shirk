// lib/presentation/cubits/kyc/kyc_state.dart
part of 'kyc_cubit.dart';

abstract class KycState extends Equatable {
  const KycState();

  @override
  List<Object> get props => [];
}

class KycInitial extends KycState {}

class KycLoading extends KycState {}

class KycSubmitting extends KycState {}

class KycSubmittedSuccessfully extends KycState {}

class KycStatusLoaded extends KycState {
  final String status;
  final String? submittedAt;
  final String? reviewedAt;
  final String? rejectionReason;

  const KycStatusLoaded({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  @override
  List<Object> get props => [status];
}

class KycError extends KycState {
  final String message;

  const KycError({required this.message});

  @override
  List<Object> get props => [message];
}
