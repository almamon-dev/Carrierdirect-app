import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../services/order_gps_tracker_service.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../data/models/shipment_item_model.dart';
import '../screens/trips_screen.dart';

class ShipmentOverviewTab extends StatelessWidget {
  final ShipmentItem shipment;
  final bool isDelivered;
  final String? podPhotoUrl;
  final String? receiverName;
  final String? podStatus;
  final String? signatureUrl;
  final String? cargoDimensions;
  final String? specialInstructions;
  final List<Map<String, dynamic>> activityLog;
  final VoidCallback onOpenPodModal;
  final VoidCallback onViewPodPhoto;
  final VoidCallback? onOpenHandover;
  final VoidCallback? onOpenAcceptHandover;

  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color successGreen = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorderColor = Color(0xFFE2E8F0);

  const ShipmentOverviewTab({
    super.key,
    required this.shipment,
    required this.isDelivered,
    this.podPhotoUrl,
    this.receiverName,
    this.podStatus,
    this.signatureUrl,
    this.cargoDimensions,
    this.specialInstructions,
    required this.activityLog,
    required this.onOpenPodModal,
    required this.onViewPodPhoto,
    this.onOpenHandover,
    this.onOpenAcceptHandover,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('overview_tab_body'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        _buildLiveGpsCard(context),
        if (shipment.isSubcontractor) ...[
          _buildSubcontractorAssignmentCard(),
          const SizedBox(height: 12),
        ],
        _buildFacilityContactsCard(context),
        const SizedBox(height: 12),
        _buildShipmentInfoCard(),
        const SizedBox(height: 12),
        if (isDelivered) ...[
          _buildProofOfDeliveryCard(),
          const SizedBox(height: 12),
        ],
        _buildRecentActivityCard(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLiveGpsCard(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OrderGpsTrackerService().isTrackingNotifier,
      builder: (context, isTracking, _) {
        final isThisOrderTracking = isTracking &&
            OrderGpsTrackerService().activeShipment?.id == shipment.id;

        final isTransit = shipment.status == ShipmentFilter.inProgress;
        if (!isTransit && !isThisOrderTracking) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isThisOrderTracking
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isThisOrderTracking
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFFFEDD5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isThisOrderTracking
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFEAD5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isThisOrderTracking
                      ? Icons.sensors_rounded
                      : Icons.location_searching_rounded,
                  color: isThisOrderTracking
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFFF5722),
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
                          isThisOrderTracking
                              ? 'Live GPS Sharing Active'
                              : 'Customer GPS Tracking',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isThisOrderTracking
                                ? const Color(0xFF15803D)
                                : const Color(0xFFC2410C),
                          ),
                        ),
                        if (isThisOrderTracking) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isThisOrderTracking
                          ? 'Customer is viewing your vehicle live.'
                          : 'Stream GPS location to customer & dispatch.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (isThisOrderTracking) {
                    OrderGpsTrackerService().stopTracking();
                  } else {
                    OrderGpsTrackerService().startTracking(shipment);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isThisOrderTracking
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isThisOrderTracking
                          ? const Color(0xFF86EFAC)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    isThisOrderTracking ? 'Stop' : 'Start GPS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isThisOrderTracking
                          ? const Color(0xFF15803D)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcontractorAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Color(0xFF2563EB),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Subcontractor Carrier',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'EXTERNAL',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  shipment.subcontractorCompany.isNotEmpty
                      ? shipment.subcontractorCompany
                      : 'External Partner Carrier',
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (shipment.subcontractorJourneyLeg.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, size: 13, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Assigned Route: ${shipment.subcontractorJourneyLeg}',
                          style: const TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityContactsCard(BuildContext context) {
    final originComp = (shipment.originCompany.isNotEmpty && shipment.originCompany != '—')
        ? shipment.originCompany
        : shipment.originTitle;
    final destComp = (shipment.destCompany.isNotEmpty && shipment.destCompany != '—')
        ? shipment.destCompany
        : shipment.destTitle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: cardBorderColor),
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
          const Row(
            children: [
              Icon(Icons.business_rounded, color: primaryOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Facility & Location Details',
                style: TextStyle(
                  color: darkSlate,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pickup Location Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'PICKUP',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            originComp,
                            style: const TextStyle(
                              color: darkSlate,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (shipment.originAddress.isNotEmpty && shipment.originAddress != '—') ...[
                      const SizedBox(height: 3),
                      Text(
                        shipment.originAddress,
                        style: const TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                    ],
                    if (shipment.pickupContactName.isNotEmpty && shipment.pickupContactName != '—') ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            shipment.pickupContactName,
                            style: const TextStyle(color: darkSlate, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (shipment.pickupDate.isNotEmpty && shipment.pickupDate != '—') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${shipment.pickupDate}${shipment.pickupTime.isNotEmpty ? ' • ${shipment.pickupTime}' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Divider(color: cardBorderColor, height: 1)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        size: 12.5,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shipment.formattedDistance,
                        style: const TextStyle(
                          color: primaryOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Divider(color: cardBorderColor, height: 1)),
              ],
            ),
          ),

          // Delivery Location Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'DELIVERY',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            destComp,
                            style: const TextStyle(
                              color: darkSlate,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (shipment.destAddress.isNotEmpty && shipment.destAddress != '—') ...[
                      const SizedBox(height: 3),
                      Text(
                        shipment.destAddress,
                        style: const TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                    ],
                    if (shipment.deliveryContactName.isNotEmpty && shipment.deliveryContactName != '—') ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            shipment.deliveryContactName,
                            style: const TextStyle(color: darkSlate, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (shipment.deliveryDate.isNotEmpty && shipment.deliveryDate != '—') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${shipment.deliveryDate}${shipment.deliveryTime.isNotEmpty ? ' • ${shipment.deliveryTime}' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentInfoCard() {
    final dims = (cargoDimensions != null && cargoDimensions!.isNotEmpty)
        ? cargoDimensions!
        : (shipment.dimensions.isNotEmpty && shipment.dimensions != '—' ? shipment.dimensions : null);
    final notes = (specialInstructions != null && specialInstructions!.isNotEmpty)
        ? specialInstructions!
        : (shipment.specialInstructions.isNotEmpty && shipment.specialInstructions != '—' ? shipment.specialInstructions : null);
    final service = (shipment.serviceType.isNotEmpty && shipment.serviceType != '—')
        ? shipment.serviceType
        : shipment.cargoType;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: cardBorderColor),
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
          const Row(
            children: [
              Icon(Icons.description_outlined, color: primaryOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Cargo & Shipment Information',
                style: TextStyle(
                  color: darkSlate,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildKeyValueRow('Quantity', shipment.palletQuantity),
          if (shipment.equipmentType.isNotEmpty && shipment.equipmentType != '—') ...[
            const SizedBox(height: 10),
            _buildKeyValueRow('Pallet Type', shipment.equipmentType),
          ],
          if (service.isNotEmpty && service != '—') ...[
            const SizedBox(height: 10),
            _buildKeyValueRow('Service Level', service),
          ],
          if (dims != null && dims.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildKeyValueRow('Dimensions', dims),
          ],
          if (shipment.payloadWeight.isNotEmpty && shipment.payloadWeight != '—') ...[
            const SizedBox(height: 10),
            _buildKeyValueRow(
              'Payload Weight',
              shipment.payloadWeight,
              isBoldValue: true,
            ),
          ],
          const SizedBox(height: 10),
          _buildKeyValueRow(
            'Route Distance',
            shipment.formattedDistance,
            isBoldValue: true,
          ),
          if (shipment.truckId.isNotEmpty && shipment.truckId != '—') ...[
            const SizedBox(height: 10),
            _buildKeyValueRow('Assigned Truck', shipment.truckId),
          ],
          if (shipment.vehicleType.isNotEmpty && shipment.vehicleType != '—') ...[
            const SizedBox(height: 10),
            _buildKeyValueRow('Vehicle Type', shipment.vehicleType),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildKeyValueRow('Instructions', notes),
          ],
        ],
      ),
    );
  }

  Widget _buildProofOfDeliveryCard() {
    final bool hasUploadedPod =
        (podStatus == 'delivered' || podStatus == 'completed') ||
        (receiverName != null && receiverName!.trim().isNotEmpty) ||
        (signatureUrl != null && signatureUrl!.trim().isNotEmpty) ||
        (podPhotoUrl != null &&
            podPhotoUrl!.trim().isNotEmpty &&
            podPhotoUrl != 'signature_captured' &&
            podPhotoUrl != 'signature_only') ||
        isDelivered ||
        shipment.status == ShipmentFilter.completed;

    final String signedByText;
    if (receiverName != null && receiverName!.trim().isNotEmpty) {
      signedByText = receiverName!.trim();
    } else if (shipment.signedBy.isNotEmpty && shipment.signedBy != '—') {
      signedByText = shipment.signedBy;
    } else if (hasUploadedPod) {
      signedByText = 'Verified Consignee';
    } else {
      signedByText = 'Pending consignee sign-off';
    }

    final String timeDateText;
    if (hasUploadedPod) {
      if (shipment.podDate.isNotEmpty && shipment.podDate != '—') {
        timeDateText = _normalizeTime(shipment.podDate);
      } else {
        timeDateText = _normalizeTime(DateTime.now().toIso8601String());
      }
    } else {
      final scheduledDate = shipment.deliveryDate.isNotEmpty
          ? shipment.deliveryDate
          : 'Pending Arrival';
      final scheduledTime = shipment.deliveryTime.isNotEmpty
          ? ', ${shipment.deliveryTime}'
          : '';
      timeDateText = 'Awaiting ($scheduledDate$scheduledTime)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: cardBorderColor),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    color: primaryOrange,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Proof of Delivery (POD)',
                    style: TextStyle(
                      color: darkSlate,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: hasUploadedPod
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasUploadedPod
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasUploadedPod
                          ? Icons.check
                          : Icons.hourglass_empty_rounded,
                      size: 11.5,
                      color: hasUploadedPod
                          ? successGreen
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      hasUploadedPod ? 'Verified' : 'Pending',
                      style: TextStyle(
                        color: hasUploadedPod
                            ? successGreen
                            : const Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            'Signed By',
            signedByText,
            isBoldValue: hasUploadedPod,
          ),
          const SizedBox(height: 8),
          _buildKeyValueRow('Time & Date', timeDateText),
          const SizedBox(height: 10),
          Material(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6.0),
            child: InkWell(
              onTap: hasUploadedPod ? onViewPodPhoto : onOpenPodModal,
              borderRadius: BorderRadius.circular(6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasUploadedPod
                          ? Icons.description_outlined
                          : Icons.upload_file_outlined,
                      size: 16,
                      color: hasUploadedPod ? successGreen : primaryOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasUploadedPod
                            ? 'Signed Bill of Lading (BOL)'
                            : 'Upload Signed BOL & Sign-Off',
                        style: const TextStyle(
                          color: darkSlate,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      hasUploadedPod ? 'View Document ›' : 'Upload ›',
                      style: TextStyle(
                        color: hasUploadedPod ? successGreen : primaryOrange,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDynamicActivitySteps() {
    String? findHistoryTime(List<String> keywords) {
      if (activityLog.isEmpty) return null;
      for (final item in activityLog) {
        final t = (item['title'] ?? item['action'] ?? item['status'] ?? '').toString().toLowerCase();
        if (keywords.any((k) => t.contains(k))) {
          final time = (item['time'] ?? item['timestamp'] ?? item['date'] ?? item['created_at'] ?? '').toString();
          if (time.isNotEmpty) return time;
        }
      }
      return null;
    }

    final rawStatus = (shipment.rawStatus.isNotEmpty
            ? shipment.rawStatus
            : shipment.statusLabel)
        .toLowerCase()
        .trim();
    final currentPodStatus = (podStatus ?? '').toLowerCase().trim();

    final orderDate = shipment.date.isNotEmpty && shipment.date != '—'
        ? shipment.date
        : (shipment.pickupDate.isNotEmpty && shipment.pickupDate != '—' ? shipment.pickupDate : 'Confirmed');
    final orderTime = shipment.time.isNotEmpty && shipment.time != '—' ? shipment.time : '';

    final pickupStr =
        (shipment.pickupDate.isNotEmpty && shipment.pickupTime.isNotEmpty)
        ? '${shipment.pickupDate}, ${shipment.pickupTime}'
        : (shipment.pickupDate.isNotEmpty ? shipment.pickupDate : 'Scheduled');


    final leg2 = shipment.isRelay
        ? shipment.relayLegs.firstWhere(
            (l) => (l['leg_number'] ?? 2) == 2,
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};
    final leg2Status = (leg2['status'] ?? '').toString().toLowerCase().trim();

    final effectiveMilestone = (shipment.rawMilestoneStatus.isNotEmpty
            ? shipment.rawMilestoneStatus
            : ((shipment.isRelay && shipment.isLeg1 && shipment.isLeg1HandoverCompleted)
                ? (leg2Status.isNotEmpty ? leg2Status : 'in_transit')
                : rawStatus))
        .toLowerCase()
        .trim();

    final isRelayLeg2Active = shipment.isRelay &&
        (leg2Status == 'in_transit' ||
            leg2Status == 'at_delivery' ||
            leg2Status == 'arrived' ||
            leg2Status == 'handover_accepted' ||
            effectiveMilestone == 'at_delivery' ||
            effectiveMilestone == 'arrived' ||
            effectiveMilestone == 'in_transit' ||
            effectiveMilestone == 'handover_accepted');

    final isCustomerApproved = !isRelayLeg2Active &&
        (currentPodStatus == 'approved' ||
            currentPodStatus == 'accepted' ||
            currentPodStatus == 'confirmed' ||
            shipment.orderStatus == 'completed' ||
            effectiveMilestone == 'completed' ||
            effectiveMilestone == 'pod_accepted' ||
            effectiveMilestone == 'order_completed' ||
            findHistoryTime([
                  'customer_approved',
                  'pod_accepted',
                  'order_complete',
                  'approved by customer',
                ]) !=
                null);

    final hasPodProof = (podPhotoUrl != null && podPhotoUrl!.isNotEmpty) ||
        (signatureUrl != null && signatureUrl!.isNotEmpty);

    final isDeliveredOrPodUploaded = isCustomerApproved ||
        hasPodProof ||
        (!isRelayLeg2Active &&
            (isDelivered ||
                effectiveMilestone == 'delivered' ||
                effectiveMilestone == 'pod_uploaded' ||
                leg2Status == 'delivered' ||
                (shipment.podDate.isNotEmpty && shipment.podDate != '—')));

    final isArrived = isDeliveredOrPodUploaded ||
        effectiveMilestone.contains('arrived') ||
        effectiveMilestone.contains('at_delivery') ||
        leg2Status == 'at_delivery' ||
        leg2Status == 'arrived' ||
        rawStatus.contains('arrived') ||
        rawStatus.contains('at_delivery');

    final isHubOrHandover =
        rawStatus == 'at_hub' ||
        rawStatus.contains('hub') ||
        rawStatus.contains('handover') ||
        shipment.isHandoverPending ||
        shipment.isHandoverAccepted ||
        shipment.currentActiveLeg >= 2;

    final isInTransit =
        isArrived ||
        isHubOrHandover ||
        rawStatus == 'in_transit' ||
        rawStatus.contains('transit') ||
        rawStatus.contains('on_route') ||
        rawStatus.contains('on route');

    final isPickedUp =
        isInTransit ||
        isHubOrHandover ||
        rawStatus.contains('picked') ||
        rawStatus.contains('loaded');

    final isAtPickup =
        rawStatus == 'at_pickup' || rawStatus.contains('arrived_at_pickup');

    final isAssigned =
        isPickedUp ||
        rawStatus.contains('assign') ||
        rawStatus.contains('accept') ||
        rawStatus.contains('schedule') ||
        rawStatus.isNotEmpty;

    final goodsPickedUpState =
        (isPickedUp || isInTransit || isDeliveredOrPodUploaded)
            ? 'done'
            : (isAtPickup ? 'current' : 'pending');

    final inTransitState = isDeliveredOrPodUploaded
        ? 'done'
        : (isInTransit ? 'current' : 'pending');

    final deliveredState = isDeliveredOrPodUploaded
        ? 'done'
        : (isArrived ? 'current' : 'pending');

    final orderCompletedState = isCustomerApproved
        ? 'done'
        : (isDeliveredOrPodUploaded ? 'current' : 'pending');

    final rawOrderTime = findHistoryTime(['confirm', 'order', 'book', 'created']) ??
        (orderTime.isNotEmpty ? '$orderDate, $orderTime' : (orderDate != 'Confirmed' ? orderDate : null));

    final rawAssignTime = findHistoryTime(['assign', 'dispatch']) ??
        (shipment.date.isNotEmpty && shipment.date != '—' ? shipment.date : null);

    if (shipment.isRelay) {
      final leg1 = shipment.relayLegs.firstWhere(
        (l) => (l['leg_number'] ?? 1) == 1,
        orElse: () => <String, dynamic>{},
      );
      final leg2 = shipment.relayLegs.firstWhere(
        (l) => (l['leg_number'] ?? 2) == 2,
        orElse: () => <String, dynamic>{},
      );

      final String pickupLabel = shipment.originTitle.isNotEmpty && shipment.originTitle != 'Origin'
          ? shipment.originTitle
          : (shipment.originAddress.contains(',') ? shipment.originAddress.split(',').first.trim() : 'Dhaka');

      final String deliveryLabel = shipment.destTitle.isNotEmpty && shipment.destTitle != 'Destination'
          ? shipment.destTitle
          : (shipment.destAddress.contains(',') ? shipment.destAddress.split(',').first.trim() : 'Chittagong');

      String hubLabel = shipment.hubLocation.isNotEmpty ? shipment.hubLocation : 'Intermediate Hub';
      if (hubLabel.toLowerCase().contains('relay hub') || hubLabel.toLowerCase().contains('transit hub')) {
        hubLabel = 'Intermediate Hub';
      }

      final leg1DriverName = (leg1['driver_name']?.toString().trim().isNotEmpty == true)
          ? leg1['driver_name'].toString().trim()
          : ((!shipment.isDeliveryOnly && shipment.driverName.isNotEmpty)
              ? shipment.driverName
              : (shipment.partnerDriver?['driver_name']?.toString().trim().isNotEmpty == true
                  ? shipment.partnerDriver!['driver_name'].toString().trim()
                  : 'Aidan Moroney'));

      final leg2DriverName = (leg2['driver_name']?.toString().trim().isNotEmpty == true)
          ? leg2['driver_name'].toString().trim()
          : ((shipment.isDeliveryOnly && shipment.driverName.isNotEmpty)
              ? shipment.driverName
              : (shipment.partnerDriver?['driver_name']?.toString().trim().isNotEmpty == true
                  ? shipment.partnerDriver!['driver_name'].toString().trim()
                  : 'Sean Murphy'));

      final leg2Assigned = (leg2['driver_name']?.toString().isNotEmpty == true) ||
          (leg2['subcontractor_driver_name']?.toString().isNotEmpty == true) ||
          (leg2['driver_id'] != null) ||
          (shipment.partnerDriver != null && shipment.partnerDriver!['driver_name'] != null);

      final leg1Status = (leg1['status'] ?? '').toString().toLowerCase().trim();
      final leg2Status = (leg2['status'] ?? '').toString().toLowerCase().trim();

      final isAtHub = rawStatus == 'at_hub' ||
          rawStatus.contains('hub') ||
          leg1Status == 'at_hub' ||
          leg1Status == 'handover_pending';

      final handoverAccepted = shipment.isHandoverAccepted ||
          isDeliveredOrPodUploaded ||
          shipment.currentActiveLeg >= 2 ||
          leg1Status == 'completed' ||
          leg2Status == 'handover_accepted' ||
          leg2Status == 'in_transit' ||
          leg2Status == 'at_delivery' ||
          leg2Status == 'delivered';

      final handoverPending = !handoverAccepted &&
          (isAtHub ||
              shipment.isHandoverPending ||
              rawStatus == 'handover_pending' ||
              leg1Status == 'at_hub' ||
              leg1Status == 'handover_pending');

      final leg1TransitDone = isAtHub ||
          handoverPending ||
          handoverAccepted ||
          isDeliveredOrPodUploaded ||
          leg1Status == 'completed';

      final leg1TransitActive = !leg1TransitDone &&
          !handoverAccepted &&
          !isDeliveredOrPodUploaded &&
          (isInTransit || leg1Status == 'in_transit') &&
          shipment.currentActiveLeg <= 1;

      final leg1PickupDone = leg1TransitActive ||
          leg1TransitDone ||
          isAtHub ||
          handoverPending ||
          handoverAccepted ||
          isDeliveredOrPodUploaded ||
          leg1Status == 'picked_up' ||
          leg1Status == 'in_transit';

      final leg1PickedUpActive = !leg1PickupDone &&
          !leg1TransitActive &&
          !leg1TransitDone &&
          (isPickedUp || leg1Status == 'picked_up');

      final leg2AtDelivery = !isDeliveredOrPodUploaded &&
          handoverAccepted &&
          (isArrived ||
              rawStatus == 'at_delivery' ||
              rawStatus == 'arrived' ||
              leg2Status == 'at_delivery' ||
              leg2Status == 'arrived');

      final leg2TransitDone = leg2AtDelivery || isDeliveredOrPodUploaded;

      final leg2TransitActive = !leg2TransitDone &&
          handoverAccepted &&
          (shipment.isLeg2 ||
              shipment.currentActiveLeg >= 2 ||
              leg2Status == 'in_transit' ||
              leg2Status == 'handover_accepted' ||
              rawStatus == 'in_transit' ||
              rawStatus == 'handover_accepted');

      final bool isLeg2Departing = leg2TransitActive &&
          (rawStatus == 'handover_accepted' ||
              leg2Status == 'handover_accepted' ||
              (!isInTransit && rawStatus != 'in_transit'));

      final rawPickupTime = leg1PickupDone
          ? (findHistoryTime(['pick', 'loaded', 'cargo_collected', 'in_transit']) ??
              (pickupStr != '—' && pickupStr != 'Scheduled' ? pickupStr : null))
          : null;

      final rawTransitTime = leg1TransitDone
          ? (findHistoryTime(['transit', 'on_route', 'hub', 'at_hub']))
          : null;

      final rawHandoverTime = handoverAccepted
          ? (findHistoryTime(['handover_accepted', 'handover accepted', 'otp_verified', 'otp verified']) ?? shipment.handover?['accepted_at']?.toString())
          : null;

      final rawFinalTransitTime = leg2TransitDone
          ? (findHistoryTime(['final_transit', 'final delivery', 'in_transit', 'transit']) ?? rawHandoverTime)
          : null;

      final rawDeliveryTime = isDeliveredOrPodUploaded
          ? (findHistoryTime(['deliver', 'pod', 'pod_uploaded']) ??
              (shipment.podDate.isNotEmpty && shipment.podDate != '—' ? shipment.podDate : null))
          : null;

      final rawCompletedTime = isCustomerApproved
          ? (findHistoryTime(['complete', 'accepted', 'customer_approved', 'pod_accepted']) ??
              (shipment.podDate.isNotEmpty && shipment.podDate != '—' ? shipment.podDate : null))
          : null;

      return [
        {
          'title': 'Order Confirmed',
          'desc': 'The shipment order has been successfully created and confirmed by the customer.',
          'date': rawOrderTime,
          'state': 'done',
        },
        {
          'title': 'Collection Driver Assigned',
          'desc': '$leg1DriverName has been assigned to collect the shipment from $pickupLabel to $hubLabel.',
          'date': rawAssignTime,
          'state': 'done',
        },
        {
          'title': 'Delivery Driver Assigned',
          'desc': leg2Assigned
              ? '$leg2DriverName has been scheduled to deliver the shipment from $hubLabel to $deliveryLabel. (Activates after handover)'
              : 'Awaiting driver assignment for the final delivery from $hubLabel to $deliveryLabel.',
          'date': leg2Assigned
              ? (findHistoryTime(['leg 2', 'delivery driver', 'relay', 'partner']) ?? rawAssignTime)
              : null,
          'state': leg2Assigned ? 'done' : 'pending',
        },
        {
          'title': 'Goods Picked Up',
          'desc': leg1PickupDone
              ? 'Cargo successfully collected from $pickupLabel by $leg1DriverName.'
              : (leg1PickedUpActive
                  ? '$leg1DriverName arrived at pickup facility ($pickupLabel); cargo loading in progress.'
                  : 'Awaiting cargo collection from consignor pickup facility ($pickupLabel).'),
          'date': leg1PickupDone ? rawPickupTime : null,
          'state': leg1PickupDone
              ? 'done'
              : (leg1PickedUpActive ? 'current' : 'pending'),
        },
        {
          'title': 'In Transit to Intermediate Hub',
          'desc': leg1TransitDone
              ? 'Cargo transported to $hubLabel by $leg1DriverName.'
              : (leg1TransitActive
                  ? '$leg1DriverName is transporting cargo to $hubLabel.'
                  : 'Cargo will be transported to $hubLabel following pickup.'),
          'date': leg1TransitDone ? rawTransitTime : null,
          'state': leg1TransitDone
              ? 'done'
              : (leg1TransitActive ? 'current' : 'pending'),
        },
        {
          'title': 'Handover at Intermediate Hub',
          'desc': handoverAccepted
              ? 'Cargo successfully handed over at $hubLabel to $leg2DriverName (OTP verified).'
              : (handoverPending
                  ? 'Arrived at $hubLabel. Waiting for $leg2DriverName to verify OTP and accept cargo.'
                  : 'Cargo will be transferred to $leg2DriverName at $hubLabel via secure OTP.'),
          'date': handoverAccepted ? rawHandoverTime : null,
          'state': handoverAccepted
              ? 'done'
              : (handoverPending ? 'current' : 'pending'),
          'isHandoverStep': true,
        },
        {
          'title': 'In Transit to Final Destination',
          'desc': leg2TransitDone
              ? 'Cargo transported by $leg2DriverName to $deliveryLabel.'
              : (leg2TransitActive
                  ? (isLeg2Departing
                      ? 'Handover accepted by $leg2DriverName; preparing departure to $deliveryLabel.'
                      : '$leg2DriverName is in transit to final destination ($deliveryLabel).')
                  : 'Cargo will be dispatched to $deliveryLabel following hub handover.'),
          'date': leg2TransitDone ? rawFinalTransitTime : null,
          'state': leg2TransitDone
              ? 'done'
              : (leg2TransitActive ? 'current' : 'pending'),
          'badgeText': leg2TransitDone
              ? null
              : (leg2TransitActive
                  ? (isLeg2Departing ? 'Ready to Depart' : 'In Transit')
                  : null),
        },
        {
          'title': 'Delivered & POD Submitted',
          'desc': leg2AtDelivery
              ? '$leg2DriverName arrived at $deliveryLabel; unloading cargo and obtaining consignee signature.'
              : (isDeliveredOrPodUploaded
                  ? 'Goods delivered to consignee at $deliveryLabel and signed Proof of Delivery (POD) submitted.'
                  : 'Delivery note and consignee signature will be collected upon arrival at $deliveryLabel.'),
          'date': isDeliveredOrPodUploaded ? rawDeliveryTime : null,
          'state': isDeliveredOrPodUploaded
              ? 'done'
              : (leg2AtDelivery ? 'current' : 'pending'),
          'badgeText': isDeliveredOrPodUploaded
              ? null
              : (leg2AtDelivery ? 'Arrived' : null),
        },
        {
          'title': 'POD Review & Approval',
          'desc': isCustomerApproved
              ? 'Proof of Delivery verified and approved by customer. Escrow payout released to carrier.'
              : 'Customer reviews Proof of Delivery to verify cargo condition and release payment.',
          'date': isCustomerApproved ? rawCompletedTime : null,
          'state': isCustomerApproved
              ? 'done'
              : (isDeliveredOrPodUploaded ? 'current' : 'pending'),
          'badgeText': isCustomerApproved
              ? 'Approved'
              : (isDeliveredOrPodUploaded ? 'Pending Approval' : 'Pending'),
        },
      ];
    }

    final rawSinglePickupTime = goodsPickedUpState == 'done'
        ? (findHistoryTime(['pick', 'loaded', 'cargo_collected', 'in_transit']) ??
            (pickupStr != '—' && pickupStr != 'Scheduled' ? pickupStr : null))
        : null;

    final rawSingleTransitTime = inTransitState == 'done'
        ? findHistoryTime(['transit', 'on_route'])
        : null;

    final rawSingleDeliveryTime = deliveredState == 'done'
        ? (findHistoryTime(['deliver', 'pod', 'pod_uploaded']) ??
            (shipment.podDate.isNotEmpty && shipment.podDate != '—' ? shipment.podDate : null))
        : null;

    final rawSingleCompletedTime = isCustomerApproved
        ? (findHistoryTime(['complete', 'accepted', 'customer_approved', 'pod_accepted']) ??
            (shipment.podDate.isNotEmpty && shipment.podDate != '—' ? shipment.podDate : null))
        : null;

    return [
      {
        'title': 'Order Confirmed',
        'desc': 'Shipment order created and confirmed by customer.',
        'date': rawOrderTime,
        'state': 'done',
      },
      {
        'title': 'Collection Driver Assigned',
        'desc': isAssigned ? 'Driver assigned to execute delivery.' : 'Waiting for carrier to assign driver.',
        'date': isAssigned ? rawAssignTime : null,
        'state': isAssigned ? 'done' : 'current',
      },
      {
        'title': 'Goods Picked Up',
        'desc': goodsPickedUpState == 'done'
            ? 'Goods collected from pickup facility.'
            : 'Awaiting collection from consignor pickup facility.',
        'date': rawSinglePickupTime,
        'state': goodsPickedUpState,
      },
      {
        'title': 'In Transit to Final Destination',
        'desc': inTransitState == 'done'
            ? 'Transit to destination completed.'
            : (inTransitState == 'current'
                ? 'Driver en route to destination.'
                : 'Awaiting transit dispatch.'),
        'date': rawSingleTransitTime,
        'state': inTransitState,
      },
      {
        'title': 'Delivered & POD Submitted',
        'desc': deliveredState == 'done'
            ? 'Goods delivered to consignee and signed Proof of Delivery submitted.'
            : 'Cargo arrival and consignee delivery.',
        'date': rawSingleDeliveryTime,
        'state': deliveredState,
      },
      {
        'title': 'POD Review & Approval',
        'desc': isCustomerApproved
            ? 'Customer reviewed and approved Proof of Delivery (POD). Escrow payout released.'
            : 'Customer reviews Proof of Delivery to release escrow payment.',
        'date': rawSingleCompletedTime,
        'state': orderCompletedState,
        'badgeText': (orderCompletedState == 'current') ? 'Awaiting Customer' : null,
      },
    ];
  }

  static String _normalizeTime(String raw) {
    return _formatTimelineDate(raw) ?? raw;
  }

  static String? _formatTimelineDate(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty ||
        str == '—' ||
        str == '-' ||
        str.toLowerCase() == 'pending' ||
        str.toLowerCase() == 'scheduled' ||
        str.toLowerCase() == 'completed' ||
        str.toLowerCase() == 'on route' ||
        str.toLowerCase() == 'at pickup' ||
        str.toLowerCase() == 'at destination' ||
        str.toLowerCase() == 'assigned' ||
        str.toLowerCase() == 'picked up' ||
        str.toLowerCase() == 'delivered' ||
        str.startsWith('Awaiting')) {
      return null;
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // 0. Parse ISO 8601 or standard SQL timestamp: "2026-11-15T09:41:20+00:00" or "2026-11-15 09:41:00"
    final parsedDt = DateTime.tryParse(str);
    if (parsedDt != null) {
      final local = parsedDt.toLocal();
      final m = months[local.month - 1];
      final d = local.day;
      final hour = local.hour;
      final minute = local.minute.toString().padLeft(2, '0');
      final mer = hour >= 12 ? 'PM' : 'AM';
      final displayHour = (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0');
      return '$m $d, $displayHour:$minute $mer';
    }

    // 1. USA format "11/15/2026, 09:41:00 AM" or "11/15/2026"
    final usMatch = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:,?\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?)?',
      caseSensitive: false,
    ).firstMatch(str);
    if (usMatch != null) {
      final mIdx = int.tryParse(usMatch.group(1)!) ?? 11;
      final d = int.tryParse(usMatch.group(2)!) ?? 15;
      final m = (mIdx >= 1 && mIdx <= 12) ? months[mIdx - 1] : 'Nov';
      final h = (int.tryParse(usMatch.group(4) ?? '9') ?? 9).toString().padLeft(2, '0');
      final min = usMatch.group(5) ?? '41';
      final mer = (usMatch.group(6) ?? 'AM').toUpperCase();
      return '$m $d, $h:$min $mer';
    }

    // 2. Day Month format "15 Nov 2026, 09:41 AM" or "15 Nov, 09:41 AM"
    final dayMonthMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})(?:\s+\d{4})?,?\s*(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(str);
    if (dayMonthMatch != null) {
      final d = int.tryParse(dayMonthMatch.group(1)!) ?? 15;
      final m = dayMonthMatch.group(2)!;
      final h = dayMonthMatch.group(3)!.padLeft(2, '0');
      final min = dayMonthMatch.group(4)!;
      final mer = (dayMonthMatch.group(5) ?? 'AM').toUpperCase();
      return '$m $d, $h:$min $mer';
    }

    // 3. Month Day format "Nov 15, 2026, 09:41 AM" or "Nov 15, 09:41 AM"
    final monthDayMatch = RegExp(
      r'^([A-Za-z]{3})\s+(\d{1,2})(?:,?\s+\d{4})?,?\s*(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(str);
    if (monthDayMatch != null) {
      final m = monthDayMatch.group(1)!;
      final d = int.tryParse(monthDayMatch.group(2)!) ?? 15;
      final h = monthDayMatch.group(3)!.padLeft(2, '0');
      final min = monthDayMatch.group(4)!;
      final mer = (monthDayMatch.group(5) ?? 'AM').toUpperCase();
      return '$m $d, $h:$min $mer';
    }

    return null;
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    final steps = _getDynamicActivitySteps();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: cardBorderColor),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.alt_route, size: 18, color: primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    'Shipment Timeline',
                    style: TextStyle(
                      color: darkSlate,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Color(0xFF94A3B8)),
                  SizedBox(width: 4),
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...List.generate(steps.length, (idx) {
            final s = steps[idx];
            final state = s['state'];
            final isDone = state == 'done';
            final isCurrent = state == 'current';
            final isPending = state == 'pending';
            final isLast = idx == steps.length - 1;

            return Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : (isCurrent ? 6 : 4),
              ),
              padding: isCurrent
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: isCurrent
                  ? BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    )
                  : null,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step Indicator Column with connecting line
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          if (isDone)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: successGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 13,
                              ),
                            )
                          else if (isCurrent)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryOrange, width: 2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          if (!isLast)
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Step Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1, bottom: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    s['title']!,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? const Color(0xFF9A3412)
                                          : (isPending ? textMuted : darkSlate),
                                      fontSize: 13,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : (isDone ? FontWeight.w600 : FontWeight.w500),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStepRightBadge(s),
                              ],
                            ),
                            if (s['desc'] != null && (s['desc'] as String).isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                s['desc']!,
                                style: TextStyle(
                                  color: isCurrent
                                      ? const Color(0xFF7C2D12)
                                      : (isPending ? const Color(0xFF94A3B8) : textMuted),
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                            if (s['isHandoverStep'] == true && isCurrent) ...[
                              const SizedBox(height: 8),
                              _buildHandoverActionInTimeline(context, s),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepRightBadge(Map<String, dynamic> s) {
    final state = s['state'];
    final rawDate = s['date'] ?? s['time'];
    final formattedDate = (state == 'done') ? _formatTimelineDate(rawDate) : null;

    if (state == 'current') {
      final customBadge = s['badgeText']?.toString();
      final isAwaiting = customBadge == 'Awaiting Customer' ||
          s['time'] == 'Awaiting Customer' ||
          s['date'] == 'Awaiting Customer';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Text(
          customBadge ?? (isAwaiting ? 'Awaiting Customer' : 'In Progress'),
          style: const TextStyle(
            color: primaryOrange,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (state == 'done') {
      if (formattedDate != null && formattedDate.isNotEmpty) {
        final parts = formattedDate.split(',');
        final datePart = parts.first.trim();
        final timePart =
            parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 11,
              color: darkSlate,
            ),
            const SizedBox(width: 4),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: timePart.isNotEmpty ? '$datePart, ' : datePart,
                    style: const TextStyle(color: darkSlate),
                  ),
                  if (timePart.isNotEmpty)
                    TextSpan(
                      text: timePart,
                      style: const TextStyle(
                        color: primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Text(
          'Completed',
          style: TextStyle(
            color: successGreen,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Pending state - strictly show "Pending" badge, NEVER show time or date!
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'Pending',
        style: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHandoverActionInTimeline(BuildContext context, Map<String, dynamic> s) {
    final partnerName = shipment.partnerDriver?['driver_name']?.toString() ?? 'Partner Driver';
    final otpCode = shipment.handover?['otp_code']?.toString() ?? '';

    if (!shipment.isDeliveryOnly) {
      // Driver 1 handover state: Show OTP code and button
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 14, color: primaryOrange),
                const SizedBox(width: 4),
                Text(
                  'Relay Partner: $partnerName',
                  style: const TextStyle(
                    color: darkSlate,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (otpCode.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    'OTP Code: ',
                    style: TextStyle(color: textMuted, fontSize: 11.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          otpCode,
                          style: const TextStyle(
                            color: primaryOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: otpCode));
                            AppToast.show(
                              context,
                              message: 'OTP Copied: $otpCode',
                              type: ToastType.success,
                            );
                          },
                          child: const Icon(Icons.copy, size: 14, color: primaryOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenHandover,
                icon: const Icon(Icons.qr_code, size: 15, color: Colors.white),
                label: const Text(
                  'View Handover OTP & Cargo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Driver 2 handover acceptance button
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 14, color: primaryOrange),
                const SizedBox(width: 4),
                Text(
                  'Relay Partner: $partnerName',
                  style: const TextStyle(
                    color: darkSlate,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenAcceptHandover,
                icon: const Icon(Icons.verified, size: 15, color: Colors.white),
                label: const Text(
                  'Accept Cargo from Driver 1',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildKeyValueRow(
    String label,
    String value, {
    bool isBoldValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 95, maxWidth: 130),
          child: Text(
            label,
            style: const TextStyle(color: textMuted, fontSize: 11.5),
          ),
        ),
        const Text(
          ' : ',
          style: TextStyle(
            color: textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            softWrap: true,
            style: TextStyle(
              color: darkSlate,
              fontSize: 11.5,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
