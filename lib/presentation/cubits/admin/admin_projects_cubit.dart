import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/services/project_service.dart';
import 'package:mmm/data/services/admin_service.dart';

// States
abstract class AdminProjectsState extends Equatable {
  const AdminProjectsState();

  @override
  List<Object?> get props => [];
}

class AdminProjectsInitial extends AdminProjectsState {}

class AdminProjectsLoading extends AdminProjectsState {}

class AdminProjectsLoaded extends AdminProjectsState {
  final List<ProjectModel> projects;

  const AdminProjectsLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

class AdminProjectsProcessing extends AdminProjectsState {
  final String message;

  const AdminProjectsProcessing(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminProjectsError extends AdminProjectsState {
  final String message;

  const AdminProjectsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AdminProjectsCubit extends Cubit<AdminProjectsState> {
  final ProjectService _projectService;
  final AdminService _adminService;

  AdminProjectsCubit({
    ProjectService? projectService,
    AdminService? adminService,
  })  : _projectService = projectService ?? ProjectService(),
        _adminService = adminService ?? AdminService(),
        super(AdminProjectsInitial());

  Future<void> loadProjects({
    ProjectStatus? status,
    String? searchQuery,
  }) async {
    emit(AdminProjectsLoading());
    try {
      final projects = await _projectService.browseProjects(
        status: status,
        searchQuery: searchQuery,
      );

      emit(AdminProjectsLoaded(projects));
    } catch (e) {
      emit(AdminProjectsError(e.toString()));
    }
  }

  Future<void> createProject({
    required String name,
    required String nameAr,
    String? description,
    String? descriptionAr,
    required ProjectStatus status,
    String? locationName,
    double? locationLat,
    double? locationLng,
    double? pricePerSqm,
    double? minInvestment,
    double? maxInvestment,
    int totalUnits = 0,
    DateTime? startDate,
    DateTime? expectedCompletionDate,
    String? heroImagePath,
    List<String>? renderImagePaths,
  }) async {
    emit(const AdminProjectsProcessing('جاري إنشاء المشروع...'));
    try {
      final project = await _projectService.createProject(
        name: name,
        nameAr: nameAr,
        description: description,
        descriptionAr: descriptionAr,
        status: status,
        locationName: locationName,
        locationLat: locationLat,
        locationLng: locationLng,
        pricePerSqm: pricePerSqm,
        minInvestment: minInvestment,
        maxInvestment: maxInvestment,
        totalUnits: totalUnits,
        startDate: startDate,
        expectedCompletionDate: expectedCompletionDate,
        heroImagePath: heroImagePath,
        renderImagePaths: renderImagePaths,
      );

      await _adminService.logActivity(
        action: 'PROJECT_CREATED',
        entityType: 'projects',
        entityId: project.id,
        description: 'تم إنشاء مشروع: $name',
      );

      await loadProjects();
    } catch (e) {
      emit(AdminProjectsError(e.toString()));
    }
  }

  Future<void> updateProject({
    required String projectId,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    ProjectStatus? status,
    double? completionPercentage,
    DateTime? actualCompletionDate,
    bool? featured,
  }) async {
    emit(const AdminProjectsProcessing('جاري التحديث...'));
    try {
      await _projectService.updateProject(
        projectId: projectId,
        name: name,
        nameAr: nameAr,
        description: description,
        descriptionAr: descriptionAr,
        status: status,
        completionPercentage: completionPercentage,
        actualCompletionDate: actualCompletionDate,
        featured: featured,
      );

      await _adminService.logActivity(
        action: 'PROJECT_UPDATED',
        entityType: 'projects',
        entityId: projectId,
        description: 'تم تحديث المشروع',
      );

      await loadProjects();
    } catch (e) {
      emit(AdminProjectsError(e.toString()));
    }
  }
}
