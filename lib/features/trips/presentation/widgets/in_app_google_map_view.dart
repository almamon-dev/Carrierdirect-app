import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../app/theme/app_colors.dart';

class InAppGoogleMapView extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String originTitle;
  final String destinationTitle;
  final bool isInteractive;
  final List<LatLng>? customRoutePoints;
  final double? customZoom;

  const InAppGoogleMapView({
    super.key,
    this.origin = const LatLng(23.8510, 90.4070), // Dhaka Airport Cargo Terminal
    this.destination = const LatLng(23.9980, 90.4260), // Gazipur Chowrasta
    this.originTitle = 'Dhaka Airport Cargo Terminal',
    this.destinationTitle = 'Gazipur Chowrasta',
    this.isInteractive = true,
    this.customRoutePoints,
    this.customZoom,
  });

  @override
  State<InAppGoogleMapView> createState() => _InAppGoogleMapViewState();
}

class _InAppGoogleMapViewState extends State<InAppGoogleMapView> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  final bool _hasMapError = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  static const Color primaryColor = AppColors.primary;

  // Exact coordinates strictly following Dhaka-Mymensingh Highway (N3)
  static const List<LatLng> _defaultHighwayRoute = [
    LatLng(23.8510, 90.4070), // Dhaka Airport Cargo Terminal
    LatLng(23.8540, 90.4040), // Airport road connector
    LatLng(23.8585, 90.4018), // Kawla roundabout
    LatLng(23.8645, 90.3999), // Jasimuddin Avenue (Uttara Sec 1/3)
    LatLng(23.8717, 90.4004), // Rajlakshmi / Sector 3-4
    LatLng(23.8760, 90.4006), // Azampur / Sector 7
    LatLng(23.8805, 90.4009), // House Building / Sector 9
    LatLng(23.8870, 90.4010), // Sector 10 Crossing
    LatLng(23.8925, 90.4019), // Abdullahpur
    LatLng(23.8970, 90.3989), // Tongi Bridge (River Turag)
    LatLng(23.9030, 90.3990), // Tongi Bazar
    LatLng(23.9090, 90.3995), // Station Road Tongi
    LatLng(23.9160, 90.4015), // Mill Gate / Gazipura
    LatLng(23.9248, 90.4042), // Cherag Ali Market
    LatLng(23.9325, 90.4078), // College Gate, Tongi
    LatLng(23.9405, 90.4110), // Hossain Market
    LatLng(23.9550, 90.4180), // Board Bazar (IUT)
    LatLng(23.9680, 90.4215), // Bangladesh Open University
    LatLng(23.9820, 90.4240), // Taragach, Gazipur
    LatLng(23.9910, 90.4250), // Chandana Chowrasta South Approach
    LatLng(23.9980, 90.4260), // Chandana Chowrasta, Gazipur
  ];

  @override
  void initState() {
    super.initState();
    _setupMarkersAndRoute();
    // Only query dynamic OSRM routing if custom points aren't provided and it's not the default Dhaka-Gazipur route
    if (widget.customRoutePoints == null && !_isDefaultDhakaGazipurRoute()) {
      _fetchRoadSnappedRoute();
    }
  }

  bool _isDefaultDhakaGazipurRoute() {
    return (widget.origin.latitude - 23.8510).abs() < 0.05 &&
           (widget.destination.latitude - 23.9980).abs() < 0.05;
  }

  List<LatLng> _getDenseRoadPoints() {
    if (widget.customRoutePoints != null && widget.customRoutePoints!.isNotEmpty) {
      return widget.customRoutePoints!;
    }
    return _defaultHighwayRoute;
  }

  void _setupMarkersAndRoute() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('origin_pin'),
        position: widget.origin,
        infoWindow: InfoWindow(title: widget.originTitle, snippet: 'Pickup Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('dest_pin'),
        position: widget.destination,
        infoWindow: InfoWindow(title: widget.destinationTitle, snippet: 'Delivery Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    final points = _getDenseRoadPoints();

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_path'),
        points: points,
        color: primaryColor,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );
  }

  Future<void> _fetchRoadSnappedRoute() async {
    if (widget.customRoutePoints != null) return;
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${widget.origin.longitude},${widget.origin.latitude};'
        '${widget.destination.longitude},${widget.destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final coordinates = routes[0]['geometry']['coordinates'] as List<dynamic>;
          final roadPoints = coordinates.map((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          if (mounted && roadPoints.isNotEmpty) {
            setState(() {
              _polylines.clear();
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route_path'),
                  points: roadPoints,
                  color: primaryColor,
                  width: 5,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
              );
            });
          }
        }
      }
    } catch (_) {
      // Keep dense road points already set
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasMapError) {
      return _buildFallbackMap();
    }

    final centerLat = (widget.origin.latitude + widget.destination.latitude) / 2;
    final centerLng = (widget.origin.longitude + widget.destination.longitude) / 2;
    final zoom = widget.customZoom ?? 11.5;

    return Stack(
      children: [
        // Google Maps View
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(centerLat, centerLng),
            zoom: zoom,
          ),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          markers: _markers,
          polylines: _polylines,
          mapType: _currentMapType,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          scrollGesturesEnabled: widget.isInteractive,
          zoomGesturesEnabled: widget.isInteractive,
          rotateGesturesEnabled: widget.isInteractive,
          tiltGesturesEnabled: widget.isInteractive,
          onCameraMoveStarted: () {},
        ),

        // Map Controls Floating Overlay (Layers, Re-center, Zoom In, Zoom Out)
        if (widget.isInteractive)
          Positioned(
            right: 10,
            top: 10,
            child: Column(
              children: [
                // Layer toggle
                _buildControlBtn(
                  icon: _currentMapType == MapType.normal ? Icons.layers_rounded : Icons.map_rounded,
                  tooltip: 'Map style',
                  onTap: () {
                    setState(() {
                      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
                    });
                  },
                ),
                const SizedBox(height: 5),

                // Re-center full route
                _buildControlBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center route',
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(centerLat, centerLng),
                          zoom: zoom,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),

                // Zoom In (+)
                _buildControlBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onTap: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 5),

                // Zoom Out (-)
                _buildControlBtn(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onTap: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: AppColors.textPrimary, size: 17),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Text(
          'Google Maps Initializing...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
