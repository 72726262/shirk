import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/admin_repository.dart';

// States
abstract class ClientsManagementState extends Equatable {
  const ClientsManagementState();

  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsManagementState {}

class ClientsLoading extends ClientsManagementState {}

class ClientsLoaded extends ClientsManagementState {
  final List<UserModel> clients;

  const ClientsLoaded(this.clients);

  @override
  List<Object?> get props => [clients];
}

class ClientsError extends ClientsManagementState {
  final String message;

  const ClientsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ClientsManagementCubit extends Cubit<ClientsManagementState> {
  final AdminRepository _adminRepository;

  ClientsManagementCubit({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository(),
        super(ClientsInitial());

  Future<void> loadClients({String? kycStatus, String? searchQuery}) async {
    emit(ClientsLoading());
    try {
      final clients = await _adminRepository.getClients(
        kycStatus: kycStatus,
        searchQuery: searchQuery,
      );
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> approveKYC(String userId) async {
    try {
      await _adminRepository.approveKYC(userId);
      // Reload to reflect changes
      if (state is ClientsLoaded) {
        await loadClients(); 
      }
    } catch (e) {
      emit(ClientsError(e.toString()));
      // Optionally reload to restore valid state
      loadClients();
    }
  }

  Future<void> rejectKYC(String userId, String reason) async {
    try {
      await _adminRepository.rejectKYC(userId: userId, reason: reason);
      if (state is ClientsLoaded) {
        await loadClients();
      }
    } catch (e) {
      emit(ClientsError(e.toString()));
      loadClients();
    }
  }
}
