enum MessageSenderRole { driver, supplierEmployee, customerReceiver, centralDispatch }

enum MessageAttachmentType { none, image, document, location }

class ChatMessage {
  final String id;
  final String shipmentId;
  final String senderId;
  final String senderName;
  final MessageSenderRole senderRole;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;
  final MessageAttachmentType attachmentType;
  final bool isFromDriver;

  const ChatMessage({
    required this.id,
    required this.shipmentId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isRead = true,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType = MessageAttachmentType.none,
    this.isFromDriver = false,
  });

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
