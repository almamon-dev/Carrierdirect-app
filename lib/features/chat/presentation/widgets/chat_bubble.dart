import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDriver = message.isFromDriver;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: Row(
        mainAxisAlignment: isDriver ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isDriver ? AppColors.primary : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isDriver ? 18 : 4),
                  bottomRight: Radius.circular(isDriver ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: isDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Attachment preview if present
                  if (message.attachmentType == MessageAttachmentType.image && message.attachmentUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        color: Colors.black12,
                        child: message.attachmentUrl!.startsWith('assets/')
                            ? Image.asset(
                                message.attachmentUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.image_outlined, size: 30, color: Colors.grey),
                                ),
                              )
                            : Image.file(
                                File(message.attachmentUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Image.asset(
                                  'assets/images/driver_avatar.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.image_outlined, size: 30, color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: isDriver ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isDriver ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        message.formattedTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDriver ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isDriver) ...[
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
