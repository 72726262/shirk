import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class ProjectLocationMapScreen extends StatefulWidget {
  final String projectName;
  final LatLng projectLocation;

  const ProjectLocationMapScreen({
    super.key,
    required this.projectName,
    required this.projectLocation,
  });

  @override
  State<ProjectLocationMapScreen> createState() => _ProjectLocationMapScreenState();
}

class _ProjectLocationMapScreenState extends State<ProjectLocationMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndRoute();
  }

  Future<void> _getCurrentLocationAndRoute() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'يرجى السماح بالوصول للموقع';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'صلاحية الموقع مرفوضة بشكل دائم';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Calculate route using OSRM
      await _calculateOSRMRoute();

      // Fit bounds to show both markers
      if (_currentLocation != null) {
        _fitBoundsToShowRoute();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في الحصول على الموقع: ${e.toString()}';
      });
    }
  }

  Future<void> _calculateOSRMRoute() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
      _errorMessage = null;
    });

    try {
      // OSRM public API endpoint
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${_currentLocation!.longitude},${_currentLocation!.latitude};'
          '${widget.projectLocation.longitude},${widget.projectLocation.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          
          // Convert coordinates to LatLng
          final routePoints = coordinates
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();

          // Get distance and duration
          final distance = route['distance'] as num; // in meters
          final duration = route['duration'] as num; // in seconds

          setState(() {
            _routePoints = routePoints;
            _routeDistance = _formatDistance(distance);
            _routeDuration = _formatDuration(duration);
            _isLoadingRoute = false;
          });
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('OSRM API error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _errorMessage = 'فشل حساب المسار، سيتم عرض خط مستقيم';
        // Fallback: straight line
        _routePoints = [_currentLocation!, widget.projectLocation];
      });
    }
  }

  String _formatDistance(num meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} كم';
    } else {
      return '${meters.toInt()} م';
    }
  }

  String _formatDuration(num seconds) {
    final minutes = (seconds / 60).round();
    if (minutes >= 60) {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours س $remainingMinutes د';
    } else {
      return '$minutes دقيقة';
    }
  }

  void _fitBoundsToShowRoute() {
    if (_currentLocation != null) {
      final bounds = LatLngBounds(
        _currentLocation!,
        widget.projectLocation,
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.projectLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sharik',
              ),
              
              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6,
                      color: AppColors.accent,
                      borderStrokeWidth: 3,
                      borderColor: AppColors.primary,
                    ),
                  ],
                ),
              
              // Markers
              MarkerLayer(
                markers: [
                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.info,
                        size: 40,
                      ),
                    ),
                  
                  // Project location marker
                  Marker(
                    point: widget.projectLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.success,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Loading indicator
          if (_isLoadingRoute)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(Dimensions.spaceXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: Dimensions.spaceM),
                      Text('جاري حساب المسار...'),
                    ],
                  ),
                ),
              ),
            ),

          // Info card at bottom
          if (_routeDistance != null || _errorMessage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusXL),
                    topRight: Radius.circular(Dimensions.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceM),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: AppColors.warning),
                            const SizedBox(width: Dimensions.spaceM),
                            Expanded(child: Text(_errorMessage!)),
                          ],
                        ),
                      ),
                    
                    if (_routeDistance != null) ...[
                      const SizedBox(height: Dimensions.spaceM),
                      Text(
                        'معلومات المسار',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              Icons.route,
                              'المسافة',
                              _routeDistance!,
                            ),
                          ),
                          if (_routeDuration != null)
                            Expanded(
                              child: _buildInfoItem(
                                Icons.access_time,
                                'الوقت المتوقع',
                                _routeDuration!,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Open in external maps app
                            // Can be implemented later
                          },
                          icon: const Icon(Icons.navigation),
                          label: const Text('التنقل باستخدام خرائط جوجل'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.all(Dimensions.spaceL),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: Dimensions.spaceS),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Dimensions.spaceXS),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
