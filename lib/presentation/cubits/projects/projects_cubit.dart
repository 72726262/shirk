import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/repositories/project_repository.dart';

// States
abstract class ProjectsState extends Equatable {
  const ProjectsState();

  @override
  List<Object?> get props => [];
}

class ProjectsInitial extends ProjectsState {}

class ProjectsLoading extends ProjectsState {}

class ProjectsLoaded extends ProjectsState {
  final List<ProjectModel> projects;

  const ProjectsLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

class ProjectsEmpty extends ProjectsState {}

class ProjectsError extends ProjectsState {
  final String message;

  const ProjectsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProjectDetailLoading extends ProjectsState {}

class ProjectDetailLoaded extends ProjectsState {
  final ProjectModel project;
  final List<UnitModel> units;

  const ProjectDetailLoaded(this.project, this.units);

  @override
  List<Object?> get props => [project, units];
}

// Cubit
class ProjectsCubit extends Cubit<ProjectsState> {
  final ProjectRepository _projectRepository;

  ProjectsCubit({ProjectRepository? projectRepository})
      : _projectRepository = projectRepository ?? ProjectRepository(),
        super(ProjectsInitial());

  Future<void> loadProjects({
    ProjectStatus? status,
    bool? featured,
    String? searchQuery,
  }) async {
    emit(ProjectsLoading());
    try {
      final projects = await _projectRepository.getProjects(
        status: status,
        featured: featured,
        searchQuery: searchQuery,
      );

      if (projects.isEmpty) {
        emit(ProjectsEmpty());
      } else {
        emit(ProjectsLoaded(projects));
      }
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> loadFeaturedProjects() async {
    emit(ProjectsLoading());
    try {
      final projects = await _projectRepository.getFeaturedProjects();
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> loadProjectDetail(String projectId) async {
    emit(ProjectDetailLoading());
    try {
      final project = await _projectRepository.getProjectById(projectId);
      final units = await _projectRepository.getProjectUnits(
        projectId: projectId,
      );
      emit(ProjectDetailLoaded(project, units));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> searchProjects(String query) async {
    await loadProjects(searchQuery: query);
  }

  Future<void> refreshProjects() async {
    await loadProjects();
  }

  Future<void> filterProjects(ProjectStatus? status) async {
    await loadProjects(status: status);
  }
}
