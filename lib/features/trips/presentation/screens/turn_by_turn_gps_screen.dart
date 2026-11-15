import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../services/google_navigation_service.dart';
import '../../../../services/location_service.dart';
import '../../../../services/order_gps_tracker_service.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/mandatory_gps_dialog.dart';
import '../../data/models/shipment_item_model.dart';
import '../widgets/navigation/nav_bottom_panel.dart';
import '../widgets/navigation/nav_exit_dialog.dart';
import '../widgets/navigation/nav_floating_action_column.dart';
import '../widgets/navigation/nav_live_speedometer.dart';
import '../widgets/navigation/nav_marker_helper.dart';
import '../widgets/navigation/nav_quick_search_modal.dart';
import '../widgets/navigation/nav_recenter_button.dart';
import '../widgets/navigation/nav_route_alternatives_modal.dart';
import '../widgets/navigation/nav_top_instruction_banner.dart';
import '../widgets/navigation/nav_turn_steps_modal.dart';

class TurnByTurnGpsScreen extends StatefulWidget {
  final ShipmentItem shipment;
  final List<LatLng>? initialRoutePoints;

  const TurnByTurnGpsScreen({
    super.key,
    required this.shipment,
    this.initialRoutePoints,
  });

  @override
  State<TurnByTurnGpsScreen> createState() => _TurnByTurnGpsScreenState();
}

class _TurnByTurnGpsScreenState extends State<TurnByTurnGpsScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  StreamSubscription<LocationData>? _locationSub;
  StreamSubscription<Position>? _geoStreamSub;

  final FlutterTts _tts = FlutterTts();
  bool _isTtsInitialized = false;

  // Real-time GPS & Navigation state
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  DateTime? _lastLocationTime;
  double _currentBearing = 0.0;
  double _currentSpeedKmh = 0.0;
  bool _isCameraTracking = true;
  bool _isProgrammaticCameraMove = false;
  bool _isNorthUp = false;
  bool _isMuted = false;
  bool _isRerouting = false;
  bool _isLoadingRoute = true;

  // Real Route Data from Google Maps API
  List<LatLng> _routePoints = [];
  List<NavigationManeuver> _maneuvers = [];
  int _currentManeuverIndex = 0;
  double _distanceToNextManeuverMeters = 0.0;
  String _currentRoadName = '';

  // Dynamic Google Route Metrics
  double _totalRouteDistanceMeters = 0.0;
  int _totalRouteDurationSeconds = 0;
  String _durationText = 'Calculating...';
  String _distanceText = '...';
  String _etaClockText = '...';

  // Consecutive off-route deviation counter
  int _consecutiveOffRouteCount = 0;

  // Multi-route alternatives & dynamic switching
  List<AlternativeRouteInfo> _alternativeRoutes = [];
  int _selectedRouteIndex = 0; // 0 = Fastest/Best, 1+ = Alternatives
  String _primaryRouteSummary = 'Fastest Route';
  List<LatLng> _primaryRoutePoints = [];
  List<NavigationManeuver> _primaryManeuvers = [];
  double _primaryDistanceMeters = 0.0;
  int _primaryDurationSeconds = 0;
  String _primaryDurationText = '';
  String _primaryDistanceText = '';
  final Map<String, BitmapDescriptor> _badgeIconCache = {};

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _vehicleIcon;
  BitmapDescriptor? _destIcon;
  BitmapDescriptor? _originIcon;

  static const Color blueNavigation = Color(0xFF2563EB);
  static const Color slateDark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialRoutePoints != null &&
        widget.initialRoutePoints!.isNotEmpty) {
      _routePoints = List.from(widget.initialRoutePoints!);
      _isLoadingRoute = false;
      _pickupLocation = _routePoints.first;
      _destinationLocation = _routePoints.last;
      _updatePolylines();
    }
    if (widget.shipment.originLat != 0.0 && widget.shipment.originLng != 0.0) {
      _pickupLocation = LatLng(
        widget.shipment.originLat,
        widget.shipment.originLng,
      );
    }
    if (widget.shipment.destLat != 0.0 && widget.shipment.destLng != 0.0) {
      _destinationLocation = LatLng(
        widget.shipment.destLat,
        widget.shipment.destLng,
      );
    }

    _initTts();
    _loadMarkerIcons();
    _startLiveGpsAndRoute();

    // Enforce online GPS tracking throughout navigation
    OrderGpsTrackerService().startTracking(widget.shipment);
    OrderGpsTrackerService().isGpsDisabledNotifier.addListener(_onGpsEnforcementChanged);

    // Initial check: if device GPS is off, immediately prompt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService().isGpsReady().then((ready) {
        if (!ready && mounted) {
          OrderGpsTrackerService().isGpsDisabledNotifier.value = true;
          MandatoryGpsDialog.show(context, shipment: widget.shipment);
        }
      });
    });
  }

  void _onGpsEnforcementChanged() {
    if (!mounted) return;
    final isDisabled = OrderGpsTrackerService().isGpsDisabledNotifier.value;
    if (isDisabled) {
      _speak('Warning: GPS signal lost. Please enable device location to continue.');
      MandatoryGpsDialog.show(context, shipment: widget.shipment);
    } else {
      _speak('GPS signal restored. Resuming live navigation.');
      _animateToDrivingPerspective();
    }
  }

  @override
  void dispose() {
    OrderGpsTrackerService().isGpsDisabledNotifier.removeListener(_onGpsEnforcementChanged);
    WidgetsBinding.instance.removeObserver(this);
    _locationSub?.cancel();
    _geoStreamSub?.cancel();
    _tts.stop();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _tts.stop();
    } else if (state == AppLifecycleState.resumed) {
      LocationService().isGpsReady().then((ready) {
        if (!ready && mounted) {
          OrderGpsTrackerService().isGpsDisabledNotifier.value = true;
          MandatoryGpsDialog.show(context, shipment: widget.shipment);
        } else if (ready && mounted) {
          if (OrderGpsTrackerService().isGpsDisabledNotifier.value) {
            OrderGpsTrackerService().isGpsDisabledNotifier.value = false;
          }
        }
      });
    }
  }

  // =========================================================================
  // Text-to-Speech Engine
  // =========================================================================
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (_) {
      _isTtsInitialized = false;
    }
  }

  Future<void> _speak(String text) async {
    if (!_isTtsInitialized || _isMuted || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  // =========================================================================
  // Google Navigation Vehicle Chevron Marker
  // =========================================================================
  Future<void> _loadMarkerIcons() async {
    try {
      final vBytes = await NavMarkerHelper.createNavigationChevronMarker(
        chevronColor: blueNavigation,
      );
      final oBytes = await NavMarkerHelper.createCustomLocationMarker(
        label: 'PICKUP',
        badgeColor: const Color(0xFFFF5722), // Orange for Pickup
        iconData: Icons.local_shipping_rounded, // Truck icon
      );
      final dBytes = await NavMarkerHelper.createCustomLocationMarker(
        label: 'DELIVERY',
        badgeColor: const Color(0xFFDC2626), // Red for Delivery
        iconData: Icons.flag_rounded, // Flag icon
      );

      if (mounted) {
        setState(() {
          _vehicleIcon = BitmapDescriptor.bytes(vBytes, width: 48, height: 48);
          _originIcon = BitmapDescriptor.bytes(oBytes, width: 70, height: 45);
          _destIcon = BitmapDescriptor.bytes(dBytes, width: 70, height: 45);
          _updateMarkers();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRouteBadgeIcons() async {
    try {
      final fastBytes = await NavMarkerHelper.createRouteBadgeIcon(
        text: 'Fastest',
        isSelected: false,
        activeColor: blueNavigation,
        textColor: slateDark,
      );
      _badgeIconCache['Fastest'] = BitmapDescriptor.bytes(
        fastBytes,
        width: 68,
        height: 24,
      );

      for (final alt in _alternativeRoutes) {
        final bBytes = await NavMarkerHelper.createRouteBadgeIcon(
          text: alt.differenceText,
          isSelected: false,
          activeColor: blueNavigation,
          textColor: slateDark,
        );
        _badgeIconCache[alt.differenceText] = BitmapDescriptor.bytes(
          bBytes,
          width: 68,
          height: 24,
        );
      }
      if (mounted) {
        setState(() => _updateMarkers());
      }
    } catch (_) {}
  }

  // =========================================================================
  // Live GPS Tracking & Initial Real-Time Google Directions Fetch
  // =========================================================================
  Future<void> _startLiveGpsAndRoute() async {
    // 1. Get initial GPS coordinate
    LatLng? initialPos;
    try {
      final initialLoc = await LocationService().getCurrentLocation();
      if (initialLoc != null && initialLoc.latitude != 0.0) {
        initialPos = LatLng(initialLoc.latitude, initialLoc.longitude);
        if (initialLoc.heading != null && initialLoc.heading! > 0) {
          _currentBearing = initialLoc.heading!;
        }
        _currentSpeedKmh = (initialLoc.speed ?? 0) * 3.6;
      }
    } catch (_) {}

    // Fallback if GPS not yet fixed: use shipment origin coordinates
    if (initialPos == null && widget.shipment.originLat != 0.0) {
      initialPos = LatLng(widget.shipment.originLat, widget.shipment.originLng);
    }

    if (mounted && initialPos != null) {
      setState(() {
        _driverLocation = initialPos;
        _updateMarkers();
      });
      _animateToDrivingPerspective();
    }

    // 2. Fetch 100% Real Live Google Directions Route
    await _fetchLiveGoogleRoute(fromCoords: initialPos);

    // 3. Listen to live GPS location stream
    _locationSub = LocationService().locationStream.listen(
      (live) {
        if (!mounted || live.latitude == 0.0) return;
        _onLiveLocationTick(
          lat: live.latitude,
          lng: live.longitude,
          heading: live.heading,
          speedKmh: (live.speed ?? 0) * 3.6,
        );
      },
      onError: (err) {
        if (mounted) {
          OrderGpsTrackerService().isGpsDisabledNotifier.value = true;
          MandatoryGpsDialog.show(context, shipment: widget.shipment);
        }
      },
    );

    try {
      _geoStreamSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 2,
            ),
          ).listen(
            (pos) {
              if (!mounted || pos.latitude == 0.0) return;
              _onLiveLocationTick(
                lat: pos.latitude,
                lng: pos.longitude,
                heading: pos.heading,
                speedKmh: pos.speed * 3.6,
              );
            },
            onError: (err) {
              if (mounted) {
                OrderGpsTrackerService().isGpsDisabledNotifier.value = true;
                MandatoryGpsDialog.show(context, shipment: widget.shipment);
              }
            },
          );
    } catch (_) {}
  }

  /// Calls Google Directions API directly for real-time turn-by-turn data
  Future<void> _fetchLiveGoogleRoute({LatLng? fromCoords}) async {
    final start =
        fromCoords ??
        _driverLocation ??
        (widget.shipment.originLat != 0.0
            ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
            : null);

    final pickupAddress =
        widget.shipment.originAddress.isNotEmpty &&
            widget.shipment.originAddress != '—'
        ? widget.shipment.originAddress
        : widget.shipment.originTitle;
    final pickupCoords =
        _pickupLocation ??
        (widget.shipment.originLat != 0.0
            ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
            : null);

    final destAddress =
        widget.shipment.destAddress.isNotEmpty &&
            widget.shipment.destAddress != '—'
        ? widget.shipment.destAddress
        : widget.shipment.destTitle;
    final destCoords =
        _destinationLocation ??
        (widget.shipment.destLat != 0.0
            ? LatLng(widget.shipment.destLat, widget.shipment.destLng)
            : null);

    final result = await GoogleNavigationService().fetchRouteByAddressOrCoords(
      originCoords: start,
      waypointAddress: pickupAddress,
      waypointCoords: pickupCoords,
      destinationAddress: destAddress,
      destinationCoords: destCoords,
      destinationTitle: widget.shipment.destTitle,
      forceRefresh: true, // Always fresh live Google Directions data!
    );

    if (mounted && result != null && result.polylinePoints.isNotEmpty) {
      setState(() {
        _isLoadingRoute = false;
        _alternativeRoutes = result.alternatives;
        _primaryRouteSummary = result.primarySummary.isNotEmpty
            ? result.primarySummary
            : 'Fastest Route';
        _primaryRoutePoints = List.from(result.polylinePoints);
        _primaryManeuvers = List.from(result.maneuvers);
        _primaryDistanceMeters = result.totalDistanceKm * 1000.0;
        _primaryDurationSeconds = result.totalDurationSeconds;
        _primaryDurationText = Formatters.formatCompactDuration(
          result.totalDurationText,
        );
        _primaryDistanceText = result.totalDistanceText;

        _selectedRouteIndex = 0;
        _routePoints = _primaryRoutePoints;
        _maneuvers = _primaryManeuvers;
        _totalRouteDistanceMeters = _primaryDistanceMeters;
        _totalRouteDurationSeconds = _primaryDurationSeconds;
        _durationText = _primaryDurationText;
        _distanceText = _primaryDistanceText;
        _etaClockText = result.etaTimeText;

        if (result.resolvedWaypoint != null) {
          _pickupLocation = result.resolvedWaypoint;
        } else if (_pickupLocation == null && result.resolvedOrigin != null) {
          _pickupLocation = result.resolvedOrigin;
        }

        if (result.resolvedDestination != null) {
          _destinationLocation = result.resolvedDestination;
        }

        if (_driverLocation == null && _routePoints.isNotEmpty) {
          _driverLocation = _routePoints.first;
        }

        if (_currentBearing == 0.0 && _routePoints.length >= 2) {
          _currentBearing = GoogleNavigationService.calculateBearing(
            _routePoints[0],
            _routePoints[1],
          );
        }

        if (_maneuvers.isNotEmpty) {
          _currentManeuverIndex = 0;
          _currentRoadName = _maneuvers[0].roadName;
          _distanceToNextManeuverMeters = _maneuvers[0].distanceMeters;
        }

        _updatePolylines();
        _updateMarkers();
      });

      _loadRouteBadgeIcons();
      _animateToDrivingPerspective();

      // Announce first Google maneuver
      if (_maneuvers.isNotEmpty) {
        final m = _maneuvers[0];
        _speak(
          'Navigating via fastest route. In ${m.distanceText}, ${m.instruction}',
        );
      }
    } else if (mounted) {
      setState(() => _isLoadingRoute = false);
    }
  }

  /// Dynamically switch active driving route when tapped on map or route selector
  void _switchToRoute(int routeIndex) {
    if (routeIndex == _selectedRouteIndex) return;

    if (routeIndex == 0) {
      // Switch back to Primary / Fastest route
      setState(() {
        _selectedRouteIndex = 0;
        _routePoints = List.from(_primaryRoutePoints);
        _maneuvers = List.from(_primaryManeuvers);
        _totalRouteDistanceMeters = _primaryDistanceMeters;
        _totalRouteDurationSeconds = _primaryDurationSeconds;
        _durationText = _primaryDurationText;
        _distanceText = _primaryDistanceText;
        _etaClockText = GoogleNavigationService.calculateClockEta(
          _primaryDurationSeconds,
        );
        _currentManeuverIndex = 0;
        if (_maneuvers.isNotEmpty) {
          _currentRoadName = _maneuvers[0].roadName;
          _distanceToNextManeuverMeters = _maneuvers[0].distanceMeters;
        }
        _updatePolylines();
        _updateMarkers();
      });

      _speak(
        'Switched to fastest route. ${_maneuvers.isNotEmpty ? _maneuvers[0].instruction : ""}',
      );
      AppToast.info(context, 'Switched to Fastest Route ($_durationText)');
    } else {
      final altIdx = routeIndex - 1;
      if (altIdx < 0 || altIdx >= _alternativeRoutes.length) return;
      final alt = _alternativeRoutes[altIdx];

      setState(() {
        _selectedRouteIndex = routeIndex;
        _routePoints = List.from(alt.polylinePoints);
        _maneuvers = List.from(
          alt.maneuvers.isNotEmpty ? alt.maneuvers : _primaryManeuvers,
        );
        _totalRouteDistanceMeters = alt.distanceKm * 1000.0;
        _totalRouteDurationSeconds = alt.durationSeconds;
        _durationText = Formatters.formatCompactDuration(alt.durationText);
        _distanceText = alt.distanceText;
        _etaClockText = GoogleNavigationService.calculateClockEta(
          alt.durationSeconds,
        );
        _currentManeuverIndex = 0;
        if (_maneuvers.isNotEmpty) {
          _currentRoadName = _maneuvers[0].roadName;
          _distanceToNextManeuverMeters = _maneuvers[0].distanceMeters;
        }
        _updatePolylines();
        _updateMarkers();
      });

      _speak(
        'Switched to ${alt.summary}. ${_maneuvers.isNotEmpty ? _maneuvers[0].instruction : ""}',
      );
      AppToast.info(
        context,
        'Switched to ${alt.summary} (${alt.durationText}, ${alt.differenceText})',
      );
    }
  }

  // =========================================================================
  // Real-time GPS Location Handler & Dynamic Metric Calculations
  // =========================================================================
  void _onLiveLocationTick({
    required double lat,
    required double lng,
    double? heading,
    required double speedKmh,
  }) {
    final currentPos = LatLng(lat, lng);
    double bearing = _currentBearing;

    if (heading != null && heading > 0.0) {
      bearing = heading;
    } else if (_driverLocation != null) {
      final dist = GoogleNavigationService.distanceBetween(
        _driverLocation!,
        currentPos,
      );
      if (dist >= 1.5) {
        bearing = GoogleNavigationService.calculateBearing(
          _driverLocation!,
          currentPos,
        );
      }
    }

    double liveSpeedKmh = speedKmh > 0 ? speedKmh : 0.0;
    final now = DateTime.now();
    if (liveSpeedKmh <= 0.0 &&
        _driverLocation != null &&
        _lastLocationTime != null) {
      final double distMeters = GoogleNavigationService.distanceBetween(
        _driverLocation!,
        currentPos,
      );
      final double elapsedSec =
          now.difference(_lastLocationTime!).inMilliseconds / 1000.0;
      if (elapsedSec > 0.4 && elapsedSec < 10.0 && distMeters > 0.8) {
        liveSpeedKmh = (distMeters / elapsedSec) * 3.6;
      }
    }
    _lastLocationTime = now;

    setState(() {
      _driverLocation = currentPos;
      _currentBearing = bearing;
      _currentSpeedKmh = liveSpeedKmh;
      _updateMarkers();
    });

    if (_isCameraTracking) {
      _animateToDrivingPerspective();
    }

    // Dynamic calculations directly based on Google route data
    _updateDynamicRouteMetrics(currentPos);
    _checkDeviationAndReroute(currentPos);
  }

  /// Calculates dynamic remaining kilometers, ETA, and step countdown
  void _updateDynamicRouteMetrics(LatLng driverPos) {
    if (_maneuvers.isEmpty || _currentManeuverIndex >= _maneuvers.length) {
      return;
    }

    final currentM = _maneuvers[_currentManeuverIndex];
    final distToTurnMeters = GoogleNavigationService.distanceBetween(
      driverPos,
      currentM.endLocation,
    );

    // Sum of remaining distance in meters
    double remainingMeters = distToTurnMeters;
    for (int i = _currentManeuverIndex + 1; i < _maneuvers.length; i++) {
      remainingMeters += _maneuvers[i].distanceMeters;
    }

    final double remainingKm = remainingMeters / 1000.0;

    // Remaining duration scaled from Google's duration
    int remainingSeconds = 0;
    if (_totalRouteDistanceMeters > 0 && _totalRouteDurationSeconds > 0) {
      final ratio = (remainingMeters / _totalRouteDistanceMeters).clamp(
        0.0,
        1.0,
      );
      remainingSeconds = (_totalRouteDurationSeconds * ratio).round();
    } else {
      remainingSeconds = (remainingKm / 40.0 * 3600).round();
    }
    if (remainingSeconds < 60) remainingSeconds = 60;

    setState(() {
      _distanceToNextManeuverMeters = distToTurnMeters;
      _currentRoadName = currentM.roadName;
      _distanceText = '${remainingKm.toStringAsFixed(1)} km';
      _durationText = GoogleNavigationService.formatDuration(remainingSeconds);
      _etaClockText = GoogleNavigationService.calculateClockEta(
        remainingSeconds,
      );
    });

    // Voice announcements at critical distance thresholds
    if (distToTurnMeters <= 500 && distToTurnMeters > 450) {
      _speak('In 500 meters, ${currentM.instruction}');
    } else if (distToTurnMeters <= 200 && distToTurnMeters > 170) {
      _speak('In 200 meters, ${currentM.instruction}');
    } else if (distToTurnMeters <= 25) {
      // Step complete! Move to next Google step
      _speak(currentM.instruction);
      if (_currentManeuverIndex + 1 < _maneuvers.length) {
        setState(() {
          _currentManeuverIndex++;
          _currentRoadName = _maneuvers[_currentManeuverIndex].roadName;
        });
      } else {
        _speak('You have arrived at ${widget.shipment.destTitle}.');
      }
    }
  }

  /// Automatically detects off-route deviation and recalculates via Google API
  void _checkDeviationAndReroute(LatLng currentPos) {
    if (_isRerouting || _routePoints.length < 2) return;

    final distToRoute = _calculateDistanceToPolyline(currentPos, _routePoints);
    if (distToRoute > 55.0) {
      _consecutiveOffRouteCount++;
      if (_consecutiveOffRouteCount >= 3) {
        _triggerRerouting(currentPos);
      }
    } else {
      _consecutiveOffRouteCount = 0;
    }
  }

  double _calculateDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    double minDist = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final dAB = GoogleNavigationService.distanceBetween(a, b);
    if (dAB == 0) return GoogleNavigationService.distanceBetween(p, a);

    final dAP = GoogleNavigationService.distanceBetween(a, p);
    final dBP = GoogleNavigationService.distanceBetween(b, p);

    if (dAP * dAP >= dBP * dBP + dAB * dAB) return dBP;
    if (dBP * dBP >= dAP * dAP + dAB * dAB) return dAP;

    final s = (dAB + dAP + dBP) / 2.0;
    final area = math.sqrt(
      math.max(0.0, s * (s - dAB) * (s - dAP) * (s - dBP)),
    );
    return (2.0 * area) / dAB;
  }

  Future<void> _triggerRerouting(LatLng currentPos) async {
    setState(() {
      _isRerouting = true;
      _consecutiveOffRouteCount = 0;
    });

    _speak('Rerouting... Finding optimal route.');
    AppToast.info(context, 'Rerouting...');

    final pickupAddress =
        widget.shipment.originAddress.isNotEmpty &&
            widget.shipment.originAddress != '—'
        ? widget.shipment.originAddress
        : widget.shipment.originTitle;
    final pickupCoords =
        _pickupLocation ??
        (widget.shipment.originLat != 0.0
            ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
            : null);

    final destAddress =
        widget.shipment.destAddress.isNotEmpty &&
            widget.shipment.destAddress != '—'
        ? widget.shipment.destAddress
        : widget.shipment.destTitle;
    final destCoords =
        _destinationLocation ??
        (widget.shipment.destLat != 0.0
            ? LatLng(widget.shipment.destLat, widget.shipment.destLng)
            : null);

    final result = await GoogleNavigationService().fetchRouteByAddressOrCoords(
      originCoords: currentPos,
      waypointAddress: pickupAddress,
      waypointCoords: pickupCoords,
      destinationAddress: destAddress,
      destinationCoords: destCoords,
      destinationTitle: widget.shipment.destTitle,
      forceRefresh: true,
    );

    if (mounted && result != null && result.polylinePoints.isNotEmpty) {
      setState(() {
        _routePoints = result.polylinePoints;
        _maneuvers = result.maneuvers;
        _currentManeuverIndex = 0;
        _totalRouteDistanceMeters = result.totalDistanceKm * 1000.0;
        _totalRouteDurationSeconds = result.totalDurationSeconds;
        _durationText = Formatters.formatCompactDuration(
          result.totalDurationText,
        );
        _distanceText = result.totalDistanceText;
        _etaClockText = result.etaTimeText;
        if (result.resolvedWaypoint != null) {
          _pickupLocation = result.resolvedWaypoint;
        }
        if (result.resolvedDestination != null) {
          _destinationLocation = result.resolvedDestination;
        }
        if (_maneuvers.isNotEmpty) {
          _currentRoadName = _maneuvers[0].roadName;
        }
        _isRerouting = false;
        _updatePolylines();
        _updateMarkers();
      });

      if (_maneuvers.isNotEmpty) {
        final m = _maneuvers[0];
        _speak('New route found. In ${m.distanceText}, ${m.instruction}');
      }
    } else if (mounted) {
      setState(() => _isRerouting = false);
    }
  }

  // =========================================================================
  // Google Map Camera Perspectives
  // =========================================================================
  void _animateToDrivingPerspective() {
    if (_mapController == null || _driverLocation == null) return;
    _isProgrammaticCameraMove = true;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _driverLocation!,
          zoom: 18.2,
          tilt: _isNorthUp ? 0.0 : 58.0,
          bearing: _isNorthUp ? 0.0 : _currentBearing,
        ),
      ),
    );
  }

  void _fitRouteOverview() {
    if (_mapController == null) return;
    final List<LatLng> allPoints = List.from(_routePoints);
    if (_pickupLocation != null) allPoints.add(_pickupLocation!);
    if (_destinationLocation != null) allPoints.add(_destinationLocation!);
    if (_driverLocation != null) allPoints.add(_driverLocation!);
    if (allPoints.isEmpty) return;

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

    _isProgrammaticCameraMove = true;
    setState(() => _isCameraTracking = false);

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80.0,
      ),
    );
  }

  // =========================================================================
  // Markers & Traffic-Colored Polylines
  // =========================================================================
  void _updateMarkers() {
    _markers.clear();

    // 1. Driver Navigation Chevron Marker
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_nav_marker'),
          position: _driverLocation!,
          anchor: const Offset(0.5, 0.5),
          rotation: _currentBearing,
          icon:
              _vehicleIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          zIndexInt: 10,
        ),
      );
    }

    // 2. Pickup Location Pin (Orange Marker with Truck Icon)
    final LatLng? pickup =
        _pickupLocation ??
        (widget.shipment.originLat != 0.0 && widget.shipment.originLng != 0.0
            ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
            : (_routePoints.length >= 2
                  ? _routePoints[1]
                  : (_routePoints.isNotEmpty ? _routePoints.first : null)));

    if (pickup != null && pickup.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup_nav_marker'),
          position: pickup,
          anchor: const Offset(0.5, 0.911),
          infoWindow: InfoWindow(
            title: 'Pickup Point',
            snippet: widget.shipment.originAddress.isNotEmpty
                ? widget.shipment.originAddress
                : widget.shipment.originTitle,
          ),
          icon:
              _originIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          zIndexInt: 8,
        ),
      );
    }

    // 3. Destination Location Pin (Red Marker with Flag Icon)
    final LatLng? dest =
        _destinationLocation ??
        (widget.shipment.destLat != 0.0 && widget.shipment.destLng != 0.0
            ? LatLng(widget.shipment.destLat, widget.shipment.destLng)
            : (_routePoints.isNotEmpty ? _routePoints.last : null));

    if (dest != null && dest.latitude != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dest_nav_marker'),
          position: dest,
          anchor: const Offset(0.5, 0.911),
          infoWindow: InfoWindow(
            title: 'Delivery Point',
            snippet: widget.shipment.destAddress.isNotEmpty
                ? widget.shipment.destAddress
                : widget.shipment.destTitle,
          ),
          icon:
              _destIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndexInt: 9,
        ),
      );
    }

    // 4. On-Map Interactive Route Badges (Fastest, +X min)
    if (_selectedRouteIndex != 0 && _primaryRoutePoints.length >= 6) {
      final midPos = _primaryRoutePoints[_primaryRoutePoints.length ~/ 2];
      final icon = _badgeIconCache['Fastest'];
      if (icon != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('badge_route_0'),
            position: midPos,
            anchor: const Offset(0.5, 0.5),
            icon: icon,
            zIndexInt: 7,
            onTap: () => _switchToRoute(0),
          ),
        );
      }
    }

    for (int i = 0; i < _alternativeRoutes.length; i++) {
      final int routeIdx = i + 1;
      if (_selectedRouteIndex != routeIdx) {
        final alt = _alternativeRoutes[i];
        if (alt.polylinePoints.length >= 6) {
          final midPos = alt.polylinePoints[alt.polylinePoints.length ~/ 2];
          final icon = _badgeIconCache[alt.differenceText];
          if (icon != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('badge_route_$routeIdx'),
                position: midPos,
                anchor: const Offset(0.5, 0.5),
                icon: icon,
                zIndexInt: 7,
                onTap: () => _switchToRoute(routeIdx),
              ),
            );
          }
        }
      }
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    // 1. Draw Inactive Alternative Routes (Tappable on map, Google-style muted gray)
    if (_selectedRouteIndex != 0 && _primaryRoutePoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('alt_route_primary'),
          points: _primaryRoutePoints,
          color: const Color(0xFF94A3B8),
          width: 6,
          zIndex: 2,
          consumeTapEvents: true,
          onTap: () => _switchToRoute(0),
        ),
      );
    }

    for (int i = 0; i < _alternativeRoutes.length; i++) {
      final int routeIdx = i + 1;
      if (_selectedRouteIndex != routeIdx) {
        final alt = _alternativeRoutes[i];
        if (alt.polylinePoints.length >= 2) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('alt_route_$i'),
              points: alt.polylinePoints,
              color: const Color(0xFF94A3B8),
              width: 6,
              zIndex: 2,
              consumeTapEvents: true,
              onTap: () => _switchToRoute(routeIdx),
            ),
          );
        }
      }
    }

    if (_routePoints.length < 2) return;

    // 2. Active Route: Outer Halo for 3D depth
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('nav_halo_route'),
        points: _routePoints,
        color: Colors.white,
        width: 12,
        zIndex: 3,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );

    // 3. Active Route: Base Blue Navigation Route
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('nav_base_blue_route'),
        points: _routePoints,
        color: blueNavigation,
        width: 9,
        zIndex: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );

    // 4. Dynamic Traffic Flow Segments along active route
    final total = _routePoints.length;
    if (total >= 6) {
      final s1 = (total * 0.32).round();
      final s2 = (total * 0.52).round();
      final s3 = (total * 0.76).round();

      if (s2 > s1 + 1) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('nav_traffic_orange'),
            points: _routePoints.sublist(s1, s2 + 1),
            color: const Color(0xFFF59E0B),
            width: 7,
            zIndex: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }

      if (s3 > s2 + 1) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('nav_traffic_red'),
            points: _routePoints.sublist(s2, s3 + 1),
            color: const Color(0xFFEF4444),
            width: 7,
            zIndex: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    }
  }

  void _showRouteAlternativesModal() {
    NavRouteAlternativesModal.show(
      context,
      selectedRouteIndex: _selectedRouteIndex,
      primaryRouteSummary: _primaryRouteSummary,
      primaryDurationText: _primaryDurationText.isNotEmpty
          ? _primaryDurationText
          : _durationText,
      primaryDistanceText: _primaryDistanceText.isNotEmpty
          ? _primaryDistanceText
          : _distanceText,
      alternativeRoutes: _alternativeRoutes,
      onSelectRoute: _switchToRoute,
    );
  }

  void _confirmExitNavigation() {
    NavExitDialog.show(context);
  }

  void _showQuickSearchModal() {
    NavQuickSearchModal.show(context);
  }

  void _showTurnStepsModal() {
    NavTurnStepsModal.show(
      context,
      maneuvers: _maneuvers,
      currentManeuverIndex: _currentManeuverIndex,
      durationText: _durationText,
      distanceText: _distanceText,
    );
  }

  // =========================================================================
  // Screen Build
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    NavigationManeuver? currentManeuver;
    NavigationManeuver? nextManeuver;
    if (_maneuvers.isNotEmpty && _currentManeuverIndex < _maneuvers.length) {
      currentManeuver = _maneuvers[_currentManeuverIndex];
      if (_currentManeuverIndex + 1 < _maneuvers.length) {
        nextManeuver = _maneuvers[_currentManeuverIndex + 1];
      }
    }

    final initialCenter =
        _driverLocation ??
        (widget.shipment.originLat != 0.0
            ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
            : const LatLng(23.8103, 90.4125));

    // Dynamic distance countdown
    final String displayDistance = _distanceToNextManeuverMeters > 0
        ? (_distanceToNextManeuverMeters >= 1000
              ? '${(_distanceToNextManeuverMeters / 1000).toStringAsFixed(1)} km'
              : '${_distanceToNextManeuverMeters.round()} m')
        : (currentManeuver?.distanceText ?? '...');

    final String displayInstruction =
        currentManeuver?.instruction ?? 'Proceed to route';
    final String displayRoad = currentManeuver?.roadName.isNotEmpty == true
        ? currentManeuver!.roadName
        : (_currentRoadName.isNotEmpty
              ? _currentRoadName
              : (widget.shipment.originTitle.isNotEmpty
                    ? widget.shipment.originTitle
                    : 'Pickup & Delivery Route'));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==========================================
          // 1. Full-screen Interactive 3D Google Map
          // ==========================================
          Listener(
            onPointerDown: (_) {
              _isProgrammaticCameraMove = false;
              if (_isCameraTracking) {
                setState(() => _isCameraTracking = false);
              }
            },
            child: GoogleMap(
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _animateToDrivingPerspective();
                });
              },
              onCameraMoveStarted: () {
                if (!_isProgrammaticCameraMove && _isCameraTracking) {
                  setState(() => _isCameraTracking = false);
                }
              },
              onCameraIdle: () {
                _isProgrammaticCameraMove = false;
              },
              initialCameraPosition: CameraPosition(
                target: initialCenter,
                zoom: 18.2,
                tilt: 58.0,
                bearing: _currentBearing,
              ),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              },
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              buildingsEnabled: true,
              trafficEnabled: true,
              indoorViewEnabled: false,
              mapToolbarEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(3.0, 20.0),
              fortyFiveDegreeImageryEnabled: true,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),
          ),

          // Loading overlay if initial Google route is computing
          if (_isLoadingRoute)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Connecting to Google Navigation...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Top Google Maps Turn Maneuver Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                child: NavTopInstructionBanner(
                  currentManeuver: currentManeuver,
                  nextManeuver: nextManeuver,
                  displayDistance: displayDistance,
                  displayInstruction: displayInstruction,
                  displayRoad: displayRoad,
                  isMuted: _isMuted,
                  onToggleMute: () {
                    setState(() => _isMuted = !_isMuted);
                    AppToast.info(
                      context,
                      _isMuted
                          ? 'Voice Guidance Muted'
                          : 'Voice Guidance Active 🎙️',
                    );
                    if (!_isMuted && currentManeuver != null) {
                      _speak(
                        'In $displayDistance, ${currentManeuver.instruction}',
                      );
                    }
                  },
                ),
              ),
            ),
          ),

          // 3. Right Floating Action Column
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 80,
            child: NavFloatingActionColumn(
              isMuted: _isMuted,
              isNorthUp: _isNorthUp,
              currentBearing: _currentBearing,
              isCameraTracking: _isCameraTracking,
              onSearch: _showQuickSearchModal,
              onToggleMute: () {
                setState(() => _isMuted = !_isMuted);
                AppToast.info(
                  context,
                  _isMuted ? 'Voice guidance muted' : 'Voice guidance enabled',
                );
              },
              onToggleCompass: () {
                setState(() {
                  _isNorthUp = !_isNorthUp;
                  _isCameraTracking = true;
                });
                _animateToDrivingPerspective();
                AppToast.info(
                  context,
                  _isNorthUp ? 'North-Up View' : '3D Driving View',
                );
              },
              onOverviewOrRecenter: () {
                if (_isCameraTracking) {
                  _fitRouteOverview();
                } else {
                  setState(() => _isCameraTracking = true);
                  _animateToDrivingPerspective();
                }
              },
            ),
          ),

          // 4. Live Speedometer (Bottom-Left)
          Positioned(
            left: 14,
            bottom: 92,
            child: NavLiveSpeedometer(currentSpeedKmh: _currentSpeedKmh),
          ),

          // 5. Google Maps-style "Re-center" Button (Right Side)
          if (!_isCameraTracking)
            Positioned(
              right: 14,
              bottom: 94,
              child: NavRecenterButton(
                onRecenter: () {
                  setState(() => _isCameraTracking = true);
                  _animateToDrivingPerspective();
                },
              ),
            ),

          // 6. Bottom Navigation Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavBottomPanel(
              durationText: _durationText,
              distanceText: _distanceText,
              etaClockText: _etaClockText,
              alternativeCount: _alternativeRoutes.length + 1,
              onOpenTurnSteps: _showTurnStepsModal,
              onOpenRouteAlternatives: _showRouteAlternativesModal,
              onExitNavigation: _confirmExitNavigation,
            ),
          ),
        ],
      ),
    );
  }
}
