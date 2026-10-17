import 'package:flutter/material.dart';

enum NotificationCategory {
  loadAssignment,
  dockSecurity,
  trafficAlert,
  paperworkBol,
  complianceSafety,
  chatMessage,
}

enum NotificationPriority {
  urgent,
  important,
  normal,
  success,
}

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
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return 'Today, $hour:$minute $period';
  }
}
