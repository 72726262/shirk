import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/services/admin_service.dart';

// States
abstract class AdminClientsState extends Equatable {
  const AdminClientsState();

  @override
  List<Object?> get props => [];
}

class AdminClientsInitial extends AdminClientsState {}

class AdminClientsLoading extends AdminClientsState {}

class AdminClientsLoaded extends AdminClientsState {
  final List<UserModel> clients;
  final List<UserModel> pendingKyc;

  const AdminClientsLoaded({
    required this.clients,
    required this.pendingKyc,
  });

  @override
  List<Object?> get props => [clients, pendingKyc];
}

class AdminClientsProcessing extends AdminClientsState {
  final String message;

  const AdminClientsProcessing(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminClientsError extends AdminClientsState {
  final String message;

  const AdminClientsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AdminClientsCubit extends Cubit<AdminClientsState> {
  final AdminService _adminService;

  AdminClientsCubit({AdminService? adminService})
      : _adminService = adminService ?? AdminService(),
        super(AdminClientsInitial());

  Future<void> loadClients({
    String? kycStatus,
    String? role,
    String? searchQuery,
  }) async {
    emit(AdminClientsLoading());
    try {
      final clients = await _adminService.getClients(
        kycStatus: kycStatus,
        role: role,
        searchQuery: searchQuery,
      );

      final pendingKyc = await _adminService.getPendingKYC();

      emit(AdminClientsLoaded(
        clients: clients,
        pendingKyc: pendingKyc,
      ));
    } catch (e) {
      emit(AdminClientsError(e.toString()));
    }
  }

  Future<void> approveKYC(String userId) async {
    emit(const AdminClientsProcessing('جاري الموافقة...'));
    try {
      await _adminService.approveKYC(userId);
      await _adminService.logActivity(
        action: 'KYC_APPROVED',
        entityType: 'profiles',
        entityId: userId,
        description: 'تم الموافقة على التحقق من الهوية',
      );
      
      await loadClients();
    } catch (e) {
      emit(AdminClientsError(e.toString()));
    }
  }

  Future<void> rejectKYC({
    required String userId,
    required String reason,
  }) async {
    emit(const AdminClientsProcessing('جاري الرفض...'));
    try {
      await _adminService.rejectKYC(userId: userId, reason: reason);
      await _adminService.logActivity(
        action: 'KYC_REJECTED',
        entityType: 'profiles',
        entityId: userId,
        description: 'تم رفض التحقق من الهوية: $reason',
      );
      
      await loadClients();
    } catch (e) {
      emit(AdminClientsError(e.toString()));
    }
  }

  Future<void> bulkApproveKYC(List<String> userIds) async {
    emit(AdminClientsProcessing('جاري الموافقة على ${userIds.length} طلبات...'));
    try {
      await _adminService.bulkApproveKYC(userIds);
      await loadClients();
    } catch (e) {
      emit(AdminClientsError(e.toString()));
    }
  }
}
