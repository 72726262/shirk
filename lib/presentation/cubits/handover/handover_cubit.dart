import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/data/services/handover_service.dart';

// States
abstract class HandoverState extends Equatable {
  const HandoverState();

  @override
  List<Object?> get props => [];
}

class HandoverInitial extends HandoverState {}

class HandoverLoading extends HandoverState {}

class HandoverLoaded extends HandoverState {
  final HandoverModel handover;
  final List<DefectModel> defects;
  final int pendingDefects;
  final int fixedDefects;
  final int criticalDefects;
  final int completionPercentage;
  final Map<String, dynamic> progress;

  const HandoverLoaded({
    required this.handover,
    required this.defects,
    required this.pendingDefects,
    required this.fixedDefects,
    required this.criticalDefects,
    required this.completionPercentage,
    required this.progress,
  });

  @override
  List<Object?> get props => [
    handover,
    defects,
    pendingDefects,
    fixedDefects,
    criticalDefects,
    completionPercentage,
    progress,
  ];
}

class HandoverSubmittingDefect extends HandoverState {
  final String message;

  const HandoverSubmittingDefect(this.message);

  @override
  List<Object?> get props => [message];
}

class HandoverSigning extends HandoverState {
  final String message;

  const HandoverSigning(this.message);

  @override
  List<Object?> get props => [message];
}

class HandoverComplete extends HandoverState {
  final HandoverModel handover;
  final String certificateUrl;

  const HandoverComplete({
    required this.handover,
    required this.certificateUrl,
  });

  @override
  List<Object?> get props => [handover, certificateUrl];
}

class HandoverError extends HandoverState {
  final String message;

  const HandoverError(this.message);

  @override
  List<Object?> get props => [message];
}

class HandoverStatusLoaded extends HandoverState {
  final String status;
  final Map<String, dynamic> data;

  const HandoverStatusLoaded({required this.status, required this.data});

  @override
  List<Object?> get props => [status, data];
}

class AppointmentBooked extends HandoverState {
  final DateTime appointmentDate;

  const AppointmentBooked(this.appointmentDate);

  @override
  List<Object?> get props => [appointmentDate];
}

class SnagAdded extends HandoverState {
  final DefectModel snag;

  const SnagAdded(this.snag);

  @override
  List<Object?> get props => [snag];
}

class SnagsLoaded extends HandoverState {
  final List<DefectModel> snags;

  const SnagsLoaded(this.snags);

  @override
  List<Object?> get props => [snags];

  List<DefectModel> get defects => snags;
}

class DefectsLoaded extends HandoverState {
  final List<DefectModel> defects;

  const DefectsLoaded(this.defects);

  @override
  List<Object?> get props => [defects];
}

class HandoverCompleted extends HandoverState {
  final HandoverModel handover;

  const HandoverCompleted(this.handover);

  @override
  List<Object?> get props => [handover];
}

// Cubit
class HandoverCubit extends Cubit<HandoverState> {
  final HandoverService _handoverService;

  HandoverCubit({HandoverService? handoverService})
    : _handoverService = handoverService ?? HandoverService(),
      super(HandoverInitial());

  // تحميل تفاصيل التسليم
  Future<void> loadHandover(String handoverId) async {
    emit(HandoverLoading());
    try {
      final details = await _handoverService.getHandoverDetails(handoverId);
      final progress = await _handoverService.getHandoverProgress(handoverId);

      emit(
        HandoverLoaded(
          handover: details['handover'] as HandoverModel,
          defects: details['defects'] as List<DefectModel>,
          pendingDefects: details['pending_defects'] as int,
          fixedDefects: details['fixed_defects'] as int,
          criticalDefects: details['critical_defects'] as int,
          completionPercentage: details['completion_percentage'] as int,
          progress: progress,
        ),
      );
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // تحميل التسليم عن طريق الاشتراك
  Future<void> loadBySubscription(String subscriptionId) async {
    emit(HandoverLoading());
    try {
      final handover = await _handoverService.getHandoverBySubscription(
        subscriptionId,
      );
      await loadHandover(handover!.id);
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // حجز موعد للتسليم
  Future<void> bookAppointment({
    required String handoverId,
    required DateTime appointmentDate,
    String? location,
    String? notes,
  }) async {
    try {
      await _handoverService.bookAppointment(
        handoverId: handoverId,
        appointmentDate: appointmentDate,
        location: location ?? 'موقع التسليم الرئيسي',
        notes: notes,
      );

      await loadHandover(handoverId);
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // حجز موعد للوحدة
  Future<void> bookAppointmentForUnit({
    required String unitId,
    required DateTime appointmentDate,
    String? location,
    String? notes,
  }) async {
    try {
      final status = await _handoverService.getHandoverStatus(unitId);
      final handoverId = status['handover_id'] as String?;

      if (handoverId != null) {
        await bookAppointment(
          handoverId: handoverId,
          appointmentDate: appointmentDate,
          location: location,
          notes: notes,
        );
      } else {
        emit(const HandoverError('لم يتم العثور على تسليم لهذه الوحدة'));
      }
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // إضافة عيب
  Future<void> submitDefect({
    required String handoverId,
    required String category,
    required String description,
    required String severity,
    String? location,
    List<String>? photosPaths,
  }) async {
    emit(const HandoverSubmittingDefect('جاري إضافة العيب...'));
    try {
      await _handoverService.submitDefect(
        handoverId: handoverId,
        category: category,
        description: description,
        severity: severity,
        location: location,
        photosPaths: photosPaths,
      );

      await loadHandover(handoverId);
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // توقيع التسليم
  Future<void> signHandover({
    required String handoverId,
    required String signaturePath,
  }) async {
    emit(const HandoverSigning('جاري التوقيع...'));
    try {
      final signedHandover = await _handoverService.signHandover(
        handoverId: handoverId,
        signaturePath: signaturePath,
      );

      final certificateUrl = await _handoverService.generateCertificate(
        handoverId,
      );

      emit(
        HandoverComplete(
          handover: signedHandover,
          certificateUrl: certificateUrl,
        ),
      );
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // تحميل حالة التسليم
  Future<void> loadHandoverStatus(String unitId) async {
    emit(HandoverLoading());
    try {
      final status = await _handoverService.getHandoverStatus(unitId);
      emit(HandoverStatusLoaded(status: 'loaded', data: status));
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // تحديث حالة التسليم
  Future<void> refreshHandoverStatus(String unitId) async {
    await loadHandoverStatus(unitId);
  }

  // تحميل العيوب
  Future<void> loadSnags(String unitId) async {
    emit(HandoverLoading());
    try {
      final snags = await _handoverService.getSnags(unitId);
      emit(SnagsLoaded(snags));
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // إضافة عيب جديد - تم إصلاح المشكلة هنا
  Future<void> addSnag({
    required String unitId,
    required String title,
    required String description,
    required List<XFile> images,
  }) async {
    try {
      // الحصول على handoverId أولاً
      final status = await _handoverService.getHandoverStatus(unitId);
      final handoverId = status['handover_id'] as String? ?? '';

      // استخدام constructor الجديد في DefectModel
      final snag = DefectModel.create(
        handoverId: handoverId,
        description: description,
        title: title, // ✅ سيتم دمجه مع الوصف تلقائياً
        photos: images.map((e) => e.path).toList(),
        location: 'الموقع العام',
        severity: DefectSeverity.medium,
        category: DefectCategory.other,
      );

      await _handoverService.addSnag(unitId, snag);
      emit(SnagAdded(snag));
      await loadSnags(unitId);
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // تحميل العيوب للموافقة
  Future<void> loadDefectsForApproval(String unitId) async {
    emit(HandoverLoading());
    try {
      final defects = await _handoverService.getDefects(unitId);
      emit(DefectsLoaded(defects));
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // الموافقة على عيب
  Future<void> approveDefect(String defectId) async {
    try {
      await _handoverService.updateDefectStatus(
        defectId: defectId,
        status: 'approved',
      );
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // رفض عيب
  Future<void> rejectDefect(String defectId) async {
    try {
      await _handoverService.updateDefectStatus(
        defectId: defectId,
        status: 'rejected',
      );
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // إكمال التسليم
  Future<void> completeHandover(String unitId, String signatureData) async {
    emit(HandoverLoading());
    try {
      final handover = await _handoverService.completeHandover(
        unitId,
        signatureData,
      );
      emit(HandoverCompleted(handover));
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // الحصول على العيوب الحرجة
  List<DefectModel> getCriticalDefects() {
    if (state is! HandoverLoaded) return [];
    return (state as HandoverLoaded).defects
        .where((defect) => defect.isCritical)
        .toList();
  }

  // الحصول على العيوب المعلقة
  List<DefectModel> getPendingDefects() {
    if (state is! HandoverLoaded) return [];
    return (state as HandoverLoaded).defects
        .where((defect) => defect.isPending)
        .toList();
  }

  // الحصول على العيوب المصلحة
  List<DefectModel> getFixedDefects() {
    if (state is! HandoverLoaded) return [];
    return (state as HandoverLoaded).defects
        .where((defect) => defect.isFixed)
        .toList();
  }

  // تحديث صورة لعيب
  Future<void> updateDefectPhoto({
    required String defectId,
    required String photoPath,
  }) async {
    try {
      await _handoverService.updateDefectPhoto(
        defectId: defectId,
        photoPath: photoPath,
      );
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // إضافة تعليق إداري على عيب
  Future<void> addAdminComment({
    required String defectId,
    required String comment,
  }) async {
    try {
      await _handoverService.updateDefectComment(
        defectId: defectId,
        comment: comment,
      );
    } catch (e) {
      emit(HandoverError(e.toString()));
    }
  }

  // تحميل بيانات الإحصائيات
  Future<Map<String, dynamic>> loadHandoverStats(String handoverId) async {
    try {
      return await _handoverService.getHandoverStats(handoverId);
    } catch (e) {
      emit(HandoverError(e.toString()));
      return {};
    }
  }

  // إعادة تعيين حالة التسليم
  void reset() {
    emit(HandoverInitial());
  }
}
