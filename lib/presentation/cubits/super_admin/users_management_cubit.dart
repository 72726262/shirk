import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/admin_repository.dart';

abstract class UsersManagementState extends Equatable {
  const UsersManagementState();
  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersManagementState {}
class UsersLoading extends UsersManagementState {}
class UsersLoaded extends UsersManagementState {
  final List<UserModel> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}
class UsersError extends UsersManagementState {
  final String message;
  const UsersError(this.message);
  @override
  List<Object?> get props => [message];
}

class UsersManagementCubit extends Cubit<UsersManagementState> {
  final AdminRepository _adminRepository;

  UsersManagementCubit({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository(),
        super(UsersInitial());

  Future<void> loadUsers({String? role, String? searchQuery}) async {
    emit(UsersLoading());
    try {
      // Reusing getClients but it filters by role if provided, otherwise generic
      // We might need to adjust getClients to NOT filter by 'client' if role is null?
      // Check AdminRepository implementation.
      // In Step 598/612, getClients takes 'role' arg.
      final users = await _adminRepository.getClients(
        role: role,
        searchQuery: searchQuery,
      );
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _adminRepository.updateUserRole(userId, newRole);
      // Reload to reflect changes
      if (state is UsersLoaded) {
        await loadUsers(); 
      }
    } catch (e) {
      emit(UsersError(e.toString()));
      loadUsers();
    }
  }
}
