import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../services/google_navigation_service.dart';
import '../../../../services/location_service.dart';
import '../../../../shared/utils/map_launcher_helper.dart';
import '../../../../shared/widgets/dashed_vertical_line.dart';
import '../../data/models/shipment_item_model.dart';
import '../screens/turn_by_turn_gps_screen.dart';
import 'in_app_google_map_view.dart';
import 'map_skeleton_placeholder.dart';

class ShipmentRouteTab extends StatefulWidget {
  final ShipmentItem shipment;
  final String estimatedDuration;
  final List<LatLng> routePoints;
  final VoidCallback onOpenExternalMaps;
  final bool isActive;

  const ShipmentRouteTab({
    super.key,
    required this.shipment,
    required this.estimatedDuration,
    required this.routePoints,
    required this.onOpenExternalMaps,
    this.isActive = false,
  });

  @override
  State<ShipmentRouteTab> createState() => _ShipmentRouteTabState();
}

class _ShipmentRouteTabState extends State<ShipmentRouteTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isRouteTabReady = false;
  Timer? _mountTimer;
  int _selectedRouteIndex = 0; // 0 = Fastest, 1 = Alt 1, 2 = Alt 2
  bool _liveTrafficEnabled = false;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  // Real or simulated driver location
  LatLng? _driverPosition;
  String _driverCity = 'Locating...';

  // Leg 1: Driver -> Pickup
  List<LatLng> _driverToPickupPoints = [];
  String _leg1DistanceText = '';
  String _leg1DurationText = '';
  double _leg1DistanceKm = 0.0;
  int _leg1Minutes = 0;

  // Leg 2: Pickup -> Delivery
  List<LatLng> _currentRoutePoints = [];
  List<LatLng>? _altRoutePoints;
  List<LatLng>? _alt2RoutePoints;
  List<AlternativeRouteInfo> _alternativeRoutes = [];
  String _calculatedDuration = '';
  double _calculatedDistanceKm = 0.0;

  static const Color orangePrimary = Color(0xFFFF5722);
  static const Color slateDark = Color(0xFF0F172A);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color greenPickup = Color(0xFF16A34A);
  static const Color redDelivery = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!_isRouteTabReady) {
      _shimmerController.repeat();
    }
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );

    _currentRoutePoints = widget.routePoints;
    if (widget.shipment.distanceKm > 0) {
      _calculatedDistanceKm = widget.shipment.distanceKm;
    }
    if (widget.shipment.estimatedDuration.isNotEmpty &&
        widget.shipment.estimatedDuration != '—') {
      _calculatedDuration = Formatters.formatCompactDuration(
        widget.shipment.estimatedDuration,
      );
    } else if (widget.estimatedDuration.isNotEmpty &&
        widget.estimatedDuration != '—') {
      _calculatedDuration = Formatters.formatCompactDuration(
        widget.estimatedDuration,
      );
    }
    _initRouteData(force: false);
    _fetchLiveDriverLocation();
    if (widget.isActive) {
      _scheduleMapMount();
    }
  }

  void _scheduleMapMount() {
    _mountTimer?.cancel();
    _isRouteTabReady = false;
    if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }
    _mountTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isRouteTabReady = true);
        _shimmerController.stop();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShipmentRouteTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routePoints != widget.routePoints) {
      _currentRoutePoints = widget.routePoints;
      _initRouteData(force: false);
    }
    if (!oldWidget.isActive && widget.isActive) {
      setState(() => _isRouteTabReady = false);
      _scheduleMapMount();
    } else if (oldWidget.isActive && !widget.isActive) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveDriverLocation() async {
    try {
      final loc = await LocationService().getCurrentLocation();
      if (loc != null && mounted) {
        final pos = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _driverPosition = pos;
        });

        // Reverse geocode driver position to real locality / area
        final area = await GoogleNavigationService().reverseGeocodeNearby(pos);
        if (mounted && area != null && area.isNotEmpty) {
          setState(() {
            _driverCity = area;
          });
        } else if (mounted && _driverCity == 'Locating...') {
          setState(() {
            _driverCity = 'Current Location';
          });
        }

        // Calculate Leg 1 (Driver GPS -> Pickup)
        _fetchLeg1Route();
      } else if (mounted && _driverPosition == null) {
        setState(() {
          _driverPosition = const LatLng(23.8041, 90.3667);
          _driverCity = 'Current Location';
        });
        _fetchLeg1Route();
      }
    } catch (_) {
      if (mounted && _driverPosition == null) {
        setState(() {
          _driverPosition = const LatLng(23.8041, 90.3667);
          _driverCity = 'Current Location';
        });
      }
    }
  }

  Future<void> _fetchLeg1Route() async {
    final driverPos = _driverPosition;
    if (driverPos == null) return;

    final LatLng? pickupCoords = widget.shipment.originLat != 0.0
        ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
        : (_currentRoutePoints.isNotEmpty ? _currentRoutePoints.first : null);

    final originAddr = widget.shipment.originAddress.isNotEmpty &&
            widget.shipment.originAddress != '—'
        ? widget.shipment.originAddress
        : widget.shipment.originTitle;

    try {
      final leg1Result =
          await GoogleNavigationService().fetchRouteByAddressOrCoords(
        originAddress: _driverCity,
        originCoords: driverPos,
        destinationAddress: originAddr,
        destinationCoords: pickupCoords,
        destinationTitle: 'Pickup Location',
      );

      if (mounted && leg1Result != null && leg1Result.polylinePoints.isNotEmpty) {
        setState(() {
          _driverToPickupPoints = leg1Result.polylinePoints;
          _leg1DistanceKm = leg1Result.totalDistanceKm;
          _leg1DistanceText =
              GoogleNavigationService.formatDistance(leg1Result.totalDistanceKm);
          _leg1DurationText = Formatters.formatCompactDuration(
            leg1Result.totalDurationText,
          );
          _leg1Minutes = _parseMinutesFromString(_leg1DurationText);
          if (_leg1Minutes <= 0) {
            _leg1Minutes = (leg1Result.totalDistanceKm * 2.0).round().clamp(1, 999);
          }
        });
      } else if (mounted && pickupCoords != null) {
        final distM = GoogleNavigationService.distanceBetween(driverPos, pickupCoords);
        final distKm = (distM / 1000.0 * 10).round() / 10.0;
        final mins = (distKm * 2.0).round().clamp(1, 999);
        setState(() {
          _driverToPickupPoints = _buildSmoothConnectingLine(driverPos, pickupCoords);
          _leg1DistanceKm = distKm;
          _leg1DistanceText = GoogleNavigationService.formatDistance(distKm);
          _leg1DurationText = _formatTotalDuration(mins);
          _leg1Minutes = mins;
        });
      }
    } catch (_) {}
  }

  Future<void> _initRouteData({bool force = false}) async {
    final originAddr =
        widget.shipment.originAddress.isNotEmpty &&
                widget.shipment.originAddress != '—'
            ? widget.shipment.originAddress
            : widget.shipment.originTitle;
    final destAddr =
        widget.shipment.destAddress.isNotEmpty &&
                widget.shipment.destAddress != '—'
            ? widget.shipment.destAddress
            : widget.shipment.destTitle;

    final LatLng? pickupCoords = widget.shipment.originLat != 0.0
        ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
        : (_currentRoutePoints.isNotEmpty ? _currentRoutePoints.first : null);

    final LatLng? destCoords = widget.shipment.destLat != 0.0
        ? LatLng(widget.shipment.destLat, widget.shipment.destLng)
        : (_currentRoutePoints.isNotEmpty ? _currentRoutePoints.last : null);

    // 1. Fetch Leg 2: Pickup -> Delivery
    final result = await GoogleNavigationService().fetchRouteByAddressOrCoords(
      originAddress: originAddr,
      originCoords: pickupCoords,
      destinationAddress: destAddr,
      destinationCoords: destCoords,
      destinationTitle: widget.shipment.destTitle,
      forceRefresh: force,
    );

    if (mounted && result != null) {
      setState(() {
        if (result.polylinePoints.isNotEmpty) {
          _currentRoutePoints = result.polylinePoints;
        }
        _alternativeRoutes = result.alternatives;
        if (result.alternativePoints != null &&
            result.alternativePoints!.isNotEmpty) {
          _altRoutePoints = result.alternativePoints;
        } else if (_currentRoutePoints.length >= 4) {
          _altRoutePoints = _generateAlternativeCurve(
            _currentRoutePoints,
            offsetKm: -1.8,
          );
        }

        if (_alternativeRoutes.length > 1 &&
            _alternativeRoutes[1].polylinePoints.isNotEmpty) {
          _alt2RoutePoints = _alternativeRoutes[1].polylinePoints;
        } else if (_currentRoutePoints.length >= 4) {
          _alt2RoutePoints = _generateAlternativeCurve(
            _currentRoutePoints,
            offsetKm: 2.3,
          );
        }

        if (result.totalDurationText.isNotEmpty) {
          _calculatedDuration = Formatters.formatCompactDuration(
            result.totalDurationText,
          );
        }
        if (result.totalDistanceKm > 0) {
          _calculatedDistanceKm = result.totalDistanceKm;
        }
      });
    } else if (mounted && _currentRoutePoints.length >= 4) {
      setState(() {
        _altRoutePoints ??= _generateAlternativeCurve(
          _currentRoutePoints,
          offsetKm: -1.8,
        );
        _alt2RoutePoints ??= _generateAlternativeCurve(
          _currentRoutePoints,
          offsetKm: 2.3,
        );
      });
    }

    // 2. Fetch Leg 1 if driver position already resolved
    _fetchLeg1Route();
  }

  List<LatLng> _buildSmoothConnectingLine(LatLng start, LatLng end) {
    final List<LatLng> points = [];
    const int segments = 12;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final offset = math.sin(t * math.pi) * 0.008;
      points.add(LatLng(lat + offset * 0.4, lng + offset));
    }
    return points;
  }

  List<LatLng> _generateAlternativeCurve(
    List<LatLng> base, {
    required double offsetKm,
  }) {
    if (base.length < 3) return base;
    final List<LatLng> result = [];
    final n = base.length;
    for (int i = 0; i < n; i++) {
      if (i == 0 || i == n - 1) {
        result.add(base[i]);
      } else {
        final t = i / (n - 1);
        final factor = math.sin(t * math.pi);
        final dLat = (offsetKm / 111.0) * factor * 0.4;
        final dLng = (offsetKm / 111.0) * factor * 0.8;
        result.add(LatLng(base[i].latitude + dLat, base[i].longitude + dLng));
      }
    }
    return result;
  }

  int _getLeg2Minutes() {
    if (_calculatedDuration.isNotEmpty && _calculatedDuration != '—') {
      final m = _parseMinutesFromString(_calculatedDuration);
      if (m > 0) return m;
    }
    if (widget.estimatedDuration.isNotEmpty &&
        widget.estimatedDuration != '—') {
      final m = _parseMinutesFromString(widget.estimatedDuration);
      if (m > 0) return m;
    }
    if (widget.shipment.estimatedDuration.isNotEmpty &&
        widget.shipment.estimatedDuration != '—') {
      final m = _parseMinutesFromString(widget.shipment.estimatedDuration);
      if (m > 0) return m;
    }
    if (_calculatedDistanceKm > 0) {
      return (_calculatedDistanceKm * 1.8).round().clamp(5, 9999);
    }
    return 30;
  }

  double _getLeg2Km() {
    if (_calculatedDistanceKm > 0) return _calculatedDistanceKm;
    if (widget.shipment.distanceKm > 0) return widget.shipment.distanceKm;
    final parsed = double.tryParse(
      widget.shipment.formattedDistance.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (parsed != null && parsed > 0) return parsed;
    return 10.0;
  }

  int _parseMinutesFromString(String text) {
    try {
      int total = 0;
      final hrMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(text);
      if (hrMatch != null) {
        total += (int.tryParse(hrMatch.group(1) ?? '0') ?? 0) * 60;
      }
      final minMatch =
          RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(text);
      if (minMatch != null) {
        total += int.tryParse(minMatch.group(1) ?? '0') ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  String _formatTotalDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return mins > 0 ? '$hours hr $mins min' : '$hours hr';
    }
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isRouteTabReady) {
      return _buildRouteTabSkeleton();
    }

    final originAddr = (widget.shipment.originAddress.isNotEmpty &&
            widget.shipment.originAddress != 'Pickup Address' &&
            widget.shipment.originAddress != '—')
        ? widget.shipment.originAddress
        : (widget.shipment.originTitle.isNotEmpty &&
                widget.shipment.originTitle != '—'
            ? widget.shipment.originTitle
            : 'Pickup Location');

    final destAddr = (widget.shipment.destAddress.isNotEmpty &&
            widget.shipment.destAddress != 'Delivery Address' &&
            widget.shipment.destAddress != '—')
        ? widget.shipment.destAddress
        : (widget.shipment.destTitle.isNotEmpty &&
                widget.shipment.destTitle != '—'
            ? widget.shipment.destTitle
            : 'Delivery Location');

    // Dynamically extract area/city from address, or fallback to titles
    final originCity = GoogleNavigationService.extractCityOrArea(
      originAddr,
      fallback: widget.shipment.originCompany.isNotEmpty &&
              widget.shipment.originCompany != '—'
          ? widget.shipment.originCompany
          : (widget.shipment.originTitle.isNotEmpty &&
                  widget.shipment.originTitle != '—'
              ? widget.shipment.originTitle
              : 'Pickup Location'),
    );

    final destCity = GoogleNavigationService.extractCityOrArea(
      destAddr,
      fallback: widget.shipment.destCompany.isNotEmpty &&
              widget.shipment.destCompany != '—'
          ? widget.shipment.destCompany
          : (widget.shipment.destTitle.isNotEmpty &&
                  widget.shipment.destTitle != '—'
              ? widget.shipment.destTitle
              : 'Delivery Location'),
    );

    final pickupBadge = GoogleNavigationService.extractShortBadgeLabel(
      originAddr,
      fallback: originCity.split(',').first.trim(),
    );

    final deliveryBadge = GoogleNavigationService.extractShortBadgeLabel(
      destAddr,
      fallback: destCity.split(',').first.trim(),
    );

    // Metrics calculation
    final leg2Km = _getLeg2Km();
    final leg2Mins = _getLeg2Minutes();

    final leg1DistText = _leg1DistanceText.isNotEmpty
        ? _leg1DistanceText
        : (_leg1DistanceKm > 0
            ? GoogleNavigationService.formatDistance(_leg1DistanceKm)
            : 'Nearby');
    final leg1DurText = _leg1DurationText.isNotEmpty
        ? _leg1DurationText
        : (_leg1Minutes > 0 ? _formatTotalDuration(_leg1Minutes) : '');

    final leg2DistText = GoogleNavigationService.formatDistance(leg2Km);
    final leg2DurText = _formatTotalDuration(leg2Mins);

    // Total journey (Driver -> Pickup -> Delivery)
    final totalKm0 = _leg1DistanceKm + leg2Km;
    final totalMins0 = _leg1Minutes + leg2Mins;
    final totalDistText0 = GoogleNavigationService.formatDistance(totalKm0);
    final totalDurText0 = _formatTotalDuration(totalMins0);

    // Alternative 1 (Google Maps Directions alternatives if available)
    final double alt1Km = _alternativeRoutes.isNotEmpty &&
            _alternativeRoutes[0].distanceKm > 0
        ? _alternativeRoutes[0].distanceKm
        : (leg2Km * 1.05 + 1.2);
    final int alt1Mins = _alternativeRoutes.isNotEmpty &&
            _alternativeRoutes[0].durationSeconds > 0
        ? (_alternativeRoutes[0].durationSeconds ~/ 60)
        : (leg2Mins + (leg2Mins * 0.08).round().clamp(3, 40));
    final totalKm1 = _leg1DistanceKm + alt1Km;
    final totalMins1 = _leg1Minutes + alt1Mins;
    final totalDistText1 = GoogleNavigationService.formatDistance(totalKm1);
    final totalDurText1 = _formatTotalDuration(totalMins1);

    // Alternative 2 (Google Maps Directions alternatives if available)
    final double alt2Km = _alternativeRoutes.length > 1 &&
            _alternativeRoutes[1].distanceKm > 0
        ? _alternativeRoutes[1].distanceKm
        : (leg2Km * 1.09 + 2.5);
    final int alt2Mins = _alternativeRoutes.length > 1 &&
            _alternativeRoutes[1].durationSeconds > 0
        ? (_alternativeRoutes[1].durationSeconds ~/ 60)
        : (leg2Mins + (leg2Mins * 0.14).round().clamp(5, 60));
    final totalKm2 = _leg1DistanceKm + alt2Km;
    final totalMins2 = _leg1Minutes + alt2Mins;
    final totalDistText2 = GoogleNavigationService.formatDistance(totalKm2);
    final totalDurText2 = _formatTotalDuration(totalMins2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =================================================================
          // 1. Top Location Stops Card (Driver -> Pickup -> Delivery)
          // =================================================================
          _buildStopsCard(
            driverCity: _driverCity,
            pickupAddress: originAddr,
            deliveryAddress: destAddr,
          ),

          const SizedBox(height: 6),

          // =================================================================
          // 2. Embedded Map View Card (Expanded to fill available space!)
          // =================================================================
          Expanded(
            child: _buildMapCard(
              originAddr: originAddr,
              destAddr: destAddr,
              originCity: originCity,
              destCity: destCity,
              pickupBadge: pickupBadge,
              deliveryBadge: deliveryBadge,
              dur0: leg2DurText,
              dist0: leg2DistText,
              dur1: _formatTotalDuration(alt1Mins),
              dist1: GoogleNavigationService.formatDistance(alt1Km),
              dur2: _formatTotalDuration(alt2Mins),
              dist2: GoogleNavigationService.formatDistance(alt2Km),
            ),
          ),

          const SizedBox(height: 6),

          // =================================================================
          // 3. 3-Segment Journey Metrics Bar
          // =================================================================
          _buildJourneyMetricsBar(
            leg1Dist: leg1DistText,
            leg1Dur: leg1DurText,
            leg2Dist: leg2DistText,
            leg2Dur: leg2DurText,
            totalDist: totalDistText0,
            totalDur: totalDurText0,
          ),

          const SizedBox(height: 6),

          // =================================================================
          // 4. Route Options Section (Fastest, Alt 1, Alt 2) + Traffic switch
          // =================================================================
          _buildRouteOptionsSection(
            dur0: totalDurText0,
            dist0: totalDistText0,
            dur1: totalDurText1,
            dist1: totalDistText1,
            dur2: totalDurText2,
            dist2: totalDistText2,
          ),

          const SizedBox(height: 10),

          // =================================================================
          // 5. Full-Width Start Navigation CTA Button
          // =================================================================
          _buildStartNavigationButton(
            estimatedDuration: totalDurText0,
            estimatedDistance: totalDistText0,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. Top Location Stops Card (Compact & 5px radius)
  // =========================================================================
  Widget _buildStopsCard({
    required String driverCity,
    required String pickupAddress,
    required String deliveryAddress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stop 1: Driver Current Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.radio_button_checked_rounded,
                color: Color(0xFF2563EB),
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location (Driver)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: slateDark,
                      ),
                    ),
                    Text(
                      driverCity,
                      style: GoogleFonts.inter(
                        fontSize: 10.0,
                        color: slateMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Current Location pill
              GestureDetector(
                onTap: _fetchLiveDriverLocation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 11.5,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Current Location',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Dashed connector 1
          Padding(
            padding: const EdgeInsets.only(left: 6.5, top: 1, bottom: 1),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashedVerticalLine(
                height: 7,
                iconWidth: 1.2,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),

          // Stop 2: Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: greenPickup,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: greenPickup,
                      ),
                    ),
                    Text(
                      pickupAddress,
                      style: GoogleFonts.inter(
                        fontSize: 10.0,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Circular navigation button
              GestureDetector(
                onTap: () {
                  MapLauncherHelper.openGoogleMaps(
                    context,
                    destinationAddress: pickupAddress,
                    destinationTitle: 'Pickup',
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: 45 * math.pi / 180,
                      child: const Icon(
                        Icons.navigation_rounded,
                        size: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Dashed connector 2
          Padding(
            padding: const EdgeInsets.only(left: 6.5, top: 1, bottom: 1),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashedVerticalLine(
                height: 7,
                iconWidth: 1.2,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),

          // Stop 3: Delivery
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: redDelivery,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: redDelivery,
                      ),
                    ),
                    Text(
                      deliveryAddress,
                      style: GoogleFonts.inter(
                        fontSize: 10.0,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Circular navigation button
              GestureDetector(
                onTap: () {
                  MapLauncherHelper.openGoogleMaps(
                    context,
                    destinationAddress: deliveryAddress,
                    destinationTitle: 'Delivery',
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: 45 * math.pi / 180,
                      child: const Icon(
                        Icons.navigation_rounded,
                        size: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. Embedded Map View Card (Takes all remaining vertical space via Expanded)
  // =========================================================================
  Widget _buildMapCard({
    required String originAddr,
    required String destAddr,
    required String originCity,
    required String destCity,
    required String pickupBadge,
    required String deliveryBadge,
    required String dur0,
    required String dist0,
    required String dur1,
    required String dist1,
    required String dur2,
    required String dist2,
  }) {
    final pickupCoords = widget.shipment.originLat != 0.0
        ? LatLng(widget.shipment.originLat, widget.shipment.originLng)
        : (_currentRoutePoints.isNotEmpty
            ? _currentRoutePoints.first
            : null);

    final destCoords = widget.shipment.destLat != 0.0
        ? LatLng(widget.shipment.destLat, widget.shipment.destLng)
        : (_currentRoutePoints.isNotEmpty
            ? _currentRoutePoints.last
            : null);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _isRouteTabReady
          ? InAppGoogleMapView(
              showTwoLegJourney: true,
              driverPosition: _driverPosition ?? const LatLng(23.8041, 90.3667),
              driverToPickupPoints: _driverToPickupPoints,
              driverToPickupDistance: _leg1DistanceText,
              driverToPickupDuration: _leg1DurationText,
              pickupLabel: pickupBadge,
              deliveryLabel: deliveryBadge,
              orderIdText: widget.shipment.id,
              driverCity: _driverCity,
              originCity: originCity,
              destCity: destCity,
              origin: pickupCoords ?? const LatLng(23.8041, 90.3667),
              destination: destCoords ?? const LatLng(23.8041, 90.3667),
              originTitle: originCity,
              destinationTitle: destCity,
              originAddress: originAddr,
              destinationAddress: destAddr,
              customRoutePoints: _currentRoutePoints,
              alternativeRoutePoints: _altRoutePoints,
              alternative2RoutePoints: _alt2RoutePoints,
              fastestDuration: dur0,
              fastestDistance: dist0,
              alternativeDuration: dur1,
              alternativeDistance: dist1,
              alternative2Duration: dur2,
              alternative2Distance: dist2,
              trafficEnabled: _liveTrafficEnabled,
              selectedRouteIndex: _selectedRouteIndex,
              onRouteSelected: (idx) {
                setState(() => _selectedRouteIndex = idx);
              },
              showRouteBadges: false,
              isInteractive: true,
            )
          : const MapSkeletonPlaceholder(),
    );
  }

  // =========================================================================
  // 3. 3-Segment Journey Metrics Bar (Compact & 5px radius)
  // =========================================================================
  Widget _buildJourneyMetricsBar({
    required String leg1Dist,
    required String leg1Dur,
    required String leg2Dist,
    required String leg2Dur,
    required String totalDist,
    required String totalDur,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Segment 1: Driver -> Pickup
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFF2563EB),
                      size: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Driver → Pickup',
                        style: GoogleFonts.inter(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        '$leg1Dist • $leg1Dur',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: slateDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider 1
          Container(
            height: 20,
            width: 1,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 3),
          ),

          // Segment 2: Pickup -> Delivery
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: greenPickup,
                      size: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pickup → Delivery',
                        style: GoogleFonts.inter(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          color: greenPickup,
                        ),
                      ),
                      Text(
                        '$leg2Dist • $leg2Dur',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: slateDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider 2
          Container(
            height: 20,
            width: 1,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 3),
          ),

          // Segment 3: Total Journey
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_rounded,
                      color: slateDark,
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Journey',
                        style: GoogleFonts.inter(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          color: slateMuted,
                        ),
                      ),
                      Text(
                        '$totalDist • $totalDur',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: slateDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. Route Options Section (Compact & 5px radius)
  // =========================================================================
  Widget _buildRouteOptionsSection({
    required String dur0,
    required String dist0,
    required String dur1,
    required String dist1,
    required String dur2,
    required String dist2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Route Options + Traffic switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  color: orangePrimary,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  'Route Options',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: slateDark,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Traffic',
                  style: GoogleFonts.inter(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: slateMuted,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 18,
                  width: 32,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: _liveTrafficEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: orangePrimary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() => _liveTrafficEnabled = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 5),

        // 3 Route Cards
        Row(
          children: [
            _buildRouteCard(
              index: 0,
              title: 'Fastest',
              duration: dur0,
              distance: dist0,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(width: 6),
            _buildRouteCard(
              index: 1,
              title: 'Alt 1',
              duration: dur1,
              distance: dist1,
              icon: Icons.alt_route_rounded,
            ),
            const SizedBox(width: 6),
            _buildRouteCard(
              index: 2,
              title: 'Alt 2',
              duration: dur2,
              distance: dist2,
              icon: Icons.alt_route_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteCard({
    required int index,
    required String title,
    required String duration,
    required String distance,
    required IconData icon,
  }) {
    final bool isSelected = _selectedRouteIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRouteIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(
              color: isSelected ? orangePrimary : borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? orangePrimary.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Icon + Title + Selected indicator
              Row(
                children: [
                  Icon(
                    icon,
                    size: 11,
                    color: isSelected ? orangePrimary : slateMuted,
                  ),
                  const SizedBox(width: 2.5),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? orangePrimary : slateDark,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: orangePrimary,
                    )
                  else
                    const Icon(
                      Icons.radio_button_unchecked,
                      size: 11,
                      color: Color(0xFFCBD5E1),
                    ),
                ],
              ),

              const SizedBox(height: 3),

              // Large Duration
              Text(
                duration,
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w900,
                  color: slateDark,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 1),

              // Distance
              Text(
                distance,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: slateMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 5. Full-Width Start Navigation CTA Button (Compact & Stadium)
  // =========================================================================
  Widget _buildStartNavigationButton({
    required String estimatedDuration,
    required String estimatedDistance,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TurnByTurnGpsScreen(
                shipment: widget.shipment,
                initialRoutePoints: _currentRoutePoints,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: orangePrimary,
          elevation: 1,
          shadowColor: orangePrimary.withValues(alpha: 0.25),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: 45 * math.pi / 180,
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Start Navigation',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 6. Route Tab Full Skeleton Loader (Animated shimmer, pure map skeleton)
  // =========================================================================
  Widget _buildShimmerBox({
    required double height,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        final val = _shimmerAnimation.value;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(5.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
              stops: [
                (val - 0.35).clamp(0.0, 1.0),
                val.clamp(0.0, 1.0),
                (val + 0.35).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteTabSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Location Stops Card Skeleton (5px radius)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Stop 1: Driver
                Row(
                  children: [
                    _buildShimmerBox(
                      height: 14,
                      width: 14,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 10, width: 110),
                          const SizedBox(height: 4),
                          _buildShimmerBox(height: 9, width: 70),
                        ],
                      ),
                    ),
                    _buildShimmerBox(
                      height: 20,
                      width: 75,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Stop 2: Pickup
                Row(
                  children: [
                    _buildShimmerBox(
                      height: 14,
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 10, width: 50),
                          const SizedBox(height: 4),
                          _buildShimmerBox(height: 9, width: 160),
                        ],
                      ),
                    ),
                    _buildShimmerBox(
                      height: 20,
                      width: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Stop 3: Delivery
                Row(
                  children: [
                    _buildShimmerBox(
                      height: 14,
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 10, width: 55),
                          const SizedBox(height: 4),
                          _buildShimmerBox(height: 9, width: 150),
                        ],
                      ),
                    ),
                    _buildShimmerBox(
                      height: 20,
                      width: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 2. Embedded Map View Skeleton (Takes all remaining vertical space)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: const MapSkeletonPlaceholder(),
            ),
          ),

          const SizedBox(height: 6),

          // 3. 3-Segment Journey Metrics Bar Skeleton (5px radius)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildShimmerBox(
                        height: 22,
                        width: 22,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 8, width: 55),
                          const SizedBox(height: 3),
                          _buildShimmerBox(height: 9, width: 70),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0xFFF1F5F9),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        _buildShimmerBox(
                          height: 22,
                          width: 22,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBox(height: 8, width: 55),
                            const SizedBox(height: 3),
                            _buildShimmerBox(height: 9, width: 70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0xFFF1F5F9),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildShimmerBox(
                        height: 22,
                        width: 22,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 8, width: 55),
                          const SizedBox(height: 3),
                          _buildShimmerBox(height: 9, width: 70),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 4. Route Selection Skeleton (3 options horizontal row)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(
                    height: 12,
                    width: 12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(width: 5),
                  _buildShimmerBox(height: 12, width: 85),
                  const Spacer(),
                  _buildShimmerBox(height: 10, width: 35),
                  const SizedBox(width: 2),
                  _buildShimmerBox(
                    height: 12,
                    width: 12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 10, width: 45),
                          const Spacer(),
                          _buildShimmerBox(height: 13, width: 55),
                          const SizedBox(height: 2),
                          _buildShimmerBox(height: 9, width: 40),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 10, width: 45),
                          const Spacer(),
                          _buildShimmerBox(height: 13, width: 55),
                          const SizedBox(height: 2),
                          _buildShimmerBox(height: 9, width: 40),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(height: 10, width: 45),
                          const Spacer(),
                          _buildShimmerBox(height: 13, width: 55),
                          const SizedBox(height: 2),
                          _buildShimmerBox(height: 9, width: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 5. Start Navigation Button Skeleton (44px pill)
          _buildShimmerBox(
            height: 44,
            borderRadius: BorderRadius.circular(22.0),
          ),
        ],
      ),
    );
  }
}
