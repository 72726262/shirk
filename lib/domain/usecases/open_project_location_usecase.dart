// lib/domain/usecases/open_project_location_usecase.dart
import 'package:mmm/data/repositories/maps_repository.dart';

class OpenProjectLocationUseCase {
  final MapsRepository _repository;

  OpenProjectLocationUseCase(this._repository);

  /// Opens Google Maps with directions to project location
  /// 
  /// Returns true if successful, throws exception otherwise
  Future<bool> call({
    required double latitude,
    required double longitude,
  }) async {
    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      throw Exception('خط العرض غير صحيح. يجب أن يكون بين -90 و 90');
    }

    if (longitude < -180 || longitude > 180) {
      throw Exception('خط الطول غير صحيح. يجب أن يكون بين -180 و 180');
    }

    print('📍 Opening location: $latitude, $longitude');

    return await _repository.openGoogleMapsDirections(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
