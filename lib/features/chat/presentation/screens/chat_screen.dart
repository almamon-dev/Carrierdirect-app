import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../trips/presentation/screens/report_issue_screen.dart';
import '../../../trips/presentation/screens/trips_screen.dart';
import '../../data/datasources/chat_mock_data_source.dart';
import '../../data/models/chat_channel_model.dart';
import '../../data/models/chat_message_model.dart';
import '../widgets/chat_bubble.dart';
import 'chat_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String shipmentId;
  final String originTitle;
  final String destTitle;
  final ChatChannelType initialChannelType;
  final bool showBackButton;

  const ChatScreen({
    super.key,
    required this.shipmentId,
    required this.originTitle,
    required this.destTitle,
    this.initialChannelType = ChatChannelType.supplierWarehouse,
    this.showBackButton = true,
  });

  static void openForShipment(
    BuildContext context, {
    required dynamic shipment,
    ChatChannelType initialChannelType = ChatChannelType.supplierWarehouse,
  }) {
    String sId = 'SHP-987654';
    String oTitle = 'Supplier Warehouse';
    String dTitle = 'Customer Store #4';

    if (shipment is ShipmentItem) {
      sId = shipment.id;
      oTitle = shipment.originTitle;
      dTitle = shipment.destTitle;
    } else if (shipment is TripModel) {
      sId = shipment.id;
      oTitle = shipment.pickupLocation;
      dTitle = shipment.dropoffLocation;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          shipmentId: sId,
          originTitle: oTitle,
          destTitle: dTitle,
          initialChannelType: initialChannelType,
        ),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<ChatChannel> _channels;
  late int _selectedChannelIndex;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isMuted = false;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Colors.white;
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;
  static const Color inputBg = Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    _channels = ChatMockDataSource.getChannelsForShipment(
      shipmentId: widget.shipmentId,
      originTitle: widget.originTitle,
      destTitle: widget.destTitle,
    );

    _selectedChannelIndex = _channels.indexWhere((c) => c.type == widget.initialChannelType);
    if (_selectedChannelIndex == -1) _selectedChannelIndex = 0;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ChatChannel get _currentChannel => _channels[_selectedChannelIndex];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(
    String text, {
    MessageAttachmentType attachmentType = MessageAttachmentType.none,
    String? attachmentUrl,
    String? attachmentName,
  }) {
    if (text.trim().isEmpty && attachmentUrl == null) return;

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      shipmentId: widget.shipmentId,
      senderId: 'driver_me',
      senderName: 'Mike Icorse (Driver)',
      senderRole: MessageSenderRole.driver,
      message: text.trim(),
      timestamp: DateTime.now(),
      isFromDriver: true,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
    );

    setState(() {
      ChatMockDataSource.addMessageToChannel(
        shipmentId: widget.shipmentId,
        channelId: _currentChannel.id,
        message: newMsg,
      );
      _channels = ChatMockDataSource.getChannelsForShipment(
        shipmentId: widget.shipmentId,
        originTitle: widget.originTitle,
        destTitle: widget.destTitle,
      );
    });

    _textController.clear();
    _scrollToBottom();

    // Trigger simulated participant response after 1.4s
    final activeChannelType = _currentChannel.type;
    final activeChannelId = _currentChannel.id;
    final participantName = _currentChannel.participantName;

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final replyText = ChatMockDataSource.getSimulatedReply(activeChannelType, text);
      final replyMsg = ChatMessage(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        shipmentId: widget.shipmentId,
        senderId: 'participant',
        senderName: participantName,
        senderRole: activeChannelType == ChatChannelType.supplierWarehouse
            ? MessageSenderRole.supplierEmployee
            : MessageSenderRole.customerReceiver,
        message: replyText,
        timestamp: DateTime.now(),
        isFromDriver: false,
      );

      setState(() {
        ChatMockDataSource.addMessageToChannel(
          shipmentId: widget.shipmentId,
          channelId: activeChannelId,
          message: replyMsg,
        );
        _channels = ChatMockDataSource.getChannelsForShipment(
          shipmentId: widget.shipmentId,
          originTitle: widget.originTitle,
          destTitle: widget.destTitle,
        );
      });
      _scrollToBottom();
    });
  }

  void _handleAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share Document or Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMain),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Option 1: Camera (Real Device Camera)
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: primaryColor,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (photo != null) {
                          _sendMessage(
                            'Captured Photo: ${photo.name} 📸',
                            attachmentType: MessageAttachmentType.image,
                            attachmentUrl: photo.path,
                            attachmentName: photo.name,
                          );
                          if (mounted) AppToast.success(context, 'Photo captured and sent');
                        }
                      } catch (e) {
                        _sendMessage(
                          'Attached Loading Dock Photo 📸',
                          attachmentType: MessageAttachmentType.image,
                          attachmentUrl: 'assets/images/driver_avatar.png',
                          attachmentName: 'Dock_Photo.jpg',
                        );
                        if (mounted) AppToast.success(context, 'Dock photo attached');
                      }
                    },
                  ),

                  // Option 2: File Upload (Real Device File / PDF Picker)
                  _buildAttachmentOption(
                    icon: Icons.upload_file_rounded,
                    label: 'File Upload',
                    color: const Color(0xFF0284C7),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'txt', 'png', 'jpg', 'jpeg'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          final isImg = ['png', 'jpg', 'jpeg'].contains(file.extension?.toLowerCase());
                          final sizeStr = file.size > 0 ? ' (${(file.size / 1024).toStringAsFixed(1)} KB)' : '';
                          _sendMessage(
                            'Attached File: ${file.name}$sizeStr 📁',
                            attachmentType: isImg ? MessageAttachmentType.image : MessageAttachmentType.document,
                            attachmentUrl: file.path,
                            attachmentName: file.name,
                          );
                          if (mounted) AppToast.success(context, 'File ${file.name} sent');
                        }
                      } catch (e) {
                        _sendMessage(
                          'Attached Document: Freight_Invoice_88902.pdf (142 KB) 📄',
                          attachmentType: MessageAttachmentType.document,
                          attachmentName: 'Freight_Invoice_88902.pdf',
                        );
                        if (mounted) AppToast.success(context, 'Document file attached');
                      }
                    },
                  ),

                  // Option 3: Others (Real Gallery Photo Picker)
                  _buildAttachmentOption(
                    icon: Icons.grid_view_rounded,
                    label: 'Others',
                    color: const Color(0xFF8B5CF6),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (photo != null) {
                          _sendMessage(
                            'Selected Photo: ${photo.name} 🖼️',
                            attachmentType: MessageAttachmentType.image,
                            attachmentUrl: photo.path,
                            attachmentName: photo.name,
                          );
                          if (mounted) AppToast.success(context, 'Photo from gallery sent');
                        }
                      } catch (e) {
                        _sendMessage(
                          'Attached Cargo Scale & Gate Slip 📎',
                          attachmentType: MessageAttachmentType.document,
                          attachmentName: 'Scale_Ticket_88902.pdf',
                        );
                        if (mounted) AppToast.success(context, 'Attachment added to conversation');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailsScreen(
          channel: _currentChannel,
          shipmentId: widget.shipmentId,
          originTitle: widget.originTitle,
          destTitle: widget.destTitle,
          onClearChat: () {
            setState(() {
              _currentChannel.messages.clear();
            });
          },
        ),
      ),
    );
  }



  void _showFooterOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Modal Header with Title & Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.tune_rounded, color: primaryColor, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chat Options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                            ),
                          ),
                          Text(
                            _currentChannel.participantName,
                            style: const TextStyle(fontSize: 11.5, color: textSub),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(modalCtx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: textSub),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: cardBorder, height: 1),
              const SizedBox(height: 8),

              // Option 1: View User & Contact Details
              _buildModalOptionItem(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Contact & User Details',
                subtitle: 'View company, facility info & order reference',
                onTap: () {
                  Navigator.pop(modalCtx);
                  _openChatDetails();
                },
              ),

              // Option 2: Mute Notifications
              _buildModalOptionItem(
                icon: _isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                iconColor: const Color(0xFFD97706),
                title: _isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                subtitle: _isMuted ? 'Turn alert sounds and banners back on' : 'Silence alerts for incoming messages',
                onTap: () {
                  Navigator.pop(modalCtx);
                  setState(() => _isMuted = !_isMuted);
                  AppToast.info(
                    context,
                    _isMuted
                        ? 'Notifications muted for ${_currentChannel.participantName}'
                        : 'Notifications unmuted for ${_currentChannel.participantName}',
                  );
                },
              ),

              // Option 3: Report Issue to Dispatch
              _buildModalOptionItem(
                icon: Icons.report_problem_outlined,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Report Issue to Dispatch',
                subtitle: 'Escalate facility delay or dock coordination concern',
                onTap: () {
                  Navigator.pop(modalCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportIssueScreen(
                        shipmentId: widget.shipmentId,
                        originTitle: widget.originTitle,
                        destTitle: widget.destTitle,
                      ),
                    ),
                  );
                },
              ),

              // Option 4: Clear Chat History
              _buildModalOptionItem(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Clear Chat Messages',
                subtitle: 'Remove all messages from this active session',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(modalCtx);
                  _confirmClearChat();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalOptionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xFFEF4444) : textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: textSub),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: textSub),
          ],
        ),
      ),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textMain)),
        content: const Text('Are you sure you want to clear messages in this chat session?', style: TextStyle(fontSize: 13.5, color: textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel', style: TextStyle(color: textSub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              setState(() {
                _currentChannel.messages.clear();
              });
              AppToast.info(context, 'Chat history cleared');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }



  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = _currentChannel;
    final isSupplier = currentChannel.type == ChatChannelType.supplierWarehouse;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: cardBorder.withValues(alpha: 0.7), height: 0.8),
        ),
        leading: (widget.showBackButton && Navigator.canPop(context))
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textMain),
                onPressed: () => Navigator.pop(context),
              )
            : const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Center(
                  child: Icon(Icons.forum_outlined, size: 20, color: primaryColor),
                ),
              ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openChatDetails,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              // Circular Real Photo Avatar with Green Online Dot
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.asset(
                        currentChannel.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          isSupplier ? Icons.warehouse_rounded : Icons.storefront_rounded,
                          size: 20,
                          color: isSupplier ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  if (currentChannel.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentChannel.participantName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentChannel.isOnline ? 'Active now' : currentChannel.lastActive,
                      style: TextStyle(
                        fontSize: 11,
                        color: currentChannel.isOnline ? const Color(0xFF10B981) : textSub,
                        fontWeight: currentChannel.isOnline ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: textMain, size: 20),
              onPressed: _showFooterOptionsModal,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Chat Messages Stream (Ultra-Clean Full Height)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: currentChannel.messages.length,
              itemBuilder: (context, index) {
                final msg = currentChannel.messages[index];
                return ChatBubble(message: msg);
              },
            ),
          ),

          // 2. Clean Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment button
                  GestureDetector(
                    onTap: _handleAttachmentPicker,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: inputBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.attach_file_rounded, color: primaryColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 100% Stadium Full Pill Text Input
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(fontSize: 14, color: textMain),
                          cursorColor: primaryColor,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'Type message...',
                            hintStyle: const TextStyle(color: textSub, fontSize: 13.5),
                            filled: true,
                            fillColor: inputBg,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          ),
                          onSubmitted: (text) => _sendMessage(text),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: () => _sendMessage(_textController.text),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 17),
                      ),
                    ),
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
