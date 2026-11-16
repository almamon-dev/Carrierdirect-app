import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationsMockDataSource {
  static final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'notif_1',
      title: 'Dock Door #4 Assigned for Pickup',
      message: 'Dhaka Central Freight Hub assigned Bay 4. Security seal #SEAL-CD-10001 verified.',
      detailedBody: 'Security clearance confirmed at North Gate Checkpoint #2. Cargo truck is authorized to back into Bay 4 for cargo loading. Warehouse operations lead Kamal Hossain is on-site to assist with pallet staging and physical seal verification.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      category: NotificationCategory.dockSecurity,
      priority: NotificationPriority.urgent,
      shipmentId: 'ORD-2026-10001',
      locationName: 'Bay 4, Dhaka Central Freight Hub',
      locationAddress: 'Tejgaon Industrial Area, Bay 4, Dhaka',
      senderName: 'Kamal Hossain (Operations Lead)',
      senderAvatar: 'assets/images/supplier_avatar.png',
      actionLabel: 'Navigate to Bay 4',
      actionIcon: Icons.alt_route_rounded,
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_2',
      title: 'Signed Digital BOL #BOL-CD-10001 Verified',
      message: 'Official electronic freight manifest signed and handed over.',
      detailedBody: 'The logistics desk agent Rafiqul Islam has digitally signed and verified Bill of Lading #BOL-CD-10001. Euro Pallets (EPAL-1) cargo (800 kg payload) are confirmed loaded. You can now view and download the official PDF manifest.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 48)),
      category: NotificationCategory.paperworkBol,
      priority: NotificationPriority.success,
      shipmentId: 'ORD-2026-10001',
      locationName: 'Dhaka Central Freight Hub',
      locationAddress: 'Tejgaon Industrial Area, Dhaka',
      senderName: 'Rafiqul Islam (Dispatch Desk)',
      senderAvatar: 'assets/images/supplier_avatar.png',
      actionLabel: 'View Digital BOL',
      actionIcon: Icons.description_outlined,
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_3',
      title: 'N1 Corridor Congestion Alert (+25 min)',
      message: 'Heavy traffic reported near Cumilla Bypass. Detour via Old Highway recommended.',
      detailedBody: 'Highways traffic monitoring radar has detected bottleneck congestion on N1 Corridor approaching Cumilla Bypass due to road maintenance. To maintain on-time delivery ETA at Chittagong Port Terminal, automated GPS rerouting is available.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      category: NotificationCategory.trafficAlert,
      priority: NotificationPriority.important,
      shipmentId: 'ORD-2026-10001',
      locationName: 'Dhaka-Chittagong Highway (N1 Corridor)',
      locationAddress: 'N1 Expressway, Cumilla Interchange',
      senderName: 'CarrierDirect Route Operations',
      actionLabel: 'Open Live GPS Navigation',
      actionIcon: Icons.navigation_rounded,
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_4',
      title: 'New Shipment Order #ORD-2026-10001 Assigned',
      message: 'Pickup at Dhaka Central Freight Hub → Delivery to Chittagong Port Terminal.',
      detailedBody: 'CarrierDirect Central Dispatch has assigned Order #ORD-2026-10001 to your vehicle. Commodity: Euro Pallets (EPAL-1), Ambient / Standard Dry (800 kg). Route distance: 250 km via Intermediate Hub.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: NotificationCategory.loadAssignment,
      priority: NotificationPriority.important,
      shipmentId: 'ORD-2026-10001',
      locationName: 'Dhaka Central Freight Hub',
      locationAddress: 'Tejgaon Industrial Area, Bay 4, Dhaka',
      senderName: 'CarrierDirect Central Dispatch',
      actionLabel: 'View Load & Route Details',
      actionIcon: Icons.local_shipping_outlined,
      isRead: true,
    ),
    NotificationModel(
      id: 'notif_5',
      title: 'Pre-Trip Vehicle Safety Inspection Completed',
      message: 'Daily electronic vehicle inspection report confirmed safe for highway operation.',
      detailedBody: 'Your digital pre-trip inspection log for commercial freight transport has been successfully recorded in compliance records. Brakes, tires, cargo securing systems, and lights are verified operational.',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      category: NotificationCategory.complianceSafety,
      priority: NotificationPriority.success,
      locationName: 'CarrierDirect Fleet Depot #1',
      locationAddress: 'Tejgaon Logistics Center, Dhaka',
      senderName: 'CarrierDirect Fleet Safety Desk',
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
