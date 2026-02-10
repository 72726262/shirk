import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/admin_repository.dart';

abstract class PaymentsManagementState extends Equatable {
  const PaymentsManagementState();
  @override
  List<Object?> get props => [];
}

class PaymentsInitial extends PaymentsManagementState {}
class PaymentsLoading extends PaymentsManagementState {}
class PaymentsLoaded extends PaymentsManagementState {
  final List<Map<String, dynamic>> transactions;
  const PaymentsLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}
class PaymentsError extends PaymentsManagementState {
  final String message;
  const PaymentsError(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentsManagementCubit extends Cubit<PaymentsManagementState> {
  final AdminRepository _adminRepository;

  PaymentsManagementCubit({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository(),
        super(PaymentsInitial());

  Future<void> loadTransactions({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(PaymentsLoading());
    try {
      final transactions = await _adminRepository.getTransactions(
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      emit(PaymentsLoaded(transactions));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }
}
