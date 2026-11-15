import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/models/chat_channel_model.dart';
import '../../data/models/chat_message_model.dart';
import '../widgets/chat_bubble.dart';
import 'chat_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String shipmentId;
  final String originTitle;
  final String destTitle;
  final ChatChannelType? initialChannelType;
  final bool showBackButton;
  final ChatChannel? initialChannel;
  final int? partnerId;

  const ChatScreen({
    super.key,
    required this.shipmentId,
    required this.originTitle,
    required this.destTitle,
    this.initialChannelType,
    this.showBackButton = true,
    this.initialChannel,
    this.partnerId,
  });

  static void openForShipment(
    BuildContext context, {
    required dynamic shipment,
    ChatChannelType? initialChannelType,
  }) {
    String sId = '';
    String oTitle = 'Origin';
    String dTitle = 'Destination';
    int? resolvedPartnerId;
    String partnerName = '';
    String partnerAvatar = '';
    final bool wantSupplier =
        initialChannelType == ChatChannelType.supplierWarehouse;

    try {
      sId = (shipment.id ?? '').toString();
      oTitle = (shipment.originTitle ?? shipment.origin ?? 'Origin').toString();
      dTitle = (shipment.destTitle ?? shipment.destination ?? 'Destination')
          .toString();
      if (wantSupplier) {
        resolvedPartnerId = shipment.supplierId as int?;
        partnerName = (shipment.supplierName ?? '').toString();
        partnerAvatar = (shipment.supplierAvatar ?? '').toString();
      } else {
        resolvedPartnerId = shipment.customerId as int?;
        partnerName = (shipment.customerName ?? '').toString();
        partnerAvatar = (shipment.customerAvatar ?? '').toString();
      }
    } catch (_) {}

    ChatChannel? channel;
    if (resolvedPartnerId != null || partnerName.isNotEmpty) {
      final effectiveType =
          initialChannelType ?? ChatChannelType.customerConsignee;
      channel = ChatChannel(
        id: 'partner_${resolvedPartnerId ?? sId}',
        partnerId: resolvedPartnerId,
        shipmentId: sId,
        type: effectiveType,
        title: wantSupplier ? 'Supplier (Carrier)' : 'Customer (Shipper)',
        participantName: partnerName.isNotEmpty
            ? partnerName
            : (wantSupplier ? oTitle : dTitle),
        companyName: partnerName.isNotEmpty
            ? partnerName
            : (wantSupplier ? oTitle : dTitle),
        participantRoleTitle:
            wantSupplier ? 'Supplier (Carrier)' : 'Customer (Shipper)',
        participantPhone: '',
        avatarUrl: partnerAvatar.isNotEmpty
            ? partnerAvatar
            : 'assets/images/customer_avatar.png',
        isOnline: true,
        lastActive: 'Active now',
        orderNumber: sId,
        orderNumbers: sId.isNotEmpty ? [sId] : const [],
        originTitle: oTitle,
        destTitle: dTitle,
        messages: const [],
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          shipmentId: sId,
          originTitle: oTitle,
          destTitle: dTitle,
          initialChannelType: initialChannelType,
          showBackButton: true,
          initialChannel: channel,
          partnerId: resolvedPartnerId,
        ),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRemoteDataSource _chatApi = ChatRemoteDataSource();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late ChatChannel _currentChannel;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isMuted = false;

  ChatMessage? _replyingTo;
  ChatMessage? _editingMessage;
  Timer? _pollTimer;

  static const Color primaryColor = AppColors.primary;
  static const Color textMain = AppColors.textPrimary;
  static const Color textSub = AppColors.textSecondary;
  static const Color cardBorder = AppColors.border;

  @override
  void initState() {
    super.initState();

    final initialType =
        widget.initialChannel?.type ??
        widget.initialChannelType ??
        ChatChannelType.customerConsignee;

    _currentChannel =
        widget.initialChannel ??
        ChatChannel(
          id: 'partner_${widget.partnerId ?? widget.shipmentId}',
          partnerId: widget.partnerId,
          shipmentId: widget.shipmentId,
          type: initialType,
          title: initialType == ChatChannelType.supplierWarehouse
              ? 'Supplier (Carrier)'
              : 'Customer (Shipper)',
          participantName: initialType == ChatChannelType.supplierWarehouse
              ? widget.originTitle
              : widget.destTitle,
          companyName: initialType == ChatChannelType.supplierWarehouse
              ? widget.originTitle
              : widget.destTitle,
          participantRoleTitle:
              initialType == ChatChannelType.supplierWarehouse
              ? 'Supplier (Carrier)'
              : 'Customer (Shipper)',
          participantPhone: '',
          avatarUrl: 'assets/images/customer_avatar.png',
          isOnline: false,
          lastActive: 'Offline',
          orderNumber: widget.shipmentId,
          orderNumbers: widget.shipmentId.isNotEmpty
              ? [widget.shipmentId]
              : const [],
          originTitle: widget.originTitle,
          destTitle: widget.destTitle,
          messages: _messages,
        );

    _messages = List<ChatMessage>.from(_currentChannel.messages);
    _initConversation();

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshMessagesSilently();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  bool _isNetworkUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Future<void> _initConversation() async {
    int? pid = _currentChannel.partnerId ?? widget.partnerId;

    // If partnerId wasn't passed directly, resolve from directory users or conversations
    if (pid == null || pid <= 0) {
      final wantSup = _currentChannel.type == ChatChannelType.supplierWarehouse;
      final dirUsers = await _chatApi.getDirectoryUsers(
        role: wantSup ? 'supplier' : 'all',
      );

      Map<String, dynamic>? matchedUser;
      final cleanShipmentId = widget.shipmentId
          .replaceFirst('#', '')
          .trim()
          .toLowerCase();

      if (cleanShipmentId.isNotEmpty) {
        for (final u in dirUsers) {
          final ordList = u['order_numbers'];
          if (ordList is List) {
            final matchesOrd = ordList.any(
              (o) => o.toString().toLowerCase().contains(cleanShipmentId),
            );
            if (matchesOrd) {
              matchedUser = u;
              break;
            }
          }
        }
      }

      matchedUser ??= dirUsers.isNotEmpty ? dirUsers.first : null;

      if (matchedUser == null) {
        final convs = await _chatApi.getConversations();
        if (convs.isNotEmpty) {
          final firstConv = convs.first;
          final ch = ChatChannel.fromConversationJson(firstConv);
          pid = ch.partnerId;
          if (mounted) {
            setState(() {
              _currentChannel = ch.copyWith(messages: _messages);
            });
          }
        }
      } else {
        final ch = ChatChannel.fromConversationJson(matchedUser);
        pid = ch.partnerId;
        if (mounted) {
          setState(() {
            _currentChannel = ch.copyWith(messages: _messages);
          });
        }
      }
    }

    if (pid != null && pid > 0) {
      final loaded = await _chatApi.getMessages(
        pid,
        partnerName: _currentChannel.participantName,
        shipmentId: _currentChannel.shipmentId,
        partnerRole: _currentChannel.type == ChatChannelType.supplierWarehouse
            ? MessageSenderRole.supplierEmployee
            : MessageSenderRole.customerReceiver,
      );
      await _chatApi.markAsRead(pid);

      if (mounted) {
        setState(() {
          _messages = loaded;
          _currentChannel = _currentChannel.copyWith(
            partnerId: pid,
            messages: _messages,
            unreadCount: 0,
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshMessagesSilently() async {
    final pid = _currentChannel.partnerId;
    if (pid == null || pid <= 0 || _isSending) return;

    final loaded = await _chatApi.getMessages(
      pid,
      partnerName: _currentChannel.participantName,
      shipmentId: _currentChannel.shipmentId,
      partnerRole: _currentChannel.type == ChatChannelType.supplierWarehouse
          ? MessageSenderRole.supplierEmployee
          : MessageSenderRole.customerReceiver,
    );

    if (!mounted) return;

    final hadCount = _messages.length;
    final hasNewLast =
        loaded.isNotEmpty &&
        (_messages.isEmpty || loaded.last.id != _messages.last.id);

    setState(() {
      _messages = loaded;
      _currentChannel = _currentChannel.copyWith(messages: _messages);
    });

    if (loaded.length > hadCount || hasNewLast) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendOrEdit(
    String text, {
    List<String>? filePaths,
    MessageAttachmentType attachmentType = MessageAttachmentType.none,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    final trimmed = text.trim();
    final hasFiles = filePaths != null && filePaths.isNotEmpty;

    if (trimmed.isEmpty && !hasFiles) return;

    // Handle Edit Mode
    if (_editingMessage != null && !hasFiles) {
      final targetMsg = _editingMessage!;
      final numId = targetMsg.numericId ?? int.tryParse(targetMsg.id);
      setState(() {
        _editingMessage = null;
        _textController.clear();
      });

      if (numId != null) {
        // Optimistic update
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == targetMsg.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              message: trimmed,
              isEdited: true,
            );
            _currentChannel = _currentChannel.copyWith(messages: _messages);
          }
        });

        final updated = await _chatApi.updateMessage(
          numId,
          trimmed,
          partnerName: _currentChannel.participantName,
          shipmentId: _currentChannel.shipmentId,
        );
        if (updated != null && mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == targetMsg.id);
            if (idx != -1) {
              _messages[idx] = updated;
              _currentChannel = _currentChannel.copyWith(messages: _messages);
            }
          });
        }
      }
      return;
    }

    final pid = _currentChannel.partnerId;
    if (pid == null || pid <= 0) {
      AppToast.warning(
        context,
        'No verified partner assigned to this conversation yet.',
      );
      return;
    }

    final replyTarget = _replyingTo;
    final replyToId =
        replyTarget != null
        ? (replyTarget.numericId ?? int.tryParse(replyTarget.id))
        : null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      shipmentId: _currentChannel.shipmentId,
      senderId: 'driver_me',
      receiverId: pid.toString(),
      senderName: 'You (Driver)',
      senderRole: MessageSenderRole.driver,
      message: trimmed,
      timestamp: DateTime.now(),
      isFromDriver: true,
      isRead: false,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      replyToId: replyToId,
      replyToMessage: replyTarget?.message,
      replyToIsMe: replyTarget?.isFromDriver ?? false,
    );

    setState(() {
      _isSending = true;
      _replyingTo = null;
      _textController.clear();
      _messages.add(tempMsg);
      _currentChannel = _currentChannel.copyWith(messages: _messages);
    });
    _scrollToBottom();

    final sentMsg = await _chatApi.sendMessage(
      receiverId: pid,
      message: trimmed.isNotEmpty ? trimmed : null,
      replyToId: replyToId,
      filePaths: filePaths,
      partnerName: _currentChannel.participantName,
      shipmentId: _currentChannel.shipmentId,
      partnerRole: _currentChannel.type == ChatChannelType.supplierWarehouse
          ? MessageSenderRole.supplierEmployee
          : MessageSenderRole.customerReceiver,
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (sentMsg != null) {
        if (idx != -1) {
          _messages[idx] = sentMsg;
        } else {
          _messages.add(sentMsg);
        }
      } else if (idx != -1) {
        _messages.removeAt(idx);
        AppToast.error(context, 'Failed to send message. Please try again.');
      }
      _currentChannel = _currentChannel.copyWith(messages: _messages);
    });
    _scrollToBottom();
  }

  Future<void> _handleTogglePin(ChatMessage msg) async {
    final numId = msg.numericId ?? int.tryParse(msg.id);
    if (numId == null) return;

    final newPinned = !msg.isPinned;
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(isPinned: newPinned);
        _currentChannel = _currentChannel.copyWith(messages: _messages);
      }
    });

    final res = await _chatApi.togglePin(
      numId,
      partnerName: _currentChannel.participantName,
      shipmentId: _currentChannel.shipmentId,
    );

    if (res != null && mounted) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = res;
          _currentChannel = _currentChannel.copyWith(messages: _messages);
        }
      });
      AppToast.info(
        context,
        res.isPinned ? 'Message pinned' : 'Message unpinned',
      );
    }
  }

  Future<void> _handleDeleteMessage(ChatMessage msg, String type) async {
    final numId = msg.numericId ?? int.tryParse(msg.id);
    if (numId == null) return;

    final ok = await _chatApi.deleteMessage(numId, type: type);
    if (!mounted) return;

    if (ok) {
      setState(() {
        if (type == 'everyone' && msg.isFromDriver) {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              isUnsent: true,
              message: 'You unsent a message',
              attachments: const [],
              attachmentUrl: null,
            );
          }
        } else {
          _messages.removeWhere((m) => m.id == msg.id);
        }
        _currentChannel = _currentChannel.copyWith(messages: _messages);
      });
    } else {
      AppToast.error(context, 'Could not remove message');
    }
  }

  void _showMessageActionsSheet(ChatMessage msg) {
    if (msg.isUnsent) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.reply_rounded, color: textMain),
                title: const Text(
                  'Reply',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textMain,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _editingMessage = null;
                    _replyingTo = msg;
                  });
                  _inputFocusNode.requestFocus();
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(
                  msg.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: primaryColor,
                ),
                title: Text(
                  msg.isPinned ? 'Unpin Message' : 'Pin Message',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textMain,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleTogglePin(msg);
                },
              ),
              if (msg.message.trim().isNotEmpty)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.copy_rounded, color: textMain),
                  title: const Text(
                    'Copy Text',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg.message));
                    AppToast.info(context, 'Message copied to clipboard');
                  },
                ),
              if (msg.isFromDriver && msg.message.trim().isNotEmpty)
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0284C7),
                  ),
                  title: const Text(
                    'Edit Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _replyingTo = null;
                      _editingMessage = msg;
                      _textController.text = msg.message;
                    });
                    _inputFocusNode.requestFocus();
                  },
                ),
              if (msg.isFromDriver)
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.undo_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  title: const Text(
                    'Unsend for Everyone',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleDeleteMessage(msg, 'everyone');
                  },
                ),
              ListTile(
                dense: true,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  'Remove for You',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteMessage(msg, 'for_me');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImagePreview(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: InteractiveViewer(
                child: _isNetworkUrl(imageUrl)
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : (imageUrl.startsWith('assets/')
                          ? Image.asset(imageUrl, fit: BoxFit.contain)
                          : Image.file(File(imageUrl), fit: BoxFit.contain)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () => Navigator.pop(dlgCtx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
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
                'Share Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                        );
                        if (photo != null) {
                          await _handleSendOrEdit(
                            _textController.text,
                            filePaths: [photo.path],
                            attachmentType: MessageAttachmentType.image,
                            attachmentUrl: photo.path,
                            attachmentName: photo.name,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          AppToast.error(
                            context,
                            'Could not open camera on this device',
                          );
                        }
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.upload_file_rounded,
                    label: 'File Upload',
                    color: const Color(0xFF0284C7),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'doc',
                            'docx',
                            'xlsx',
                            'txt',
                            'png',
                            'jpg',
                            'jpeg',
                          ],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.path != null && file.path!.isNotEmpty) {
                            final isImg = [
                              'png',
                              'jpg',
                              'jpeg',
                            ].contains(file.extension?.toLowerCase());
                            await _handleSendOrEdit(
                              _textController.text,
                              filePaths: [file.path!],
                              attachmentType: isImg
                                  ? MessageAttachmentType.image
                                  : MessageAttachmentType.document,
                              attachmentUrl: file.path,
                              attachmentName: file.name,
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          AppToast.error(context, 'Could not pick file');
                        }
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF8B5CF6),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (photo != null) {
                          await _handleSendOrEdit(
                            _textController.text,
                            filePaths: [photo.path],
                            attachmentType: MessageAttachmentType.image,
                            attachmentUrl: photo.path,
                            attachmentName: photo.name,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          AppToast.error(context, 'Could not open gallery');
                        }
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
          channel: _currentChannel.copyWith(messages: _messages),
          shipmentId: widget.shipmentId,
          originTitle: widget.originTitle,
          destTitle: widget.destTitle,
          onTogglePin: _handleTogglePin,
          onClearChat: () {
            setState(() {
              _messages.clear();
              _currentChannel = _currentChannel.copyWith(messages: _messages);
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
                          child: Icon(
                            Icons.tune_rounded,
                            color: primaryColor,
                            size: 18,
                          ),
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
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: textSub,
                            ),
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
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: textSub,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: cardBorder, height: 1),
              const SizedBox(height: 8),

              _buildModalOptionItem(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Contact & User Details',
                subtitle: 'View company, pinned messages, shared photos & docs',
                onTap: () {
                  Navigator.pop(modalCtx);
                  _openChatDetails();
                },
              ),

              _buildModalOptionItem(
                icon: _isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                iconColor: const Color(0xFFD97706),
                title: _isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                subtitle: _isMuted
                    ? 'Turn alert sounds and banners back on'
                    : 'Silence alerts for incoming messages',
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
              child: Center(child: Icon(icon, color: iconColor, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textMain,
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: textSub,
            ),
          ],
        ),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar(ChatChannel channel, bool isSupplier) {
    final avatar = channel.avatarUrl;
    if (_isNetworkUrl(avatar)) {
      return Image.network(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          isSupplier ? Icons.warehouse_rounded : Icons.storefront_rounded,
          size: 20,
          color: isSupplier ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
        ),
      );
    }
    return Image.asset(
      avatar,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(
        isSupplier ? Icons.warehouse_rounded : Icons.storefront_rounded,
        size: 20,
        color: isSupplier ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) return 'Yesterday';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildDateChip(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF54656F),
          ),
        ),
      ),
    );
  }

  Widget _buildEncryptionNotice() {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 6, 24, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: Color(0xFF54656F)),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Messages and files are end-to-end protected in this chat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF54656F),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQuickCameraCapture() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        await _handleSendOrEdit(
          _textController.text,
          filePaths: [photo.path],
          attachmentType: MessageAttachmentType.image,
          attachmentUrl: photo.path,
          attachmentName: photo.name,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not open camera');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = _currentChannel;
    final isSupplier = currentChannel.type == ChatChannelType.supplierWarehouse;
    final pinnedMessages = _messages
        .where((m) => m.isPinned && !m.isUnsent)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEAE2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: cardBorder.withValues(alpha: 0.7),
            height: 0.8,
          ),
        ),
        leading: (widget.showBackButton && Navigator.canPop(context))
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: textMain,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Center(
                  child: Icon(
                    Icons.forum_outlined,
                    size: 20,
                    color: primaryColor,
                  ),
                ),
              ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openChatDetails,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
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
                      child: _buildHeaderAvatar(currentChannel, isSupplier),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currentChannel.participantName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currentChannel.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Color(0xFF059669),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      currentChannel.isOnline
                          ? 'online'
                          : currentChannel.lastActive,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: currentChannel.isOnline
                            ? const Color(0xFF10B981)
                            : textSub,
                        fontWeight: currentChannel.isOnline
                            ? FontWeight.w500
                            : FontWeight.normal,
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
              icon: const Icon(
                Icons.more_vert_rounded,
                color: textMain,
                size: 20,
              ),
              onPressed: _showFooterOptionsModal,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Message Bar
          if (pinnedMessages.isNotEmpty)
            InkWell(
              onTap: _openChatDetails,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 15,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pinnedMessages.last.message.isNotEmpty
                            ? pinnedMessages.last.message
                            : 'Pinned attachment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ),
                    Text(
                      '${pinnedMessages.length} pinned',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 1. WhatsApp-Style Chat Messages Stream
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEncryptionNotice(),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Say hello to ${currentChannel.participantName} 👋',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textMain,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Send a message, photo, or document below.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSub,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final prevMsg = index > 0 ? _messages[index - 1] : null;
                      final nextMsg = index < _messages.length - 1
                          ? _messages[index + 1]
                          : null;

                      final showDateChip =
                          prevMsg == null ||
                          !_isSameDay(prevMsg.timestamp, msg.timestamp);

                      final isFirstInGroup =
                          showDateChip ||
                          prevMsg.isFromDriver != msg.isFromDriver;

                      final isLastInGroup =
                          nextMsg == null ||
                          !_isSameDay(nextMsg.timestamp, msg.timestamp) ||
                          nextMsg.isFromDriver != msg.isFromDriver;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (index == 0) _buildEncryptionNotice(),
                          if (showDateChip)
                            _buildDateChip(_formatDateHeader(msg.timestamp)),
                          ChatBubble(
                            message: msg,
                            isFirstInGroup: isFirstInGroup,
                            isLastInGroup: isLastInGroup,
                            onLongPress: () => _showMessageActionsSheet(msg),
                            onSwipeReply: () {
                              setState(() {
                                _editingMessage = null;
                                _replyingTo = msg;
                              });
                              _inputFocusNode.requestFocus();
                            },
                            onTapImage: _openImagePreview,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // 2. WhatsApp-Style Bottom Input Bar + Attached Reply/Edit Preview
          Container(
            color: const Color(0xFFEFEAE2),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left White Pill Container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Reply / Edit Preview inside WhatsApp input card
                          if (_replyingTo != null || _editingMessage != null)
                            Container(
                              margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(14),
                                border: const Border(
                                  left: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _editingMessage != null
                                              ? 'Edit message'
                                              : (_replyingTo!.isFromDriver
                                                    ? 'You'
                                                    : currentChannel
                                                          .participantName),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          (_editingMessage ?? _replyingTo)!
                                                  .message
                                                  .isNotEmpty
                                              ? (_editingMessage ??
                                                        _replyingTo)!
                                                    .message
                                              : '📷 Photo / Attachment',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF54656F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (_editingMessage != null) {
                                          _textController.clear();
                                        }
                                        _editingMessage = null;
                                        _replyingTo = null;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 17,
                                        color: Color(0xFF54656F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 46),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    focusNode: _inputFocusNode,
                                    minLines: 1,
                                    maxLines: 4,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF111B21),
                                      height: 1.25,
                                    ),
                                    cursorColor: primaryColor,
                                    decoration: InputDecoration(
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hintText: _editingMessage != null
                                          ? 'Edit message...'
                                          : 'Message',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF8696A0),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 10,
                                          ),
                                    ),
                                    onSubmitted: (text) =>
                                        _handleSendOrEdit(text),
                                  ),
                                ),
                                InkWell(
                                  onTap: _handleAttachmentPicker,
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    child: Icon(
                                      Icons.attach_file_rounded,
                                      color: Color(0xFF54656F),
                                      size: 21,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _handleQuickCameraCapture,
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.only(
                                      left: 6,
                                      right: 14,
                                      top: 10,
                                      bottom: 10,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: Color(0xFF54656F),
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Circular Floating Send Button (WhatsApp style)
                  GestureDetector(
                    onTap: () => _handleSendOrEdit(_textController.text),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.28),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _editingMessage != null
                              ? Icons.check_rounded
                              : Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
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
