// lib/presentation/cubits/admin/client_management_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/admin_repository.dart';
import 'package:mmm/data/models/user_model.dart';

// States
abstract class ClientManagementState extends Equatable {
  const ClientManagementState();

  @override
  List<Object?> get props => [];
}

class ClientManagementInitial extends ClientManagementState {}

class ClientManagementLoading extends ClientManagementState {}

class ClientManagementLoaded extends ClientManagementState {
  final List<UserModel> clients;

  const ClientManagementLoaded(this.clients);

  @override
  List<Object?> get props => [clients];
}

class KycApproved extends ClientManagementState {}

class KycRejected extends ClientManagementState {}

class ClientManagementError extends ClientManagementState {
  final String message;

  const ClientManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ClientManagementCubit extends Cubit<ClientManagementState> {
  final AdminRepository _adminRepository;

  ClientManagementCubit({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? AdminRepository(),
      super(ClientManagementInitial());

  // Load clients with optional filters
  Future<void> loadClients({String? kycStatus, String? searchQuery}) async {
    try {
      emit(ClientManagementLoading());

      print('📥 جلب العملاء من Supabase...');

      final clients = await _adminRepository.getClients(
        // role: 'client', // Removed to allow viewing all users/requests for now
        kycStatus: kycStatus,
        searchQuery: searchQuery,
      );

      print('✅ تم جلب ${clients.length} عميل');

      emit(ClientManagementLoaded(clients));
    } catch (e) {
      print('❌ خطأ في loadClients: $e');
      emit(ClientManagementError('فشل تحميل العملاء: ${e.toString()}'));
    }
  }

  // Approve KYC
  Future<void> approveKyc(String userId) async {
    try {
      emit(ClientManagementLoading());

      print('✅ الموافقة على KYC للمستخدم: $userId');

      await _adminRepository.approveKYC(userId);

      print('✅ تمت الموافقة بنجاح');

      emit(KycApproved());
    } catch (e) {
      print('❌ خطأ في approveKyc: $e');
      emit(ClientManagementError('فشلت الموافقة: ${e.toString()}'));
    }
  }

  // Reject KYC
  Future<void> rejectKyc(String userId, String reason) async {
    try {
      emit(ClientManagementLoading());

      print('❌ رفض KYC للمستخدم: $userId');
      print('   السبب: $reason');

      await _adminRepository.rejectKYC(userId: userId, reason: reason);

      print('✅ تم الرفض بنجاح');

      emit(KycRejected());
    } catch (e) {
      print('❌ خطأ في rejectKyc: $e');
      emit(ClientManagementError('فشل الرفض: ${e.toString()}'));
    }
  }

  // Update Client
  Future<void> updateClient({
    required String userId,
    String? fullName,
    String? phone,
    String? nationalId,
    String? avatarPath,
  }) async {
    try {
      emit(ClientManagementLoading());

      await _adminRepository.updateClient(
        userId: userId,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        avatarPath: avatarPath,
      );

      // Reload clients to show updates
      await loadClients();
    } catch (e) {
      emit(ClientManagementError('فشل تحديث البيانات: ${e.toString()}'));
    }
  }
}
