import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/transaction_model.dart';

// Report Data Model
class ReportData {
  final List<double> revenueData;
  final int newClients;
  final int newProjects;
  final double totalPayments;
  final double conversionRate;

  const ReportData({
    this.revenueData = const [],
    this.newClients = 0,
    this.newProjects = 0,
    this.totalPayments = 0,
    this.conversionRate = 0,
  });

  factory ReportData.fromMap(Map<String, dynamic> map) {
    return ReportData(
      revenueData: List<double>.from(map['revenue_data'] ?? []),
      newClients: map['new_clients'] ?? 0,
      newProjects: map['new_projects'] ?? 0,
      totalPayments: (map['total_payments'] ?? 0).toDouble(),
      conversionRate: (map['conversion_rate'] ?? 0).toDouble(),
    );
  }
}

// States
abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}

class ClientsLoaded extends AdminState {
  final List<UserModel> clients;
  const ClientsLoaded(this.clients);
  @override
  List<Object?> get props => [clients];
}

class ProjectsLoadedAdmin extends AdminState {
  final List<ProjectModel> projects;
  const ProjectsLoadedAdmin(this.projects);
  @override
  List<Object?> get props => [projects];
}

class PaymentsLoaded extends AdminState {
  final List<TransactionModel> payments;
  const PaymentsLoaded(this.payments);
  @override
  List<Object?> get props => [payments];
}

class ReportsLoaded extends AdminState {
  final Map<String, dynamic> stats;
  final ReportData reports;
  const ReportsLoaded(this.stats, {this.reports = const ReportData()});
  @override
  List<Object?> get props => [stats, reports];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class AdminCubit extends Cubit<AdminState> {
  AdminCubit() : super(AdminInitial());

  // Clients
  Future<void> loadClients() async {
    emit(AdminLoading());
    try {
      // Mock data for now or use repository
      await Future.delayed(const Duration(seconds: 1));
      emit(const ClientsLoaded([]));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> refreshClients() => loadClients();

  Future<void> approveKYC(String clientId) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تمت الموافقة على العميل'));
      loadClients();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> blockClient(String clientId) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تم حظر العميل'));
      loadClients();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Projects
  Future<void> loadProjects() async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const ProjectsLoadedAdmin([]));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> refreshProjects() => loadProjects();

  Future<void> createProject(ProjectModel project) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تم إنشاء المشروع بنجاح'));
      loadProjects();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateProject(ProjectModel project) async {
     emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تم تحديث المشروع بنجاح'));
      loadProjects();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteProject(String projectId) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تم حذف المشروع'));
      loadProjects();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Payments
  Future<void> loadPayments([String? filter]) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const PaymentsLoaded([]));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> refreshPayments(String filter) => loadPayments(filter);

  Future<void> approvePayment(String id) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تمت الموافقة على الدفع'));
      loadPayments('pending');
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> rejectPayment(String id) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تم رفض الدفع'));
      loadPayments('pending');
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Reports
  Future<void> loadReports([String? period]) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const ReportsLoaded({
        'total_revenue': 0,
        'active_projects': 0,
        'total_clients': 0,
      }));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> refreshReports(String period) => loadReports(period);

  Future<void> exportReport(String period) async {
    emit(AdminLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AdminActionSuccess('تم تصدير التقرير'));
      loadReports(period);
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
