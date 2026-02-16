import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/repositories/units_repository.dart';

// States
abstract class UnitsManagementState extends Equatable {
  const UnitsManagementState();

  @override
  List<Object?> get props => [];
}

class UnitsManagementInitial extends UnitsManagementState {}

class UnitsManagementLoading extends UnitsManagementState {}

class UnitsManagementLoaded extends UnitsManagementState {
  final List<UnitModel> units;
  final String? selectedProjectId;

  const UnitsManagementLoaded({
    required this.units,
    this.selectedProjectId,
  });

  @override
  List<Object?> get props => [units, selectedProjectId];

  UnitsManagementLoaded copyWith({
    List<UnitModel>? units,
    String? selectedProjectId,
  }) {
    return UnitsManagementLoaded(
      units: units ?? this.units,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class UnitsManagementError extends UnitsManagementState {
  final String message;

  const UnitsManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

class UnitOperationSuccess extends UnitsManagementState {
  final String message;

  const UnitOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class UnitsManagementCubit extends Cubit<UnitsManagementState> {
  final UnitsRepository _unitsRepository;

  UnitsManagementCubit({
    required UnitsRepository unitsRepository,
  })  : _unitsRepository = unitsRepository,
        super(UnitsManagementInitial());

  Future<void> loadUnits({String? projectId}) async {
    emit(UnitsManagementLoading());
    try {
      final units = await _unitsRepository.getUnits(projectId: projectId);
      emit(UnitsManagementLoaded(
        units: units,
        selectedProjectId: projectId,
      ));
    } catch (e) {
      emit(UnitsManagementError(e.toString()));
    }
  }

  Future<void> addUnit(UnitModel unit) async {
    emit(UnitsManagementLoading());
    try {
      await _unitsRepository.addUnit(unit);
      
      // Reload to reflect changes
      // Check if we were filtering by the same project
      String? filterId;
      if (state is UnitsManagementLoaded) {
        filterId = (state as UnitsManagementLoaded).selectedProjectId;
      }
      
      // If the new unit belongs to the current filter or no filter, reload
      if (filterId == null || filterId == unit.projectId) {
         final units = await _unitsRepository.getUnits(projectId: filterId);
         emit(UnitsManagementLoaded(units: units, selectedProjectId: filterId));
      } else {
        // Just reload current view
         final units = await _unitsRepository.getUnits(projectId: filterId);
         emit(UnitsManagementLoaded(units: units, selectedProjectId: filterId));
      }
      // We might want to emit a success state briefly or use a listener
      // For simplicity, we just reload and stay in Loaded, 
      // but to show a snackbar we might need a side effect or loop.
      // Let's rely on the UI checking for state changes or explicit Success state if needed.
    } catch (e) {
      emit(UnitsManagementError(e.toString()));
      // Restore previous state if possible? 
      // For now, load default
      loadUnits(); 
    }
  }

  Future<void> updateUnit(UnitModel unit) async {
    // Optimistic update or reload? Reload is safer.
    emit(UnitsManagementLoading());
    try {
      await _unitsRepository.updateUnit(unit);
      
      String? filterId;
      if (state is UnitsManagementLoaded) {
        filterId = (state as UnitsManagementLoaded).selectedProjectId;
      }
      
      final units = await _unitsRepository.getUnits(projectId: filterId);
      emit(UnitsManagementLoaded(units: units, selectedProjectId: filterId));
    } catch (e) {
      emit(UnitsManagementError(e.toString()));
    }
  }

  Future<void> deleteUnit(String unitId) async {
    emit(UnitsManagementLoading());
    try {
      await _unitsRepository.deleteUnit(unitId);
      
       String? filterId;
      if (state is UnitsManagementLoaded) {
        filterId = (state as UnitsManagementLoaded).selectedProjectId;
      }
      
      final units = await _unitsRepository.getUnits(projectId: filterId);
      emit(UnitsManagementLoaded(units: units, selectedProjectId: filterId));
    } catch (e) {
      emit(UnitsManagementError(e.toString()));
    }
  }
}
