import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../services/google_navigation_service.dart';
import '../../../../services/location_service.dart';

class InAppGoogleMapView extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String originTitle;
  final String destinationTitle;
  final String originAddress;
  final String destinationAddress;
  final bool isInteractive;
  final List<LatLng>? customRoutePoints;
  final List<LatLng>? alternativeRoutePoints;
  final List<LatLng>? alternative2RoutePoints;
  final double? customZoom;
  final String fastestDuration;
  final String fastestDistance;
  final String alternativeDuration;
  final String alternativeDistance;
  final String alternative2Duration;
  final String alternative2Distance;
  final bool showRouteBadges;
  final int selectedRouteIndex;
  final ValueChanged<int>? onRouteSelected;
  final bool trafficEnabled;
  final bool showTwoLegJourney;
  final LatLng? driverPosition;
  final List<LatLng>? driverToPickupPoints;
  final String driverToPickupDistance;
  final String driverToPickupDuration;
  final String pickupLabel;
  final String deliveryLabel;
  final String orderIdText;
  final String driverCity;
  final String originCity;
  final String destCity;

  const InAppGoogleMapView({
    super.key,
    this.origin = const LatLng(0.0, 0.0),
    this.destination = const LatLng(0.0, 0.0),
    this.originTitle = 'Pickup Location',
    this.destinationTitle = 'Delivery Destination',
    this.originAddress = '',
    this.destinationAddress = '',
    this.isInteractive = true,
    this.customRoutePoints,
    this.alternativeRoutePoints,
    this.alternative2RoutePoints,
    this.customZoom,
    this.fastestDuration = '',
    this.fastestDistance = '',
    this.alternativeDuration = '',
    this.alternativeDistance = '',
    this.alternative2Duration = '',
    this.alternative2Distance = '',
    this.showRouteBadges = true,
    this.selectedRouteIndex = 0,
    this.onRouteSelected,
    this.trafficEnabled = true,
    this.showTwoLegJourney = false,
    this.driverPosition,
    this.driverToPickupPoints,
    this.driverToPickupDistance = '',
    this.driverToPickupDuration = '',
    this.pickupLabel = '',
    this.deliveryLabel = '',
    this.orderIdText = '',
    this.driverCity = '',
    this.originCity = '',
    this.destCity = '',
  });

  @override
  State<InAppGoogleMapView> createState() => _InAppGoogleMapViewState();
}

class _InAppGoogleMapViewState extends State<InAppGoogleMapView> {
  GoogleMapController? _mapController;
  StreamSubscription<LocationData>? _locationSub;
  MapType _currentMapType = MapType.normal;
  final bool _hasMapError = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isUserInteracting = false;
  bool _userHasPannedMap = false;
  bool _isProgrammaticCameraMove = false;

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destinationIcon;

  late LatLng _currentOrigin;
  late LatLng _currentDestination;
  LatLng? _driverLocation;
  List<LatLng> _resolvedRoutePoints = [];
  int _activeRouteIndex = 0;

  void _handleRouteSelected(int index) {
    if (_activeRouteIndex == index) return;
    setState(() {
      _activeRouteIndex = index;
      _setupMarkersAndRoute();
    });
    _userHasPannedMap = false;
    _fitCameraToRoute(force: true);
    widget.onRouteSelected?.call(index);
  }

  @override
  void initState() {
    super.initState();
    _activeRouteIndex = widget.selectedRouteIndex;
    _currentOrigin = widget.origin;
    _currentDestination = widget.destination;
    _resolveRealLocations();
    _loadCustomMarkerIcons().then((_) {
      if (mounted) _setupMarkersAndRoute();
    });
    _setupMarkersAndRoute();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _resolveRealLocations() async {
    // 1. Fetch & stream driver's live GPS location ("Your Location")
    try {
      final loc = await LocationService().getCurrentLocation();
      if (loc != null && loc.latitude != 0.0 && mounted) {
        setState(() {
          _driverLocation = LatLng(loc.latitude, loc.longitude);
        });
        _setupMarkersAndRoute();
        if (!_userHasPannedMap) _fitCameraToRoute();
      }
      _locationSub = LocationService().locationStream.listen((liveLoc) {
        if (!mounted || liveLoc.latitude == 0.0) {
          return;
        }
        if (_isUserInteracting) {
          return; // Never interrupt map scrolling or gesture
        }

        final newPos = LatLng(liveLoc.latitude, liveLoc.longitude);
        if (_driverLocation != null) {
          final dist = GoogleNavigationService.distanceBetween(
            _driverLocation!,
            newPos,
          );
          if (dist < 2.5) {
            return; // Skip negligible micro-updates to keep 60-120 FPS
          }
        }

        setState(() {
          _driverLocation = newPos;
        });
        _setupMarkersAndRoute();
      });
    } catch (_) {}

    // 2. Dynamically resolve pickup & destination coordinates/route if missing
    final String oQuery = widget.originAddress.isNotEmpty
        ? widget.originAddress
        : widget.originTitle;
    final String dQuery = widget.destinationAddress.isNotEmpty
        ? widget.destinationAddress
        : widget.destinationTitle;

    if ((_currentOrigin.latitude == 0.0 ||
            _currentDestination.latitude == 0.0) &&
        (oQuery.isNotEmpty || dQuery.isNotEmpty)) {
      try {
        final routeRes = await GoogleNavigationService()
            .fetchRouteByAddressOrCoords(
              originAddress: oQuery,
              originCoords: _currentOrigin.latitude != 0.0
                  ? _currentOrigin
                  : null,
              destinationAddress: dQuery,
              destinationCoords: _currentDestination.latitude != 0.0
                  ? _currentDestination
                  : null,
              destinationTitle: widget.destinationTitle,
            );
        if (routeRes != null && mounted) {
          setState(() {
            if (_currentOrigin.latitude == 0.0 &&
                routeRes.resolvedOrigin != null) {
              _currentOrigin = routeRes.resolvedOrigin!;
            }
            if (_currentDestination.latitude == 0.0 &&
                routeRes.resolvedDestination != null) {
              _currentDestination = routeRes.resolvedDestination!;
            }
            if (routeRes.polylinePoints.isNotEmpty) {
              _resolvedRoutePoints = routeRes.polylinePoints;
            }
          });
          _setupMarkersAndRoute();
          if (!_userHasPannedMap) _fitCameraToRoute();
        }
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(covariant InAppGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRouteIndex != widget.selectedRouteIndex) {
      _activeRouteIndex = widget.selectedRouteIndex;
    }
    if (oldWidget.selectedRouteIndex != widget.selectedRouteIndex ||
        oldWidget.trafficEnabled != widget.trafficEnabled ||
        oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination ||
        oldWidget.customRoutePoints != widget.customRoutePoints ||
        oldWidget.alternativeRoutePoints != widget.alternativeRoutePoints ||
        oldWidget.alternative2RoutePoints != widget.alternative2RoutePoints ||
        oldWidget.showTwoLegJourney != widget.showTwoLegJourney ||
        oldWidget.driverPosition != widget.driverPosition ||
        oldWidget.driverToPickupPoints != widget.driverToPickupPoints ||
        oldWidget.driverToPickupDistance != widget.driverToPickupDistance ||
        oldWidget.driverToPickupDuration != widget.driverToPickupDuration ||
        oldWidget.pickupLabel != widget.pickupLabel ||
        oldWidget.deliveryLabel != widget.deliveryLabel ||
        oldWidget.fastestDistance != widget.fastestDistance ||
        oldWidget.fastestDuration != widget.fastestDuration ||
        oldWidget.driverCity != widget.driverCity ||
        oldWidget.originCity != widget.originCity ||
        oldWidget.destCity != widget.destCity ||
        oldWidget.orderIdText != widget.orderIdText) {
      if (mounted) {
        setState(() {
          if (widget.origin.latitude != 0.0) {
            _currentOrigin = widget.origin;
          }
          if (widget.destination.latitude != 0.0) {
            _currentDestination = widget.destination;
          }
          _setupMarkersAndRoute();
        });
        _loadCustomMarkerIcons().then((_) {
          if (mounted) setState(() => _setupMarkersAndRoute());
        });
        if (!_userHasPannedMap) {
          _fitCameraToRoute();
        }
      }
    }
  }

  static BitmapDescriptor? _cachedCleanDeliveryPin;
  static BitmapDescriptor? _cachedCleanPickupPin;
  static BitmapDescriptor? _cachedCleanDriverPuck;

  Future<void> _loadCustomMarkerIcons() async {
    try {
      if (_cachedCleanDeliveryPin == null) {
        final delBytes = await _createCleanLollipopPinMarker(
          bodyColor: const Color(0xFFE53935), // Google Red matching custom design
        );
        _cachedCleanDeliveryPin = BitmapDescriptor.bytes(
          delBytes,
          width: 32,
          height: 41,
        );
      }

      if (_cachedCleanPickupPin == null) {
        final pickBytes = await _createCleanLollipopPinMarker(
          bodyColor: const Color(0xFFF97316), // Clean Orange
        );
        _cachedCleanPickupPin = BitmapDescriptor.bytes(
          pickBytes,
          width: 32,
          height: 41,
        );
      }

      if (_cachedCleanDriverPuck == null) {
        final drivBytes = await _createCleanNavigationDriverMarker();
        _cachedCleanDriverPuck = BitmapDescriptor.bytes(
          drivBytes,
          width: 28,
          height: 28,
        );
      }

      if (mounted) {
        setState(() {
          _driverIcon = _cachedCleanDriverPuck;
          _originIcon = _cachedCleanPickupPin;
          _destinationIcon = _cachedCleanDeliveryPin;
        });
      }
    } catch (_) {}
  }

  /// Creates the ultra-clean red/orange destination & pickup pin matching user's custom screenshot:
  /// Round colored head with white outer border, white location pin icon inside with central dot,
  /// sleek needle/stem pointing down, and a soft ground drop-shadow.
  Future<Uint8List> _createCleanLollipopPinMarker({
    required Color bodyColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double w = 72.0;
    const double h = 92.0;
    const double cx = w / 2;
    const double cy = 30.0;
    const double r = 24.0;

    // 1. Soft ground drop-shadow oval under the needle tip
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(cx, h - 8), width: 34, height: 10),
      shadowPaint,
    );

    // 2. Needle / Stem pointing to the exact ground coordinate
    final stemPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(cx, cy + r - 3), const Offset(cx, h - 8), stemPaint);

    // 3. Colored circular head fill
    final headPaint = Paint()..color = bodyColor;
    canvas.drawCircle(const Offset(cx, cy), r, headPaint);

    // 4. Crisp white outer border ring
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(const Offset(cx, cy), r, whiteStroke);

    // 5. White location pin silhouette inside head
    final miniPinPath = Path();
    const double mcx = cx;
    const double mcy = cy - 2;
    miniPinPath.addOval(Rect.fromCircle(center: const Offset(mcx, mcy), radius: 8.5));
    miniPinPath.moveTo(mcx - 7.5, mcy + 2.5);
    miniPinPath.lineTo(mcx, mcy + 12.0);
    miniPinPath.lineTo(mcx + 7.5, mcy + 2.5);
    miniPinPath.close();

    final whiteFill = Paint()..color = Colors.white;
    canvas.drawPath(miniPinPath, whiteFill);

    // 6. Center dot inside white pin
    final innerDot = Paint()..color = bodyColor;
    canvas.drawCircle(const Offset(mcx, mcy), 3.2, innerDot);

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Clean Google Navigation driver puck marker:
  /// Blue circular disc with white border, navigation arrow, and soft drop shadow.
  Future<Uint8List> _createCleanNavigationDriverMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 64.0;
    const double cx = size / 2;
    const double cy = size / 2;

    // Ground shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(const Offset(cx, cy + 2), 22, shadowPaint);

    // White outer ring
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(cx, cy), 22, whitePaint);

    // Blue fill circle
    final bluePaint = Paint()..color = const Color(0xFF1A73E8);
    canvas.drawCircle(const Offset(cx, cy), 18, bluePaint);

    // Inner white arrow pointing forward
    final arrowPath = Path()
      ..moveTo(cx, cy - 9)
      ..lineTo(cx + 6.5, cy + 7)
      ..lineTo(cx, cy + 3.5)
      ..lineTo(cx - 6.5, cy + 7)
      ..close();
    canvas.drawPath(arrowPath, whitePaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  List<LatLng> _getPrimaryRoutePoints() {
    if (widget.customRoutePoints != null &&
        widget.customRoutePoints!.isNotEmpty) {
      return widget.customRoutePoints!;
    }
    if (_resolvedRoutePoints.isNotEmpty) {
      return _resolvedRoutePoints;
    }
    final List<LatLng> pts = [];
    if (_currentOrigin.latitude != 0.0) pts.add(_currentOrigin);
    if (_currentDestination.latitude != 0.0) pts.add(_currentDestination);
    return pts;
  }

  void _setupTwoLegJourney() {
    _markers.clear();
    _polylines.clear();

    final driverPos = widget.driverPosition ?? _driverLocation ?? const LatLng(23.8041, 90.3667);

    // 1. Driver Marker (Clean Google Navigation Blue Puck)
    _markers.add(
      Marker(
        markerId: const MarkerId('two_leg_driver_pin'),
        position: driverPos,
        anchor: const Offset(0.5, 0.5),
        icon: _cachedCleanDriverPuck ??
            _driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: 25,
      ),
    );

    // 2. Pickup Marker (Ultra-clean Lollipop Pin matching custom screenshot)
    if (_currentOrigin.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('two_leg_pickup_pin'),
          position: _currentOrigin,
          anchor: const Offset(0.5, 84.0 / 92.0),
          icon: _cachedCleanPickupPin ??
              _originIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          zIndexInt: 22,
        ),
      );
    }

    // 3. Delivery Marker (Ultra-clean Red Lollipop Pin exactly matching custom screenshot)
    if (_currentDestination.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('two_leg_delivery_pin'),
          position: _currentDestination,
          anchor: const Offset(0.5, 84.0 / 92.0),
          icon: _cachedCleanDeliveryPin ??
              _destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndexInt: 22,
        ),
      );
    }

    // 4. Polyline 1 (Driver -> Pickup: Subtle clean slate path)
    final leg1Pts = widget.driverToPickupPoints != null &&
            widget.driverToPickupPoints!.isNotEmpty
        ? widget.driverToPickupPoints!
        : [driverPos, _currentOrigin];

    if (leg1Pts.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('leg1_blue_route'),
          points: leg1Pts,
          color: const Color(0xFF475569), // Sleek subtle slate
          width: 4,
          zIndex: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    // 5. Polyline 2 (Pickup -> Delivery: Crisp Jet Black/Dark Slate polyline matching custom screenshot!)
    final leg2Pts = _getPrimaryRoutePoints();
    if (leg2Pts.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('leg2_green_route'),
          points: leg2Pts,
          color: const Color(0xFF111827), // Crisp Jet Slate / Black (#111827)
          width: 5,
          zIndex: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
  }

  void _setupMarkersAndRoute() {
    if (widget.showTwoLegJourney) {
      _setupTwoLegJourney();
      return;
    }
    _markers.clear();

    // 1. Driver Live Location (Clean Navigation Puck)
    LatLng? currentDriverPos = _driverLocation;
    if (currentDriverPos == null || currentDriverPos.latitude == 0.0) {
      final routePts = _getPrimaryRoutePoints();
      if (routePts.length >= 4) {
        currentDriverPos = routePts[routePts.length ~/ 3];
      } else if (_currentOrigin.latitude != 0.0 &&
          _currentDestination.latitude != 0.0) {
        currentDriverPos = LatLng(
          _currentOrigin.latitude * 0.65 + _currentDestination.latitude * 0.35,
          _currentOrigin.longitude * 0.65 +
              _currentDestination.longitude * 0.35,
        );
      }
    }

    if (currentDriverPos != null && currentDriverPos.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_live_pin'),
          position: currentDriverPos,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Driver Live GPS Position',
          ),
          icon:
              _cachedCleanDriverPuck ??
              _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          zIndexInt: 25,
        ),
      );
    }

    // 2. Pickup Location (Clean Lollipop Pin matching custom screenshot)
    if (_currentOrigin.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('origin_pin'),
          position: _currentOrigin,
          anchor: const Offset(0.5, 84.0 / 92.0),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.originAddress.isNotEmpty
                ? widget.originAddress
                : widget.originTitle,
          ),
          icon:
              _cachedCleanPickupPin ??
              _originIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          zIndexInt: 20,
        ),
      );
    }

    // 3. Delivery Destination (Clean Red Lollipop Pin exactly matching custom screenshot)
    if (_currentDestination.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dest_pin'),
          position: _currentDestination,
          anchor: const Offset(0.5, 84.0 / 92.0),
          infoWindow: InfoWindow(
            title: 'Destination Location',
            snippet: widget.destinationAddress.isNotEmpty
                ? widget.destinationAddress
                : widget.destinationTitle,
          ),
          icon:
              _cachedCleanDeliveryPin ??
              _destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndexInt: 21,
        ),
      );
    }

    // Build routes
    _polylines.clear();

    final List<List<LatLng>> allRoutes = [
      _getPrimaryRoutePoints(),
      widget.alternativeRoutePoints ?? [],
      widget.alternative2RoutePoints ?? [],
    ];

    for (int i = 0; i < allRoutes.length; i++) {
      final routePts = allRoutes[i];
      if (routePts.length < 2) continue;

      final bool isSelected = i == _activeRouteIndex;

      if (!isSelected) {
        // Alternative Route (Subtle clean gray)
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_alt_$i'),
            points: routePts,
            color: const Color(0xFF94A3B8),
            width: 4,
            zIndex: 1,
            consumeTapEvents: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            onTap: () => _handleRouteSelected(i),
          ),
        );
      } else {
        // Selected / Fastest Route (Crisp Dark Polyline)
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_selected_$i'),
            points: routePts,
            color: const Color(0xFF111827),
            width: 5,
            zIndex: 2,
            consumeTapEvents: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            onTap: () => _handleRouteSelected(i),
          ),
        );
      }
    }

    // Connector from Driver Live Location -> Pickup Location
    if (_driverLocation != null &&
        _driverLocation!.latitude != 0.0 &&
        _currentOrigin.latitude != 0.0) {
      final distToOrigin = GoogleNavigationService.distanceBetween(
        _driverLocation!,
        _currentOrigin,
      );
      if (distToOrigin > 30 && distToOrigin < 500000) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('driver_to_pickup_path'),
            points: [_driverLocation!, _currentOrigin],
            color: const Color(0xFF475569),
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            patterns: [PatternItem.dash(14), PatternItem.gap(8)],
          ),
        );
      }
    }
  }

  LatLng get _computedInitialTarget {
    if (_currentOrigin.latitude != 0.0 && _currentDestination.latitude != 0.0) {
      return LatLng(
        (_currentOrigin.latitude + _currentDestination.latitude) / 2,
        (_currentOrigin.longitude + _currentDestination.longitude) / 2,
      );
    }
    if (_currentOrigin.latitude != 0.0) return _currentOrigin;
    if (_currentDestination.latitude != 0.0) return _currentDestination;
    return _driverLocation ?? const LatLng(53.3498, -6.2603);
  }

  double get _computedInitialZoom {
    if (widget.customZoom != null) return widget.customZoom!;
    if (_currentOrigin.latitude != 0.0 && _currentDestination.latitude != 0.0) {
      final distM = GoogleNavigationService.distanceBetween(
        _currentOrigin,
        _currentDestination,
      );
      return GoogleNavigationService.calculateZoomForDistance(distM / 1000.0);
    }
    return 13.0;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCameraToRoute(force: true);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_userHasPannedMap) _fitCameraToRoute(force: true);
    });
  }

  void _fitCameraToRoute({bool force = false}) {
    if (_mapController == null) return;
    if (!force && _userHasPannedMap) return;
    _isProgrammaticCameraMove = true;
    final List<LatLng> allPoints = [];
    if (_currentOrigin.latitude != 0.0) allPoints.add(_currentOrigin);
    if (_currentDestination.latitude != 0.0) allPoints.add(_currentDestination);

    final List<LatLng> selectedRoutePts;
    if (widget.selectedRouteIndex == 1 &&
        widget.alternativeRoutePoints != null &&
        widget.alternativeRoutePoints!.isNotEmpty) {
      selectedRoutePts = widget.alternativeRoutePoints!;
    } else if (widget.selectedRouteIndex == 2 &&
        widget.alternative2RoutePoints != null &&
        widget.alternative2RoutePoints!.isNotEmpty) {
      selectedRoutePts = widget.alternative2RoutePoints!;
    } else {
      selectedRoutePts = _getPrimaryRoutePoints();
    }

    for (final p in selectedRoutePts) {
      if (p.latitude != 0.0) allPoints.add(p);
    }

    if (widget.showTwoLegJourney) {
      final driverPos = widget.driverPosition ?? _driverLocation;
      if (driverPos != null && driverPos.latitude != 0.0) {
        allPoints.add(driverPos);
      }
      if (widget.driverToPickupPoints != null) {
        for (final p in widget.driverToPickupPoints!) {
          if (p.latitude != 0.0) allPoints.add(p);
        }
      }
    } else if (_driverLocation != null && _driverLocation!.latitude != 0.0) {
      allPoints.add(_driverLocation!);
    }

    if (allPoints.isEmpty) return;

    if (allPoints.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: allPoints.first, zoom: 15.0),
        ),
      );
      return;
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if (minLat == maxLat) {
      minLat -= 0.005;
      maxLat += 0.005;
    }
    if (minLng == maxLng) {
      minLng -= 0.005;
      maxLng += 0.005;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final distKm =
        GoogleNavigationService.distanceBetween(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ) /
        1000.0;
    final zoom = GoogleNavigationService.calculateZoomForDistance(distKm);

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          60.0,
        ),
      );
    } catch (_) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: zoom),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMapSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMapSupported || _hasMapError) {
      return _buildFallbackMap();
    }

    return Stack(
      children: [
        // Google Maps View (Configured for ultra-smooth 60-120fps hardware scrolling)
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _computedInitialTarget,
            zoom: _computedInitialZoom,
          ),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
            Factory<ScaleGestureRecognizer>(
              () => ScaleGestureRecognizer(),
            ),
            Factory<PanGestureRecognizer>(
              () => PanGestureRecognizer(),
            ),
            Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
            ),
            Factory<HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(),
            ),
          },
          markers: _markers,
          polylines: _polylines,
          mapType: _currentMapType,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          trafficEnabled: widget.trafficEnabled,
          zoomControlsEnabled: false,
          compassEnabled: false,
          indoorViewEnabled: false,
          mapToolbarEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(3.0, 20.0),
          fortyFiveDegreeImageryEnabled: false,
          scrollGesturesEnabled: widget.isInteractive,
          zoomGesturesEnabled: widget.isInteractive,
          rotateGesturesEnabled: widget.isInteractive,
          tiltGesturesEnabled: widget.isInteractive,
          onCameraMoveStarted: () {
            _isUserInteracting = true;
            if (!_isProgrammaticCameraMove) {
              _userHasPannedMap = true;
            }
          },
          onCameraMove: (pos) {
            if (_isUserInteracting && !_isProgrammaticCameraMove) {
              _userHasPannedMap = true;
            }
          },
          onCameraIdle: () {
            _isUserInteracting = false;
            _isProgrammaticCameraMove = false;
          },
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
                  icon: _currentMapType == MapType.normal
                      ? Icons.layers_rounded
                      : Icons.map_rounded,
                  tooltip: 'Map style',
                  onTap: () {
                    setState(() {
                      _currentMapType = _currentMapType == MapType.normal
                          ? MapType.satellite
                          : MapType.normal;
                    });
                  },
                ),
                const SizedBox(height: 5),

                // Re-center full route
                _buildControlBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center route',
                  onTap: () {
                    _userHasPannedMap = false;
                    _fitCameraToRoute(force: true);
                  },
                ),
                const SizedBox(height: 5),

                // Zoom In (+)
                _buildControlBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onTap: () {
                    _userHasPannedMap = true;
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 5),

                // Zoom Out (-)
                _buildControlBtn(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onTap: () {
                    _userHasPannedMap = true;
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
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6.0),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: AppColors.textPrimary, size: 19),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      color: const Color(0xFF161B26),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 10,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.originTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.destinationTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${widget.fastestDuration} • Driving Route Active',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isInteractive)
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  _buildControlBtn(
                    icon: Icons.layers_rounded,
                    onTap: () {},
                    tooltip: 'Map style',
                  ),
                  const SizedBox(height: 5),
                  _buildControlBtn(
                    icon: Icons.my_location_rounded,
                    onTap: () {},
                    tooltip: 'Center route',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
