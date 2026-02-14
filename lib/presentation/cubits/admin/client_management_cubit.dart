// lib/presentation/cubits/admin/client_management_cubit.dart
import 'dart:async';
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
  StreamSubscription? _clientsSubscription;

  ClientManagementCubit({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? AdminRepository(),
      super(ClientManagementInitial());

  // Load clients with optional filters (Stream based)
  Future<void> loadClients({String? kycStatus, String? searchQuery}) async {
    try {
      emit(ClientManagementLoading());

      // Cancel previous subscription if exists
      await _clientsSubscription?.cancel();

      print('📥 بدء الاستماع للعملاء من Supabase...');

      _clientsSubscription = _adminRepository
          .getClientsStream(kycStatus: kycStatus, searchQuery: searchQuery)
          .listen(
            (clients) {
              print('✅ تم استقبال تحديث: ${clients.length} عميل');
              emit(ClientManagementLoaded(clients));
            },
            onError: (error) {
              print('❌ خطأ في stream العملاء: $error');
              emit(
                ClientManagementError('فشل تحميل العملاء: ${error.toString()}'),
              );
            },
          );
    } catch (e) {
      print('❌ خطأ في loadClients: $e');
      emit(ClientManagementError('فشل تحميل العملاء: ${e.toString()}'));
    }
  }

  // Approve KYC
  Future<void> approveKyc(String userId) async {
    try {
      // emit(ClientManagementLoading()); // Don't emit loading here to avoid flickering list, or handle carefully
      // Actually, for actions, we might want to show loading overlay or similar, but main list is stream.
      // If we emit loading, we clear the list. Let's keep existing list if possible, or emit loading if we really want to block UI.
      // For better UX with streams, we usually don't emit 'Loading' for actions unless it blocks the whole view.
      // But existing logic emits Loading. Let's iterate.
      // If we emit Loading, the Stream listener might emit Loaded immediately after if data changes, or we might miss current state.
      // Let's stick to simple "Optimistic UI" or just wait for stream update.
      // But we need to handle success/error feedback.
      // Existing UI listens for KycApproved state.

      print('✅ الموافقة على KYC للمستخدم: $userId');

      await _adminRepository.approveKYC(userId);

      print('✅ تمت الموافقة بنجاح');

      emit(KycApproved());
      // No need to reload, stream updates automatically
    } catch (e) {
      print('❌ خطأ في approveKyc: $e');
      emit(ClientManagementError('فشلت الموافقة: ${e.toString()}'));
      // After error, we might want to re-emit loaded state?
      // The stream is still active, but current state is Error.
      // We might need to "reset" to loaded if stream pushes again?
      // Or manually re-emit last known data? Stream doesn't keep "last value" accessible easily unless we store it.
      // For now, let's leave as is, user might retry or refresh.
    }
  }

  // Reject KYC
  Future<void> rejectKyc(String userId, String reason) async {
    try {
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

  // Delete Client
  Future<void> deleteClient(String userId) async {
    try {
      await _adminRepository.deleteClient(userId);

      // Success is indicated by lack of error.
      // Stream will automatically remove the client from list.
    } catch (e) {
      print("object" + e.toString());
      emit(ClientManagementError(e.toString().replaceAll('Exception: ', '')));
      rethrow;
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
      // emit(ClientManagementLoading());

      await _adminRepository.updateClient(
        userId: userId,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        avatarPath: avatarPath,
      );

      // No need to reload, stream updates automatically
    } catch (e) {
      emit(ClientManagementError('فشل تحديث البيانات: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _clientsSubscription?.cancel();
    return super.close();
  }
}
