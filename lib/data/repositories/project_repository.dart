import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';

class ProjectRepository {
  final SupabaseClient _client;

  ProjectRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ========== FUTURE-BASED METHODS (Original) ==========

  Future<List<ProjectModel>> getProjects({
    ProjectStatus? status,
    bool? featured,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('projects').select();

      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (featured != null) {
        query = query.eq('featured', featured);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name_ar', '%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('فشل تحميل المشاريع: ${e.toString()}');
    }
  }

  Future<List<ProjectModel>> getFeaturedProjects() async {
    return getProjects(featured: true);
  }

  Future<ProjectModel> getProjectById(String id) async {
    try {
      final response =
          await _client.from('projects').select().eq('id', id).single();
      return ProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل تحميل تفاصيل المشروع: ${e.toString()}');
    }
  }

  Future<ProjectModel> addProject(Map<String, dynamic> projectData) async {
    try {
      final response =
          await _client.from('projects').insert(projectData).select().single();
      return ProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل إضافة المشروع: ${e.toString()}');
    }
  }

  Future<ProjectModel> updateProject(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response =
          await _client
              .from('projects')
              .update(updates)
              .eq('id', id)
              .select()
              .single();
      return ProjectModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل تحديث المشروع: ${e.toString()}');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _client.from('projects').delete().eq('id', id);
    } catch (e) {
      throw Exception('فشل حذف المشروع: ${e.toString()}');
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
    try {
      await _client
          .from('construction_updates')
          .insert({
            'project_id': projectId,
            'week_number': weekNumber,
            'completion_percentage': completionPercentage,
            'notes': notes,
            'images': images ?? [],
            'videos': videos ?? [],
            'created_at': DateTime.now().toIso8601String(),
          });

      await updateProject(
        projectId,
        {'completion_percentage': completionPercentage},
      );

      if (notifyClients) {
        final project = await getProjectById(projectId);
      }
    } catch (e) {
      throw Exception('خطأ في إضافة تحديث التنفيذ: ${e.toString()}');
    }
  }

  Future<List<UnitModel>> getProjectUnits({
    required String projectId,
    String? status,
  }) async {
    try {
      var query = _client.from('units').select().eq('project_id', projectId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('unit_number', ascending: true);

      return (response as List).map((json) => UnitModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل تحميل الوحدات: ${e.toString()}');
    }
  }

  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    return addProject(data);
  }

  Future<String> uploadProjectImage(String projectId, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final path = '$projectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _client.storage.from('project-images').upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      return _client.storage.from('project-images').getPublicUrl(path);
    } catch (e) {
      throw Exception('فشل رفع الصورة: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    try {
      final project = await getProjectById(projectId);
      return {
        'total_units': project.totalUnits,
        'sold_units': project.soldUnits,
        'reserved_units': project.reservedUnits,
        'available_units': project.availableUnits,
      };
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات المشروع: ${e.toString()}');
    }
  }

  Future<UnitModel> getUnitById(String unitId) async {
    try {
      final response = await _client
          .from('units')
          .select()
          .eq('id', unitId)
          .single();
      return UnitModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل تحميل الوحدة: ${e.toString()}');
    }
  }

  Future<void> reserveUnit(String unitId) async {
    try {
      await _client
          .from('units')
          .update({'status': UnitStatus.reserved.name})
          .eq('id', unitId);
    } catch (e) {
      throw Exception('فشل حجز الوحدة: ${e.toString()}');
    }
  }

  // ========== STREAM-BASED METHODS (Real-time) ==========

  /// Get projects with real-time updates
  Stream<List<ProjectModel>> getProjectsStream({
    ProjectStatus? status,
    bool? featured,
    String? searchQuery,
  }) {
    return _client
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      var filtered = data;

      // Apply filters
      if (status != null) {
        filtered = filtered.where((p) => p['status'] == status.name).toList();
      }
      if (featured != null) {
        filtered = filtered.where((p) => p['featured'] == featured).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filtered = filtered.where((p) => 
          p['name_ar']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false
        ).toList();
      }

      return filtered.map((json) => ProjectModel.fromJson(json)).toList();
    });
  }

  /// Get featured projects with real-time updates
  Stream<List<ProjectModel>> getFeaturedProjectsStream() {
    return getProjectsStream(featured: true);
  }

  /// Get single project by ID with real-time updates
  Stream<ProjectModel> getProjectByIdStream(String id) {
    return _client
        .from('projects')
        .stream(primaryKey: ['id'])
        .map((data) {
          final project = data.firstWhere(
            (p) => p['id'] == id,
            orElse: () => throw Exception('المشروع غير موجود'),
          );
          return ProjectModel.fromJson(project);
        });
  }

  /// Get project units with real-time updates
  Stream<List<UnitModel>> getProjectUnitsStream({
    required String projectId,
    String? status,
  }) {
    return _client
        .from('units')
        .stream(primaryKey: ['id'])
        .order('unit_number', ascending: true)
        .map((data) {
      var filtered = data.where((u) => u['project_id'] == projectId).toList();

      if (status != null) {
        filtered = filtered.where((u) => u['status'] == status).toList();
      }

      return filtered.map((json) => UnitModel.fromJson(json)).toList();
    });
  }

  /// Get project stats with real-time updates
  Stream<Map<String, dynamic>> getProjectStatsStream(String projectId) {
    return getProjectByIdStream(projectId).map((project) => {
      'total_units': project.totalUnits,
      'sold_units': project.soldUnits,
      'reserved_units': project.reservedUnits,
      'available_units': project.availableUnits,
    });
  }

  /// Get single unit by ID with real-time updates
  Stream<UnitModel> getUnitByIdStream(String unitId) {
    return _client
        .from('units')
        .stream(primaryKey: ['id'])
        .map((data) {
          final unit = data.firstWhere(
            (u) => u['id'] == unitId,
            orElse: () => throw Exception('الوحدة غير موجودة'),
          );
          return UnitModel.fromJson(unit);
        });
  }
}
