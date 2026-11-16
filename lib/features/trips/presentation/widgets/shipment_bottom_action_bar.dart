import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/order_gps_tracker_service.dart';
import '../../../../shared/utils/map_launcher_helper.dart';
import '../../../../shared/widgets/slide_to_act_button.dart';
import '../../data/models/shipment_item_model.dart';
import '../screens/in_app_navigation_screen.dart';

class ShipmentBottomActionBar extends StatelessWidget {
  final ShipmentItem shipment;
  final bool isLoading;
  final bool isUpdatingStatus;
  final String slideActionText;
  final Future<bool> Function() onSlideComplete;
  final bool isDelivered;
  final String? podStatus;
  final VoidCallback? onOpenHandover;
  final VoidCallback? onOpenAcceptHandover;
  final VoidCallback? onOpenPodModal;

  static const Color primaryOrange = AppColors.primary;
  static const Color successGreen = AppColors.success;
  static const Color cardBorderColor = AppColors.border;

  const ShipmentBottomActionBar({
    super.key,
    required this.shipment,
    required this.isLoading,
    required this.isUpdatingStatus,
    required this.slideActionText,
    required this.onSlideComplete,
    this.isDelivered = false,
    this.podStatus,
    this.onOpenHandover,
    this.onOpenAcceptHandover,
    this.onOpenPodModal,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cardBorderColor, width: 1)),
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      );
    }

    final rawStatus = (shipment.rawStatus.isNotEmpty
            ? shipment.rawStatus
            : shipment.statusLabel)
        .toLowerCase()
        .trim();
    final pStatus = (podStatus ?? '').toLowerCase().trim();

    final isCustomerApproved =
        pStatus == 'approved' ||
        pStatus == 'accepted' ||
        rawStatus == 'completed' ||
        rawStatus == 'pod_accepted' ||
        rawStatus == 'order_completed';

    final isDeliveredOrUploaded =
        isCustomerApproved ||
        isDelivered ||
        pStatus == 'delivered' ||
        pStatus == 'pending' ||
        rawStatus == 'delivered' ||
        rawStatus == 'completed' ||
        rawStatus == 'pod_accepted' ||
        shipment.status == ShipmentFilter.completed;

    final isDelivering = shipment.status == ShipmentFilter.inProgress ||
        shipment.status == ShipmentFilter.completed ||
        rawStatus == 'in_transit' ||
        rawStatus == 'at_delivery' ||
        rawStatus == 'at_hub';

    if (shipment.isEmergency) {
      return _buildContainerWrapper(
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause_circle_outline_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Shift on Hold • Reassignment Active',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1. RELAY WORKFLOW – DRIVER 1 (Leg 1: Pickup to Hub)
    if (shipment.isLeg1) {
      if (shipment.isLeg1HandoverCompleted) {
        return _buildContainerWrapper(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: successGreen,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Collection Completed • Handed Over',
                  style: TextStyle(
                    color: successGreen,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (shipment.isHandoverPending) {
        return _buildContainerWrapper(
          child: Row(
            children: [
              _buildGpsButton(context, isDelivering: true),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onOpenHandover,
                    icon: const Icon(
                      Icons.vpn_key_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'View Handover OTP & Cargo',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (rawStatus == 'at_hub') {
        return _buildContainerWrapper(
          child: Row(
            children: [
              _buildGpsButton(context, isDelivering: true),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onOpenHandover,
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Handover Cargo to Delivery Driver',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Leg 1 pickup / in_transit slide action
      return _buildContainerWrapper(
        child: Row(
          children: [
            _buildGpsButton(context, isDelivering: isDelivering),
            const SizedBox(width: 10),
            Expanded(
              child: SlideToActButton(
                text: slideActionText,
                isLoading: isUpdatingStatus,
                onSlideComplete: onSlideComplete,
              ),
            ),
          ],
        ),
      );
    }

    // 2. RELAY WORKFLOW – DRIVER 2 (Leg 2: Hub to Destination)
    if (shipment.isLeg2) {
      if (isDeliveredOrUploaded) {
        return _buildDeliveredCard(isCustomerApproved);
      }

      if (rawStatus == 'at_delivery' || rawStatus == 'arrived') {
        return _buildContainerWrapper(
          child: Row(
            children: [
              _buildGpsButton(context, isDelivering: true),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onOpenPodModal,
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Complete Delivery & Upload POD',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (shipment.isHandoverPending) {
        return _buildContainerWrapper(
          child: Row(
            children: [
              _buildGpsButton(context, isDelivering: false),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onOpenAcceptHandover,
                    icon: const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Accept Cargo from Collection Driver',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (!shipment.isHandoverAccepted) {
        return _buildContainerWrapper(
          child: Row(
            children: [
              _buildGpsButton(context, isDelivering: false),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Awaiting Cargo Handover from Collection Driver',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Handover accepted, ready to depart or in transit to destination
      return _buildContainerWrapper(
        child: Row(
          children: [
            _buildGpsButton(context, isDelivering: true),
            const SizedBox(width: 10),
            Expanded(
              child: SlideToActButton(
                text: slideActionText,
                isLoading: isUpdatingStatus,
                onSlideComplete: onSlideComplete,
              ),
            ),
          ],
        ),
      );
    }

    // 3. SINGLE DRIVER SHIPMENT WORKFLOW
    if (isDeliveredOrUploaded) {
      return _buildDeliveredCard(isCustomerApproved);
    }

    if (rawStatus == 'at_delivery' || rawStatus == 'arrived') {
      return _buildContainerWrapper(
        child: Row(
          children: [
            _buildGpsButton(context, isDelivering: true),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onOpenPodModal,
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Complete Delivery & Upload POD',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildContainerWrapper(
      child: Row(
        children: [
          _buildGpsButton(context, isDelivering: isDelivering),
          const SizedBox(width: 10),
          Expanded(
            child: SlideToActButton(
              text: slideActionText,
              isLoading: isUpdatingStatus,
              onSlideComplete: onSlideComplete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cardBorderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }

  Widget _buildDeliveredCard(bool isCustomerApproved) {
    return _buildContainerWrapper(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isCustomerApproved
              ? const Color(0xFFECFDF5)
              : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCustomerApproved
                ? const Color(0xFFA7F3D0)
                : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCustomerApproved
                  ? Icons.check_circle_rounded
                  : Icons.hourglass_top_rounded,
              color: isCustomerApproved
                  ? successGreen
                  : const Color(0xFFD97706),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isCustomerApproved
                  ? 'Order Completed • POD Verified'
                  : 'Awaiting Customer Confirmation',
              style: TextStyle(
                color: isCustomerApproved
                    ? successGreen
                    : const Color(0xFFD97706),
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsButton(BuildContext context, {required bool isDelivering}) {
    return SizedBox(
      width: 50,
      height: 50,
      child: OutlinedButton(
        onPressed: () async {
          OrderGpsTrackerService().startTracking(shipment);

          String targetAddr;
          double? targetLat;
          double? targetLng;
          String targetTitle;

          if (shipment.isLeg1) {
            targetAddr = shipment.hubLocation.isNotEmpty
                ? shipment.hubLocation
                : (shipment.destAddress.isNotEmpty
                    ? shipment.destAddress
                    : shipment.destTitle);
            targetLat = shipment.destLat != 0.0 ? shipment.destLat : null;
            targetLng = shipment.destLng != 0.0 ? shipment.destLng : null;
            targetTitle = shipment.hubLocation.isNotEmpty
                ? 'Relay Hub: ${shipment.hubLocation}'
                : shipment.destTitle;
          } else if (isDelivering) {
            targetAddr = shipment.destAddress;
            targetLat = shipment.destLat != 0.0 ? shipment.destLat : null;
            targetLng = shipment.destLng != 0.0 ? shipment.destLng : null;
            targetTitle = shipment.destTitle;
          } else {
            targetAddr = shipment.originAddress;
            targetLat = shipment.originLat != 0.0 ? shipment.originLat : null;
            targetLng = shipment.originLng != 0.0 ? shipment.originLng : null;
            targetTitle = shipment.originTitle;
          }

          await MapLauncherHelper.openGoogleMaps(
            context,
            destinationAddress: targetAddr.isNotEmpty && targetAddr != '—'
                ? targetAddr
                : targetTitle,
            latitude: targetLat,
            longitude: targetLng,
            destinationTitle: targetTitle,
          );
        },
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InAppNavigationScreen(shipment: shipment),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(
            color: primaryOrange,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Icon(
          Icons.navigation_rounded,
          size: 20,
          color: primaryOrange,
        ),
      ),
    );
  }
}
