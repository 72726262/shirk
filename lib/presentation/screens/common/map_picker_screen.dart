import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  LatLng _selectedLocation = LatLng(30.0444, 31.2357); // Default: Cairo
  final List<Marker> _markers = [];
  
  // ✅ Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Use initial location if provided
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _addMarker(_selectedLocation);
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: position,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 60,
          ),
        ),
      );
      _selectedLocation = position;
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    _addMarker(position);
    // ✅ Auto-save indication
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم اختيار الموقع: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLocation() {
    // ✅ Return coordinates automatically
    Navigator.pop(context, {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  // ✅ Search for location using Nominatim API
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'MMM Flutter App'},
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        setState(() {
          _searchResults = results.map((r) => {
            'name': r['display_name'] as String,
            'lat': double.parse(r['lat'] as String),
            'lon': double.parse(r['lon'] as String),
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: $e')),
        );
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final location = LatLng(result['lat'], result['lon']);
    _addMarker(location);
    _mapController.move(location, 15);
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر موقع المشروع'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _confirmLocation,
            tooltip: 'تأكيد الموقع',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ OpenStreetMap - Free, No API Key Required!
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Map Tiles from OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mmm.app',
                maxZoom: 19,
              ),
              // Markers Layer
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),

          // ✅ Search Bar
          Positioned(
            top: Dimensions.spaceM,
            left: Dimensions.spaceM,
            right: Dimensions.spaceM,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مكان... (مثال: القاهرة)',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(Dimensions.spaceM),
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        _searchLocation(value);
                      } else {
                        setState(() => _searchResults = []);
                      }
                    },
                  ),
                ),
                
                // Search Results
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Card(
                      elevation: 4,
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: AppColors.primary),
                            title: Text(
                              result['name'],
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                  ),
                
                if (_isSearching)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.spaceM),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: Dimensions.spaceL,
            left: Dimensions.spaceL,
            right: Dimensions.spaceL,
            child: ElevatedButton.icon(
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check_circle),
              label: const Text('✓ تأكيد الموقع وحفظ الإحداثيات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.spaceM,
                  horizontal: Dimensions.spaceL,
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
