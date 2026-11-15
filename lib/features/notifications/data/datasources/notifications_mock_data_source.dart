import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationsMockDataSource {
  static final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'notif_1',
      title: 'Dock Door #4 Assigned for Pickup',
      message: 'ABC Warehouse Logistics assigned Bay 4. Security seal #SEAL-88902 verified.',
      detailedBody: 'Security clearance confirmed at South Gate Checkpoint #2. Trailer #TR-402 is authorized to back into Bay 4 for cargo loading. Warehouse dock lead David Miller is on-site to assist with pallet staging and physical seal verification.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      category: NotificationCategory.dockSecurity,
      priority: NotificationPriority.urgent,
      shipmentId: 'SHP-987654',
      locationName: 'Bay 4, ABC Warehouse Logistics',
      locationAddress: 'Port Logistics Park, Bay 4, Seattle WA',
      senderName: 'David Miller (Dock Lead)',
      senderAvatar: 'assets/images/supplier_avatar.png',
      actionLabel: 'Navigate to Bay 4',
      actionIcon: Icons.alt_route_rounded,
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_2',
      title: 'Signed Digital BOL #BOL-88902 Verified',
      message: 'Official electronic freight manifest signed and handed over.',
      detailedBody: 'The shipper agent David Miller has digitally signed and verified Bill of Lading #BOL-88902-US. 20 refrigerated pallets (18,400 lbs total weight) are confirmed loaded. You can now view and download the official PDF manifest.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 48)),
      category: NotificationCategory.paperworkBol,
      priority: NotificationPriority.success,
      shipmentId: 'SHP-987654',
      locationName: 'ABC Warehouse Logistics',
      locationAddress: 'Port Logistics Park, Bay 4',
      senderName: 'David Miller (Warehouse Desk)',
      senderAvatar: 'assets/images/supplier_avatar.png',
      actionLabel: 'View Digital BOL',
      actionIcon: Icons.description_outlined,
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_3',
      title: 'I-95 South Severe Congestion Alert (+25 min)',
      message: 'Heavy traffic reported near Exit 14. Detour via Route 9W recommended.',
      detailedBody: 'State DOT traffic radar has detected a multi-lane bottleneck on I-95 South approaching Exit 14 due to construction. To maintain your on-time delivery ETA of 04:30 PM at Starlight Supermarket Central, automated GPS rerouting is available via Route 9W.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      category: NotificationCategory.trafficAlert,
      priority: NotificationPriority.important,
      shipmentId: 'SHP-987654',
      locationName: 'I-95 Southbound Corridor (Mile Marker 42)',
      locationAddress: 'Interstate 95 South Exit 14',
      senderName: 'Central 24/7 Dispatch Radar',
      actionLabel: 'Open Live GPS Navigation',
      actionIcon: Icons.navigation_rounded,
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_4',
      title: 'New Refrigerated Load #SHP-987654 Assigned',
      message: 'Pickup at ABC Warehouse → Delivery to Starlight Supermarket Central.',
      detailedBody: 'Logistics Desk #204 has assigned Load #SHP-987654 to your semi-truck. Commodity: Refrigerated Dairy & Frozen Bakery Goods (18,400 lbs, Reefer temp set to -18°C). Distance: 42.8 km. Estimated drive time: 1 hr 15 mins.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: NotificationCategory.loadAssignment,
      priority: NotificationPriority.important,
      shipmentId: 'SHP-987654',
      locationName: 'ABC Warehouse Logistics',
      locationAddress: 'Port Logistics Park, Bay 4',
      senderName: 'Central Dispatch HQ',
      actionLabel: 'View Load & Route Details',
      actionIcon: Icons.local_shipping_outlined,
      isRead: true,
    ),
    NotificationModel(
      id: 'notif_5',
      title: 'Pre-Trip DVIR Inspection Completed',
      message: 'Daily vehicle inspection report confirmed safe for highway operation.',
      detailedBody: 'Your electronic DVIR pre-trip inspection log for Tractor #TR-402 and 53ft Reefer Trailer has been successfully transmitted to DOT compliance records. Brakes, tires, reefer temperature unit, and lights are verified operational.',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      category: NotificationCategory.complianceSafety,
      priority: NotificationPriority.success,
      locationName: 'Carrier Yard Depot #1',
      locationAddress: 'Apex Transport Logistics Yard, Seattle WA',
      senderName: 'Fleet Safety & Compliance Desk',
      actionLabel: 'View Safety Checklist',
      actionIcon: Icons.verified_user_outlined,
      isRead: true,
    ),
  ];

  static List<NotificationModel> getNotifications() {
    return List.from(_mockNotifications);
  }

  static void markAsRead(String id) {
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(
        isRead: true,
      );
    }
  }

  static void markAllAsRead() {
    for (int i = 0; i < _mockNotifications.length; i++) {
      _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
    }
  }

  static void deleteNotification(String id) {
    _mockNotifications.removeWhere((n) => n.id == id);
  }

  static int getUnreadCount() {
    return _mockNotifications.where((n) => !n.isRead).length;
  }
}
