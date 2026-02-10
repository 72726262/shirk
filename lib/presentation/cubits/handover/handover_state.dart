import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/models/defect_model.dart';

abstract class HandoverState extends Equatable {
  const HandoverState();

  @override
  List<Object?> get props => [];
}

class HandoverInitial extends HandoverState {}

class HandoverLoading extends HandoverState {}

class HandoverLoaded extends HandoverState {
  final HandoverModel handover;
  final List<DefectModel> defects;
  final int pendingDefects;
  final int fixedDefects;
  final int criticalDefects;
  final int completionPercentage;
  final Map<String, dynamic> progress;

  const HandoverLoaded({
    required this.handover,
    required this.defects,
    required this.pendingDefects,
    required this.fixedDefects,
    required this.criticalDefects,
    required this.completionPercentage,
    required this.progress,
  });

  @override
  List<Object?> get props => [
    handover,
    defects,
    pendingDefects,
    fixedDefects,
    criticalDefects,
    completionPercentage,
    progress,
  ];
}

class HandoversListLoaded extends HandoverState {
  final List<HandoverModel> handovers;

  const HandoversListLoaded(this.handovers);

  @override
  List<Object?> get props => [handovers];
}

class HandoverSubmittingDefect extends HandoverState {
  final String message;

  const HandoverSubmittingDefect(this.message);

  @override
  List<Object?> get props => [message];
}

class HandoverSigning extends HandoverState {
  final String message;

  const HandoverSigning(this.message);

  @override
  List<Object?> get props => [message];
}

class HandoverComplete extends HandoverState {
  final HandoverModel handover;
  final String certificateUrl;

  const HandoverComplete({
    required this.handover,
    required this.certificateUrl,
  });

  @override
  List<Object?> get props => [handover, certificateUrl];
}

class HandoverError extends HandoverState {
  final String message;

  const HandoverError(this.message);

  @override
  List<Object?> get props => [message];
}

class HandoverStatusLoaded extends HandoverState {
  final String status;
  final Map<String, dynamic> data;

  const HandoverStatusLoaded({required this.status, required this.data});

  @override
  List<Object?> get props => [status, data];
}

class AppointmentBooked extends HandoverState {
  final DateTime appointmentDate;

  const AppointmentBooked(this.appointmentDate);

  @override
  List<Object?> get props => [appointmentDate];
}

class SnagAdded extends HandoverState {
  final DefectModel snag;

  const SnagAdded(this.snag);

  @override
  List<Object?> get props => [snag];
}

class SnagsLoaded extends HandoverState {
  final List<DefectModel> snags;

  const SnagsLoaded(this.snags);

  @override
  List<Object?> get props => [snags];

  List<DefectModel> get defects => snags;
}

class DefectsLoaded extends HandoverState {
  final List<DefectModel> defects;

  const DefectsLoaded(this.defects);

  @override
  List<Object?> get props => [defects];
}

class HandoverCompleted extends HandoverState {
  final HandoverModel handover;

  const HandoverCompleted(this.handover);

  @override
  List<Object?> get props => [handover];
}
