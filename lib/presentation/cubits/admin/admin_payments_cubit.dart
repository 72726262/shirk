import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/services/admin_service.dart';

// States
abstract class AdminPaymentsState extends Equatable {
  const AdminPaymentsState();

  @override
  List<Object?> get props => [];
}

class AdminPaymentsInitial extends AdminPaymentsState {}

class AdminPaymentsLoading extends AdminPaymentsState {}

class AdminPaymentsLoaded extends AdminPaymentsState {
  final List<dynamic> payments;
  final List<Map<String, dynamic>> monthlyRevenue;

  const AdminPaymentsLoaded({
    required this.payments,
    required this.monthlyRevenue,
  });

  @override
  List<Object?> get props => [payments, monthlyRevenue];
}

class AdminPaymentsError extends AdminPaymentsState {
  final String message;

  const AdminPaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AdminPaymentsCubit extends Cubit<AdminPaymentsState> {
  final AdminService _adminService;

  AdminPaymentsCubit({AdminService? adminService})
      : _adminService = adminService ?? AdminService(),
        super(AdminPaymentsInitial());

  Future<void> loadPayments({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(AdminPaymentsLoading());
    try {
      final payments = await _adminService.getPayments(
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      final monthlyRevenue = await _adminService.getMonthlyRevenue(months: 12);

      emit(AdminPaymentsLoaded(
        payments: payments,
        monthlyRevenue: monthlyRevenue,
      ));
    } catch (e) {
      emit(AdminPaymentsError(e.toString()));
    }
  }

  Future<void> refreshPayments() async {
    await loadPayments();
  }
}
