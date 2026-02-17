import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/data/repositories/construction_repository.dart';
import 'package:mmm/data/services/storage_service.dart';

/// Construction Service - Handles construction tracking business logic
class ConstructionService {
  final ConstructionRepository _constructionRepository;
  final StorageService _storageService;

  ConstructionService({
    ConstructionRepository? constructionRepository,
    StorageService? storageService,
  })  : _constructionRepository =
            constructionRepository ?? ConstructionRepository(),
        _storageService = storageService ?? StorageService();

  // Get all construction updates for a project
  Future<List<ConstructionUpdateModel>> getConstructionUpdates(
    String projectId,
  ) async {
    try {
      return await _constructionRepository.getConstructionUpdates(projectId: projectId);
    } catch (e) {
      throw Exception('فشل تحميل تحديثات البناء: ${e.toString()}');
    }
  }

  // Get updates by week number
  Future<List<ConstructionUpdateModel>> getUpdatesByWeek({
    required String projectId,
    required int weekNumber,
  }) async {
    try {
      return await _constructionRepository.getUpdatesByWeek(
        projectId: projectId,
        weekNumber: weekNumber,
      );
    } catch (e) {
      throw Exception('فشل تحميل تحديثات الأسبوع: ${e.toString()}');
    }
  }

  // Get latest update for a project
  Future<ConstructionUpdateModel?> getLatestUpdate(String projectId) async {
    try {
      return await _constructionRepository.getLatestUpdate(projectId);
    } catch (e) {
      throw Exception('فشل تحميل آخر تحديث: ${e.toString()}');
    }
  }

  // Real-time construction updates stream
  Stream<List<ConstructionUpdateModel>> watchConstructionUpdates(
    String projectId,
  ) {
    try {
      return _constructionRepository.watchConstructionUpdates(projectId);
    } catch (e) {
      throw Exception('فشل الاشتراك في التحديثات: ${e.toString()}');
    }
  }

  // Admin: Create construction update with media uploads
  Future<List<ConstructionUpdateModel>> getUserConstructionUpdates(String userId) async {
    return _constructionRepository.getUserConstructionUpdates(userId);
  }

  Future<ConstructionUpdateModel> createUpdate({
    required String projectId,
    required String title,
    required String titleAr,
    String? description,
    String? descriptionAr,
    required UpdateType type,
    double? completionPercentage,
    int? weekNumber,
    List<String>? photosPaths,
    List<String>? videosPaths,
    String? engineeringReportPath,
    String? financialReportPath,
    String? supervisionReportPath,
    bool isPublic = true,
    bool notifyClients = true,
  }) async {
    try {
      // 1. Create the update record first to get the ID
      final update = await _constructionRepository.createUpdate(
        projectId: projectId,
        title: title,
        titleAr: titleAr,
        description: description,
        descriptionAr: descriptionAr,
        type: type,
        completionPercentage: completionPercentage,
        weekNumber: weekNumber,
        isPublic: isPublic,
        notifyClients: notifyClients,
      );

      // 2. Upload photos to construction-media bucket
      if (photosPaths != null && photosPaths.isNotEmpty) {
        await _constructionRepository.uploadProgressMedia(
          projectId: projectId,
          updateId: update.id,
          filePaths: photosPaths,
          mediaType: 'photo',
        );
      }

      // 3. Upload videos to construction-media bucket
      if (videosPaths != null && videosPaths.isNotEmpty) {
        await _constructionRepository.uploadProgressMedia(
          projectId: projectId,
          updateId: update.id,
          filePaths: videosPaths,
          mediaType: 'video',
        );
      }

      // 4. Upload reports to reports bucket
      if (engineeringReportPath != null) {
        await _constructionRepository.uploadReport(
          updateId: update.id,
          filePath: engineeringReportPath,
          reportType: 'engineering',
        );
      }

      if (financialReportPath != null) {
        await _constructionRepository.uploadReport(
          updateId: update.id,
          filePath: financialReportPath,
          reportType: 'financial',
        );
      }

      if (supervisionReportPath != null) {
        await _constructionRepository.uploadReport(
          updateId: update.id,
          filePath: supervisionReportPath,
          reportType: 'supervision',
        );
      }

      // 5. Notify subscribers if requested
      if (notifyClients) {
        await _constructionRepository.notifySubscribers(projectId, titleAr, update.id);
      }

      return update;
    } catch (e) {
      throw Exception('فشل إنشاء التحديث: ${e.toString()}');
    }
  }
  
  // Get updates for specific user's projects
  Future<List<ConstructionUpdateModel>> getUserProjectUpdates(String userId) async {
    try {
      // This would need to get user's subscriptions first then fetch updates
      // For now, return empty list - implement properly when needed
      return [];
    } catch (e) {
      throw Exception('فشل تحميل تحديثات المستخدم: ${e.toString()}');
    }
  }

  // Get construction timeline (grouped by week/month)
  Future<Map<String, List<ConstructionUpdateModel>>> getConstructionTimeline(
    String projectId,
  ) async {
    try {
      final updates = await _constructionRepository.getConstructionUpdates(
        projectId: projectId,
      );

      // Group by month
      final timeline = <String, List<ConstructionUpdateModel>>{};
      for (final update in updates) {
        final monthKey = '${update.createdAt.year}-${update.createdAt.month.toString().padLeft(2, '0')}';
        timeline.putIfAbsent(monthKey, () => []).add(update);
      }

      return timeline;
    } catch (e) {
      throw Exception('فشل تحميل الخط الزمني: ${e.toString()}');
    }
  }

  // Get construction progress summary
  Future<Map<String, dynamic>> getProgressSummary(String projectId) async {
    try {
      final updates = await _constructionRepository.getConstructionUpdates(
        projectId: projectId,
      );
      final latestUpdate = await _constructionRepository.getLatestUpdate(
        projectId,
      );

      return {
        'total_updates': updates.length,
        'latest_update': latestUpdate,
        'completion_percentage': latestUpdate?.progressPercentage ?? 0.0,
        'milestones': updates
            .where((u) => u.type == UpdateType.milestone)
            .length,
        'issues': updates
            .where((u) => u.type == UpdateType.delay) // Assuming delay maps to issues/delays concept
            .length,
        'delays': updates
            .where((u) => u.type == UpdateType.delay)
            .length,
      };
    } catch (e) {
      throw Exception('فشل تحميل ملخص التقدم: ${e.toString()}');
    }
  }
}
