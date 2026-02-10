import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class HandoverRepository {
  final SupabaseService _supabaseService;

  HandoverRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ============ BASIC HANDOVER OPERATIONS ============

  // Get handover by subscription ID
  Future<HandoverModel?> getHandoverBySubscription(
    String subscriptionId,
  ) async {
    try {
      final response = await _client
          .from('handovers')
          .select('*, defects(*)')
          .eq('subscription_id', subscriptionId)
          .maybeSingle();

      if (response == null) return null;
      return HandoverModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل الاستلام: ${e.toString()}');
    }
  }

  // Get handover by Unit ID
  Future<HandoverModel?> getHandoverByUnit(String unitId) async {
    try {
      final response = await _client
          .from('handovers')
          .select('*, defects(*)')
          .eq('unit_id', unitId)
          .maybeSingle();

      if (response == null) return null;
      return HandoverModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل الاستلام: ${e.toString()}');
    }
  }

  // Get handover by ID
  Future<HandoverModel> getHandoverById(String handoverId) async {
    try {
      final response = await _client
          .from('handovers')
          .select('*, defects(*)')
          .eq('id', handoverId)
          .single();

      return HandoverModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل الاستلام: ${e.toString()}');
    }
  }

  // Create handover (when subscription is ready)
  Future<HandoverModel> createHandover({
    required String subscriptionId,
    required String userId,
    required String projectId,
    String? unitId,
  }) async {
    try {
      final handoverData = {
        'subscription_id': subscriptionId,
        'user_id': userId,
        'project_id': projectId,
        'unit_id': unitId,
        'status': 'not_started',
        'defects_count': 0,
        'defects_fixed': 0,
      };

      final response = await _client
          .from('handovers')
          .insert(handoverData)
          .select('*, defects(*)')
          .single();

      return HandoverModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إنشاء الاستلام: ${e.toString()}');
    }
  }

  // ============ APPOINTMENT OPERATIONS ============

  // Book appointment
  Future<void> bookAppointment({
    required String handoverId,
    required DateTime appointmentDate,
    required String location,
    String? notes,
  }) async {
    try {
      await _client
          .from('handovers')
          .update({
            'appointment_date': appointmentDate.toIso8601String(),
            'appointment_location': location,
            'appointment_notes': notes,
            'status': 'appointment_booked',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في حجز الموعد: ${e.toString()}');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment({
    required String handoverId,
    required DateTime newAppointmentDate,
    String? reason,
  }) async {
    try {
      await _client
          .from('handovers')
          .update({
            'appointment_date': newAppointmentDate.toIso8601String(),
            'reschedule_reason': reason,
            'status': 'appointment_booked',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في إعادة جدولة الموعد: ${e.toString()}');
    }
  }

  // ============ DEFECT OPERATIONS ============

  // Submit defect (snag list)
  Future<void> submitDefect({
    required String handoverId,
    required String category,
    required String description,
    String? location,
    String? severity,
    List<String>? photosPaths,
  }) async {
    try {
      // Upload photos if provided
      List<String> photoUrls = [];
      if (photosPaths != null && photosPaths.isNotEmpty) {
        for (var i = 0; i < photosPaths.length; i++) {
          final url = await _supabaseService.uploadFile(
            bucketName: 'defect_photos',
            path:
                'handovers/$handoverId/defects/photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            filePath: photosPaths[i],
          );
          photoUrls.add(url);
        }
      }

      // Create defect
      final defectData = {
        'handover_id': handoverId,
        'category': category,
        'description': description,
        'location': location,
        'severity': severity ?? 'medium',
        'photos': photoUrls,
        'status': 'pending',
        'reported_at': DateTime.now().toIso8601String(),
      };

      await _client.from('defects').insert(defectData);

      // Update handover defects count
      final handover = await getHandoverById(handoverId);
      await _client
          .from('handovers')
          .update({
            'defects_count': handover.defectsCount + 1,
            'status': 'defects_submitted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في إضافة العيب: ${e.toString()}');
    }
  }

  // Get defects for handover
  Future<List<Map<String, dynamic>>> getDefects(String handoverId) async {
    try {
      final response = await _client
          .from('defects')
          .select()
          .eq('handover_id', handoverId)
          .order('reported_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطأ في تحميل العيوب: ${e.toString()}');
    }
  }

  // Update defect status (Admin)
  Future<void> updateDefectStatus({
    required String defectId,
    required String status,
    String? adminComment,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminComment != null) {
        updates['admin_comment'] = adminComment;
      }

      if (status == 'fixed') {
        updates['fixed_at'] = DateTime.now().toIso8601String();
      }

      await _client.from('defects').update(updates).eq('id', defectId);

      // Update handover defects_fixed count
      final defect = await _client
          .from('defects')
          .select('handover_id')
          .eq('id', defectId)
          .single();

      final fixedCount = await _client
          .from('defects')
          .select()
          .eq('handover_id', defect['handover_id'])
          .eq('status', 'fixed')
          .count();

      await _client
          .from('handovers')
          .update({
            'defects_fixed': fixedCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', defect['handover_id']);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العيب: ${e.toString()}');
    }
  }

  // Update defect photo
  Future<void> updateDefectPhoto({
    required String defectId,
    required String photoPath,
  }) async {
    try {
      // Upload new photo
      final photoUrl = await _supabaseService.uploadFile(
        bucketName: 'defect_photos',
        path:
            'defects/$defectId/update_${DateTime.now().millisecondsSinceEpoch}.jpg',
        filePath: photoPath,
      );

      // Get existing photos
      final defect = await _client
          .from('defects')
          .select('photos, handover_id')
          .eq('id', defectId)
          .single();

      List<String> photos = List<String>.from(defect['photos'] ?? []);
      photos.add(photoUrl);

      await _client
          .from('defects')
          .update({
            'photos': photos,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', defectId);
    } catch (e) {
      throw Exception('خطأ في تحديث صورة العيب: ${e.toString()}');
    }
  }

  // Update defect comment
  Future<void> updateDefectComment({
    required String defectId,
    required String comment,
  }) async {
    try {
      await _client
          .from('defects')
          .update({
            'admin_comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', defectId);
    } catch (e) {
      throw Exception('خطأ في تحديث تعليق العيب: ${e.toString()}');
    }
  }

  // Mark defect as fixing
  Future<void> markDefectAsFixing({
    required String defectId,
    String? estimatedCompletionDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': 'fixing',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (estimatedCompletionDate != null) {
        updates['estimated_completion_date'] = estimatedCompletionDate;
      }

      await _client.from('defects').update(updates).eq('id', defectId);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العيب: ${e.toString()}');
    }
  }

  // Mark defect as fixed
  Future<void> markDefectAsFixed({
    required String defectId,
    String? fixNotes,
    List<String>? afterPhotos,
  }) async {
    try {
      // Upload after photos if provided
      List<String> afterPhotoUrls = [];
      if (afterPhotos != null && afterPhotos.isNotEmpty) {
        for (var i = 0; i < afterPhotos.length; i++) {
          final url = await _supabaseService.uploadFile(
            bucketName: 'defect_photos',
            path:
                'defects/$defectId/after_fix_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            filePath: afterPhotos[i],
          );
          afterPhotoUrls.add(url);
        }
      }

      final updates = <String, dynamic>{
        'status': 'fixed',
        'fixed_at': DateTime.now().toIso8601String(),
        'fix_notes': fixNotes,
        'after_photos': afterPhotoUrls,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('defects').update(updates).eq('id', defectId);

      // Update handover defects_fixed count
      final defect = await _client
          .from('defects')
          .select('handover_id')
          .eq('id', defectId)
          .single();

      final fixedCount = await _client
          .from('defects')
          .select()
          .eq('handover_id', defect['handover_id'])
          .eq('status', 'fixed')
          .count();

      await _client
          .from('handovers')
          .update({
            'defects_fixed': fixedCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', defect['handover_id']);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العيب: ${e.toString()}');
    }
  }

  // Update defect information
  Future<void> updateDefect({
    required String defectId,
    String? description,
    String? location,
    String? severity,
    String? category,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (severity != null) updates['severity'] = severity;
      if (category != null) updates['category'] = category;

      await _client.from('defects').update(updates).eq('id', defectId);
    } catch (e) {
      throw Exception('خطأ في تحديث العيب: ${e.toString()}');
    }
  }

  // Get defect by ID
  Future<Map<String, dynamic>> getDefectById(String defectId) async {
    try {
      final response = await _client
          .from('defects')
          .select()
          .eq('id', defectId)
          .single();

      return response;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات العيب: ${e.toString()}');
    }
  }

  // ============ HANDOVER COMPLETION ============

  // Sign handover
  Future<void> signHandover({
    required String handoverId,
    required String signatureData,
  }) async {
    try {
      // Upload signature
      final signatureUrl = await _supabaseService.uploadFile(
        bucketName: 'signatures',
        path:
            'handovers/$handoverId/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        filePath: signatureData,
      );

      // Update handover
      await _client
          .from('handovers')
          .update({
            'handover_signed_at': DateTime.now().toIso8601String(),
            'signature_url': signatureUrl,
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في توقيع الاستلام: ${e.toString()}');
    }
  }

  // Cancel handover
  Future<void> cancelHandover({
    required String handoverId,
    required String reason,
  }) async {
    try {
      await _client
          .from('handovers')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في إلغاء الاستلام: ${e.toString()}');
    }
  }

  // ============ CERTIFICATE GENERATION ============

  // Generate handover certificate
  Future<String> generateCertificate(String handoverId) async {
    try {
      // TODO: Implement PDF generation
      final certificateUrl = 'certificates/handover_$handoverId.pdf';

      await _client
          .from('handovers')
          .update({
            'handover_certificate_url': certificateUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);

      return certificateUrl;
    } catch (e) {
      throw Exception('خطأ في إنشاء شهادة الاستلام: ${e.toString()}');
    }
  }

  // ============ UTILITY FUNCTIONS ============

  // Check if all defects are fixed
  Future<bool> areAllDefectsFixed(String handoverId) async {
    try {
      final handover = await getHandoverById(handoverId);
      return handover.defectsCount == handover.defectsFixed;
    } catch (e) {
      return false;
    }
  }

  // Update handover status
  Future<void> updateHandoverStatus({
    required String handoverId,
    required HandoverStatus status,
  }) async {
    try {
      await _client
          .from('handovers')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الاستلام: ${e.toString()}');
    }
  }

  // Get all handovers for user
  Future<List<HandoverModel>> getUserHandovers(String userId) async {
    try {
      final response = await _client
          .from('handovers')
          .select('*, defects(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HandoverModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب قائمة الاستلام: ${e.toString()}');
    }
  }

  // Get handover statistics
  Future<Map<String, dynamic>> getHandoverStats(String handoverId) async {
    try {
      final handover = await getHandoverById(handoverId);
      final defects = await getDefects(handoverId);

      final totalDefects = defects.length;
      final pendingDefects = defects
          .where((d) => d['status'] == 'pending')
          .length;
      final fixedDefects = defects.where((d) => d['status'] == 'fixed').length;
      final criticalDefects = defects
          .where((d) => d['severity'] == 'critical')
          .length;
      final inProgressDefects = defects
          .where((d) => d['status'] == 'fixing')
          .length;

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
        // 'overall_progress': handover.completionPercentage,
        'status': handover.status.name,
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات الاستلام: ${e.toString()}');
    }
  }

  // Get defect statistics by category
  Future<Map<String, int>> getDefectsByCategory(String handoverId) async {
    try {
      final defects = await getDefects(handoverId);
      final Map<String, int> result = {};

      for (final defect in defects) {
        final category = defect['category'] as String;
        result[category] = (result[category] ?? 0) + 1;
      }

      return result;
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات الفئات: ${e.toString()}');
    }
  }

  // Get defect statistics by severity
  Future<Map<String, int>> getDefectsBySeverity(String handoverId) async {
    try {
      final defects = await getDefects(handoverId);
      final Map<String, int> result = {};

      for (final defect in defects) {
        final severity = defect['severity'] as String;
        result[severity] = (result[severity] ?? 0) + 1;
      }

      return result;
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات الخطورة: ${e.toString()}');
    }
  }

  // Delete handover (admin only)
  Future<void> deleteHandover(String handoverId) async {
    try {
      // First delete all defects
      await _client.from('defects').delete().eq('handover_id', handoverId);

      // Then delete handover
      await _client.from('handovers').delete().eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في حذف الاستلام: ${e.toString()}');
    }
  }

  // Complete handover preparation
  Future<void> completePreparation({
    required String handoverId,
    required bool isReadyForHandover,
    String? preparationNotes,
  }) async {
    try {
      await _client
          .from('handovers')
          .update({
            'is_ready_for_handover': isReadyForHandover,
            'preparation_notes': preparationNotes,
            'status': isReadyForHandover
                ? 'ready_for_handover'
                : 'defects_fixing',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', handoverId);
    } catch (e) {
      throw Exception('خطأ في إكمال التحضير: ${e.toString()}');
    }
  }

  // Send handover notification
  Future<void> sendNotification({
    required String handoverId,
    required String notificationType,
    required String message,
  }) async {
    try {
      final handover = await getHandoverById(handoverId);

      // Create notification record
      await _client.from('handover_notifications').insert({
        'handover_id': handoverId,
        'user_id': handover.userId,
        'notification_type': notificationType,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('خطأ في إرسال الإشعار: ${e.toString()}');
    }
  }

  // Get handover notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _client
          .from('handover_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطأ في جلب الإشعارات: ${e.toString()}');
    }
  }
}
