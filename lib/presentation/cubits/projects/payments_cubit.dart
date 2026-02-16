
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/repositories/payments_repository.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object> get props => [];
}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<InstallmentModel> payments;

  const PaymentsLoaded(this.payments);

  @override
  List<Object> get props => [payments];
}

class PaymentsError extends PaymentsState {
  final String message;

  const PaymentsError(this.message);

  @override
  List<Object> get props => [message];
}

class PaymentsCubit extends Cubit<PaymentsState> {
  final PaymentsRepository _paymentsRepository;

  PaymentsCubit(this._paymentsRepository) : super(PaymentsInitial());

  Future<void> loadProjectPayments(String projectId) async {
    emit(PaymentsLoading());
    try {
      final data = await _paymentsRepository.getProjectPayments(projectId);
      final payments = data.map((json) => InstallmentModel.fromJson(json)).toList();
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> loadUserProjectPayments(String userId, String projectId) async {
    emit(PaymentsLoading());
    try {
      final data = await _paymentsRepository.getUserProjectPayments(userId, projectId);
      final payments = data.map((json) => InstallmentModel.fromJson(json)).toList();
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }
}
