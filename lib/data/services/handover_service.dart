import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/data/repositories/handover_repository.dart';
import 'package:mmm/data/services/storage_service.dart';

/// Handover Service - Handles unit handover process business logic
class HandoverService {
  final HandoverRepository _handoverRepository;
  final StorageService _storageService;

  HandoverService({
    HandoverRepository? handoverRepository,
    StorageService? storageService,
  }) : _handoverRepository = handoverRepository ?? HandoverRepository(),
       _storageService = storageService ?? StorageService();

  // Get handover by subscription ID
  Future<HandoverModel?> getHandoverBySubscription(
    String subscriptionId,
  ) async {
    try {
      return await _handoverRepository.getHandoverBySubscription(
        subscriptionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get all handovers for a user
  Future<List<HandoverModel>> getUserHandovers(String userId) async {
    try {
      return await _handoverRepository.getUserHandovers(userId);
    } catch (e) {
      throw Exception('فشل تحميل التسليمات: ${e.toString()}');
    }
  }

  // Get handovers stream
  Stream<List<HandoverModel>> getUserHandoversStream(String userId) {
    return _handoverRepository.getUserHandoversStream(userId);
  }

  // Get subscription ID by user and project
  Future<String?> getSubscriptionId({
    required String userId,
    required String projectId,
  }) async {
    try {
      return await _handoverRepository.getSubscriptionId(
        userId: userId,
        projectId: projectId,
      );
    } catch (e) {
      // Return null or rethrow? For now, return null as it's a helper
      return null;
    }
  }

  // Create new handover
  Future<HandoverModel> createHandover({
    required String userId,
    required String projectId,
    String? subscriptionId,
    required DateTime appointmentDate,
    String? appointmentLocation,
    String? notes,
  }) async {
    try {
      return await _handoverRepository.createHandover(
        userId: userId,
        projectId: projectId,
        subscriptionId: subscriptionId,
        appointmentDate: appointmentDate,
        appointmentLocation: appointmentLocation,
        notes: notes,
      );
    } catch (e) {
      print("object" + e.toString());
      throw Exception('فشل إنشاء التسليم: ${e.toString()}');
    }
  }

  // Book appointment for handover
  Future<HandoverModel> bookAppointment({
    required String handoverId,
    required DateTime appointmentDate,
    required String location,
    String? notes,
  }) async {
    try {
      await _handoverRepository.bookAppointment(
        handoverId: handoverId,
        appointmentDate: appointmentDate,
        location: location,
        notes: notes,
      );
      return await _handoverRepository.getHandoverById(handoverId);
    } catch (e) {
      throw Exception('فشل حجز الموعد: ${e.toString()}');
    }
  }

  // Get handover details with defects
  Future<Map<String, dynamic>> getHandoverDetails(String handoverId) async {
    try {
      final handover = await _handoverRepository.getHandoverById(handoverId);
      final defectsData = await _handoverRepository.getDefects(handoverId);
      final defects = defectsData.map((d) => DefectModel.fromJson(d)).toList();

      return {
        'handover': handover,
        'defects': defects,
        'pending_defects': defects
            .where((d) => d.status.name != 'fixed')
            .length,
        'fixed_defects': defects.where((d) => d.status.name == 'fixed').length,
        'critical_defects': defects
            .where((d) => d.severity == DefectSeverity.critical)
            .length,
        'completion_percentage': defects.isNotEmpty
            ? (defects.where((d) => d.status.name == 'fixed').length /
                      defects.length *
                      100)
                  .round()
            : 100,
      };
    } catch (e) {
      throw Exception('فشل تحميل تفاصيل التسليم: ${e.toString()}');
    }
  }

  // Submit defect with photos
  Future<void> submitDefect({
    required String handoverId,
    required String category,
    required String description,
    required String severity,
    String? location,
    List<String>? photosPaths,
  }) async {
    try {
      // Upload defect photos to construction-media bucket
      List<String>? photoUrls;
      if (photosPaths != null && photosPaths.isNotEmpty) {
        photoUrls = [];
        for (final photoPath in photosPaths) {
          // Get project ID from handover (assuming we have it in context)
          final handover = await _handoverRepository.getHandoverById(
            handoverId,
          );
          final projectId = handover.projectId ?? 'unknown';

          final url = await _storageService.uploadConstructionMedia(
            photoPath,
            projectId,
            isVideo: false,
          );
          photoUrls.add(url);
        }
      }

      await _handoverRepository.submitDefect(
        handoverId: handoverId,
        category: category,
        description: description,
        severity: severity,
        location: location,
        photosPaths: photoUrls,
      );
    } catch (e) {
      throw Exception('فشل إرسال العيب: ${e.toString()}');
    }
  }

  // Get all defects for a handover
  Future<List<DefectModel>> getDefects(String handoverId) async {
    try {
      final defectsData = await _handoverRepository.getDefects(handoverId);
      return defectsData.map((d) => DefectModel.fromJson(d)).toList();
    } catch (e) {
      throw Exception('فشل تحميل قائمة العيوب: ${e.toString()}');
    }
  }

  // Admin: Update defect status
  Future<void> updateDefectStatus({
    required String defectId,
    required String status,
    String? adminComment,
  }) async {
    try {
      await _handoverRepository.updateDefectStatus(
        defectId: defectId,
        status: status,
        adminComment: adminComment,
      );
    } catch (e) {
      throw Exception('فشل تحديث حالة العيب: ${e.toString()}');
    }
  }

  // Sign handover with signature upload
  Future<HandoverModel> signHandover({
    required String handoverId,
    required String signaturePath,
  }) async {
    try {
      // Validate all defects are fixed before signing
      final defects = await _handoverRepository.getDefects(handoverId);
      final pendingDefects = defects
          .where((d) => d.toString() != DefectStatus.fixed)
          .length;

      if (pendingDefects > 0) {
        throw Exception(
          'يجب إصلاح جميع العيوب قبل التوقيع ($pendingDefects عيب معلق)',
        );
      }

      await _handoverRepository.signHandover(
        handoverId: handoverId,
        signatureData: signaturePath,
      );

      return await _handoverRepository.getHandoverById(handoverId);
    } catch (e) {
      throw Exception('فشل توقيع التسليم: ${e.toString()}');
    }
  }

  // Generate handover certificate
  Future<String> generateCertificate(String handoverId) async {
    try {
      return await _handoverRepository.generateCertificate(handoverId);
    } catch (e) {
      throw Exception('فشل إنشاء شهادة التسليم: ${e.toString()}');
    }
  }

  // Get handover progress
  Future<Map<String, dynamic>> getHandoverProgress(String handoverId) async {
    try {
      final handover = await _handoverRepository.getHandoverById(handoverId);

      // Calculate progress based on status
      int progressPercentage = 0;
      switch (handover.status) {
        case HandoverStatus.notStarted:
          progressPercentage = 0;
          break;
        case HandoverStatus.appointmentBooked:
          progressPercentage = 20;
          break;
        case HandoverStatus.inProgress:
          progressPercentage = 20;
          break;
        case HandoverStatus.scheduled:
          progressPercentage = 30;
          break;
        case HandoverStatus.inspectionPending:
          progressPercentage = 40;
          break;
        case HandoverStatus.defectsSubmitted:
          progressPercentage = 60;
          break;
        case HandoverStatus.defectsFixing:
          progressPercentage = 80;
          break;
        case HandoverStatus.readyForHandover:
          progressPercentage = 90;
          break;
        case HandoverStatus.completed:
          progressPercentage = 100;
          break;
        case HandoverStatus.cancelled:
          progressPercentage = 0;
          break;
      }

      return {
        'handover': handover,
        'progress_percentage': progressPercentage,
        'current_step': handover.status.name,
        'is_completed': handover.status == HandoverStatus.completed,
        'can_sign': handover.status == HandoverStatus.readyForHandover,
      };
    } catch (e) {
      throw Exception('فشل تحميل تقدم التسليم: ${e.toString()}');
    }
  }

  // --- Convenience methods for HandoverCubit (Unit ID based) ---

  Future<Map<String, dynamic>> getHandoverStatus(String unitId) async {
    try {
      final handover = await _handoverRepository.getHandoverByUnit(unitId);
      if (handover == null) {
        return {'status': 'not_started', 'defects_count': 0};
      }
      return {
        'status': handover.status.name,
        'defects_count': handover.defectsCount,
        'handover_id': handover.id,
      };
    } catch (e) {
      throw Exception('فشل جلب حالة التسليم: ${e.toString()}');
    }
  }

  Future<List<DefectModel>> getSnags(String unitId) async {
    try {
      final handover = await _handoverRepository.getHandoverByUnit(unitId);
      if (handover == null) throw Exception('لا يوجد تسليم لهذه الوحدة');
      return await getDefects(handover.id);
    } catch (e) {
      throw Exception('فشل جلب العيوب: ${e.toString()}');
    }
  }

  Future<void> addSnag(String unitId, DefectModel snag) async {
    try {
      final handover = await _handoverRepository.getHandoverByUnit(unitId);
      if (handover == null) throw Exception('لا يوجد تسليم لهذه الوحدة');

      await submitDefect(
        handoverId: handover.id,
        category: snag.category.name,
        description: snag.description,
        severity: snag.severity.name,
        location: snag.location,
        photosPaths: snag.photos,
      );
    } catch (e) {
      throw Exception('فشل إضافة العيب: ${e.toString()}');
    }
  }

  Future<HandoverModel> completeHandover(
    String unitId,
    String signatureData,
  ) async {
    try {
      final handover = await _handoverRepository.getHandoverByUnit(unitId);
      if (handover == null) throw Exception('لا يوجد تسليم لهذه الوحدة');

      return await signHandover(
        handoverId: handover.id,
        signaturePath: signatureData,
      );
    } catch (e) {
      throw Exception('فشل إكمال التسليم: ${e.toString()}');
    }
  }

  // ============ الدوال الجديدة المطلوبة ============

  // تحديث صورة العيب
  Future<void> updateDefectPhoto({
    required String defectId,
    required String photoPath,
  }) async {
    try {
      await _handoverRepository.updateDefectPhoto(
        defectId: defectId,
        photoPath: photoPath,
      );
    } catch (e) {
      throw Exception('فشل تحديث صورة العيب: ${e.toString()}');
    }
  }

  // إضافة/تحديث تعليق إداري على العيب
  Future<void> updateDefectComment({
    required String defectId,
    required String comment,
  }) async {
    try {
      await _handoverRepository.updateDefectComment(
        defectId: defectId,
        comment: comment,
      );
    } catch (e) {
      throw Exception('فشل تحديث تعليق العيب: ${e.toString()}');
    }
  }

  // الحصول على إحصائيات التسليم
  Future<Map<String, dynamic>> getHandoverStats(String handoverId) async {
    try {
      final handover = await _handoverRepository.getHandoverById(handoverId);
      final defects = await getDefects(handoverId);

      final totalDefects = defects.length;
      final pendingDefects = defects.where((d) => d.isPending).length;
      final fixedDefects = defects.where((d) => d.isFixed).length;
      final criticalDefects = defects.where((d) => d.isCritical).length;
      final inProgressDefects = defects.where((d) => d.isFixing).length;

      final completionRate = totalDefects > 0
          ? (fixedDefects / totalDefects) * 100
          : 100.0;

      return {
        'handover_id': handoverId,
        'total_defects': totalDefects,
        'pending_defects': pendingDefects,
        'fixed_defects': fixedDefects,
        'critical_defects': criticalDefects,
        'in_progress_defects': inProgressDefects,
        'completion_rate': completionRate,
        // 'overall_progress': handover.ov,
        'status': handover.status.name,
        'defects_by_category': _groupDefectsByCategory(defects),
        'defects_by_severity': _groupDefectsBySeverity(defects),
      };
    } catch (e) {
      throw Exception('فشل جلب إحصائيات التسليم: ${e.toString()}');
    }
  }

  // الحصول على التسليم بواسطة الـ ID
  Future<HandoverModel> getHandoverById(String handoverId) async {
    try {
      return await _handoverRepository.getHandoverById(handoverId);
    } catch (e) {
      throw Exception('فشل جلب بيانات التسليم: ${e.toString()}');
    }
  }

  // الحصول على التسليم بواسطة الوحدة
  Future<HandoverModel?> getHandoverByUnit(String unitId) async {
    try {
      return await _handoverRepository.getHandoverByUnit(unitId);
    } catch (e) {
      return null;
    }
  }

  // إعادة جدولة موعد التسليم
  Future<HandoverModel> rescheduleAppointment({
    required String handoverId,
    required DateTime newAppointmentDate,
    String? reason,
  }) async {
    try {
      await _handoverRepository.rescheduleAppointment(
        handoverId: handoverId,
        newAppointmentDate: newAppointmentDate,
        reason: reason,
      );
      return await _handoverRepository.getHandoverById(handoverId);
    } catch (e) {
      throw Exception('فشل إعادة جدولة الموعد: ${e.toString()}');
    }
  }

  // إلغاء التسليم
  Future<HandoverModel> cancelHandover({
    required String handoverId,
    required String reason,
  }) async {
    try {
      await _handoverRepository.cancelHandover(
        handoverId: handoverId,
        reason: reason,
      );
      return await _handoverRepository.getHandoverById(handoverId);
    } catch (e) {
      throw Exception('فشل إلغاء التسليم: ${e.toString()}');
    }
  }

  // تحديث حالة العيب إلى "قيد الإصلاح"
  Future<void> markDefectAsFixing({
    required String defectId,
    String? estimatedCompletionDate,
  }) async {
    try {
      await _handoverRepository.markDefectAsFixing(
        defectId: defectId,
        estimatedCompletionDate: estimatedCompletionDate,
      );
    } catch (e) {
      throw Exception('فشل تحديث حالة العيب: ${e.toString()}');
    }
  }

  // تحديث حالة العيب إلى "مُصلح"
  Future<void> markDefectAsFixed({
    required String defectId,
    String? fixNotes,
    List<String>? afterPhotos,
  }) async {
    try {
      await _handoverRepository.markDefectAsFixed(
        defectId: defectId,
        fixNotes: fixNotes,
        afterPhotos: afterPhotos,
      );
    } catch (e) {
      throw Exception('فشل تحديث حالة العيب: ${e.toString()}');
    }
  }

  // ============ دوال مساعدة خاصة ============

  // تجميع العيوب حسب الفئة
  Map<String, int> _groupDefectsByCategory(List<DefectModel> defects) {
    final Map<String, int> result = {};

    for (final defect in defects) {
      final category = defect.category.name;
      result[category] = (result[category] ?? 0) + 1;
    }

    return result;
  }

  // تجميع العيوب حسب الخطورة
  Map<String, int> _groupDefectsBySeverity(List<DefectModel> defects) {
    final Map<String, int> result = {};

    for (final defect in defects) {
      final severity = defect.severity.name;
      result[severity] = (result[severity] ?? 0) + 1;
    }

    return result;
  }

  // التحقق من جاهزية التسليم للتوقيع
  Future<bool> isReadyForSigning(String handoverId) async {
    try {
      final defects = await getDefects(handoverId);
      final pendingDefects = defects.where((d) => !d.isFixed).length;
      return pendingDefects == 0;
    } catch (e) {
      return false;
    }
  }

  // الحصول على العيوب المعلقة
  Future<List<DefectModel>> getPendingDefects(String handoverId) async {
    try {
      final defects = await getDefects(handoverId);
      return defects.where((d) => d.isPending).toList();
    } catch (e) {
      return [];
    }
  }

  // الحصول على العيوب الحرجة
  Future<List<DefectModel>> getCriticalDefects(String handoverId) async {
    try {
      final defects = await getDefects(handoverId);
      return defects.where((d) => d.isCritical).toList();
    } catch (e) {
      return [];
    }
  }

  // تحديث معلومات العيب
  Future<void> updateDefect({
    required String defectId,
    String? description,
    String? location,
    DefectSeverity? severity,
    DefectCategory? category,
  }) async {
    try {
      await _handoverRepository.updateDefect(
        defectId: defectId,
        description: description,
        location: location,
        severity: severity?.name,
        category: category?.name,
      );
    } catch (e) {
      throw Exception('فشل تحديث العيب: ${e.toString()}');
    }
  }
}
