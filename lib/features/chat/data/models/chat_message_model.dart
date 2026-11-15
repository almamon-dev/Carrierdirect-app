enum MessageSenderRole {
  driver,
  supplierEmployee,
  customerReceiver,
  centralDispatch,
}

enum MessageAttachmentType { none, image, document, location }

class ChatAttachmentItem {
  final String name;
  final String url;
  final String? size;
  final String type; // 'image' or 'file'
  final String? mime;

  const ChatAttachmentItem({
    required this.name,
    required this.url,
    this.size,
    this.type = 'file',
    this.mime,
  });

  bool get isImage {
    if (type.toLowerCase() == 'image') return true;
    if (mime != null && mime!.toLowerCase().startsWith('image/')) return true;
    final lower = (name.isNotEmpty ? name : url).toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  factory ChatAttachmentItem.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final name = (raw['name'] ?? raw['filename'] ?? 'Attachment').toString();
      final url = (raw['url'] ?? raw['path'] ?? '').toString();
      final rawSize = raw['size'];
      String? sizeStr;
      if (rawSize is num && rawSize > 0) {
        if (rawSize >= 1024 * 1024) {
          sizeStr = '${(rawSize / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          sizeStr = '${(rawSize / 1024).toStringAsFixed(1)} KB';
        }
      } else if (rawSize is String && rawSize.isNotEmpty) {
        sizeStr = rawSize;
      }
      final mime = raw['mime']?.toString();
      final rawType = (raw['type'] ?? '').toString().toLowerCase();
      final isImg = rawType == 'image' ||
          (mime != null && mime.startsWith('image/')) ||
          RegExp(r'\.(jpg|jpeg|png|webp|gif|svg)$', caseSensitive: false)
              .hasMatch(name.isNotEmpty ? name : url);
      return ChatAttachmentItem(
        name: name,
        url: url,
        size: sizeStr,
        type: isImg ? 'image' : 'file',
        mime: mime,
      );
    }
    final str = raw?.toString() ?? '';
    final name = str.split('/').last;
    final isImg = RegExp(r'\.(jpg|jpeg|png|webp|gif|svg)$', caseSensitive: false)
        .hasMatch(str);
    return ChatAttachmentItem(
      name: name.isNotEmpty ? name : 'Attachment',
      url: str,
      type: isImg ? 'image' : 'file',
    );
  }
}

class ChatMessage {
  final String id;
  final int? numericId;
  final String shipmentId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final MessageSenderRole senderRole;
  final String message;
  final String messageType;
  final DateTime timestamp;
  final String? timeString;
  final String? dateString;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;
  final MessageAttachmentType attachmentType;
  final List<ChatAttachmentItem> attachments;
  final bool isFromDriver;
  final bool isUnsent;
  final bool isEdited;
  final bool isPinned;
  final int? replyToId;
  final String? replyToMessage;
  final bool replyToIsMe;

  const ChatMessage({
    required this.id,
    this.numericId,
    required this.shipmentId,
    required this.senderId,
    this.receiverId = '',
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.messageType = 'text',
    required this.timestamp,
    this.timeString,
    this.dateString,
    this.isRead = true,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType = MessageAttachmentType.none,
    this.attachments = const [],
    this.isFromDriver = false,
    this.isUnsent = false,
    this.isEdited = false,
    this.isPinned = false,
    this.replyToId,
    this.replyToMessage,
    this.replyToIsMe = false,
  });

  String get formattedTime {
    if (timeString != null && timeString!.trim().isNotEmpty) {
      return timeString!.trim();
    }
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  ChatMessage copyWith({
    String? id,
    int? numericId,
    String? shipmentId,
    String? senderId,
    String? receiverId,
    String? senderName,
    MessageSenderRole? senderRole,
    String? message,
    String? messageType,
    DateTime? timestamp,
    String? timeString,
    String? dateString,
    bool? isRead,
    String? attachmentUrl,
    String? attachmentName,
    MessageAttachmentType? attachmentType,
    List<ChatAttachmentItem>? attachments,
    bool? isFromDriver,
    bool? isUnsent,
    bool? isEdited,
    bool? isPinned,
    int? replyToId,
    String? replyToMessage,
    bool? replyToIsMe,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      numericId: numericId ?? this.numericId,
      shipmentId: shipmentId ?? this.shipmentId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      timeString: timeString ?? this.timeString,
      dateString: dateString ?? this.dateString,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentType: attachmentType ?? this.attachmentType,
      attachments: attachments ?? this.attachments,
      isFromDriver: isFromDriver ?? this.isFromDriver,
      isUnsent: isUnsent ?? this.isUnsent,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToIsMe: replyToIsMe ?? this.replyToIsMe,
    );
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String partnerName = 'Partner',
    String shipmentId = '',
    MessageSenderRole partnerRole = MessageSenderRole.customerReceiver,
  }) {
    final int? numId = int.tryParse((json['id'] ?? '').toString());
    final String msgId = (json['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    final bool isMe = json['is_me'] == true || json['is_me'] == 1;
    final bool isUnsent = json['is_unsent'] == true || json['is_unsent'] == 1;
    final bool isEdited = json['is_edited'] == true || json['is_edited'] == 1;
    final bool isPinned = json['is_pinned'] == true || json['is_pinned'] == 1;
    final bool isRead = json['is_read'] == true || json['is_read'] == 1;

    final List<ChatAttachmentItem> parsedAttachments = [];
    if (json['attachments'] is List) {
      for (final rawAtt in (json['attachments'] as List)) {
        if (rawAtt != null) {
          parsedAttachments.add(ChatAttachmentItem.fromDynamic(rawAtt));
        }
      }
    }

    final String msgType = (json['message_type'] ?? 'text').toString().toLowerCase();
    MessageAttachmentType attType = MessageAttachmentType.none;
    String? firstAttUrl;
    String? firstAttName;

    if (parsedAttachments.isNotEmpty) {
      final first = parsedAttachments.first;
      firstAttUrl = first.url;
      firstAttName = first.name;
      attType = first.isImage
          ? MessageAttachmentType.image
          : MessageAttachmentType.document;
    } else if (msgType == 'image') {
      attType = MessageAttachmentType.image;
    } else if (msgType == 'file') {
      attType = MessageAttachmentType.document;
    }

    String rawMessage = (json['message'] ?? '').toString();
    if (isUnsent) {
      rawMessage = isMe ? 'You unsent a message' : 'Message was unsent';
    }

    int? replyToId = int.tryParse((json['reply_to_id'] ?? '').toString());
    String? replyToMessage;
    bool replyToIsMe = false;
    if (json['reply_to'] is Map) {
      final replyMap = json['reply_to'] as Map;
      replyToId ??= int.tryParse((replyMap['id'] ?? '').toString());
      replyToMessage = (replyMap['message'] ?? '').toString();
      if (replyToMessage.isEmpty) {
        final rType = (replyMap['message_type'] ?? '').toString();
        replyToMessage = rType == 'image' ? '📷 Photo' : '📎 Attachment';
      }
      replyToIsMe = replyMap['is_me'] == true || replyMap['is_me'] == 1;
    }

    DateTime parsedTime = DateTime.now();
    if (json['created_at'] != null) {
      parsedTime = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return ChatMessage(
      id: msgId,
      numericId: numId,
      shipmentId: shipmentId,
      senderId: (json['sender_id'] ?? '').toString(),
      receiverId: (json['receiver_id'] ?? '').toString(),
      senderName: isMe ? 'You (Driver)' : partnerName,
      senderRole: isMe ? MessageSenderRole.driver : partnerRole,
      message: rawMessage,
      messageType: msgType,
      timestamp: parsedTime,
      timeString: json['time']?.toString(),
      dateString: json['date']?.toString(),
      isRead: isRead,
      attachmentUrl: firstAttUrl,
      attachmentName: firstAttName,
      attachmentType: attType,
      attachments: parsedAttachments,
      isFromDriver: isMe,
      isUnsent: isUnsent,
      isEdited: isEdited,
      isPinned: isPinned,
      replyToId: replyToId,
      replyToMessage: replyToMessage,
      replyToIsMe: replyToIsMe,
    );
  }
}
