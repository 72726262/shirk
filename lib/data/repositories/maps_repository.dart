// lib/data/repositories/maps_repository.dart
import 'package:url_launcher/url_launcher.dart';

class MapsRepository {
  /// Opens Google Maps with directions to the specified location
  /// 
  /// [latitude] - Destination latitude
  /// [longitude] - Destination longitude
  /// 
  /// Returns true if Maps opened successfully, false otherwise
  Future<bool> openGoogleMapsDirections({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // ✅ Free Google Maps URL - No API key needed
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude'
        '&travelmode=driving',
      );

      print('🗺️ Opening Google Maps: $url');

      // ✅ Launch in external app (not in-app browser)
      final canLaunch = await canLaunchUrl(url);
      
      if (!canLaunch) {
        print('❌ Cannot launch Google Maps');
        throw Exception('لا يمكن فتح خرائط Google. تأكد من تثبيت التطبيق.');
      }

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ Google Maps opened successfully');
      } else {
        print('❌ Failed to launch Google Maps');
      }

      return launched;
    } catch (e) {
      print('❌ Error opening Google Maps: $e');
      rethrow;
    }
  }

  /// Opens Google Maps to show a location without directions
  Future<bool> openGoogleMapsLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=$latitude,$longitude'
        '${label != null ? '&query_place_id=$label' : ''}',
      );

      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('❌ Error opening location: $e');
      rethrow;
    }
  }
}
