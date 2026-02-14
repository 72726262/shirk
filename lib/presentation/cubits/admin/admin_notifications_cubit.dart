import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/admin_repository.dart';

abstract class AdminNotificationsState extends Equatable {
  const AdminNotificationsState();
  @override
  List<Object?> get props => [];
}

class AdminNotificationsInitial extends AdminNotificationsState {}
class AdminNotificationsSending extends AdminNotificationsState {}
class AdminNotificationsSent extends AdminNotificationsState {}
class AdminNotificationsError extends AdminNotificationsState {
  final String message;
  const AdminNotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminNotificationsCubit extends Cubit<AdminNotificationsState> {
  final AdminRepository _adminRepository;

  AdminNotificationsCubit({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository(),
        super(AdminNotificationsInitial());

  Future<void> sendNotification({
    required String title,
    required String titleAr,
    required String body,
    required String bodyAr,
    String? userId,
    List<String>? userIds,
    String? projectId,
    String priority = 'normal',
  }) async {
    emit(AdminNotificationsSending());
    try {
      await _adminRepository.sendNotification(
        title: title,
        titleAr: titleAr,
        body: body,
        bodyAr: bodyAr,
        userId: userId,
        userIds: userIds,
        projectId: projectId,
        priority: priority,
      );
      emit(AdminNotificationsSent());
    } catch (e) {
      emit(AdminNotificationsError(e.toString()));
    }
  }
}
