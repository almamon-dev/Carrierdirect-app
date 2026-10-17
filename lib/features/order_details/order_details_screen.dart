import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../shared/utils/app_toast.dart';

/// Screen 10: Order Tracking (Details)
class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const OrderDetailsScreen({super.key, this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPodUploaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleUploadPod() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload Proof of Delivery (POD)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo of the signed delivery receipt or Bill of Lading (BOL).',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF2EB), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _isPodUploaded = true);
                  AppToast.success(context, 'Signed POD document captured & uploaded successfully!');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F172A)),
                ),
                title: const Text('Upload from Gallery / Files', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _isPodUploaded = true);
                  AppToast.success(context, 'Signed POD document uploaded successfully!');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order ?? {
      'id': 'ORD-10001',
      'from': 'London, UK',
      'to': 'Manchester, UK',
      'pickupTime': 'Oct 16, 2026 • 10:00 AM',
      'deliveryTime': 'Oct 16, 2026 • 04:30 PM',
      'currentLocation': 'M1, Manchester, UK',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Order #${order['id'] ?? 'ORD-10001'}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Route'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Details & Order Timeline (Matches Mockup Screen 10)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Steps
                _buildTimelineStep(
                  dotColor: AppColors.primary,
                  isDashedLine: false,
                  title: 'Pickup',
                  location: order['from'] as String? ?? 'London, UK',
                  time: order['pickupTime'] as String? ?? 'Oct 16, 2026 • 10:00 AM',
                  statusBadge: 'Completed',
                  statusBadgeColor: const Color(0xFF10B981),
                  statusBadgeBg: const Color(0xFFECFDF5),
                ),

                _buildTimelineStep(
                  dotColor: const Color(0xFF2563EB),
                  isDashedLine: false,
                  title: 'In Transit',
                  location: 'Current Location',
                  time: order['currentLocation'] as String? ?? 'M1, Manchester, UK',
                  statusBadge: null,
                ),

                _buildTimelineStep(
                  dotColor: const Color(0xFF94A3B8),
                  isDashedLine: true,
                  isLast: true,
                  title: 'Delivery',
                  location: order['to'] as String? ?? 'Manchester, UK',
                  time: order['deliveryTime'] as String? ?? 'Oct 16, 2026 • 04:30 PM',
                  statusBadge: _isPodUploaded ? 'Completed' : 'Pending',
                  statusBadgeColor: _isPodUploaded ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  statusBadgeBg: _isPodUploaded ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                ),

                const Spacer(),

                // "Upload POD" Action Button
                CustomButton(
                  text: _isPodUploaded ? 'POD Uploaded ✓' : 'Upload POD',
                  icon: Icons.description_outlined,
                  isOutlined: true,
                  backgroundColor: _isPodUploaded ? const Color(0xFF10B981) : AppColors.primary,
                  textColor: _isPodUploaded ? const Color(0xFF10B981) : AppColors.primary,
                  onPressed: _handleUploadPod,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Tab 2: Route View
          const Center(
            child: Text(
              'Interactive GPS Route View',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),

          // Tab 3: Documents View
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shipment Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _buildDocumentRow('Bill of Lading (BOL)', 'Verified', Icons.receipt_long_rounded),
                const SizedBox(height: 12),
                _buildDocumentRow('Rate Confirmation', 'Signed', Icons.check_circle_outline_rounded),
                const SizedBox(height: 12),
                _buildDocumentRow(
                  'Proof of Delivery (POD)',
                  _isPodUploaded ? 'Uploaded' : 'Pending',
                  Icons.assignment_turned_in_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required Color dotColor,
    required bool isDashedLine,
    required String title,
    required String location,
    required String time,
    String? statusBadge,
    Color? statusBadgeColor,
    Color? statusBadgeBg,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Dot & Vertical Line
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Step Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (statusBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusBadge,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statusBadgeColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
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

  Widget _buildDocumentRow(String title, String status, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14),
            ),
          ),
          Text(
            status,
            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
