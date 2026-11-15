import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/shipment_item_model.dart';

class ViewLegsModal extends StatelessWidget {
  final ShipmentItem shipment;

  const ViewLegsModal({super.key, required this.shipment});

  static Future<void> show(BuildContext context, ShipmentItem shipment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewLegsModal(shipment: shipment),
    );
  }

  static const Color primaryOrange = AppColors.primary;
  static const Color darkSlate = AppColors.textPrimary;
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final fromCity = shipment.originTitle.isNotEmpty ? shipment.originTitle : 'Origin';
    final toCity = shipment.destTitle.isNotEmpty ? shipment.destTitle : 'Destination';
    final hubLocation = shipment.hubLocation.isNotEmpty
        ? shipment.hubLocation
        : 'Intermediate Hub';

    final relayLegs = shipment.relayLegs;
    final Map<String, dynamic> leg1 = relayLegs.firstWhere(
      (l) => l['leg_number'] == 1,
      orElse: () => {
        'leg_number': 1,
        'journey_leg': '$fromCity ➔ $hubLocation',
        'status': shipment.isLeg1
            ? shipment.rawStatus
            : (shipment.currentActiveLeg > 1 ? 'completed' : 'in_progress'),
        'driver_name': shipment.isDeliveryOnly
            ? (shipment.partnerDriver?['driver_name'] ?? 'Driver 1')
            : 'You (Driver 1)',
        'driver_phone': shipment.isDeliveryOnly
            ? (shipment.partnerDriver?['driver_phone'] ?? '—')
            : 'Your Phone',
        'vehicle_plate': shipment.truckId,
      },
    );

    final Map<String, dynamic> leg2 = relayLegs.firstWhere(
      (l) => l['leg_number'] == 2,
      orElse: () => {
        'leg_number': 2,
        'journey_leg': '$hubLocation ➔ $toCity',
        'status': shipment.isLeg2
            ? shipment.rawStatus
            : (shipment.isHandoverAccepted ? 'in_transit' : 'assigned'),
        'driver_name': shipment.isDeliveryOnly
            ? 'You (Driver 2)'
            : (shipment.partnerDriver?['driver_name'] ?? 'Driver 2'),
        'driver_phone': shipment.isDeliveryOnly
            ? 'Your Phone'
            : (shipment.partnerDriver?['driver_phone'] ?? '—'),
        'vehicle_plate': shipment.isDeliveryOnly
            ? shipment.truckId
            : (shipment.partnerDriver?['vehicle_plate'] ?? '—'),
      },
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Multi-Driver Relay Manifest',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: darkSlate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${relayLegs.length > 1 ? relayLegs.length : 2} Legs',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Load #${shipment.id} • Relay Corridor Overview',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: slate500),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Visual Corridor Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: slate200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 15,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fromCity,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: slate500),
                    Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hubLocation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: slate500),
                    Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: primaryOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          toCity,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Leg 1 Card
              _buildLegCard(
                legNumber: 1,
                title: 'Leg 1: Pickup ➔ $hubLocation',
                routeSubtitle: '$fromCity ➔ $hubLocation',
                status: leg1['status']?.toString() ?? 'assigned',
                driverName: leg1['driver_name']?.toString() ?? 'Driver 1',
                driverPhone: leg1['driver_phone']?.toString() ?? '—',
                vehiclePlate: leg1['vehicle_plate']?.toString() ?? shipment.truckId,
                isMyLeg: shipment.isLeg1,
              ),
              const SizedBox(height: 12),

              // Leg 2 Card
              _buildLegCard(
                legNumber: 2,
                title: 'Leg 2: $hubLocation ➔ Destination',
                routeSubtitle: '$hubLocation ➔ $toCity',
                status: leg2['status']?.toString() ?? 'assigned',
                driverName: leg2['driver_name']?.toString() ?? 'Driver 2',
                driverPhone: leg2['driver_phone']?.toString() ?? '—',
                vehiclePlate: leg2['vehicle_plate']?.toString() ?? '—',
                isMyLeg: shipment.isLeg2,
              ),

              if (shipment.handover != null && shipment.handover!['otp_code'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 20, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Handover OTP Code',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                            Text(
                              shipment.handover!['otp_code'].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: Color(0xFF5B21B6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Text(
                          shipment.handover!['status']?.toString().toUpperCase() ?? 'PENDING',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegCard({
    required int legNumber,
    required String title,
    required String routeSubtitle,
    required String status,
    required String driverName,
    required String driverPhone,
    required String vehiclePlate,
    required bool isMyLeg,
  }) {
    final isDone = status.contains('complete') || status.contains('deliver');
    final isInProgress = status.contains('transit') ||
        status.contains('picked') ||
        status.contains('hub') ||
        status.contains('handover');

    Color badgeBg = const Color(0xFFF1F5F9);
    Color badgeColor = slate500;
    if (isDone) {
      badgeBg = const Color(0xFFECFDF5);
      badgeColor = const Color(0xFF059669);
    } else if (isInProgress) {
      badgeBg = const Color(0xFFFFF7ED);
      badgeColor = primaryOrange;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMyLeg ? primaryOrange : slate200,
          width: isMyLeg ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isMyLeg ? primaryOrange : const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$legNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkSlate,
                  ),
                ),
              ),
              if (isMyLeg)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Text(
                    'YOU',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            routeSubtitle,
            style: const TextStyle(fontSize: 11.5, color: slate500),
          ),
          const Divider(height: 16, color: slate100),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: slate500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  driverName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: darkSlate,
                  ),
                ),
              ),
              const Icon(Icons.local_shipping_outlined, size: 15, color: slate500),
              const SizedBox(width: 4),
              Text(
                vehiclePlate,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: darkSlate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
