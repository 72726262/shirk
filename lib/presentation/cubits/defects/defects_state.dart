// lib/presentation/cubits/defects/defects_state.dart
part of 'defects_cubit.dart';

abstract class DefectsState extends Equatable {
  const DefectsState();

  @override
  List<Object?> get props => [];
}

class DefectsInitial extends DefectsState {}

class DefectsLoading extends DefectsState {}

class DefectsLoaded extends DefectsState {
  final List<DefectModel> defects;
  final int pendingCount;
  final int fixedCount;

  const DefectsLoaded({
    required this.defects,
    required this.pendingCount,
    required this.fixedCount,
  });

  @override
  List<Object?> get props => [defects, pendingCount, fixedCount];
}

class DefectsError extends DefectsState {
  final String message;

  const DefectsError({required this.message});

  @override
  List<Object?> get props => [message];
}
