import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class ProjectRepository {
  final SupabaseService _supabaseService;
  
  ProjectRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // Get all projects with filters
  Future<List<ProjectModel>> getProjects({
    ProjectStatus? status,
    bool? featured,
    bool? isActive,
    String? searchQuery,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('projects')
          .select('*');

      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (featured != null) {
        query = query.eq('featured', featured);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,name_ar.ilike.%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل المشاريع: ${e.toString()}');
    }
  }

  // Get project by ID
  Future<ProjectModel> getProjectById(String projectId) async {
    try {
      final response = await _client
          .from('projects')
          .select()
          .eq('id', projectId)
          .single();

      return ProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل المشروع: ${e.toString()}');
    }
  }

  // Get featured projects
  Future<List<ProjectModel>> getFeaturedProjects() async {
    return await getProjects(featured: true, isActive: true, limit: 10);
  }

  // Get project units
  Future<List<UnitModel>> getProjectUnits({
    required String projectId,
    UnitStatus? status,
  }) async {
    try {
      var query = _client
          .from('units')
          .select('*')
          .eq('project_id', projectId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('unit_number');
      return (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل الوحدات: ${e.toString()}');
    }
  }

  // Get available units only
  Future<List<UnitModel>> getAvailableUnits(String projectId) async {
    return await getProjectUnits(
      projectId: projectId,
      status: UnitStatus.available,
    );
  }

  // Get unit by ID
  Future<UnitModel> getUnitById(String unitId) async {
    try {
      final response = await _client
          .from('units')
          .select()
          .eq('id', unitId)
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل الوحدة: ${e.toString()}');
    }
  }

  // Reserve unit
  Future<void> reserveUnit(String unitId) async {
    try {
      await _client
          .from('units')
          .update({
            'status': 'reserved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', unitId);
    } catch (e) {
      throw Exception('خطأ في حجز الوحدة: ${e.toString()}');
    }
  }

  // Mark unit as sold
  Future<void> markUnitAsSold(String unitId) async {
    try {
      await _client
          .from('units')
          .update({
            'status': 'sold',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', unitId);

      // Update project sold units count
      final unit = await getUnitById(unitId);
      final project = await getProjectById(unit.projectId);
      
      await _client
          .from('projects')
          .update({
            'sold_units': project.soldUnits + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', unit.projectId);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الوحدة: ${e.toString()}');
    }
  }

  // Create project (Admin only)
  Future<ProjectModel> createProject({
    required String name,
    required String nameAr,
    String? description,
    String? descriptionAr,
    required String locationName,
    double? locationLat,
    double? locationLng,
    double? pricePerSqm,
    double? minInvestment,
    double? maxInvestment,
    DateTime? startDate,
    DateTime? expectedCompletionDate,
    String? heroImageUrl,
    List<String>? renderImages,
  }) async {
    try {
      final projectData = {
        'name': name,
        'name_ar': nameAr,
        'description': description,
        'description_ar': descriptionAr,
        'status': 'upcoming',
        'location_name': locationName,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'price_per_sqm': pricePerSqm,
        'min_investment': minInvestment,
        'max_investment': maxInvestment,
        'start_date': startDate?.toIso8601String(),
        'expected_completion_date': expectedCompletionDate?.toIso8601String(),
        'hero_image_url': heroImageUrl,
        'render_images': renderImages ?? [],
        'total_units': 0,
        'sold_units': 0,
        'reserved_units': 0,
        'completion_percentage': 0,
        'total_partners': 0,
        'featured': false,
        'is_active': true,
        'created_by': _client.auth.currentUser?.id,
      };

      final response = await _client
          .from('projects')
          .insert(projectData)
          .select()
          .single();

      return ProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إنشاء المشروع: ${e.toString()}');
    }
  }

  // Update project (Admin only)
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
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (nameAr != null) updates['name_ar'] = nameAr;
      if (description != null) updates['description'] = description;
      if (descriptionAr != null) updates['description_ar'] = descriptionAr;
      if (status != null) updates['status'] = status.name;
      if (completionPercentage != null) {
        updates['completion_percentage'] = completionPercentage;
      }
      if (actualCompletionDate != null) {
        updates['actual_completion_date'] = actualCompletionDate.toIso8601String();
      }
      if (featured != null) updates['featured'] = featured;
      if (isActive != null) updates['is_active'] = isActive;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('projects')
          .update(updates)
          .eq('id', projectId)
          .select()
          .single();

      return ProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث المشروع: ${e.toString()}');
    }
  }

  // Upload project images
  Future<String> uploadProjectImage({
    required String projectId,
    required String filePath,
    required String imageType, // hero, render, etc
  }) async {
    try {
      final imageUrl = await _supabaseService.uploadFile(
        bucketName: 'project_images',
        path: 'projects/$projectId/${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        filePath: filePath,
      );

      return imageUrl;
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: ${e.toString()}');
    }
  }

  // Get project statistics
  Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    try {
      final project = await getProjectById(projectId);
      final units = await getProjectUnits(projectId: projectId);

      final availableUnits = units.where((u) => u.status == UnitStatus.available).length;
      final reservedUnits = units.where((u) => u.status == UnitStatus.reserved).length;
      final soldUnits = units.where((u) => u.status == UnitStatus.sold).length;

      return {
        'total_units': units.length,
        'available_units': availableUnits,
        'reserved_units': reservedUnits,
        'sold_units': soldUnits,
        'completion_percentage': project.completionPercentage,
        'total_partners': project.totalPartners,
        'status': project.status.name,
      };
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات المشروع: ${e.toString()}');
    }
  }
}
