import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/repositories/project_repository.dart';
import 'package:mmm/core/services/cache_service.dart';
import 'package:mmm/core/utils/error_handler.dart';

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

      // Cache the projects data for offline access
      await CacheService().cacheProjects(
        projects.map((p) => p.toJson()).toList(),
      );

      if (projects.isEmpty) {
        emit(ProjectsEmpty());
      } else {
        emit(ProjectsLoaded(projects));
      }
    } catch (e) {
      // Try to load from cache when network fails
      final cachedProjects = CacheService().getCachedProjects();
      if (cachedProjects != null && cachedProjects.isNotEmpty) {
        final projects = cachedProjects
            .map((json) => ProjectModel.fromJson(json))
            .toList();
        emit(ProjectsLoaded(projects));
      } else {
        emit(ProjectsError(ErrorHandler.getErrorMessage(e)));
      }
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

  // Admin Actions
  Future<void> addProject(Map<String, dynamic> projectData) async {
    emit(ProjectsLoading());
    try {
      await _projectRepository.addProject(projectData);
      await loadProjects(); // Reload list
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> updates) async {
    emit(ProjectsLoading());
    try {
      await _projectRepository.updateProject(id, updates);
      await loadProjects();
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> deleteProject(String id) async {
    emit(ProjectsLoading());
    try {
      await _projectRepository.deleteProject(id);
      await loadProjects();
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> addConstructionUpdate({
    required String projectId,
    required int weekNumber,
    required double completionPercentage,
    String? notes,
    List<String>? images,
    List<String>? videos,
    bool notifyClients = false,
  }) async {
    // We don't necessarily need to emit Loading here if we want to keep the UI responsive or handling it locally
    // But for consistency let's just do the operation and optionally reload
    try {
      await _projectRepository.addConstructionUpdate(
        projectId: projectId,
        weekNumber: weekNumber,
        completionPercentage: completionPercentage,
        notes: notes,
        images: images,
        videos: videos,
        notifyClients: notifyClients,
      );
      // Reload projects to update progress
      await loadProjects();
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }
}
