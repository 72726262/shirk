import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/data/services/construction_service.dart';
import 'dart:async';

// States
abstract class ConstructionState extends Equatable {
  const ConstructionState();

  @override
  List<Object?> get props => [];
}

class ConstructionInitial extends ConstructionState {}

class ConstructionLoading extends ConstructionState {}

class ConstructionLoaded extends ConstructionState {
  final List<ConstructionUpdateModel> updates;
  final ConstructionUpdateModel? latestUpdate;
  final Map<String, List<ConstructionUpdateModel>> timeline;
  final Map<String, dynamic> progressSummary;

  const ConstructionLoaded({
    required this.updates,
    this.latestUpdate,
    required this.timeline,
    required this.progressSummary,
  });

  @override
  List<Object?> get props => [updates, latestUpdate, timeline, progressSummary];

  double get overallProgress => (progressSummary['overall'] as num?)?.toDouble() ?? 0.0;
}

class ConstructionError extends ConstructionState {
  final String message;

  const ConstructionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ConstructionCubit extends Cubit<ConstructionState> {
  final ConstructionService _constructionService;
  StreamSubscription? _updatesSubscription;

  ConstructionCubit({ConstructionService? constructionService})
      : _constructionService = constructionService ?? ConstructionService(),
        super(ConstructionInitial());

  Future<void> loadUpdates(String projectId) async {
    emit(ConstructionLoading());
    try {
      final results = await Future.wait([
        _constructionService.getConstructionUpdates(projectId),
        _constructionService.getLatestUpdate(projectId),
        _constructionService.getConstructionTimeline(projectId),
        _constructionService.getProgressSummary(projectId),
      ]);

      emit(ConstructionLoaded(
        updates: results[0] as List<ConstructionUpdateModel>,
        latestUpdate: results[1] as ConstructionUpdateModel?,
        timeline: results[2] as Map<String, List<ConstructionUpdateModel>>,
        progressSummary: results[3] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(ConstructionError(e.toString()));
    }
  }

  void subscribeToUpdates(String projectId) {
    _updatesSubscription?.cancel();
    _updatesSubscription = _constructionService
        .watchConstructionUpdates(projectId)
        .listen((updates) {
      // Auto-reload when new update arrives
      loadUpdates(projectId);
    }, onError: (error) {
      emit(ConstructionError(error.toString()));
    });
  }

  @override
  Future<void> close() {
    _updatesSubscription?.cancel();
    return super.close();
  }

  void unsubscribeFromUpdates() {
    _updatesSubscription?.cancel();
  }

  Future<void> refreshUpdates(String projectId) async {
    await loadUpdates(projectId);
  }
}
