import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/datasources/chat_mock_data_source.dart';
import '../../data/models/chat_channel_model.dart';
import '../screens/chat_screen.dart';

class ChatChannelsModal {
  static void show(
    BuildContext context, {
    required dynamic shipment,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ChatChannelsSheet(shipment: shipment),
    );
  }
}

class _ChatChannelsSheet extends StatelessWidget {
  final dynamic shipment;

  const _ChatChannelsSheet({required this.shipment});

  @override
  Widget build(BuildContext context) {
    String sId = 'SHP987654';
    String oTitle = 'ABC Warehouse';
    String dTitle = 'Customer Store #4';

    try {
      sId = shipment.id as String;
      oTitle = (shipment.originTitle ?? shipment.origin) as String;
      dTitle = (shipment.destTitle ?? shipment.destination) as String;
    } catch (_) {}

    final channels = ChatMockDataSource.getChannelsForShipment(
      shipmentId: sId,
      originTitle: oTitle,
      destTitle: dTitle,
    );

    const primaryColor = AppColors.primary;
    const cardBorder = AppColors.border;
    const textSub = AppColors.textSecondary;
    const textMain = AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.forum_outlined, color: primaryColor, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Direct Shipment Chat',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$sId',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSub),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a logistics party to start or continue real-time messaging:',
              style: TextStyle(fontSize: 12, color: textSub),
            ),
            const SizedBox(height: 16),

            // Channels List
            ...List.generate(channels.length, (index) {
              final channel = channels[index];
              final isSup = channel.type == ChatChannelType.supplierWarehouse;
              final lastMsg = channel.lastMessage?.message ?? 'Start conversation...';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSup
                          ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                          : const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSup ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isSup ? Icons.warehouse_rounded : Icons.storefront_rounded,
                        size: 22,
                        color: isSup ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        channel.participantName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isSup ? const Color(0xFFEA580C) : const Color(0xFF0284C7)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isSup ? 'Supplier' : 'Customer',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isSup ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      lastMsg,
                      style: const TextStyle(fontSize: 11.5, color: textSub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
                  onTap: () {
                    Navigator.pop(context);
                    ChatScreen.openForShipment(
                      context,
                      shipment: shipment,
                      initialChannelType: channel.type,
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
