import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/handover_model.dart';

abstract class HandoverState extends Equatable {
  const HandoverState();

  @override
  List<Object?> get props => [];
}

class HandoverInitial extends HandoverState {}

class HandoverLoading extends HandoverState {}

class HandoverLoaded extends HandoverState {
  final List<HandoverModel> handovers;

  const HandoverLoaded({required this.handovers});

  @override
  List<Object?> get props => [handovers];
}

class HandoverError extends HandoverState {
  final String message;

  const HandoverError({required this.message});

  @override
  List<Object?> get props => [message];
}
