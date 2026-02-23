import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/repositories/notification_repository.dart';

// States
abstract class NotificationDetailState extends Equatable {
  const NotificationDetailState();

  @override
  List<Object?> get props => [];
}

class NotificationDetailInitial extends NotificationDetailState {}

class NotificationDetailLoading extends NotificationDetailState {}

class NotificationDetailLoaded extends NotificationDetailState {
  final NotificationModel notification;

  const NotificationDetailLoaded(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationDetailError extends NotificationDetailState {
  final String message;

  const NotificationDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotificationDetailCubit extends Cubit<NotificationDetailState> {
  final NotificationRepository _notificationRepository;

  NotificationDetailCubit({NotificationRepository? notificationRepository})
      : _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        super(NotificationDetailInitial());

  Future<void> loadNotificationDetail(String notificationId) async {
    emit(NotificationDetailLoading());
    try {
      final notification = await _notificationRepository.getNotificationById(notificationId);
      emit(NotificationDetailLoaded(notification));
    } catch (e) {
      emit(NotificationDetailError(e.toString()));
    }
  }
}
