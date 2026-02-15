import 'dart:async';
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

// ========== UPDATED CUBIT WITH STREAM SUPPORT ==========
class ProjectsCubit extends Cubit<ProjectsState> {
  final ProjectRepository _projectRepository;
  
  // Stream subscriptions for real-time updates
  StreamSubscription<List<ProjectModel>>? _projectsSubscription;
  StreamSubscription<ProjectModel>? _projectDetailSubscription;
  StreamSubscription<List<UnitModel>>? _unitsSubscription;
  
  // Cache for null-safe fallback
  List<ProjectModel>? _cachedProjects;
  ProjectModel? _cachedProjectDetail;
  List<UnitModel>? _cachedUnits;

  ProjectsCubit({ProjectRepository? projectRepository})
      : _projectRepository = projectRepository ?? ProjectRepository(),
        super(ProjectsInitial());

  /// Load projects with REAL-TIME STREAM support
  void loadProjects({
    ProjectStatus? status,
    bool? featured,
    String? searchQuery,
  }) {
    emit(ProjectsLoading());
    
    // Cancel previous subscription
    _projectsSubscription?.cancel();
    
    print('📋 الاشتراك في البث المباشر للمشاريع...');
    
    // Subscribe to real-time stream
    _projectsSubscription = _projectRepository.getProjectsStream(
      status: status,
      featured: featured,
      searchQuery: searchQuery,
    ).listen(
      (projects) {
        print('🔄 تحديث جديد: ${projects.length} مشروع');
        
        // NULL-SAFE FALLBACK
        if (projects.isEmpty && _cachedProjects != null && _cachedProjects!.isNotEmpty) {
          print('⚠️ القائمة فارغة، الاحتفاظ بالبيانات المخبأة');
          return; // Keep showing cached projects
        }
        
        // Update cache
        _cachedProjects = projects;
        
        // Cache for offline access
        CacheService().cacheProjects(projects.map((p) => p.toJson()).toList());
        
        if (projects.isEmpty) {
          emit(ProjectsEmpty());
        } else {
          emit(ProjectsLoaded(projects));
        }
      },
      onError: (error) {
        print('❌ خطأ في البث المباشر للمشاريع: $error');
        
        // On error, show cached data if available
        if (_cachedProjects != null && _cachedProjects!.isNotEmpty) {
          print('📦 عرض البيانات المخبأة');
          emit(ProjectsLoaded(_cachedProjects!));
        } else {
          // Try cache service
          final cachedData = CacheService().getCachedProjects();
          if (cachedData != null && cachedData.isNotEmpty) {
            final projects = cachedData.map((json) => ProjectModel.fromJson(json)).toList();
            _cachedProjects = projects;
            emit(ProjectsLoaded(projects));
          } else {
            emit(ProjectsError(ErrorHandler.getErrorMessage(error)));
          }
        }
      },
    );
  }

  /// Load featured projects with REAL-TIME STREAM support
  void loadFeaturedProjects() {
    loadProjects(featured: true);
  }

  /// Load project detail with REAL-TIME STREAM support
  void loadProjectDetail(String projectId) {
    emit(ProjectDetailLoading());
    
    // Cancel previous subscriptions
    _projectDetailSubscription?.cancel();
    _unitsSubscription?.cancel();
    
    print('📋 الاشتراك في البث المباشر لتفاصيل المشروع: $projectId');
    
    // Subscribe to project details stream
    _projectDetailSubscription = _projectRepository.getProjectByIdStream(projectId).listen(
      (project) async {
        print('🔄 تحديث تفاصيل المشروع');
        
        _cachedProjectDetail = project;
        
        // Also subscribe to units stream
        _unitsSubscription?.cancel();
        _unitsSubscription = _projectRepository.getProjectUnitsStream(
          projectId: projectId,
        ).listen(
          (units) {
            print('🔄 تحديث الوحدات: ${units.length}');
            _cachedUnits = units;
            emit(ProjectDetailLoaded(project, units));
          },
          onError: (error) {
            print('❌ خطأ في تحميل الوحدات: $error');
            // Show project with cached units if available
            if (_cachedUnits != null) {
              emit(ProjectDetailLoaded(project, _cachedUnits!));
            } else {
              emit(ProjectDetailLoaded(project, []));
            }
          },
        );
      },
      onError: (error) {
        print('❌ خطأ في تحميل تفاصيل المشروع: $error');
        
        // Show cached data if available
        if (_cachedProjectDetail != null) {
          emit(ProjectDetailLoaded(
            _cachedProjectDetail!,
            _cachedUnits ?? [],
          ));
        } else {
          emit(ProjectsError(ErrorHandler.getErrorMessage(error)));
        }
      },
    );
  }

  /// Add new project (still uses Future since it's a write operation)
  Future<void> addProject(Map<String, dynamic> projectData) async {
    try {
      await _projectRepository.addProject(projectData);
      // No need to reload - stream will auto-update!
      print('✅ المشروع added - سيتم التحديث تلقائياً');
    } catch (e) {
      emit(ProjectsError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Update project (still uses Future since it's a write operation)
  Future<void> updateProject(String id, Map<String, dynamic> updates) async {
    try {
      await _projectRepository.updateProject(id, updates);
      // No need to reload - stream will auto-update!
      print('✅ المشروع updated - س يتم التحديث تلقائياً');
    } catch (e) {
      emit(ProjectsError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Delete project (still uses Future since it's a write operation)
  Future<void> deleteProject(String id) async {
    try {
      await _projectRepository.deleteProject(id);
      // No need to reload - stream will auto-update!
      print('✅ المشروع deleted - سيتم التحديث تلقائياً');
    } catch (e) {
      emit(ProjectsError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Upload project image
  Future<String?> uploadProjectImage(String projectId, String filePath, String fileName) async {
    try {
      return await _projectRepository.uploadProjectImage(projectId, filePath, fileName);
    } catch (e) {
      emit(ProjectsError(ErrorHandler.getErrorMessage(e)));
      return null;
    }
  }

  /// Add construction update
  Future<void> addConstructionUpdate({
    required String projectId,
    required int weekNumber,
    required double completionPercentage,
    String? notes,
    List<String>? images,
    List<String>? videos,
    bool notifyClients = false,
  }) async {
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
      // Stream will auto-update!
      print('✅ تم إضافة تحديث البناء - سيتم التحديث تلقائياً');
    } catch (e) {
      emit(ProjectsError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Search projects
  void searchProjects(String query) {
    loadProjects(searchQuery: query);
  }

  /// Filter projects by status
  void filterProjects(ProjectStatus? status) {
    loadProjects(status: status);
  }

  /// Refresh (same as load since we use streams)
  Future<void> refreshProjects() async {
    loadProjects();
  }

  @override
  Future<void> close() {
    // CRITICAL: Cancel all subscriptions to prevent memory leaks
    _projectsSubscription?.cancel();
    _projectDetailSubscription?.cancel();
    _unitsSubscription?.cancel();
    return super.close();
  }
}
