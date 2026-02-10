// lib/presentation/cubits/installments/installments_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/repositories/installment_repository.dart';

part 'installments_state.dart';

class InstallmentsCubit extends Cubit<InstallmentsState> {
  InstallmentsCubit({required this.repository}) : super(InstallmentsInitial());

  final InstallmentRepository repository;

  /// Load installments for a subscription
  Future<void> loadSubscriptionInstallments(String subscriptionId) async {
    try {
      emit(InstallmentsLoading());
      final installments =
          await repository.getInstallmentsBySubscription(subscriptionId);
      emit(InstallmentsLoaded(
        installments: installments,
        overdueCount: _countOverdue(installments),
        upcomingCount: _countUpcoming(installments),
      ));
    } catch (e) {
      emit(InstallmentsError(message: e.toString()));
    }
  }

  /// Load all user installments
  Future<void> loadUserInstallments(String userId) async {
    try {
      emit(InstallmentsLoading());
      final installments = await repository.getInstallmentsByUser(userId);
      emit(InstallmentsLoaded(
        installments: installments,
        overdueCount: _countOverdue(installments),
        upcomingCount: _countUpcoming(installments),
      ));
    } catch (e) {
      emit(InstallmentsError(message: e.toString()));
    }
  }

  /// Load overdue installments
  Future<void> loadOverdueInstallments(String userId) async {
    try {
      emit(InstallmentsLoading());
      final installments = await repository.getOverdueInstallments(userId);
      emit(InstallmentsLoaded(
        installments: installments,
        overdueCount: installments.length,
        upcomingCount: 0,
      ));
    } catch (e) {
      emit(InstallmentsError(message: e.toString()));
    }
  }

  /// Load upcoming installments
  Future<void> loadUpcomingInstallments(String userId) async {
    try {
      emit(InstallmentsLoading());
      final installments = await repository.getUpcomingInstallments(userId);
      emit(InstallmentsLoaded(
        installments: installments,
        overdueCount: 0,
        upcomingCount: installments.length,
      ));
    } catch (e) {
      emit(InstallmentsError(message: e.toString()));
    }
  }

  /// Pay an installment
  Future<void> payInstallment({
    required String installmentId,
    required String transactionId,
    required String userId,
  }) async {
    try {
      await repository.payInstallment(
        installmentId: installmentId,
        transactionId: transactionId,
      );
      // Reload installments after payment
      await loadUserInstallments(userId);
    } catch (e) {
      emit(InstallmentsError(message: 'فشل الدفع: ${e.toString()}'));
    }
  }

  int _countOverdue(List<InstallmentModel> installments) {
    final now = DateTime.now();
    return installments
        .where((i) =>
            i.status == InstallmentStatus.pending &&
            i.dueDate.isBefore(now))
        .length;
  }

  int _countUpcoming(List<InstallmentModel> installments) {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 30));
    return installments
        .where((i) =>
            i.status == InstallmentStatus.pending &&
            i.dueDate.isAfter(now) &&
            i.dueDate.isBefore(future))
        .length;
  }
}
