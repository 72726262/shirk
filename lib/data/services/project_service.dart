import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/repositories/project_repository.dart';

/// Project Service - Handles project and unit business logic
class ProjectService {
  final ProjectRepository _projectRepository;

  ProjectService({ProjectRepository? projectRepository})
    : _projectRepository = projectRepository ?? ProjectRepository();

  // Browse all projects with filters
  Future<List<ProjectModel>> browseProjects({
    ProjectStatus? status,
    bool? featured,
    String? searchQuery,
  }) async {
    try {
      return await _projectRepository.getProjects(
        status: status,
        featured: featured,
        searchQuery: searchQuery,
      );
    } catch (e) {
      throw Exception('فشل تحميل المشاريع: ${e.toString()}');
    }
  }

  // Get featured projects only
  Future<List<ProjectModel>> getFeaturedProjects() async {
    try {
      return await _projectRepository.getFeaturedProjects();
    } catch (e) {
      throw Exception('فشل تحميل المشاريع المميزة: ${e.toString()}');
    }
  }

  // Get project details with units
  Future<Map<String, dynamic>> getProjectDetails(String projectId) async {
    try {
      final project = await _projectRepository.getProjectById(projectId);
      final units = await _projectRepository.getProjectUnits(
        projectId: projectId,
      );

      return {
        'project': project,
        'units': units,
        'availableUnits': units
            .where((u) => u.status == UnitStatus.available)
            .toList(),
        'soldUnits': units.where((u) => u.status == UnitStatus.sold).toList(),
        'reservedUnits': units
            .where((u) => u.status == UnitStatus.reserved)
            .toList(),
      };
    } catch (e) {
      throw Exception('فشل تحميل تفاصيل المشروع: ${e.toString()}');
    }
  }

  // Get available units for a project
  Future<List<UnitModel>> getAvailableUnits(String projectId) async {
    try {
      return await _projectRepository.getProjectUnits(
        projectId: projectId,
        status: UnitStatus.available.name,
      );
    } catch (e) {
      throw Exception('فشل تحميل الوحدات المتاحة: ${e.toString()}');
    }
  }

  // Search projects
  Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      if (query.isEmpty) {
        return await browseProjects();
      }
      return await _projectRepository.getProjects(searchQuery: query);
    } catch (e) {
      throw Exception('فشل البحث: ${e.toString()}');
    }
  }

  // Get project statistics
  Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    try {
      final stats = await _projectRepository.getProjectStats(projectId);
      final project = await _projectRepository.getProjectById(projectId);

      return {
        ...stats,
        'completion_percentage': project.completionPercentage,
        'status': project.status,
      };
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات المشروع: ${e.toString()}');
    }
  }

  // Admin: Create project with image upload
  Future<ProjectModel> createProject({
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
    try {
      // 1. Upload Hero Image if provided
      String? heroImageUrl;
      if (heroImagePath != null) {
        // We use a temporary project ID for path, or just a timestamp based path since we don't have ID yet
        // A better approach is to let Supabase generate ID or use a temp ID.
        // For now, using a timestamp based folder to avoid collisions before project creation
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        heroImageUrl = await _projectRepository.uploadProjectImage(
          'new_$tempId',
          heroImagePath,
          'hero_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // 2. Upload Render Images if provided
      List<String> renderImages = [];
      if (renderImagePaths != null && renderImagePaths.isNotEmpty) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        for (var path in renderImagePaths) {
          final url = await _projectRepository.uploadProjectImage(
            'new_$tempId',
            path,
            'render_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          renderImages.add(url);
        }
      }

      return await _projectRepository.createProject({
        'name': name,
        'name_ar': nameAr,
        'description': description,
        'description_ar': descriptionAr,
        'location_name': locationName ?? '',
        'location_lat': locationLat,
        'location_lng': locationLng,
        'price_per_sqm': pricePerSqm,
        'min_investment': minInvestment,
        'max_investment': maxInvestment,
        'start_date': startDate?.toIso8601String(),
        'expected_completion_date': expectedCompletionDate?.toIso8601String(),
        'hero_image_url': heroImageUrl,
        'render_images': renderImages,
        'total_units': totalUnits,
        'status': status.name,
      });
    } catch (e) {
      throw Exception('فشل إنشاء المشروع: ${e.toString()}');
    }
  }

  // Admin: Update project
  Future<ProjectModel> updateProject({
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
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (nameAr != null) updates['name_ar'] = nameAr;
      if (description != null) updates['description'] = description;
      if (descriptionAr != null) updates['description_ar'] = descriptionAr;
      if (status != null) updates['status'] = status.name;
      if (completionPercentage != null) updates['completion_percentage'] = completionPercentage;
      if (actualCompletionDate != null) updates['actual_completion_date'] = actualCompletionDate.toIso8601String();
      if (featured != null) updates['featured'] = featured;
      
      return await _projectRepository.updateProject(projectId, updates);
    } catch (e) {
      throw Exception('فشل تحديث المشروع: ${e.toString()}');
    }
  }

  // Reserve unit
  Future<UnitModel> reserveUnit(String unitId) async {
    try {
      await _projectRepository.reserveUnit(unitId);
      return await _projectRepository.getUnitById(unitId);
    } catch (e) {
      throw Exception('فشل حجز الوحدة: ${e.toString()}');
    }
  }
}
