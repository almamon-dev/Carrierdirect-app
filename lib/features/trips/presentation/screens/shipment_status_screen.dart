import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/file_upload_helper.dart';
import '../widgets/customer_delivery_verification_modal.dart';
import 'live_tracking_screen.dart';
import 'trips_screen.dart';

class ShipmentStatusScreen extends StatefulWidget {
  final ShipmentItem shipment;

  const ShipmentStatusScreen({
    super.key,
    required this.shipment,
  });

  @override
  State<ShipmentStatusScreen> createState() => _ShipmentStatusScreenState();
}

class _ShipmentStatusScreenState extends State<ShipmentStatusScreen> {
  int _currentStepIndex = 3; // Default at "In Transit" (Step 3)
  bool _isUpdating = false;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = AppColors.background;
  static const Color cardBg = AppColors.surface;
  static const Color cardBorder = AppColors.border;
  static const Color textMuted = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  final List<Map<String, dynamic>> _stepDefinitions = [
    {
      'title': 'Assigned',
      'subtitle': 'Dispatched by Logistics Desk #204',
      'time': 'Today, 08:30 AM',
      'icon': Icons.alt_route_rounded,
      'actionLabel': 'Accept Shipment',
    },
    {
      'title': 'Accepted',
      'subtitle': 'Driver confirmed load acceptance',
      'time': 'Today, 08:45 AM',
      'icon': Icons.check_circle_outline_rounded,
      'actionLabel': 'Confirm Pickup & Loading',
    },
    {
      'title': 'Pickup Completed',
      'subtitle': 'Cargo loaded & BOL signed at shipper',
      'time': 'Today, 09:05 AM',
      'icon': Icons.inventory_2_outlined,
      'actionLabel': 'Start Trip (In Transit)',
    },
    {
      'title': 'In Transit',
      'subtitle': 'Semi-truck en route to destination dock',
      'time': 'Today, 09:10 AM',
      'icon': Icons.local_shipping_rounded,
      'actionLabel': 'Mark Out for Delivery',
    },
    {
      'title': 'Out for Delivery',
      'subtitle': 'Arrived at receiver facility gate',
      'time': 'Today, 10:30 AM',
      'icon': Icons.near_me_outlined,
      'actionLabel': 'Complete Delivery & Upload POD',
    },
    {
      'title': 'Delivered',
      'subtitle': 'Proof of delivery signed & load closed',
      'time': 'Today, 10:45 AM',
      'icon': Icons.task_alt_rounded,
      'actionLabel': 'Delivery Completed ✓',
    },
  ];

  void _advanceNextStatus() async {
    if (_currentStepIndex >= _stepDefinitions.length - 1) return;

    // If next step is "Delivered", allow POD upload
    if (_currentStepIndex == 4) {
      _showPodConfirmationSheet();
      return;
    }

    setState(() => _isUpdating = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isUpdating = false;
        _currentStepIndex++;
      });

      final nextTitle = _stepDefinitions[_currentStepIndex]['title'];
      AppToast.success(context, 'Status updated: $nextTitle');
    }
  }

  void _showPodConfirmationSheet() {
    UploadedFileInfo? localPodFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 3.5,
                    decoration: BoxDecoration(color: const Color(0xFFCED0D4), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attach Signed POD',
                            style: TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Upload signed BOL/Gate Pass photo to verify',
                            style: TextStyle(color: textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Compact Interactive Photo Box
                GestureDetector(
                  onTap: () async {
                    final file = await FileUploadHelper.pickFileOrPhoto(
                      modalCtx,
                      title: 'Capture / Attach Signed POD Photo',
                    );
                    if (file != null && modalCtx.mounted) {
                      setModalState(() {
                        localPodFile = file;
                      });
                      AppToast.success(modalCtx, 'POD Attached: ${file.name}');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: localPodFile != null ? const Color(0xFF10B981) : cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          localPodFile != null ? Icons.check_circle_rounded : Icons.photo_camera_outlined,
                          color: localPodFile != null ? const Color(0xFF10B981) : primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localPodFile != null
                                ? 'Attached: ${localPodFile!.name}'
                                : 'Tap to take/attach signed POD photo *',
                            style: TextStyle(
                              color: localPodFile != null ? const Color(0xFF065F46) : textMain,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Action Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (localPodFile == null) {
                        AppToast.warning(
                          modalCtx,
                          'Please take or attach a photo of the signed POD first!',
                          icon: Icons.camera_alt_rounded,
                        );
                        final file = await FileUploadHelper.pickFileOrPhoto(
                          modalCtx,
                          title: 'Capture / Attach Signed POD Photo',
                        );
                        if (file != null && modalCtx.mounted) {
                          setModalState(() {
                            localPodFile = file;
                          });
                          AppToast.success(modalCtx, 'POD Attached: ${file.name}');
                        }
                        return;
                      }

                      Navigator.pop(ctx);
                      CustomerDeliveryVerificationModal.show(
                        context,
                        shipment: widget.shipment,
                        podFileName: localPodFile?.name ?? 'Signed_POD.jpg',
                        onVerified: () {
                          if (!mounted) return;
                          setState(() {
                            _currentStepIndex = 5; // Delivered
                          });
                          AppToast.success(
                            context,
                            '✓ Customer verified delivery! Shipment #${widget.shipment.id} closed.',
                            icon: Icons.verified_user_rounded,
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      localPodFile != null ? 'Proceed to Customer Verification →' : 'Attach POD & Verify Customer',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _currentStepIndex >= 5;
    final nextActionLabel = isDelivered
        ? 'Delivery Completed ✓'
        : _stepDefinitions[_currentStepIndex + 1]['actionLabel'] as String;

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textMain),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipment Status',
                        style: TextStyle(
                          color: textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '#${widget.shipment.id} • ${_stepDefinitions[_currentStepIndex]['title']}',
                        style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Shortcut to Live Map
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LiveTrackingScreen(shipment: widget.shipment),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_rounded, size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text('Map View', style: TextStyle(color: textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: cardBorder, height: 1),

            // Stepper List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                children: [
                  ...List.generate(_stepDefinitions.length, (index) {
                    final step = _stepDefinitions[index];
                    final isCompleted = index < _currentStepIndex;
                    final isActive = index == _currentStepIndex;
                    final isLast = index == _stepDefinitions.length - 1;

                    return _buildTimelineItem(
                      icon: step['icon'] as IconData,
                      title: step['title'] as String,
                      subtitle: step['subtitle'] as String,
                      time: isCompleted || isActive ? step['time'] as String : 'Pending',
                      isCompleted: isCompleted,
                      isActive: isActive,
                      isLast: isLast,
                    );
                  }),
                ],
              ),
            ),

            // Driver Status Update Action Bar
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                border: const Border(top: BorderSide(color: cardBorder)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Update Status Button
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: isDelivered || _isUpdating ? null : _advanceNextStatus,
                        icon: _isUpdating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(isDelivered ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 16),
                        label: Text(
                          _isUpdating ? 'Updating...' : nextActionLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDelivered ? const Color(0xFF059669) : primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE4E6EB),
                          disabledForegroundColor: textMuted,
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final bool isHighlighted = isCompleted || isActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline column (icon badge + vertical connector)
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted ? primaryColor : const Color(0xFFF0F2F5),
                border: Border.all(
                  color: isHighlighted ? primaryColor : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isHighlighted ? Colors.white : textMuted,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 52,
                color: isCompleted ? primaryColor : const Color(0xFFCBD5E1),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Right details column
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isHighlighted ? textMain : textMuted,
                        fontSize: 15,
                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(color: primaryColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFD97706) : const Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
