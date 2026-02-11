// lib/presentation/cubits/location/location_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/domain/usecases/open_project_location_usecase.dart';
import 'package:mmm/presentation/cubits/location/location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final OpenProjectLocationUseCase _openLocationUseCase;

  LocationCubit(this._openLocationUseCase) : super(const LocationInitial());

  /// Opens Google Maps with project location
  Future<void> openProjectLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      emit(const LocationLoading());

      print('🚀 LocationCubit: Opening location $latitude, $longitude');

      final success = await _openLocationUseCase(
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {
        emit(const LocationSuccess());
      } else {
        emit(const LocationError('فشل فتح خرائط Google'));
      }
    } catch (e) {
      print('❌ LocationCubit error: $e');
      emit(LocationError(e.toString()));
    }
  }

  void reset() {
    emit(const LocationInitial());
  }
}
