// lib/presentation/cubits/installments/installments_state.dart
part of 'installments_cubit.dart';

abstract class InstallmentsState extends Equatable {
  const InstallmentsState();

  @override
  List<Object?> get props => [];
}

class InstallmentsInitial extends InstallmentsState {}

class InstallmentsLoading extends InstallmentsState {}

class InstallmentsLoaded extends InstallmentsState {
  final List<InstallmentModel> installments;
  final int overdueCount;
  final int upcomingCount;

  const InstallmentsLoaded({
    required this.installments,
    required this.overdueCount,
    required this.upcomingCount,
  });

  double get totalAmount =>
      installments.fold(0.0, (sum, i) => sum + i.amount);

  double get totalPaid => installments
      .where((i) => i.status == InstallmentStatus.paid)
      .fold(0.0, (sum, i) => sum + i.amount);

  double get totalPending => installments
      .where((i) => i.status == InstallmentStatus.pending)
      .fold(0.0, (sum, i) => sum + i.amount);

  @override
  List<Object?> get props => [installments, overdueCount, upcomingCount];
}

class InstallmentsError extends InstallmentsState {
  final String message;

  const InstallmentsError({required this.message});

  @override
  List<Object?> get props => [message];
}
