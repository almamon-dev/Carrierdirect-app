import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../services/google_navigation_service.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/dashed_vertical_line.dart';
import '../../data/models/shipment_item_model.dart';
import '../widgets/in_app_google_map_view.dart';
import 'turn_by_turn_gps_screen.dart';


class RouteOverviewScreen extends StatefulWidget {
  final ShipmentItem shipment;

  const RouteOverviewScreen({super.key, required this.shipment});

  @override
  State<RouteOverviewScreen> createState() => _RouteOverviewScreenState();
}

class _RouteOverviewScreenState extends State<RouteOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LatLng> _routePoints = [];
  List<LatLng>? _altRoutePoints;
  String _altDuration = '';
  List<LatLng>? _alt2RoutePoints;
  String _alt2Duration = '';
  int _trafficDelayMinutes = 0;
  String? _trafficStatusText;
  String _calculatedDuration = '—';
  double _distanceKm = 0.0;
  LatLng _originCoords = const LatLng(0.0, 0.0);
  LatLng _destCoords = const LatLng(0.0, 0.0);
  int _selectedRouteIndex = 0;

  static const Color orangePrimary = Color(0xFFFF5722);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color greenPickup = Color(0xFF16A34A);
  static const Color redDelivery = Color(0xFFE53935);

  // Exact 5px card border radius requested by user
  static const double cardRadius = 5.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initStats();
    _loadRoute();
  }

  void _initStats() {
    if (widget.shipment.originLat != 0.0 && widget.shipment.originLng != 0.0) {
      _originCoords = LatLng(widget.shipment.originLat, widget.shipment.originLng);
    }
    if (widget.shipment.destLat != 0.0 && widget.shipment.destLng != 0.0) {
      _destCoords = LatLng(widget.shipment.destLat, widget.shipment.destLng);
    }
    if (widget.shipment.distanceKm > 0) {
      _distanceKm = widget.shipment.distanceKm;
      if (widget.shipment.estimatedDuration.isNotEmpty) {
        _calculatedDuration = Formatters.formatCompactDuration(
          widget.shipment.estimatedDuration,
        );
      } else {
        final totalMins = ((_distanceKm / 75.0) * 60).round();
        final hours = totalMins ~/ 60;
        final mins = totalMins % 60;
        if (hours > 0) {
          _calculatedDuration = '${hours}h ${mins > 0 ? '${mins}m' : ''}'.trim();
        } else {
          _calculatedDuration = '${mins}m';
        }
      }
    } else {
      _distanceKm = 0.0;
      _calculatedDuration = widget.shipment.estimatedDuration.isNotEmpty
          ? Formatters.formatCompactDuration(widget.shipment.estimatedDuration)
          : '—';
    }
  }

  Future<void> _loadRoute() async {
    try {
      final originAddr = widget.shipment.originAddress.isNotEmpty &&
              widget.shipment.originAddress != '—'
          ? widget.shipment.originAddress
          : widget.shipment.originTitle;
      final destAddr = widget.shipment.destAddress.isNotEmpty &&
              widget.shipment.destAddress != '—'
          ? widget.shipment.destAddress
          : widget.shipment.destTitle;

      final result = await GoogleNavigationService().fetchRouteByAddressOrCoords(
        originAddress: originAddr,
        originCoords: _originCoords.latitude != 0.0 ? _originCoords : null,
        destinationAddress: destAddr,
        destinationCoords: _destCoords.latitude != 0.0 ? _destCoords : null,
        destinationTitle: widget.shipment.destTitle,
      );

      if (mounted && result != null) {
        setState(() {
          if (result.polylinePoints.isNotEmpty) {
            _routePoints = result.polylinePoints;
          }
          if (result.alternativePoints != null && result.alternativePoints!.isNotEmpty) {
            _altRoutePoints = result.alternativePoints;
          }
          if (result.alternatives.isNotEmpty) {
            _altDuration = result.alternatives.first.durationText;
          }
          if (result.alternatives.length > 1) {
            _alt2RoutePoints = result.alternatives[1].polylinePoints;
            _alt2Duration = result.alternatives[1].durationText;
          }
          _trafficDelayMinutes = result.trafficDelayMinutes;
          _trafficStatusText = result.trafficStatusText;

          if (result.resolvedOrigin != null) {
            _originCoords = result.resolvedOrigin!;
          }
          if (result.resolvedDestination != null) {
            _destCoords = result.resolvedDestination!;
          }
          if (result.totalDistanceKm > 0 && _distanceKm <= 0) {
            _distanceKm = (result.totalDistanceKm * 10).round() / 10.0;
          }
          if (result.totalDurationText.isNotEmpty) {
            _calculatedDuration = Formatters.formatCompactDuration(result.totalDurationText);
          }
        });
        return;
      }
    } catch (_) {}
  }

  void _startNavigation() {
    final selectedPoints = (_selectedRouteIndex == 1 && _altRoutePoints != null && _altRoutePoints!.isNotEmpty)
        ? _altRoutePoints
        : _routePoints;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TurnByTurnGpsScreen(
          shipment: widget.shipment,
          initialRoutePoints: selectedPoints,
        ),
      ),
    );
  }

  String _getFormattedOrderId() {
    final rawId = widget.shipment.id.trim();
    if (rawId.isEmpty || rawId == '—') return 'ORD-2026-10001';
    final clean = rawId.replaceAll('#', '').trim();
    if (clean.toUpperCase().startsWith('ORD-')) return clean;
    return 'ORD-$clean';
  }

  void _shareRoute() {
    final orderId = _getFormattedOrderId();
    final shareText =
        'Tracking Shipment #$orderId\nFrom: ${widget.shipment.originAddress}\nTo: ${widget.shipment.destAddress}\nDistance: ${_distanceKm.toStringAsFixed(0)} km • Duration: $_calculatedDuration';
    Clipboard.setData(ClipboardData(text: shareText));
    AppToast.success(context, 'Route tracking details copied to clipboard!');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: slateDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Route Overview',
          style: GoogleFonts.inter(
            color: slateDark,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: slateDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: orangePrimary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: orangePrimary,
              unselectedLabelColor: slateMuted,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_list_bulleted_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Overview'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Route'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildRouteStopsTab(),
                ],
              ),
            ),
            // Bottom Sticky CTA: Start Navigation
            _buildBottomStartNavigationButton(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW TAB (Mockup Middle Screen)
  // ==========================================
  Widget _buildOverviewTab() {
    final orderId = _getFormattedOrderId();

    final originAddr = widget.shipment.originAddress.isNotEmpty &&
            widget.shipment.originAddress != '—'
        ? widget.shipment.originAddress
        : widget.shipment.originTitle;

    final destAddr = widget.shipment.destAddress.isNotEmpty &&
            widget.shipment.destAddress != '—'
        ? widget.shipment.destAddress
        : widget.shipment.destTitle;

    final pickupDateStr = widget.shipment.pickupDate.isNotEmpty &&
            widget.shipment.pickupDate != '—'
        ? '${widget.shipment.pickupDate}${widget.shipment.pickupTime.isNotEmpty && widget.shipment.pickupTime != '—' ? ' • ${widget.shipment.pickupTime}' : ''}'
        : (widget.shipment.date.isNotEmpty ? widget.shipment.date : '—');

    final deliveryDateStr = widget.shipment.deliveryDate.isNotEmpty &&
            widget.shipment.deliveryDate != '—'
        ? '${widget.shipment.deliveryDate}${widget.shipment.deliveryTime.isNotEmpty && widget.shipment.deliveryTime != '—' ? ' • ${widget.shipment.deliveryTime}' : ''}'
        : '—';

    final distStr = _distanceKm > 0
        ? '${_distanceKm.toStringAsFixed(_distanceKm.truncateToDouble() == _distanceKm ? 0 : 1)} km'
        : widget.shipment.formattedDistance;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stats Row: Distance & Est. Time (5px Radius)
          _buildStatsRow(
            icon1: Icons.alt_route_rounded,
            value1: distStr,
            label1: 'Distance',
            icon2: Icons.access_time_rounded,
            value2: _calculatedDuration,
            label2: 'Est. Time',
          ),

          const SizedBox(height: 14),

          // 2. Shipment Card with Order ID & Timeline (5px Radius)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: orangePrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$orderId',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: slateDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            '1 Shipment',
                            style: TextStyle(
                              color: slateMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Pickup Stop
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: greenPickup,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Pickup',
                              style: TextStyle(
                                color: greenPickup,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            originAddr,
                            style: GoogleFonts.inter(
                              color: slateDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: orangePrimary,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  pickupDateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: orangePrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Connecting Line
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
                  child: DashedVerticalLine(
                    iconWidth: 2,
                    height: 24,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),

                // Delivery Stop
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: redDelivery,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Delivery',
                              style: TextStyle(
                                color: redDelivery,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            destAddr,
                            style: GoogleFonts.inter(
                              color: slateDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: orangePrimary,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  deliveryDateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: orangePrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Quick Actions
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              color: slateDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // View on Map Button (5px Radius)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: orangePrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View on Map',
                          style: GoogleFonts.inter(
                            color: slateDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Share Route Button (5px Radius)
              Expanded(
                child: GestureDetector(
                  onTap: _shareRoute,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          color: orangePrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Share Route',
                          style: GoogleFonts.inter(
                            color: slateDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  // ==========================================
  // TAB 2: ROUTE STOPS TAB (Mockup Right Screen)
  // ==========================================
  Widget _buildRouteStopsTab() {
    final originAddr = widget.shipment.originAddress.isNotEmpty &&
            widget.shipment.originAddress != '—'
        ? widget.shipment.originAddress
        : widget.shipment.originTitle;

    final originCity = widget.shipment.originCompany.isNotEmpty &&
            widget.shipment.originCompany != '—'
        ? widget.shipment.originCompany
        : (widget.shipment.originTitle.isNotEmpty && widget.shipment.originTitle != '—'
            ? widget.shipment.originTitle
            : 'Origin');

    final destAddr = widget.shipment.destAddress.isNotEmpty &&
            widget.shipment.destAddress != '—'
        ? widget.shipment.destAddress
        : widget.shipment.destTitle;

    final destCity = widget.shipment.destCompany.isNotEmpty &&
            widget.shipment.destCompany != '—'
        ? widget.shipment.destCompany
        : (widget.shipment.destTitle.isNotEmpty && widget.shipment.destTitle != '—'
            ? widget.shipment.destTitle
            : 'Destination');

    final pickupDateStr = widget.shipment.pickupDate.isNotEmpty &&
            widget.shipment.pickupDate != '—'
        ? '${widget.shipment.pickupDate}${widget.shipment.pickupTime.isNotEmpty && widget.shipment.pickupTime != '—' ? ' • ${widget.shipment.pickupTime}' : ''}'
        : (widget.shipment.date.isNotEmpty ? widget.shipment.date : '—');

    final deliveryDateStr = widget.shipment.deliveryDate.isNotEmpty &&
            widget.shipment.deliveryDate != '—'
        ? '${widget.shipment.deliveryDate}${widget.shipment.deliveryTime.isNotEmpty && widget.shipment.deliveryTime != '—' ? ' • ${widget.shipment.deliveryTime}' : ''}'
        : '—';

    final distStr = _distanceKm > 0
        ? '${_distanceKm.toStringAsFixed(_distanceKm.truncateToDouble() == _distanceKm ? 0 : 1)} km'
        : widget.shipment.formattedDistance;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stats Row: Total Stops & Total Distance (5px Radius)
          _buildStatsRow(
            icon1: Icons.location_on_outlined,
            value1: '2 Stops',
            label1: 'Total Stops',
            icon2: Icons.alt_route_rounded,
            value2: distStr,
            label2: 'Total Distance',
          ),

          const SizedBox(height: 14),

          // 2. Stops List Card (5px Radius)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Stop 1 (Pickup)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: greenPickup,
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Pickup',
                              style: TextStyle(
                                color: greenPickup,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            originAddr,
                            style: GoogleFonts.inter(
                              color: slateDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            originCity,
                            style: const TextStyle(
                              color: slateMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: orangePrimary,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  pickupDateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: orangePrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),

                // Dotted connector
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DashedVerticalLine(
                      iconWidth: 2,
                      height: 28,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),

                // Stop 2 (Delivery)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: redDelivery,
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Delivery',
                              style: TextStyle(
                                color: redDelivery,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            destAddr,
                            style: GoogleFonts.inter(
                              color: slateDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            destCity,
                            style: const TextStyle(
                              color: slateMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: orangePrimary,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  deliveryDateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: orangePrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Embedded Google Map Preview (5px Radius) with Live Traffic & Alternatives
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InAppGoogleMapView(
              origin: _originCoords.latitude != 0.0
                  ? _originCoords
                  : (_routePoints.isNotEmpty ? _routePoints.first : const LatLng(0.0, 0.0)),
              destination: _destCoords.latitude != 0.0
                  ? _destCoords
                  : (_routePoints.isNotEmpty ? _routePoints.last : const LatLng(0.0, 0.0)),
              originTitle: originCity,
              destinationTitle: destCity,
              originAddress: originAddr,
              destinationAddress: destAddr,
              customRoutePoints: _routePoints,
              alternativeRoutePoints: _altRoutePoints,
              alternative2RoutePoints: _alt2RoutePoints,
              fastestDuration: _calculatedDuration,
              fastestDistance: _distanceKm > 0
                  ? GoogleNavigationService.formatDistance(_distanceKm)
                  : '',
              alternativeDuration: _altDuration,
              alternativeDistance: _distanceKm > 0
                  ? GoogleNavigationService.formatDistance(_distanceKm * 1.11)
                  : '',
              alternative2Duration: _alt2Duration,
              alternative2Distance: _distanceKm > 0
                  ? GoogleNavigationService.formatDistance(_distanceKm * 1.21)
                  : '',
              selectedRouteIndex: _selectedRouteIndex,
              onRouteSelected: (idx) {
                setState(() => _selectedRouteIndex = idx);
              },
              showRouteBadges: true,
              isInteractive: true,
            ),
          ),

          // Live Traffic Alert Banner if delay detected
          if (_trafficDelayMinutes >= 3)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.traffic_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _trafficStatusText ?? 'Traffic delay: +${_trafficDelayMinutes}m slowdown reported along route',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED STATS ROW (2 White Cards with 5px Radius)
  // ==========================================
  Widget _buildStatsRow({
    required IconData icon1,
    required String value1,
    required String label1,
    required IconData icon2,
    required String value2,
    required String label2,
  }) {
    return Row(
      children: [
        // Left Stat Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon1, color: slateDark, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value1,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            color: slateDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        label1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: slateMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Right Stat Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon2, color: slateDark, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value2,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            color: slateDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        label2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: slateMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM STICKY START NAVIGATION BUTTON (5px Radius)
  // ==========================================
  Widget _buildBottomStartNavigationButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _startNavigation,
          icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
          label: Text(
            'Start Navigation',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: orangePrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
      ),
    );
  }
}
