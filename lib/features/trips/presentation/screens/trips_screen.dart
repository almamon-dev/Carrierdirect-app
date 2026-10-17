import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/coming_soon_modal.dart';
import '../../../../shared/widgets/dashed_vertical_line.dart';
import 'shipment_details_screen.dart';

enum ShipmentFilter { all, inProgress, scheduled, completed, cancelled }

class ShipmentItem {
  final String id;
  final String truckId;
  final String originTitle;
  final String originAddress;
  final String originCompany;
  final String pickupDate;
  final String pickupTime;
  final String destTitle;
  final String destAddress;
  final String destCompany;
  final String deliveryDate;
  final String deliveryTime;
  final double distanceKm;
  final String cargoType;
  final String equipmentType;
  final String palletQuantity;
  final String temperature;
  final String cargoManifest;
  final String payloadWeight;
  final String hazmatStatus;
  final ShipmentFilter status;
  final String statusLabel;
  final String time;
  final String date;
  final String signedBy;
  final String podDate;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  const ShipmentItem({
    required this.id,
    this.truckId = 'TRK-10001',
    required this.originTitle,
    required this.originAddress,
    this.originCompany = 'Dummy',
    this.pickupDate = '19 Oct 2026',
    this.pickupTime = '03:00 PM',
    required this.destTitle,
    required this.destAddress,
    this.destCompany = 'Test',
    this.deliveryDate = '21 Oct 2026',
    this.deliveryTime = '12:00 PM',
    required this.distanceKm,
    required this.cargoType,
    this.equipmentType = 'Pallets',
    this.palletQuantity = '1 Standard Pallets',
    this.temperature = 'Ambient / Standard Dry',
    this.cargoManifest = 'Commercial Freight Shipment',
    this.payloadWeight = '1,200 kg',
    this.hazmatStatus = 'No (Standard Cargo)',
    required this.status,
    required this.statusLabel,
    required this.time,
    required this.date,
    this.signedBy = 'Michael',
    this.podDate = '10/17/2026, 3:51:21 PM',
    this.originLat = 23.8510,
    this.originLng = 90.4070,
    this.destLat = 23.9980,
    this.destLng = 90.4260,
  });
}

class TripsScreen extends StatefulWidget {
  final bool showBackButton;
  const TripsScreen({super.key, this.showBackButton = false});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  ShipmentFilter _selectedFilter = ShipmentFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = AppColors.background;

  final List<ShipmentItem> _allShipments = const [
    ShipmentItem(
      id: 'ORD-NIBE-10001',
      truckId: 'TRK-10001',
      originTitle: 'Dhaka Airport',
      originAddress: 'Hazrat Shahjalal International Airport, Cargo Terminal, Kurmitola, Dhaka 1229',
      originCompany: 'Dhaka Air Cargo Logistics',
      pickupDate: '19 Oct 2026',
      pickupTime: '03:00 PM',
      destTitle: 'Gazipur',
      destAddress: 'Chandana Chowrasta, Dhaka - Mymensingh Hwy (N3), Gazipur 1700',
      destCompany: 'Gazipur Central Logistics Park',
      deliveryDate: '21 Oct 2026',
      deliveryTime: '12:00 PM',
      distanceKm: 21.4,
      cargoType: 'Dry Freight',
      equipmentType: 'Pallets',
      palletQuantity: '1 Standard Pallets',
      temperature: 'Ambient / Standard Dry',
      cargoManifest: 'Commercial Freight Shipment',
      payloadWeight: '1,200 kg',
      hazmatStatus: 'No (Standard Cargo)',
      status: ShipmentFilter.completed,
      statusLabel: 'Completed',
      time: '03:00 PM',
      date: '19 Oct 2026',
      signedBy: 'Michael',
      podDate: '10/17/2026, 3:51:21 PM',
      originLat: 23.8510,
      originLng: 90.4070,
      destLat: 23.9980,
      destLng: 90.4260,
    ),
    ShipmentItem(
      id: 'SHP987654',
      originTitle: 'ABC Warehouse',
      originAddress: '12 Industrial Area, New York, USA',
      destTitle: 'Customer A',
      destAddress: '456 Market Street, New York, USA',
      distanceKm: 24.5,
      cargoType: 'Dry Van 53ft',
      status: ShipmentFilter.inProgress,
      statusLabel: 'In Progress',
      time: '01:15 PM',
      date: 'Today',
    ),
    ShipmentItem(
      id: 'SHP987652',
      originTitle: 'North River Terminal, Gate 3',
      originAddress: '22 Harbor Road, Jersey City, NJ',
      destTitle: 'Metro Retail Hub, Dock 8',
      destAddress: '104 Atlantic Ave, Brooklyn, NY',
      distanceKm: 32.0,
      cargoType: 'Reefer Trailer',
      status: ShipmentFilter.inProgress,
      statusLabel: 'In Progress',
      time: '02:00 PM',
      date: 'Today',
    ),
    ShipmentItem(
      id: 'SHP987655',
      originTitle: 'Logistics Hub 7, Dock B',
      originAddress: '88 Cargo Terminal, JFK Airport, NY',
      destTitle: 'Midtown Express Depot',
      destAddress: '742 5th Avenue, New York, USA',
      distanceKm: 28.4,
      cargoType: 'Dry Van 53ft',
      status: ShipmentFilter.scheduled,
      statusLabel: 'Scheduled',
      time: '04:30 PM',
      date: 'Today',
    ),
    ShipmentItem(
      id: 'SHP987640',
      originTitle: 'Port Container Bay 4',
      originAddress: '10 Marine Blvd, Newark, NJ',
      destTitle: 'Central Fulfillment Hub',
      destAddress: '550 Commerce Way, Queens, NY',
      distanceKm: 42.0,
      cargoType: 'Flatbed 48ft',
      status: ShipmentFilter.completed,
      statusLabel: 'Delivered',
      time: '11:30 AM',
      date: 'Today',
    ),
    ShipmentItem(
      id: 'SHP987638',
      originTitle: 'South Terminal Cargo 2',
      originAddress: '14 Airport Road, Long Island, NY',
      destTitle: 'Apex Retail Warehouse',
      destAddress: '89 Main St, Brooklyn, NY',
      distanceKm: 18.2,
      cargoType: 'Dry Van 53ft',
      status: ShipmentFilter.completed,
      statusLabel: 'Delivered',
      time: '09:45 AM',
      date: 'Today',
    ),
    ShipmentItem(
      id: 'SHP987620',
      originTitle: 'Hudson Distribution Center',
      originAddress: '400 River Road, Hoboken, NJ',
      destTitle: 'Starlight Plaza Store #4',
      destAddress: '220 Broadway, Manhattan, NY',
      distanceKm: 15.0,
      cargoType: 'Box Truck 26ft',
      status: ShipmentFilter.cancelled,
      statusLabel: 'Cancelled',
      time: 'Yesterday',
      date: 'Yesterday',
    ),
  ];

  List<ShipmentItem> get _filteredShipments {
    return _allShipments.where((item) {
      final matchesFilter = _selectedFilter == ShipmentFilter.all || item.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          item.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.originTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.destTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.destAddress.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Color _getStatusColor(ShipmentFilter status) {
    switch (status) {
      case ShipmentFilter.inProgress:
        return const Color(0xFF0284C7);
      case ShipmentFilter.scheduled:
        return const Color(0xFFD97706);
      case ShipmentFilter.completed:
        return const Color(0xFF059669);
      case ShipmentFilter.cancelled:
        return const Color(0xFFDC2626);
      default:
        return primaryColor;
    }
  }

  Color _getStatusBg(ShipmentFilter status) {
    switch (status) {
      case ShipmentFilter.inProgress:
        return const Color(0xFFF0F9FF);
      case ShipmentFilter.scheduled:
        return const Color(0xFFFFFBEB);
      case ShipmentFilter.completed:
        return const Color(0xFFECFDF5);
      case ShipmentFilter.cancelled:
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  int _getCount(ShipmentFilter filter) {
    if (filter == ShipmentFilter.all) return _allShipments.length;
    return _allShipments.where((item) => item.status == filter).length;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      if (widget.showBackButton && canPop)
                        GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 14.0),
                            child: Icon(Icons.arrow_back, size: 22, color: Color(0xFF0F172A)),
                          ),
                        ),
                      const Expanded(
                        child: Text(
                          'My Shipments',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // Live Load Board (Coming Soon)
                      GestureDetector(
                        onTap: () => ComingSoonModal.show(
                          context,
                          featureName: 'Live Load Board & Spot Freight',
                          description: 'Browse available spot freight, claim priority carrier load routes, and dispatch directly from certified shippers.',
                          icon: Icons.local_shipping_rounded,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1EB),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: const Color(0xFFFFCCBC)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFFFF5722)),
                              SizedBox(width: 4),
                              Text(
                                'Load Board',
                                style: TextStyle(
                                  color: Color(0xFFFF5722),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter options button
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 14, color: Color(0xFFFF5722)),
                              SizedBox(width: 4),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar with 60px Rounded Stadium Pill Shape (matching Messages)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      cursorColor: const Color(0xFFFF5722),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        hintText: 'Search shipments by ID, location...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14.0, right: 8.0),
                          child: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(60),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(60),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(60),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      ),
                    ),
                  ),
                ),

                // Horizontal Filter Chips (matching Messages style)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(ShipmentFilter.all, 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip(ShipmentFilter.inProgress, 'Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip(ShipmentFilter.scheduled, 'Scheduled'),
                        const SizedBox(width: 8),
                        _buildFilterChip(ShipmentFilter.completed, 'Completed'),
                        const SizedBox(width: 8),
                        _buildFilterChip(ShipmentFilter.cancelled, 'Cancelled'),
                      ],
                    ),
                  ),
                ),

                // Shipment List
                Expanded(
                  child: _filteredShipments.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredShipments.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _filteredShipments[index];
                            return _buildShipmentListItem(item);
                          },
                        ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFilterChip(ShipmentFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    final count = _getCount(filter);
    final isAll = filter == ShipmentFilter.all;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAll ? 'All ($count)' : label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (!isAll && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentListItem(ShipmentItem item) {
    final statusColor = _getStatusColor(item.status);
    final statusBg = _getStatusBg(item.status);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipmentDetailsScreen(shipment: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID + Cargo + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '#${item.id}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.time}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          item.cargoType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Origin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    color: Color(0xFFEA580C),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.originTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.originAddress,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Dashed connector line
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: DashedVerticalLine(
                  iconWidth: 14,
                  height: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ),

            // Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0284C7),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.destTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.destAddress,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 8),

            // Bottom Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route_rounded, size: 13.5, color: Color(0xFFD97706)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${item.distanceKm} km total',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (item.status == ShipmentFilter.inProgress) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.navigation_rounded, size: 10, color: Color(0xFF059669)),
                            SizedBox(width: 3),
                            Text(
                              'LIVE GPS',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
                Text(
                  item.date,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Shipments Found',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No shipment records match your active search or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Filter Shipments by Status',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select a shipment delivery status to filter the list view.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ShipmentFilter.values.map((f) {
                          final isSel = _selectedFilter == f;
                          final label = f == ShipmentFilter.all
                              ? 'All Shipments (${_allShipments.length})'
                              : '${f.name[0].toUpperCase()}${f.name.substring(1)} (${_getCount(f)})';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = f;
                              });
                              setModalState(() {});
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFFF5722) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  color: isSel ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSel ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
