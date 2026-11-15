import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/chat_message_model.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final void Function(String imageUrl, String title)? onTapImage;

  const ChatBubble({
    super.key,
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.onLongPress,
    this.onSwipeReply,
    this.onTapImage,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  double _dragOffset = 0.0;
  bool _replyTriggered = false;

  bool _isNetworkUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Widget _buildImageWidget(String url) {
    if (_isNetworkUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 30,
            color: Colors.grey,
          ),
        ),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.image_outlined, size: 30, color: Colors.grey),
        ),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.image_outlined, size: 30, color: Colors.grey),
      ),
    );
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onSwipeReply == null || widget.message.isUnsent) return;
    final delta = details.primaryDelta ?? 0.0;
    if (delta > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + delta * 0.65).clamp(0.0, 68.0);
      });
      if (_dragOffset >= 48.0 && !_replyTriggered) {
        _replyTriggered = true;
        HapticFeedback.lightImpact();
      } else if (_dragOffset < 48.0) {
        _replyTriggered = false;
      }
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_replyTriggered && widget.onSwipeReply != null) {
      widget.onSwipeReply!();
    }
    setState(() {
      _dragOffset = 0.0;
      _replyTriggered = false;
    });
  }

  Widget _buildTimeAndTicks({
    required bool isDriver,
    bool isOverImage = false,
  }) {
    final textColor = isOverImage
        ? Colors.white
        : (isDriver
              ? Colors.white.withValues(alpha: 0.82)
              : const Color(0xFF667781));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.isPinned) ...[
          Icon(Icons.push_pin_rounded, size: 11, color: textColor),
          const SizedBox(width: 3),
        ],
        if (widget.message.isEdited) ...[
          Text(
            'Edited ',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: textColor,
            ),
          ),
        ],
        Text(
          widget.message.formattedTime,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
        if (isDriver) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.done_all_rounded,
            size: 14.5,
            color: widget.message.isRead
                ? (isOverImage
                      ? const Color(0xFF53BDEB)
                      : const Color(0xFFBAE6FD))
                : textColor,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isDriver = msg.isFromDriver;

    // Unsent message (WhatsApp "You deleted this message" / "This message was deleted" style)
    if (msg.isUnsent) {
      return Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          top: widget.isFirstInGroup ? 5 : 1.5,
          bottom: widget.isLastInGroup ? 5 : 1.5,
        ),
        child: Row(
          mainAxisAlignment: isDriver
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDriver
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.block_flipped,
                    size: 14,
                    color: Color(0xFF8696A0),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDriver
                        ? 'You deleted this message'
                        : 'This message was deleted',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF667781),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.formattedTime,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8696A0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Collect image & document attachments
    final List<ChatAttachmentItem> imageAtts = msg.attachments
        .where((a) => a.isImage && a.url.isNotEmpty)
        .toList();
    if (imageAtts.isEmpty &&
        msg.attachmentType == MessageAttachmentType.image &&
        msg.attachmentUrl != null &&
        msg.attachmentUrl!.isNotEmpty) {
      imageAtts.add(
        ChatAttachmentItem(
          name: msg.attachmentName ?? 'Photo',
          url: msg.attachmentUrl!,
          type: 'image',
        ),
      );
    }

    final List<ChatAttachmentItem> docAtts = msg.attachments
        .where((a) => !a.isImage)
        .toList();
    if (docAtts.isEmpty &&
        msg.attachmentType == MessageAttachmentType.document &&
        (msg.attachmentName != null || msg.attachmentUrl != null)) {
      docAtts.add(
        ChatAttachmentItem(
          name: msg.attachmentName ?? 'Document',
          url: msg.attachmentUrl ?? '',
          type: 'file',
        ),
      );
    }

    final hasReply =
        msg.replyToMessage != null && msg.replyToMessage!.isNotEmpty;
    final hasText = msg.message.trim().isNotEmpty;
    final isImageOnly = imageAtts.isNotEmpty && !hasText && docAtts.isEmpty;

    // Reserve trailing space inside text so WhatsApp inline timestamp never overlaps text
    final trailingSpace = isDriver
        ? (msg.isEdited
              ? '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0'
              : '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0')
        : (msg.isEdited
              ? '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0'
              : '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0');

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // WhatsApp Swipe-to-Reply icon indicator
          if (_dragOffset > 6)
            Positioned(
              left: (_dragOffset - 36).clamp(8.0, 26.0),
              child: AnimatedScale(
                scale: (_dragOffset / 48.0).clamp(0.5, 1.0),
                duration: const Duration(milliseconds: 80),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reply_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Padding(
              padding: EdgeInsets.only(
                left: isDriver ? 54.0 : 12.0,
                right: isDriver ? 12.0 : 54.0,
                top: widget.isFirstInGroup ? 5.0 : 1.5,
                bottom: widget.isLastInGroup ? 3.0 : 1.5,
              ),
              child: Row(
                mainAxisAlignment: isDriver
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left tail for first received message in group
                  if (!isDriver && widget.isFirstInGroup)
                    CustomPaint(
                      size: const Size(8, 12),
                      painter: _WhatsAppTailPainter(
                        color: Colors.white,
                        isSent: false,
                      ),
                    )
                  else if (!isDriver)
                    const SizedBox(width: 8),

                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.77,
                        minWidth: 78,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        isImageOnly ? 4 : 10,
                        isImageOnly ? 4 : 6,
                        isImageOnly ? 4 : 10,
                        isImageOnly ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDriver ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            !isDriver && widget.isFirstInGroup ? 0 : 10,
                          ),
                          topRight: Radius.circular(
                            isDriver && widget.isFirstInGroup ? 0 : 10,
                          ),
                          bottomLeft: const Radius.circular(10),
                          bottomRight: const Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quoted Reply Preview (WhatsApp style)
                          if (hasReply)
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(
                                bottom: 5,
                                left: isImageOnly ? 4 : 0,
                                right: isImageOnly ? 4 : 0,
                                top: isImageOnly ? 2 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? Colors.black.withValues(alpha: 0.15)
                                    : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border(
                                  left: BorderSide(
                                    color: isDriver
                                        ? Colors.white
                                        : AppColors.primary,
                                    width: 3.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.replyToIsMe ? 'You' : msg.senderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDriver
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    msg.replyToMessage!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDriver
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF54656F),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Image Attachments
                          for (int i = 0; i < imageAtts.length; i++) ...[
                            GestureDetector(
                              onTap: widget.onTapImage != null
                                  ? () => widget.onTapImage!(
                                      imageAtts[i].url,
                                      imageAtts[i].name,
                                    )
                                  : null,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 175,
                                      width: double.infinity,
                                      color: Colors.black12,
                                      child: _buildImageWidget(
                                        imageAtts[i].url,
                                      ),
                                    ),
                                    if (isImageOnly &&
                                        i == imageAtts.length - 1)
                                      Positioned(
                                        bottom: 6,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: _buildTimeAndTicks(
                                            isDriver: isDriver,
                                            isOverImage: true,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isImageOnly || i < imageAtts.length - 1)
                              const SizedBox(height: 5),
                          ],

                          // Document Attachments (WhatsApp PDF/File card style)
                          for (final doc in docAtts) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? Colors.black.withValues(alpha: 0.14)
                                    : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDriver
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : AppColors.primary.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.insert_drive_file_rounded,
                                        size: 20,
                                        color: isDriver
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDriver
                                                ? Colors.white
                                                : const Color(0xFF111B21),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          doc.size != null &&
                                                  doc.size!.isNotEmpty
                                              ? '${doc.size!} • Document'
                                              : 'Document',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDriver
                                                ? Colors.white.withValues(
                                                    alpha: 0.8,
                                                  )
                                                : const Color(0xFF667781),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Text + Inline Bottom-Right Timestamp & Checkmarks (WhatsApp Layout)
                          if (hasText)
                            Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '${msg.message}$trailingSpace',
                                    style: TextStyle(
                                      fontSize: 14.2,
                                      height: 1.32,
                                      color: isDriver
                                          ? Colors.white
                                          : const Color(0xFF111B21),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: _buildTimeAndTicks(isDriver: isDriver),
                                ),
                              ],
                            )
                          else if (!isImageOnly)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: _buildTimeAndTicks(isDriver: isDriver),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right tail for first sent message in group
                  if (isDriver && widget.isFirstInGroup)
                    CustomPaint(
                      size: const Size(8, 12),
                      painter: _WhatsAppTailPainter(
                        color: AppColors.primary,
                        isSent: true,
                      ),
                    )
                  else if (isDriver)
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppTailPainter extends CustomPainter {
  final Color color;
  final bool isSent;

  const _WhatsAppTailPainter({required this.color, required this.isSent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isSent) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.2, size.height * 0.5, 0, size.height);
      path.close();
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.5,
        size.width,
        size.height,
      );
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSent != isSent;
  }
}
