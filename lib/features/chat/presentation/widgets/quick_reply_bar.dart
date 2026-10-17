import 'package:flutter/material.dart';
import '../../data/models/chat_channel_model.dart';

class QuickReplyBar extends StatelessWidget {
  final ChatChannelType channelType;
  final Function(String) onQuickReplySelected;

  const QuickReplyBar({
    super.key,
    required this.channelType,
    required this.onQuickReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> chips = channelType == ChatChannelType.supplierWarehouse
        ? const [
            'Arrived at Security Gate 📍',
            'Dock door assigned? 🚪',
            'Pre-trip inspection done ✓',
            'Stuck at weigh scale ⏳',
            'Loading complete! Thank you 🚛',
          ]
        : const [
            'Approaching receiving dock (~15m) 📍',
            'Arrived at North Gate 2 🚛',
            'Dock door ready? 🚪',
            'Unloading started 📦',
            'POD ready for digital signature ✍️',
          ];

    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final chipText = chips[index];
          return InkWell(
            onTap: () => onQuickReplySelected(chipText),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  chipText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
