import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectLocationViewerScreen extends StatefulWidget {
  final double projectLat;
  final double projectLng;
  final String projectName;
  final String projectLocation;

  const ProjectLocationViewerScreen({
    super.key,
    required this.projectLat,
    required this.projectLng,
    required this.projectName,
    required this.projectLocation,
  });

  @override
  State<ProjectLocationViewerScreen> createState() =>
      _ProjectLocationViewerScreenState();
}

class _ProjectLocationViewerScreenState
    extends State<ProjectLocationViewerScreen> {
  late MapController _mapController;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  final List<Marker> _markers = [];
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _addMarkers();
        _calculateRoute();
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحديد الموقع: $e')));
      }
    }
  }

  void _addMarkers() {
    _markers.clear();

    // Project marker
    _markers.add(
      Marker(
        point: LatLng(widget.projectLat, widget.projectLng),
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'المشروع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          point: _currentLocation!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.my_location,
            color: AppColors.accent,
            size: 40,
          ),
        ),
      );
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null) return;

    try {
      // استخدام OSRM API المجاني لحساب المسار الفعلي
      final startLng = _currentLocation!.longitude;
      final startLat = _currentLocation!.latitude;
      final endLng = widget.projectLng;
      final endLat = widget.projectLat;

      // OSRM Public API endpoint
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          
          // تحويل الإحداثيات إلى LatLng
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();
        } else {
          // في حالة عدم وجود مسار، استخدم خط مستقيم
          _routePoints = [_currentLocation!, LatLng(endLat, endLng)];
        }
      } else {
        // في حالة فشل الطلب، استخدم خط مستقيم
        _routePoints = [
          _currentLocation!,
          LatLng(widget.projectLat, widget.projectLng),
        ];
      }

      setState(() {});

      // ضبط الخريطة لعرض المسار كاملاً
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            _currentLocation!,
            LatLng(widget.projectLat, widget.projectLng),
          ),
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (e) {
      // في حالة حدوث خطأ، استخدم خط مستقيم كبديل
      setState(() {
        _routePoints = [
          _currentLocation!,
          LatLng(widget.projectLat, widget.projectLng),
        ];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حساب المسار، يتم عرض خط مستقيم'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openInGoogleMaps() async {
    final lat = widget.projectLat;
    final lng = widget.projectLng;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  String _calculateDistance() {
    if (_currentLocation == null) return 'غير متاح';

    const Distance distance = Distance();
    final meters = distance.as(
      LengthUnit.Meter,
      _currentLocation!,
      LatLng(widget.projectLat, widget.projectLng),
    );

    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} متر';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} كم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('موقع المشروع'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInGoogleMaps,
            tooltip: 'فتح في Google Maps',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.projectLat, widget.projectLng),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Map Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sharik', // Must match Android applicationId
                // Add error tile callback to catch loading errors
                errorTileCallback: (tile, error, stackTrace) {
                   print('❌ Tile loading error: $error');
                },
              ),

              // Route Polyline
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
              MarkerLayer(markers: _markers),
            ],
          ),

          // Loading Indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.spaceL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: Dimensions.spaceM),
                        Text('جاري تحديد موقعك...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Project Info Card
          Positioned(
            top: Dimensions.spaceM,
            left: Dimensions.spaceM,
            right: Dimensions.spaceM,
            child: Card(
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: AppColors.primary),
                        const SizedBox(width: Dimensions.spaceS),
                        Expanded(
                          child: Text(
                            widget.projectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spaceS),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: Dimensions.spaceS),
                        Expanded(
                          child: Text(
                            widget.projectLocation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_currentLocation != null) ...[
                      const SizedBox(height: Dimensions.spaceS),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: Dimensions.spaceS),
                          Text(
                            'المسافة: ${_calculateDistance()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Navigation Button
          Positioned(
            bottom: Dimensions.spaceL,
            left: Dimensions.spaceL,
            right: Dimensions.spaceL,
            child: ElevatedButton.icon(
              onPressed: _openInGoogleMaps,
              icon: const Icon(Icons.navigation),
              label: const Text('التنقل في Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.spaceM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
