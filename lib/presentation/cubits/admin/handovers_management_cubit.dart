import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mmm/data/services/handover_service.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/repositories/handover_repository.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/presentation/cubits/admin/handovers_management_state.dart';

// Cubit
class HandoversManagementCubit extends Cubit<HandoversManagementState> {
  final HandoverService _handoverService = HandoverService();
  final HandoverRepository _handoverRepository = HandoverRepository();
  StreamSubscription? _handoversSubscription;

  HandoversManagementCubit() : super(HandoversManagementInitial());

  Future<void> loadHandovers({String? userId, String? status}) async {
    try {
      emit(HandoversManagementLoading());

      if (userId == null) {
        emit(HandoversManagementError(message: 'معرف المستخدم مطلوب'));
        return;
      }

      await _handoversSubscription?.cancel();

      // Subscribe to stream
      _handoversSubscription = _handoverService.getUserHandoversStream(userId).listen(
        (handovers) {
          // Apply status filter in memory if provided
          final filteredHandovers = status != null
              ? handovers.where((h) => h.status.name == status).toList()
              : handovers;

          emit(HandoversManagementLoaded(handovers: filteredHandovers));
        },
        onError: (e) {
          emit(
            HandoversManagementError(
              message: 'فشل في تحميل عمليات التسليم: ${e.toString()}',
            ),
          );
        },
      );
    } catch (e) {
      emit(
        HandoversManagementError(
          message: 'فشل في تحميل عمليات التسليم: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> createHandover({
    required String userId,
    required String projectId,
    String? subscriptionId,
    required DateTime appointmentDate,
    String? appointmentLocation,
    String? notes,
  }) async {
    try {
      emit(HandoversManagementCreating());

      await _handoverService.createHandover(
        userId: userId,
        projectId: projectId,
        subscriptionId: subscriptionId,
        appointmentDate: appointmentDate,
        appointmentLocation: appointmentLocation,
        notes: notes,
      );

      emit(HandoverCreatedSuccessfully());
      // Stream updates automatically
    } catch (e) {
      emit(
        HandoversManagementError(
          message: 'فشل في إنشاء عملية التسليم: ${e.toString()}',
        ),
      );
    }
  }

  Future<String?> getSubscriptionId(String userId, String projectId) async {
    try {
      return await _handoverService.getSubscriptionId(
        userId: userId,
        projectId: projectId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadHandoverById(String handoverId) async {
    try {
      emit(HandoversManagementLoading());

      final handover = await _handoverService.getHandoverById(handoverId);

      emit(HandoverDetailLoaded(handover: handover));
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في تحميل تفاصيل التسليم'));
    }
  }

  Future<void> loadDefects(String handoverId) async {
    try {
      final defects = await _handoverService.getDefects(handoverId);
      emit(DefectsLoaded(defects: defects));
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في تحميل العيوب'));
    }
  }

  Future<void> bookHandoverAppointment({
    required String handoverId,
    required DateTime appointmentDate,
    required String location,
    String? notes,
  }) async {
    try {
      await _handoverService.bookAppointment(
        handoverId: handoverId,
        appointmentDate: appointmentDate,
        location: location,
        notes: notes,
      );

      emit(HandoverCompletedSuccessfully());
      final handover = await _handoverService.getHandoverById(handoverId);
      emit(HandoverDetailLoaded(handover: handover));
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في حجز موعد التسليم'));
    }
  }

  Future<void> rescheduleAppointment({
    required String handoverId,
    required DateTime appointmentDate,
    String? reason,
  }) async {
    try {
      await _handoverService.rescheduleAppointment(
        handoverId: handoverId,
        newAppointmentDate: appointmentDate,
        reason: reason,
      );

      final handover = await _handoverService.getHandoverById(handoverId);
      emit(HandoverDetailLoaded(handover: handover));
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في إعادة جدولة الموعد'));
    }
  }

  Future<void> updateDefectStatus({
    required String defectId,
    required DefectStatus status,
    String? adminComment,
  }) async {
    try {
      // updateDefectStatus expects String, not DefectStatus enum
      await _handoverService.updateDefectStatus(
        defectId: defectId,
        status: status.name,
        adminComment: adminComment,
      );

      emit(HandoverCompletedSuccessfully());
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في تحديث حالة العيب'));
    }
  }

  Future<void> completeHandover({
    required String handoverId,
    required String signaturePath,
  }) async {
    try {
      await _handoverService.signHandover(
        handoverId: handoverId,
        signaturePath: signaturePath,
      );

      emit(HandoverCompletedSuccessfully());
      final handover = await _handoverService.getHandoverById(handoverId);
      emit(HandoverDetailLoaded(handover: handover));
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في إتمام التسليم'));
    }
  }

  Future<void> generateHandoverCertificate(String handoverId) async {
    try {
      final certificateUrl = await _handoverService.generateCertificate(
        handoverId,
      );
      emit(HandoverCertificateGenerated(certificateUrl: certificateUrl));
    } catch (e) {
      emit(HandoversManagementError(message: 'فشل في إصدار الشهادة'));
    }
  }

  Future<void> updateHandover({
    required String handoverId,
    DateTime? appointmentDate,
    String? appointmentLocation,
    String? notes,
  }) async {
    try {
      emit(HandoversManagementLoading());
      await _handoverRepository.updateHandover(
        handoverId: handoverId,
        appointmentDate: appointmentDate,
        appointmentLocation: appointmentLocation,
        notes: notes,
      );
      emit(const HandoverUpdatedSuccessfully());
      // Stream updates automatically
    } catch (e) {
      emit(
        HandoversManagementError(message: 'فشل تحديث الاستلام: ${e.toString()}'),
      );
    }
  }

  Future<void> deleteHandover(String handoverId) async {
    try {
      emit(HandoversManagementLoading());
      await _handoverRepository.deleteHandover(handoverId);
      emit(const HandoverDeletedSuccessfully());
      // Stream updates automatically
    } catch (e) {
      emit(
        HandoversManagementError(message: 'فشل حذف الاستلام: ${e.toString()}'),
      );
    }
  }

  @override
  Future<void> close() {
    _handoversSubscription?.cancel();
    return super.close();
  }
}
