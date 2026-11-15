import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../trips/presentation/screens/bol_paperwork_screen.dart';
import '../../../trips/presentation/screens/in_app_navigation_screen.dart';
import '../../../trips/presentation/screens/shipment_details_screen.dart';
import '../../../trips/presentation/screens/trips_screen.dart';
import '../../data/models/notification_model.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onDeleted;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
    this.onDeleted,
  });

  @override
  State<NotificationDetailsScreen> createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  late NotificationModel _notif;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  @override
  void initState() {
    super.initState();
    _notif = widget.notification;
    if (!_notif.isRead) {
      _markReadApi(_notif.id);
      _notif = _notif.copyWith(isRead: true);
    }
  }

  Future<void> _markReadApi(String id) async {
    try {
      final token =
          await SecureStorage().read(AppConstants.keyAuthToken) ??
          await LocalStorage().getString(AppConstants.keyAuthToken);
      if (token == null) return;
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/driver/notifications/$id/read',
      );
      await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  Future<void> _deleteApi(String id) async {
    try {
      final token =
          await SecureStorage().read(AppConstants.keyAuthToken) ??
          await LocalStorage().getString(AppConstants.keyAuthToken);
      if (token == null) return;
      final uri = Uri.parse('${ApiConstants.baseUrl}/driver/notifications/$id');
      await http
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.dockSecurity:
        return const Color(0xFFEA580C);
      case NotificationCategory.paperworkBol:
        return const Color(0xFF0284C7);
      case NotificationCategory.trafficAlert:
        return const Color(0xFFEF4444);
      case NotificationCategory.loadAssignment:
        return const Color(0xFFD97706);
      case NotificationCategory.complianceSafety:
        return const Color(0xFF10B981);
      case NotificationCategory.chatMessage:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.dockSecurity:
        return Icons.warehouse_rounded;
      case NotificationCategory.paperworkBol:
        return Icons.description_rounded;
      case NotificationCategory.trafficAlert:
        return Icons.warning_amber_rounded;
      case NotificationCategory.loadAssignment:
        return Icons.local_shipping_rounded;
      case NotificationCategory.complianceSafety:
        return Icons.verified_user_rounded;
      case NotificationCategory.chatMessage:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _getCategoryTitle(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.dockSecurity:
        return 'Dock & Security Clearance';
      case NotificationCategory.paperworkBol:
        return 'Electronic Paperwork (BOL)';
      case NotificationCategory.trafficAlert:
        return 'Road & Traffic Alert';
      case NotificationCategory.loadAssignment:
        return 'Load Assignment';
      case NotificationCategory.complianceSafety:
        return 'Safety & Compliance';
      case NotificationCategory.chatMessage:
        return 'Live Dispatch Chat';
    }
  }

  void _handlePrimaryAction() {
    final shipmentId = _notif.shipmentId ?? 'SHP-987654';

    switch (_notif.category) {
      case NotificationCategory.dockSecurity:
      case NotificationCategory.trafficAlert:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppNavigationScreen(
              shipment: ShipmentItem(
                id: shipmentId,
                status: ShipmentFilter.inProgress,
                originTitle: 'Warehouse Logistics',
                originAddress: 'Port Logistics Park',
                destTitle: 'Starlight Supermarket Central',
                destAddress: 'Dock 12, 742 Evergreen Terrace',
                date: 'Today',
                time: '04:30 PM',
                cargoType: 'Commercial Goods',
                distanceKm: 25.0,
                statusLabel: 'In Transit',
              ),
            ),
          ),
        );
        break;

      case NotificationCategory.paperworkBol:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BolPaperworkScreen(
              shipmentId: shipmentId,
              originTitle: 'ABC Warehouse Logistics',
              destTitle: 'Starlight Supermarket Central',
            ),
          ),
        );
        break;

      case NotificationCategory.loadAssignment:
      case NotificationCategory.complianceSafety:
      case NotificationCategory.chatMessage:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShipmentDetailsScreen(
              shipment: ShipmentItem(
                id: shipmentId,
                status: ShipmentFilter.inProgress,
                originTitle: 'ABC Warehouse Logistics',
                originAddress: 'Bay 4, Port Logistics Park',
                destTitle: 'Starlight Supermarket Central',
                destAddress: 'Dock 12, 742 Evergreen Terrace',
                date: 'Today',
                time: '04:30 PM',
                cargoType: 'Refrigerated Dairy & Goods',
                distanceKm: 42.8,
                statusLabel: 'In Transit',
              ),
            ),
          ),
        );
        break;
    }
  }

  void _deleteNotification() {
    _deleteApi(_notif.id);
    widget.onDeleted?.call();
    Navigator.pop(context);
    AppToast.info(context, 'Notification removed');
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(_notif.category);
    final catIcon = _getCategoryIcon(_notif.category);
    final catTitle = _getCategoryTitle(_notif.category);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: textMain,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          catTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: cardBorder),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            onPressed: _deleteNotification,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Title & Priority Card (Compact & Professional)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Compact Circular Category Icon Container
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(catIcon, color: catColor, size: 19),
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
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  catTitle.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_notif.formattedDateTime} • ${_notif.timeAgo}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _notif.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _notif.message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: textSub,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2. Full Instruction & Logistics Context Card (Compact)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logistics Instructions & Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        _notif.detailedBody,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: textMain,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 3. Key Logistics Metadata Summary Card (Compact)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reference & Facility Information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_notif.shipmentId != null)
                      _buildMetaRow(
                        Icons.inventory_2_outlined,
                        'Load Reference:',
                        '#${_notif.shipmentId!}',
                      ),
                    if (_notif.locationName != null)
                      _buildMetaRow(
                        Icons.location_on_outlined,
                        'Assigned Dock / Bay:',
                        _notif.locationName!,
                      ),
                    if (_notif.locationAddress != null)
                      _buildMetaRow(
                        Icons.map_outlined,
                        'Facility Address:',
                        _notif.locationAddress!,
                      ),
                    if (_notif.senderName != null)
                      _buildMetaRow(
                        Icons.person_outline_rounded,
                        'Dispatched By:',
                        _notif.senderName!,
                      ),
                    _buildMetaRow(
                      Icons.verified_outlined,
                      'Notice Status:',
                      'Verified & Handled',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Compact Primary Interactive Action Button
              if (_notif.actionLabel != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _handlePrimaryAction,
                    icon: Icon(
                      _notif.actionIcon ?? Icons.arrow_forward_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _notif.actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 5. Compact Secondary Dismiss Button
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSub,
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Back to Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontSize: 12, color: textSub)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
