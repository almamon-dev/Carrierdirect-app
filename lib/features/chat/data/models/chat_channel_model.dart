import 'chat_message_model.dart';

enum ChatChannelType { supplierWarehouse, customerConsignee, centralDispatch }

class ChatChannel {
  final String id;
  final String shipmentId;
  final ChatChannelType type;
  final String title;
  final String participantName;
  final String participantRoleTitle;
  final String participantPhone;
  final String avatarUrl;
  final bool isOnline;
  final String lastActive;
  final bool isVerified;
  final String orderNumber;
  final List<ChatMessage> messages;

  const ChatChannel({
    required this.id,
    required this.shipmentId,
    required this.type,
    required this.title,
    required this.participantName,
    required this.participantRoleTitle,
    required this.participantPhone,
    required this.avatarUrl,
    this.isOnline = true,
    this.lastActive = 'Active now',
    this.isVerified = true,
    this.orderNumber = '',
    this.messages = const [],
  });

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
}
