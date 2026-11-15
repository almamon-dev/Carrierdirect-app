import 'chat_message_model.dart';

enum ChatChannelType { supplierWarehouse, customerConsignee, centralDispatch }

class ChatChannel {
  final String id;
  final int? partnerId;
  final String shipmentId;
  final ChatChannelType type;
  final String title;
  final String participantName;
  final String companyName;
  final String participantRoleTitle;
  final String participantPhone;
  final String participantEmail;
  final String avatarUrl;
  final bool isOnline;
  final String lastActive;
  final bool isVerified;
  final String orderNumber;
  final List<String> orderNumbers;
  final String originTitle;
  final String destTitle;
  final int unreadCount;
  final List<ChatMessage> messages;

  const ChatChannel({
    required this.id,
    this.partnerId,
    required this.shipmentId,
    required this.type,
    required this.title,
    required this.participantName,
    this.companyName = '',
    required this.participantRoleTitle,
    required this.participantPhone,
    this.participantEmail = '',
    required this.avatarUrl,
    this.isOnline = true,
    this.lastActive = 'Active now',
    this.isVerified = true,
    this.orderNumber = '',
    this.orderNumbers = const [],
    this.originTitle = '',
    this.destTitle = '',
    this.unreadCount = 0,
    this.messages = const [],
  });

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  ChatChannel copyWith({
    String? id,
    int? partnerId,
    String? shipmentId,
    ChatChannelType? type,
    String? title,
    String? participantName,
    String? companyName,
    String? participantRoleTitle,
    String? participantPhone,
    String? participantEmail,
    String? avatarUrl,
    bool? isOnline,
    String? lastActive,
    bool? isVerified,
    String? orderNumber,
    List<String>? orderNumbers,
    String? originTitle,
    String? destTitle,
    int? unreadCount,
    List<ChatMessage>? messages,
  }) {
    return ChatChannel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      shipmentId: shipmentId ?? this.shipmentId,
      type: type ?? this.type,
      title: title ?? this.title,
      participantName: participantName ?? this.participantName,
      companyName: companyName ?? this.companyName,
      participantRoleTitle: participantRoleTitle ?? this.participantRoleTitle,
      participantPhone: participantPhone ?? this.participantPhone,
      participantEmail: participantEmail ?? this.participantEmail,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      orderNumber: orderNumber ?? this.orderNumber,
      orderNumbers: orderNumbers ?? this.orderNumbers,
      originTitle: originTitle ?? this.originTitle,
      destTitle: destTitle ?? this.destTitle,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  factory ChatChannel.fromConversationJson(Map<String, dynamic> json) {
    final userMap = (json['user'] is Map)
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;
    final int? uid = int.tryParse((userMap['id'] ?? json['partner_id'] ?? '').toString());
    final String name = (userMap['company_name'] != null &&
            userMap['company_name'].toString().trim().isNotEmpty)
        ? userMap['company_name'].toString().trim()
        : ((userMap['display_name'] ?? userMap['name'] ?? 'Partner').toString().trim());
    final String compName = (userMap['company_name'] ?? name).toString();
    final String userType = (userMap['user_type'] ?? '').toString().toLowerCase();
    final String roleStr = (userMap['role'] ?? '').toString();

    final ChatChannelType channelType = (userType.contains('supplier') ||
            userType.contains('carrier') ||
            roleStr.toLowerCase().contains('supplier'))
        ? ChatChannelType.supplierWarehouse
        : ChatChannelType.customerConsignee;

    final String roleTitle = roleStr.isNotEmpty
        ? roleStr
        : (channelType == ChatChannelType.supplierWarehouse
            ? 'Supplier (Carrier)'
            : 'Customer (Shipper)');

    final List<String> orderNums = [];
    if (json['order_numbers'] is List) {
      for (final o in (json['order_numbers'] as List)) {
        if (o != null && o.toString().isNotEmpty) {
          orderNums.add(o.toString());
        }
      }
    } else if (userMap['order_numbers'] is List) {
      for (final o in (userMap['order_numbers'] as List)) {
        if (o != null && o.toString().isNotEmpty) {
          orderNums.add(o.toString());
        }
      }
    }

    String latestOrdNum = orderNums.isNotEmpty ? orderNums.first : '';
    String origTitle = '';
    String dstTitle = '';

    if (json['latest_order'] is Map) {
      final lo = json['latest_order'] as Map;
      if (latestOrdNum.isEmpty && lo['order_number'] != null) {
        latestOrdNum = lo['order_number'].toString();
      }
      origTitle = (lo['pickup_address'] ?? '').toString();
      dstTitle = (lo['delivery_address'] ?? '').toString();
    } else if (userMap['orders'] is List && (userMap['orders'] as List).isNotEmpty) {
      final firstOrd = (userMap['orders'] as List).first;
      if (firstOrd is Map) {
        if (latestOrdNum.isEmpty && firstOrd['order_number'] != null) {
          latestOrdNum = firstOrd['order_number'].toString();
        }
        origTitle = (firstOrd['pickup_address'] ?? '').toString();
        dstTitle = (firstOrd['delivery_address'] ?? '').toString();
      }
    }

    final bool isOnline = userMap['is_online'] == true || userMap['is_online'] == 1;
    final String lastSeen = (userMap['last_seen_human'] ??
            (isOnline ? 'Active now' : 'Offline'))
        .toString();
    final bool isVerified = userMap['is_verified'] == null
        ? true
        : (userMap['is_verified'] == true || userMap['is_verified'] == 1);
    final String avatar = (userMap['avatar'] ?? '').toString();
    final int unread = int.tryParse((json['unread_count'] ?? '0').toString()) ?? 0;

    return ChatChannel(
      id: 'partner_${uid ?? DateTime.now().millisecondsSinceEpoch}',
      partnerId: uid,
      shipmentId: latestOrdNum,
      type: channelType,
      title: roleTitle,
      participantName: name,
      companyName: compName,
      participantRoleTitle: roleTitle,
      participantPhone: (userMap['phone'] ?? '').toString(),
      participantEmail: (userMap['email'] ?? '').toString(),
      avatarUrl: avatar.isNotEmpty ? avatar : 'assets/images/customer_avatar.png',
      isOnline: isOnline,
      lastActive: lastSeen,
      isVerified: isVerified,
      orderNumber: latestOrdNum,
      orderNumbers: orderNums,
      originTitle: origTitle,
      destTitle: dstTitle,
      unreadCount: unread,
      messages: const [],
    );
  }
}
