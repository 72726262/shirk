// lib/presentation/widgets/common/location_button.dart
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/screens/projects/project_location_viewer_screen.dart';

class LocationButton extends StatelessWidget {
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? projectName;

  const LocationButton({
    super.key,
    this.locationName,
    this.latitude,
    this.longitude,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    // If no coordinates provided, don't show button
    if (latitude == null || longitude == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: InkWell(
          onTap: () {
            // ✅ Navigate to location viewer screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectLocationViewerScreen(
                  projectLat: latitude!,
                  projectLng: longitude!,
                  projectName: projectName ?? 'المشروع',
                  projectLocation: locationName ?? 'الموقع',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.spaceXL,
              vertical: Dimensions.spaceM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: Dimensions.spaceM),
                const Text(
                  'رؤية الموقع والمسار',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: Dimensions.spaceS),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
