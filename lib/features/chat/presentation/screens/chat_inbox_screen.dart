import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/models/chat_channel_model.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ChatRemoteDataSource _chatApi = ChatRemoteDataSource();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0; // 0: All, 1: Unread
  bool _isLoading = true;

  // Dynamic contacts from assigned orders (`GET /messages/users`)
  List<Map<String, dynamic>> _assignedContacts = [];

  // Dynamic active conversations (`GET /messages/conversations`)
  List<Map<String, dynamic>> _conversations = [];

  Timer? _pollTimer;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Colors.white;
  static const Color textMain = AppColors.textPrimary;
  static const Color textSub = AppColors.textSecondary;
  static const Color cardBorder = AppColors.border;
  static const Color searchBg = Color(0xFFF3F4F6);
  static const Color onlineGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadInboxData();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _loadInboxData(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isNetworkUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Map<String, dynamic> _mapApiConversationItem(Map<String, dynamic> raw) {
    final channel = ChatChannel.fromConversationJson(raw);
    final lastMsg = (raw['last_message'] is Map)
        ? Map<String, dynamic>.from(raw['last_message'] as Map)
        : null;

    String previewText = 'Start a conversation';
    String timeLabel = '';
    bool lastIsMe = false;
    bool lastIsRead = false;

    if (lastMsg != null) {
      final bool isUnsent =
          lastMsg['is_unsent'] == true || lastMsg['is_unsent'] == 1;
      final bool isMe = lastMsg['is_me'] == true || lastMsg['is_me'] == 1;
      final bool isRead = lastMsg['is_read'] == true || lastMsg['is_read'] == 1;
      final String msgType =
          (lastMsg['message_type'] ?? 'text').toString().toLowerCase();
      final String rawText = (lastMsg['message'] ?? '').toString().trim();

      lastIsMe = isMe;
      lastIsRead = isRead;

      if (isUnsent) {
        previewText =
            isMe ? 'You deleted this message' : 'This message was deleted';
      } else if (rawText.isNotEmpty) {
        previewText = rawText;
      } else if (msgType == 'image') {
        previewText = '📷 Photo';
      } else if (msgType == 'file') {
        previewText = '📎 Document';
      }

      timeLabel =
          (lastMsg['time'] ?? lastMsg['created_at_human'] ?? '').toString();
    }

    return {
      'id': channel.id,
      'partnerId': channel.partnerId,
      'channel': channel,
      'name': channel.participantName,
      'companyName': channel.companyName,
      'role': channel.participantRoleTitle,
      'roleType': channel.type,
      'lastMessage': previewText,
      'lastIsMe': lastIsMe,
      'lastIsRead': lastIsRead,
      'time': timeLabel,
      'unreadCount': channel.unreadCount,
      'isOnline': channel.isOnline,
      'isVerified': channel.isVerified,
      'lastActive': channel.lastActive,
      'avatar': channel.avatarUrl,
      'shipmentId': channel.shipmentId,
      'orderNumbers': channel.orderNumbers,
      'originTitle': channel.originTitle.isNotEmpty
          ? channel.originTitle
          : 'Origin',
      'destTitle': channel.destTitle.isNotEmpty
          ? channel.destTitle
          : channel.participantName,
    };
  }

  Map<String, dynamic> _mapApiDirectoryContact(Map<String, dynamic> raw) {
    final channel = ChatChannel.fromConversationJson(raw);
    final orderNums = channel.orderNumbers;
    final orderDisplay = orderNums.isNotEmpty
        ? orderNums.join(', ')
        : (channel.orderNumber.isNotEmpty ? channel.orderNumber : 'Assigned Order');

    return {
      'id': channel.id,
      'partnerId': channel.partnerId,
      'channel': channel,
      'name': channel.participantName,
      'companyName': channel.companyName,
      'role': channel.participantRoleTitle,
      'roleType': channel.type,
      'orderId': orderDisplay,
      'shipmentId': channel.orderNumber,
      'originTitle': channel.originTitle.isNotEmpty
          ? channel.originTitle
          : 'Origin',
      'destTitle': channel.destTitle.isNotEmpty
          ? channel.destTitle
          : channel.participantName,
      'avatar': channel.avatarUrl,
      'isOnline': channel.isOnline,
      'isVerified': channel.isVerified,
      'lastActive': channel.lastActive,
    };
  }

  Future<void> _loadInboxData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    await _chatApi.sendHeartbeat();

    final results = await Future.wait([
      _chatApi.getConversations(),
      _chatApi.getDirectoryUsers(),
    ]);

    if (!mounted) return;

    final rawConvs = results[0];
    final rawContacts = results[1];

    setState(() {
      _conversations = rawConvs.map(_mapApiConversationItem).toList();
      _assignedContacts = rawContacts.map(_mapApiDirectoryContact).toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredConversations {
    return _conversations.where((conv) {
      if (_filterIndex == 1 && ((conv['unreadCount'] as int? ?? 0) == 0)) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (conv['name'] ?? '').toString().toLowerCase();
        final msg = (conv['lastMessage'] ?? '').toString().toLowerCase();
        final shp = (conv['shipmentId'] ?? '').toString().toLowerCase();
        final ords = ((conv['orderNumbers'] as List?) ?? [])
            .join(' ')
            .toLowerCase();
        return name.contains(q) ||
            msg.contains(q) ||
            shp.contains(q) ||
            ords.contains(q);
      }
      return true;
    }).toList();
  }

  int get _unreadCount {
    return _conversations.fold<int>(
      0,
      (sum, item) => sum + ((item['unreadCount'] as int?) ?? 0),
    );
  }

  Future<void> _openChat(Map<String, dynamic> conv) async {
    setState(() {
      conv['unreadCount'] = 0;
    });

    final ChatChannel? baseChannel = conv['channel'] as ChatChannel?;
    final int? pid = conv['partnerId'] as int? ?? baseChannel?.partnerId;

    final channel = (baseChannel ??
            ChatChannel(
              id: (conv['id'] ?? 'partner_$pid').toString(),
              partnerId: pid,
              shipmentId: (conv['shipmentId'] ?? '').toString(),
              type:
                  (conv['roleType'] as ChatChannelType?) ??
                  ChatChannelType.customerConsignee,
              title: (conv['role'] ?? 'Customer (Shipper)').toString(),
              participantName: (conv['name'] ?? 'Partner').toString(),
              companyName: (conv['companyName'] ?? conv['name'] ?? '').toString(),
              participantRoleTitle:
                  (conv['role'] ?? 'Customer (Shipper)').toString(),
              participantPhone: '',
              avatarUrl:
                  (conv['avatar'] ?? 'assets/images/customer_avatar.png')
                      .toString(),
              isOnline: conv['isOnline'] as bool? ?? false,
              lastActive: (conv['lastActive'] ?? 'Offline').toString(),
              isVerified: conv['isVerified'] as bool? ?? true,
              orderNumber: (conv['shipmentId'] ?? '').toString(),
            ))
        .copyWith(unreadCount: 0);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          shipmentId: (conv['shipmentId'] ?? '').toString(),
          originTitle: (conv['originTitle'] ?? 'Origin').toString(),
          destTitle: (conv['destTitle'] ?? 'Destination').toString(),
          initialChannelType:
              conv['roleType'] as ChatChannelType? ??
              ChatChannelType.customerConsignee,
          showBackButton: true,
          initialChannel: channel,
          partnerId: pid,
        ),
      ),
    );

    if (mounted) {
      _loadInboxData(silent: true);
    }
  }

  Widget _buildAvatarImage(String avatarUrl, {double size = 48}) {
    if (_isNetworkUrl(avatarUrl)) {
      return Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.person_rounded,
          color: primaryColor,
        ),
      );
    }
    return Image.asset(
      avatarUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person_rounded,
        color: primaryColor,
      ),
    );
  }

  /// Opens the Web-Style "Message Customer" Modal (Contacts from Assigned Orders)
  void _showMessageCustomerDialog() {
    String modalSearch = '';
    final existingPartnerIds = _conversations
        .map((c) => c['partnerId'])
        .whereType<int>()
        .toSet();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredContacts = _assignedContacts.where((c) {
              if (modalSearch.trim().isEmpty) return true;
              final q = modalSearch.toLowerCase();
              return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (c['orderId'] ?? '').toString().toLowerCase().contains(q) ||
                  (c['role'] ?? '').toString().toLowerCase().contains(q);
            }).toList();

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 520,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Modal Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFCCBC),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.people_outline_rounded,
                                size: 17,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Message Customer',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textMain,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select a verified partner to open or start a message thread',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(dialogCtx),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: textSub,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: cardBorder),
                      const SizedBox(height: 10),

                      // 2. Contacts from Assigned Orders + Available Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Contacts from Assigned Orders',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textSub,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filteredContacts.length} available',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 3. Search Bar inside Modal
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setModalState(() => modalSearch = val),
                          style: const TextStyle(fontSize: 13, color: textMain),
                          cursorColor: primaryColor,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: searchBg,
                            hintText: 'Search by customer name or order #...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: textSub,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12.0, right: 6.0),
                              child: Icon(
                                Icons.search_rounded,
                                size: 17,
                                color: textSub,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 38,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(60),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(60),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(60),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4. List of Assigned Contacts
                      Flexible(
                        child: filteredContacts.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 12,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'No assigned customer orders yet',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        modalSearch.isNotEmpty
                                            ? 'Try searching with another keyword or order number.'
                                            : 'When a supplier assigns a shipment to you, the customer of that order will appear here to chat.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: textSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredContacts.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1, color: cardBorder),
                                itemBuilder: (context, index) {
                                  final contact = filteredContacts[index];
                                  final isOnline =
                                      contact['isOnline'] as bool? ?? false;
                                  final pid = contact['partnerId'] as int?;
                                  final hasExisting =
                                      pid != null &&
                                      existingPartnerIds.contains(pid);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: cardBorder,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: _buildAvatarImage(
                                                  (contact['avatar'] ??
                                                          'assets/images/customer_avatar.png')
                                                      .toString(),
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                            if (isOnline)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: onlineGreen,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      (contact['name'] ??
                                                              'Customer')
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textMain,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.verified_rounded,
                                                    size: 14,
                                                    color: Color(0xFF009688),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1.5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFE8F5E9,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      (contact['role'] ??
                                                              'Customer')
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF2E7D32,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${contact['orderId']} • Verified Partner',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: textSub,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(dialogCtx);
                                            _startChatWithContact(contact);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1EB),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFFFCCBC),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  hasExisting
                                                      ? Icons.chat_bubble_outline_rounded
                                                      : Icons
                                                            .person_add_alt_1_rounded,
                                                  size: 13,
                                                  color: const Color(0xFFFF5722),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  hasExisting ? 'Chat' : 'Start',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFF5722),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startChatWithContact(Map<String, dynamic> contact) {
    final pid = contact['partnerId'] as int?;
    final existingIdx = _conversations.indexWhere(
      (c) =>
          (pid != null && c['partnerId'] == pid) ||
          (c['shipmentId'] != null &&
              c['shipmentId'].toString().isNotEmpty &&
              c['shipmentId'] == contact['shipmentId']),
    );
    Map<String, dynamic> convItem;
    if (existingIdx != -1) {
      convItem = _conversations[existingIdx];
    } else {
      convItem = {
        'id': contact['id'] ?? 'partner_${pid ?? DateTime.now().millisecondsSinceEpoch}',
        'partnerId': pid,
        'channel': contact['channel'],
        'name': contact['name'],
        'companyName': contact['companyName'] ?? contact['name'],
        'role': contact['role'],
        'roleType': contact['roleType'] ?? ChatChannelType.customerConsignee,
        'lastMessage': 'Start a conversation',
        'time': 'Just now',
        'unreadCount': 0,
        'isOnline': contact['isOnline'] ?? false,
        'isVerified': contact['isVerified'] ?? true,
        'lastActive': contact['lastActive'] ?? 'Offline',
        'avatar': contact['avatar'] ?? 'assets/images/customer_avatar.png',
        'shipmentId': contact['shipmentId'] ?? '',
        'originTitle': contact['originTitle'] ?? 'Origin',
        'destTitle': contact['destTitle'] ?? contact['name'] ?? 'Destination',
      };
      setState(() {
        _conversations.insert(0, convItem);
      });
    }

    _openChat(convItem);
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredConversations;
    final unreadTotal = _unreadCount;

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: () => _loadInboxData(silent: false),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Web-Style Header: Messages title + Circle [+ New Message] button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textMain,
                          letterSpacing: -0.4,
                        ),
                      ),
                      InkWell(
                        onTap: _showMessageCustomerDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search Conversations Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13.5, color: textMain),
                      cursorColor: primaryColor,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: searchBg,
                        hintText: 'Search conversations',
                        hintStyle: const TextStyle(fontSize: 13, color: textSub),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14.0, right: 8.0),
                          child: Icon(
                            Icons.search_rounded,
                            color: textSub,
                            size: 20,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 42,
                          minHeight: 42,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 16,
                                  color: textSub,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(60),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(60),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(60),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Filter Tabs (All / Unread)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _filterIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _filterIndex == 0
                                ? const Color(0xFFFFF1EB)
                                : searchBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _filterIndex == 0
                                  ? const Color(0xFFFF5722)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            'All (${_conversations.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _filterIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _filterIndex == 0
                                  ? const Color(0xFFFF5722)
                                  : textSub,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: () => setState(() => _filterIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _filterIndex == 1
                                ? const Color(0xFFFFF1EB)
                                : searchBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _filterIndex == 1
                                  ? const Color(0xFFFF5722)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Unread',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _filterIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: _filterIndex == 1
                                      ? const Color(0xFFFF5722)
                                      : textSub,
                                ),
                              ),
                              if (unreadTotal > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$unreadTotal',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // 4. Loading, Empty State, or Conversations List
              if (_isLoading && _conversations.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 40.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No chats found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Start a new conversation using the\n"New Message" button above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSub,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _showMessageCustomerDialog,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Start Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredList[index];
                    final isOnline = item['isOnline'] as bool? ?? false;
                    final isVerified = item['isVerified'] as bool? ?? true;
                    final unreadCount = item['unreadCount'] as int? ?? 0;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _openChat(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 11.0,
                            ),
                            child: Row(
                              children: [
                                // Avatar with Online indicator
                                Stack(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: _buildAvatarImage(
                                          (item['avatar'] ??
                                                  'assets/images/customer_avatar.png')
                                              .toString(),
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: onlineGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Name, Time, Tick & Last Message (WhatsApp Inbox Layout)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    (item['name'] ?? 'Partner')
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: unreadCount > 0
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                      color: textMain,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isVerified) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.verified_rounded,
                                                    size: 14,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            (item['time'] ?? '').toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: unreadCount > 0
                                                  ? primaryColor
                                                  : textSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (item['lastIsMe'] == true) ...[
                                            Icon(
                                              Icons.done_all_rounded,
                                              size: 15,
                                              color: item['lastIsRead'] == true
                                                  ? const Color(0xFF53BDEB)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Expanded(
                                            child: Text(
                                              (item['lastMessage'] ?? '')
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: unreadCount > 0
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: unreadCount > 0
                                                    ? textMain
                                                    : textSub,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (unreadCount > 0)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$unreadCount',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (index < filteredList.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 0.6,
                            indent: 76,
                            endIndent: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                      ],
                    );
                  }, childCount: filteredList.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
