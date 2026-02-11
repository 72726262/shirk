import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/data/models/handover_model.dart';

abstract class HandoversManagementState extends Equatable {
  const HandoversManagementState();

  @override
  List<Object?> get props => [];
}

class HandoversManagementInitial extends HandoversManagementState {}

class HandoversManagementLoading extends HandoversManagementState {}

class HandoversManagementLoaded extends HandoversManagementState {
  final List<HandoverModel> handovers;

  const HandoversManagementLoaded({required this.handovers});

  @override
  List<Object?> get props => [handovers];
}

class HandoverDetailLoaded extends HandoversManagementState {
  final HandoverModel handover;

  const HandoverDetailLoaded({required this.handover});

  @override
  List<Object?> get props => [handover];
}

class DefectsLoaded extends HandoversManagementState {
  final List<DefectModel> defects;

  const DefectsLoaded({required this.defects});

  @override
  List<Object?> get props => [defects];
}

class HandoverAppointmentBookedSuccessfully extends HandoversManagementState {
  const HandoverAppointmentBookedSuccessfully();
}

class HandoverRescheduledSuccessfully extends HandoversManagementState {
  const HandoverRescheduledSuccessfully();
}

class DefectUpdatedSuccessfully extends HandoversManagementState {
  const DefectUpdatedSuccessfully();
}

class HandoverCompletedSuccessfully extends HandoversManagementState {
  const HandoverCompletedSuccessfully();
}

class HandoverCertificateGenerated extends HandoversManagementState {
  final String certificateUrl;

  const HandoverCertificateGenerated({required this.certificateUrl});

  @override
  List<Object?> get props => [certificateUrl];
}

class HandoversManagementError extends HandoversManagementState {
  final String message;

  const HandoversManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}
