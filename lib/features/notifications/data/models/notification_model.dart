import 'package:flutter/material.dart';

enum NotificationCategory {
  loadAssignment,
  dockSecurity,
  trafficAlert,
  paperworkBol,
  complianceSafety,
  chatMessage,
}

enum NotificationPriority { urgent, important, normal, success }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String detailedBody;
  final DateTime timestamp;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String? shipmentId;
  final String? locationName;
  final String? locationAddress;
  final String? senderName;
  final String? senderAvatar;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.detailedBody,
    required this.timestamp,
    required this.category,
    this.priority = NotificationPriority.normal,
    this.shipmentId,
    this.locationName,
    this.locationAddress,
    this.senderName,
    this.senderAvatar,
    this.actionLabel,
    this.actionIcon,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type']?.toString() ?? 'system').toLowerCase();

    NotificationCategory category = NotificationCategory.complianceSafety;
    NotificationPriority priority = NotificationPriority.normal;
    IconData? actionIcon;
    String? actionLabel = 'View Details';

    if (type.contains('account_verified') ||
        type.contains('verified') ||
        type.contains('profile')) {
      category = NotificationCategory.complianceSafety;
      priority = NotificationPriority.success;
      actionIcon = Icons.verified_rounded;
      actionLabel = 'View Status';
    } else if (type.contains('reject')) {
      category = NotificationCategory.complianceSafety;
      priority = NotificationPriority.urgent;
      actionIcon = Icons.error_outline_rounded;
      actionLabel = 'Fix Documents';
    } else if (type.contains('order') ||
        type.contains('load') ||
        type.contains('shipment') ||
        type.contains('delivery')) {
      category = NotificationCategory.loadAssignment;
      priority = NotificationPriority.important;
      actionIcon = Icons.local_shipping_rounded;
      actionLabel = 'View Shipment';
    } else if (type.contains('bol') ||
        type.contains('paperwork') ||
        type.contains('doc')) {
      category = NotificationCategory.paperworkBol;
      priority = NotificationPriority.normal;
      actionIcon = Icons.description_rounded;
      actionLabel = 'View BOL';
    } else if (type.contains('dock') ||
        type.contains('bay') ||
        type.contains('security')) {
      category = NotificationCategory.dockSecurity;
      priority = NotificationPriority.important;
      actionIcon = Icons.warehouse_rounded;
      actionLabel = 'Dock Pass';
    } else if (type.contains('chat') || type.contains('message')) {
      category = NotificationCategory.chatMessage;
      priority = NotificationPriority.normal;
      actionIcon = Icons.chat_bubble_outline_rounded;
      actionLabel = 'Open Chat';
    } else if (type.contains('alert') || type.contains('traffic')) {
      category = NotificationCategory.trafficAlert;
      priority = NotificationPriority.urgent;
      actionIcon = Icons.warning_amber_rounded;
      actionLabel = 'Check Route';
    }

    DateTime parsedDate;
    if (json['created_at'] != null) {
      parsedDate =
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      detailedBody:
          json['details']?.toString() ?? json['message']?.toString() ?? '',
      timestamp: parsedDate,
      category: category,
      priority: priority,
      shipmentId:
          json['order_number']?.toString() ?? json['order_id']?.toString(),
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      isRead: json['is_read'] == true,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? detailedBody,
    DateTime? timestamp,
    NotificationCategory? category,
    NotificationPriority? priority,
    String? shipmentId,
    String? locationName,
    String? locationAddress,
    String? senderName,
    String? senderAvatar,
    String? actionLabel,
    IconData? actionIcon,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      detailedBody: detailedBody ?? this.detailedBody,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      shipmentId: shipmentId ?? this.shipmentId,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      actionLabel: actionLabel ?? this.actionLabel,
      actionIcon: actionIcon ?? this.actionIcon,
      isRead: isRead ?? this.isRead,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  String get formattedDateTime {
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return 'Today, $hour:$minute $period';
  }
}
