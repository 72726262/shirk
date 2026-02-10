import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/data/repositories/construction_repository.dart';

/// Construction Service - Handles construction tracking business logic
class ConstructionService {
  final ConstructionRepository _constructionRepository;

  ConstructionService({ConstructionRepository? constructionRepository})
      : _constructionRepository =
            constructionRepository ?? ConstructionRepository();

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
      return await _constructionRepository.createUpdate(
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
    } catch (e) {
      throw Exception('فشل إنشاء التحديث: ${e.toString()}');
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
