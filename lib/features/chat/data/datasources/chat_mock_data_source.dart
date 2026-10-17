import '../models/chat_channel_model.dart';
import '../models/chat_message_model.dart';

class ChatMockDataSource {
  static final Map<String, List<ChatChannel>> _shipmentChannels = {};

  static List<ChatChannel> getChannelsForShipment({
    required String shipmentId,
    required String originTitle,
    required String destTitle,
  }) {
    if (_shipmentChannels.containsKey(shipmentId)) {
      return _shipmentChannels[shipmentId]!;
    }

    final now = DateTime.now();

    if (shipmentId.contains('CD-0004')) {
      final cdChannels = [
        ChatChannel(
          id: '${shipmentId}_customer_co1',
          shipmentId: shipmentId,
          type: ChatChannelType.customerConsignee,
          title: 'Customer (Shipper)',
          participantName: 'Customer Co 1',
          participantRoleTitle: 'Customer (Shipper) • Verified Partner',
          participantPhone: '+1 (555) 345-6789',
          avatarUrl: 'assets/images/customer_avatar.png',
          isOnline: true,
          lastActive: 'Active now',
          isVerified: true,
          orderNumber: '#CD-0004',
          messages: [
            ChatMessage(
              id: 'm1_cd4',
              shipmentId: shipmentId,
              senderId: 'customer_co1',
              senderName: 'Customer Co 1',
              senderRole: MessageSenderRole.customerReceiver,
              message: 'Hello Captain! Order #CD-0004 is cleared for carrier pickup. Please check in with dock coordinator upon arrival.',
              timestamp: now.subtract(const Duration(minutes: 15)),
              isFromDriver: false,
            ),
          ],
        ),
      ];
      _shipmentChannels[shipmentId] = cdChannels;
      return cdChannels;
    }

    final defaultChannels = [
      // 1. Supplier / Shipper Warehouse Desk
      ChatChannel(
        id: '${shipmentId}_supplier',
        shipmentId: shipmentId,
        type: ChatChannelType.supplierWarehouse,
        title: 'Supplier Warehouse Dock',
        participantName: 'David Miller',
        participantRoleTitle: 'Dock Dispatcher • $originTitle',
        participantPhone: '+1 (555) 234-8901',
        avatarUrl: 'assets/images/supplier_avatar.png',
        isOnline: true,
        messages: [
          ChatMessage(
            id: 'm1_sup',
            shipmentId: shipmentId,
            senderId: 'david_sup',
            senderName: 'David Miller',
            senderRole: MessageSenderRole.supplierEmployee,
            message: 'Hello Captain! Load #$shipmentId is staged at Bay 4. Security seal #SEAL-88902 is verified and ready for pickup.',
            timestamp: now.subtract(const Duration(minutes: 45)),
            isFromDriver: false,
          ),
          ChatMessage(
            id: 'm2_sup',
            shipmentId: shipmentId,
            senderId: 'driver_me',
            senderName: 'Mike Icorse (Driver)',
            senderRole: MessageSenderRole.driver,
            message: 'Got it David! Pre-trip trailer inspection is complete. Backing into Bay 4 now.',
            timestamp: now.subtract(const Duration(minutes: 40)),
            isFromDriver: true,
          ),
          ChatMessage(
            id: 'm3_sup',
            shipmentId: shipmentId,
            senderId: 'david_sup',
            senderName: 'David Miller',
            senderRole: MessageSenderRole.supplierEmployee,
            message: 'Dock loading complete. BOL paperwork has been signed and handed to you. Drive safe!',
            timestamp: now.subtract(const Duration(minutes: 30)),
            isFromDriver: false,
          ),
        ],
      ),

      // 2. Customer / Consignee Receiving Team
      ChatChannel(
        id: '${shipmentId}_customer',
        shipmentId: shipmentId,
        type: ChatChannelType.customerConsignee,
        title: 'Customer Receiving Desk',
        participantName: 'Sarah Jenkins',
        participantRoleTitle: 'Receiving Lead • $destTitle',
        participantPhone: '+1 (555) 876-5432',
        avatarUrl: 'assets/images/customer_avatar.png',
        isOnline: false,
        lastActive: 'Active 10m ago',
        messages: [
          ChatMessage(
            id: 'm1_cust',
            shipmentId: shipmentId,
            senderId: 'sarah_cust',
            senderName: 'Sarah Jenkins',
            senderRole: MessageSenderRole.customerReceiver,
            message: 'Hi Driver! We are expecting shipment #$shipmentId. Please enter through North Gate 2 on 5th Avenue.',
            timestamp: now.subtract(const Duration(minutes: 25)),
            isFromDriver: false,
          ),
          ChatMessage(
            id: 'm2_cust',
            shipmentId: shipmentId,
            senderId: 'driver_me',
            senderName: 'Mike Icorse (Driver)',
            senderRole: MessageSenderRole.driver,
            message: 'Thank you Sarah! Estimated arrival is in ~25 mins. I will check in at North Gate 2.',
            timestamp: now.subtract(const Duration(minutes: 18)),
            isFromDriver: true,
          ),
          ChatMessage(
            id: 'm3_cust',
            shipmentId: shipmentId,
            senderId: 'sarah_cust',
            senderName: 'Sarah Jenkins',
            senderRole: MessageSenderRole.customerReceiver,
            message: 'Great! Dock door 12 is reserved for your trailer. Our forklift team is on standby.',
            timestamp: now.subtract(const Duration(minutes: 10)),
            isFromDriver: false,
          ),
        ],
      ),
    ];

    _shipmentChannels[shipmentId] = defaultChannels;
    return defaultChannels;
  }

  static void addMessageToChannel({
    required String shipmentId,
    required String channelId,
    required ChatMessage message,
  }) {
    final channels = _shipmentChannels[shipmentId];
    if (channels != null) {
      final index = channels.indexWhere((c) => c.id == channelId);
      if (index != -1) {
        final updatedList = List<ChatMessage>.from(channels[index].messages)..add(message);
        channels[index] = ChatChannel(
          id: channels[index].id,
          shipmentId: channels[index].shipmentId,
          type: channels[index].type,
          title: channels[index].title,
          participantName: channels[index].participantName,
          participantRoleTitle: channels[index].participantRoleTitle,
          participantPhone: channels[index].participantPhone,
          avatarUrl: channels[index].avatarUrl,
          isOnline: channels[index].isOnline,
          messages: updatedList,
        );
      }
    }
  }

  static String getSimulatedReply(ChatChannelType type, String driverText) {
    final text = driverText.toLowerCase();
    if (type == ChatChannelType.supplierWarehouse) {
      if (text.contains('gate') || text.contains('arrived')) {
        return 'Noted! Security gate #4 has been alerted to open for your rig.';
      } else if (text.contains('traffic') || text.contains('delay')) {
        return 'Understood, we updated the staging bay schedule accordingly.';
      } else if (text.contains('dock') || text.contains('door')) {
        return 'Dock door Bay 4 is open and clear for backing in.';
      }
      return 'Received! Supplier warehouse team is updated. Let us know if you need anything else.';
    } else {
      if (text.contains('gate') || text.contains('arrived')) {
        return 'Welcome! Guard at North Gate 2 will give you the dock badge.';
      } else if (text.contains('traffic') || text.contains('delay')) {
        return 'Thanks for letting us know! Receiving team is ready whenever you arrive.';
      } else if (text.contains('dock') || text.contains('door')) {
        return 'Door 12 is assigned. Please have the receiver sign the digital POD.';
      }
      return 'Message received by Receiving Lead. We are ready for your arrival!';
    }
  }
}
