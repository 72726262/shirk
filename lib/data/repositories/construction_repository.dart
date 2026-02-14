import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class ConstructionRepository {
  final SupabaseService _supabaseService;
  
  ConstructionRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // Get construction updates for a project
  Future<List<ConstructionUpdateModel>> getConstructionUpdates({
    required String projectId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('construction_updates')
          .select('*')
          .eq('project_id', projectId)
          .eq('is_public', true)
          .order('update_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ConstructionUpdateModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل تحديثات البناء: ${e.toString()}');
    }
  }

  // Get update by ID
  Future<ConstructionUpdateModel> getUpdateById(String updateId) async {
    try {
      final response = await _client
          .from('construction_updates')
          .select('*')
          .eq('id', updateId)
          .single();

      return ConstructionUpdateModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل التحديث: ${e.toString()}');
    }
  }

  // Subscribe to real-time construction updates
  Stream<List<ConstructionUpdateModel>> watchConstructionUpdates(String projectId) {
    return _client
        .from('construction_updates')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId) // Filter by project
        .order('update_date', ascending: false)
        .map((data) => (data)
            .where((json) => json['is_public'] == true) // Filter public client-side if stream doesn't support multiple filters
            .map((json) => ConstructionUpdateModel.fromJson(json))
            .toList());
  }

  // Create construction update (Admin only)
  Future<ConstructionUpdateModel> createUpdate({
    required String projectId,
    required String title,
    required String titleAr,
    String? description,
    String? descriptionAr,
    required UpdateType type,
    double? completionPercentage,
    int? weekNumber,
    List<String>? photos,
    List<String>? videos,
    String? engineeringReportUrl,
    String? financialReportUrl,
    String? supervisionReportUrl,
    bool isPublic = true,
    bool notifyClients = true,
  }) async {
    try {
      final updateData = {
        'project_id': projectId,
        'title': title,
        'title_ar': titleAr,
        'description': description,
        'description_ar': descriptionAr,
        'update_type': type.name,
        'completion_percentage': completionPercentage,
        'week_number': weekNumber,
        'photos': photos,
        'videos': videos,
        'engineering_report_url': engineeringReportUrl,
        'financial_report_url': financialReportUrl,
        'supervision_report_url': supervisionReportUrl,
        'is_public': isPublic,
        'notify_clients': notifyClients,
        'update_date': DateTime.now().toIso8601String().split('T')[0],
        'created_by': _client.auth.currentUser?.id,
      };

      final response = await _client
          .from('construction_updates')
          .insert(updateData)
          .select()
          .single();

      final update = ConstructionUpdateModel.fromJson(response);

      // Update project completion percentage if provided
      if (completionPercentage != null) {
        await _client
            .from('projects')
            .update({
              'completion_percentage': completionPercentage,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId);
      }

      return update;
    } catch (e) {
      throw Exception('خطأ في إنشاء التحديث: ${e.toString()}');
    }
  }

  // Upload progress photos/videos
  Future<List<String>> uploadProgressMedia({
    required String projectId,
    required String updateId,
    required List<String> filePaths,
    required String mediaType, // photo or video
  }) async {
    try {
      final urls = <String>[];

      for (var i = 0; i < filePaths.length; i++) {
        // Use StorageService constant or correct string 'construction-media'
        final url = await _supabaseService.uploadFile(
          bucketName: 'construction-media', 
          path: 'projects/$projectId/updates/$updateId/${mediaType}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          filePath: filePaths[i],
        );
        urls.add(url);
      }

      // Update construction update with media URLs
      final update = await getUpdateById(updateId);
      final currentPhotos = List<String>.from(update.photos);
      final currentVideos = List<String>.from(update.videos);

      if (mediaType == 'photo') {
        currentPhotos.addAll(urls);
      } else {
        currentVideos.addAll(urls);
      }

      await _client
          .from('construction_updates')
          .update({
            'photos': currentPhotos,
            'videos': currentVideos,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', updateId);

      return urls;
    } catch (e) {
      throw Exception('خطأ في رفع الوسائط: ${e.toString()}');
    }
  }

  // Upload engineering/financial/supervision reports
  Future<void> uploadReport({
    required String updateId,
    required String filePath,
    required String reportType, // engineering, financial, supervision
  }) async {
    try {
      // Use correct bucket name 'reports'
      final url = await _supabaseService.uploadFile(
        bucketName: 'reports',
        path: 'updates/$updateId/${reportType}_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        filePath: filePath,
      );

      final updates = <String, dynamic>{};
      if (reportType == 'engineering') {
        updates['engineering_report_url'] = url;
      } else if (reportType == 'financial') {
        updates['financial_report_url'] = url;
      } else if (reportType == 'supervision') {
        updates['supervision_report_url'] = url;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('construction_updates')
          .update(updates)
          .eq('id', updateId);
    } catch (e) {
      throw Exception('خطأ في رفع التقرير: ${e.toString()}');
    }
  }

  // Get latest update for project
  Future<ConstructionUpdateModel?> getLatestUpdate(String projectId) async {
    try {
      final response = await _client
          .from('construction_updates')
          .select('*')
          .eq('project_id', projectId)
          .eq('is_public', true)
          .order('update_date', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return ConstructionUpdateModel.fromJson(response.first);
    } catch (e) {
      return null;
    }
  }

  // Get updates by week number
  Future<List<ConstructionUpdateModel>> getUpdatesByWeek({
    required String projectId,
    required int weekNumber,
  }) async {
    try {
      final response = await _client
          .from('construction_updates')
          .select('*')
          .eq('project_id', projectId)
          .eq('week_number', weekNumber)
          .order('update_date', ascending: false);

      return (response as List)
          .map((json) => ConstructionUpdateModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل تحديثات الأسبوع: ${e.toString()}');
    }
  }
}
