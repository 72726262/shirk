// lib/presentation/cubits/defects/defects_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/data/repositories/handover_repository.dart';

part 'defects_state.dart';

class DefectsCubit extends Cubit<DefectsState> {
  DefectsCubit({required this.repository}) : super(DefectsInitial());

  final HandoverRepository repository;

  /// Load defects for a handover
  Future<void> loadDefects(String handoverId) async {
    try {
      emit(DefectsLoading());
      final defects = await repository.getDefectsByHandover(handoverId);
      emit(
        DefectsLoaded(
          defects: defects,
          pendingCount: defects
              .where((d) => d.status == DefectStatus.pending)
              .length,
          fixedCount: defects
              .where((d) => d.status == DefectStatus.fixed)
              .length,
        ),
      );
    } catch (e) {
      emit(DefectsError(message: e.toString()));
    }
  }

  /// Report a new defect
  Future<void> reportDefect({
    required String handoverId,
    required String category,
    required String description,
    String? location,
    String? severity,
    List<String>? photos,
  }) async {
    try {
      await repository.reportDefect(
        handoverId: handoverId,
        category: category,
        description: description,
        location: location,
        severity: severity,
        photosPaths: photos,
      );
      await loadDefects(handoverId);
    } catch (e) {
      emit(DefectsError(message: 'فشل الإبلاغ عن المشكلة: ${e.toString()}'));
    }
  }

  /// Update defect status
  Future<void> updateDefectStatus({
    required String defectId,
    required String handoverId,
    required String status,
    String? adminComment,
  }) async {
    try {
      await repository.updateDefectStatus(
        defectId: defectId,
        status: status,
        adminComment: adminComment,
      );
      await loadDefects(handoverId);
    } catch (e) {
      emit(DefectsError(message: 'فشل تحديث حالة المشكلة: ${e.toString()}'));
    }
  }
}
