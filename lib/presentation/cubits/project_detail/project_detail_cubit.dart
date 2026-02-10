import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/repositories/project_repository.dart';
import 'package:mmm/data/services/project_service.dart';

// States
abstract class ProjectDetailState extends Equatable {
  const ProjectDetailState();

  @override
  List<Object?> get props => [];
}

class ProjectDetailInitial extends ProjectDetailState {}

class ProjectDetailLoading extends ProjectDetailState {}

class ProjectDetailLoaded extends ProjectDetailState {
  final ProjectModel project;
  final List<UnitModel> allUnits;
  final List<UnitModel> availableUnits;
  final List<UnitModel> soldUnits;
  final List<UnitModel> reservedUnits;
  final Map<String, dynamic> stats;

  const ProjectDetailLoaded({
    required this.project,
    required this.allUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.reservedUnits,
    required this.stats,
  });

  @override
  List<Object?> get props => [
    project,
    allUnits,
    availableUnits,
    soldUnits,
    reservedUnits,
    stats,
  ];
}

class ProjectDetailError extends ProjectDetailState {
  final String message;

  const ProjectDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ProjectDetailCubit extends Cubit<ProjectDetailState> {
  final ProjectService _projectService;

  ProjectDetailCubit({ProjectRepository? projectRepository})
    : _projectService = ProjectService(projectRepository: projectRepository),
      super(ProjectDetailInitial());

  Future<void> loadProjectDetail(String projectId) async {
    emit(ProjectDetailLoading());
    try {
      final details = await _projectService.getProjectDetails(projectId);
      final stats = await _projectService.getProjectStats(projectId);

      emit(
        ProjectDetailLoaded(
          project: details['project'] as ProjectModel,
          allUnits: details['units'] as List<UnitModel>,
          availableUnits: details['availableUnits'] as List<UnitModel>,
          soldUnits: details['soldUnits'] as List<UnitModel>,
          reservedUnits: details['reservedUnits'] as List<UnitModel>,
          stats: stats,
        ),
      );
    } catch (e) {
      emit(ProjectDetailError(e.toString()));
    }
  }

  Future<void> refreshProject(String projectId) async {
    await loadProjectDetail(projectId);
  }

  Future<void> reserveUnit(String projectId, String unitId) async {
    if (state is! ProjectDetailLoaded) return;

    try {
      await _projectService.reserveUnit(unitId);
      // Reload project to get updated units
      await loadProjectDetail(projectId);
    } catch (e) {
      emit(ProjectDetailError(e.toString()));
    }
  }
}
