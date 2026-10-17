import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/chat_channel_model.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0; // 0: All, 1: Unread

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Colors.white;
  static const Color searchBg = Color(0xFFF1F5F9);
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;
  static const Color onlineGreen = Color(0xFF10B981);

  // Verified Contacts from Assigned Orders (matches web version popup)
  final List<Map<String, dynamic>> _assignedContacts = [
    {
      'id': 'contact_cd4',
      'name': 'Customer Co 1',
      'initial': 'C',
      'avatarColor': const Color(0xFF10B981),
      'role': 'Customer (Shipper)',
      'roleType': ChatChannelType.customerConsignee,
      'orderId': '#CD-0004',
      'isVerified': true,
      'isOnline': true,
      'lastActive': 'Active now',
      'shipmentId': 'CD-0004',
      'originTitle': 'Customer Co 1 Facility',
      'destTitle': 'Central Distribution Dock',
      'lastMessage': 'Hello Captain! Order #CD-0004 is cleared for carrier pickup.',
    },
    {
      'id': 'contact_miller',
      'name': 'David Miller',
      'initial': 'D',
      'avatar': 'assets/images/supplier_avatar.png',
      'role': 'Supplier Warehouse',
      'roleType': ChatChannelType.supplierWarehouse,
      'orderId': '#SHP-987654',
      'isVerified': true,
      'isOnline': true,
      'lastActive': 'Active now',
      'shipmentId': 'SHP-987654',
      'originTitle': 'ABC Warehouse Logistics',
      'destTitle': 'Starlight Supermarket Central',
      'lastMessage': 'Dock loading complete. BOL paperwork has been signed.',
    },
    {
      'id': 'contact_jenkins',
      'name': 'Sarah Jenkins',
      'initial': 'S',
      'avatar': 'assets/images/customer_avatar.png',
      'role': 'Customer Consignee',
      'roleType': ChatChannelType.customerConsignee,
      'orderId': '#SHP-987654',
      'isVerified': true,
      'isOnline': false,
      'lastActive': 'Active 10m ago',
      'shipmentId': 'SHP-987654',
      'originTitle': 'ABC Warehouse Logistics',
      'destTitle': 'Starlight Supermarket Central',
      'lastMessage': 'Door 12 is reserved for your trailer. Forklift ready.',
    },
    {
      'id': 'contact_port',
      'name': 'Alex Port Security',
      'initial': 'A',
      'avatar': 'assets/images/driver_avatar.png',
      'role': 'Port Gate & Weighing',
      'roleType': ChatChannelType.supplierWarehouse,
      'orderId': '#SHP-987650',
      'isVerified': true,
      'isOnline': true,
      'lastActive': 'Active now',
      'shipmentId': 'SHP-987650',
      'originTitle': 'Port Security Bay 2',
      'destTitle': 'Port Weigh Scale',
      'lastMessage': 'Gate slip #G-4401 issued. Proceed to lane 3.',
    },
  ];

  // Full Messenger Conversations List
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'conv_1',
      'name': 'David Miller',
      'role': 'Supplier Warehouse',
      'roleType': ChatChannelType.supplierWarehouse,
      'lastMessage': 'Dock loading complete. BOL paperwork has been signed.',
      'time': '9:34 PM',
      'unreadCount': 0,
      'isOnline': true,
      'lastActive': 'Active now',
      'avatar': 'assets/images/supplier_avatar.png',
      'shipmentId': 'SHP-987654',
      'originTitle': 'ABC Warehouse Logistics',
      'destTitle': 'Starlight Supermarket Central',
    },
    {
      'id': 'conv_2',
      'name': 'Sarah Jenkins',
      'role': 'Customer Receiving',
      'roleType': ChatChannelType.customerConsignee,
      'lastMessage': 'Door 12 is reserved for your trailer. Forklift ready.',
      'time': '9:30 PM',
      'unreadCount': 1,
      'isOnline': false,
      'lastActive': 'Active 10m ago',
      'avatar': 'assets/images/customer_avatar.png',
      'shipmentId': 'SHP-987654',
      'originTitle': 'ABC Warehouse Logistics',
      'destTitle': 'Starlight Supermarket Central',
    },
    {
      'id': 'conv_3',
      'name': 'Marcus Reed (Dispatch HQ)',
      'role': '24/7 Central Dispatch',
      'roleType': ChatChannelType.centralDispatch,
      'lastMessage': 'Route clearance confirmed for I-95 North bypass.',
      'time': '1:49 PM',
      'unreadCount': 0,
      'isOnline': true,
      'lastActive': 'Active now',
      'avatar': 'assets/images/driver_avatar.png',
      'shipmentId': 'SHP-987654',
      'originTitle': 'Central Logistics HQ',
      'destTitle': 'All Assigned Routes',
    },
    {
      'id': 'conv_4',
      'name': 'Alex Port Security',
      'role': 'Port Gate & Weighing',
      'roleType': ChatChannelType.supplierWarehouse,
      'lastMessage': 'Gate slip #G-4401 issued. Proceed to lane 3.',
      'time': '10:02 AM',
      'unreadCount': 0,
      'isOnline': true,
      'lastActive': 'Active now',
      'avatar': 'assets/images/driver_avatar.png',
      'shipmentId': 'SHP-987650',
      'originTitle': 'Port Security Bay 2',
      'destTitle': 'Port Weigh Scale',
    },
    {
      'id': 'conv_5',
      'name': 'Apex Cold Chain Team',
      'role': 'Supplier Shipper',
      'roleType': ChatChannelType.supplierWarehouse,
      'lastMessage': 'Reefer temp set to -18°C. Pre-cool complete.',
      'time': 'Sat',
      'unreadCount': 2,
      'isOnline': false,
      'lastActive': 'Active 1d ago',
      'avatar': 'assets/images/driver_avatar.png',
      'shipmentId': 'SHP-987645',
      'originTitle': 'Apex Refrigerated Bay',
      'destTitle': 'Metro Cold Storage',
    },
    {
      'id': 'conv_6',
      'name': 'Metro Groceries Dock',
      'role': 'Customer Consignee',
      'roleType': ChatChannelType.customerConsignee,
      'lastMessage': 'Delivery received & digital POD signed by dock lead.',
      'time': 'Sat',
      'unreadCount': 0,
      'isOnline': false,
      'lastActive': 'Active 2d ago',
      'avatar': 'assets/images/driver_avatar.png',
      'shipmentId': 'SHP-987642',
      'originTitle': 'Supplier Hub',
      'destTitle': 'Metro Groceries Store #12',
    },
    {
      'id': 'conv_7',
      'name': 'Hafsa Fleet Safety',
      'role': 'Safety & Compliance',
      'roleType': ChatChannelType.centralDispatch,
      'lastMessage': 'The audio call ended (Duration: 3m 42s).',
      'time': 'Sat',
      'unreadCount': 0,
      'isOnline': true,
      'lastActive': 'Active now',
      'avatar': 'assets/images/driver_avatar.png',
      'shipmentId': 'SHP-987640',
      'originTitle': 'Carrier Safety Desk',
      'destTitle': 'Compliance Center',
    },
  ];

  List<Map<String, dynamic>> get _filteredConversations {
    var list = _conversations;
    if (_filterIndex == 1) {
      list = list.where((c) => (c['unreadCount'] as int? ?? 0) > 0).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final role = (c['role'] as String? ?? '').toLowerCase();
      final msg = (c['lastMessage'] as String).toLowerCase();
      return name.contains(q) || role.contains(q) || msg.contains(q);
    }).toList();
  }

  int get _unreadCount => _conversations.where((c) => (c['unreadCount'] as int? ?? 0) > 0).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          shipmentId: item['shipmentId'] as String,
          originTitle: item['originTitle'] as String,
          destTitle: item['destTitle'] as String,
          initialChannelType: item['roleType'] as ChatChannelType? ?? ChatChannelType.supplierWarehouse,
        ),
      ),
    );
  }

  // Opens "Message Customer" modal dialog matching web version screenshot
  void _showMessageCustomerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        String modalSearch = '';
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            final filteredContacts = _assignedContacts.where((c) {
              if (modalSearch.trim().isEmpty) return true;
              final q = modalSearch.toLowerCase();
              final name = (c['name'] as String).toLowerCase();
              final orderId = (c['orderId'] as String).toLowerCase();
              final role = (c['role'] as String).toLowerCase();
              return name.contains(q) || orderId.contains(q) || role.contains(q);
            }).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.people_alt_outlined, color: Color(0xFFFF5722), size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Message Customer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textMain,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select a verified partner to open or start a message thread',
                                  style: TextStyle(fontSize: 11.5, color: textSub),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(dialogCtx),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close_rounded, size: 20, color: textSub),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Section Title with Available Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Contacts from Assigned Orders',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textMain),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1EB),
                              borderRadius: BorderRadius.circular(12),
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

                      // Search Customer Input (100% Fully Rounded Stadium Pill)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: TextField(
                            onChanged: (val) => setModalState(() => modalSearch = val),
                            style: const TextStyle(fontSize: 13, color: textMain),
                            cursorColor: primaryColor,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              hintText: 'Search customer by name or order',
                              hintStyle: const TextStyle(fontSize: 12.5, color: textSub),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 14.0, right: 8.0),
                                child: Icon(Icons.search_rounded, size: 18, color: textSub),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contacts List
                      Flexible(
                        child: filteredContacts.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text('No contacts found', style: TextStyle(color: textSub, fontSize: 13)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredContacts.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, idx) {
                                  final contact = filteredContacts[idx];
                                  final isOnline = contact['isOnline'] as bool? ?? false;
                                  final hasAvatarImg = contact['avatar'] != null;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        // Avatar with Online dot
                                        Stack(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (contact['avatarColor'] as Color? ?? const Color(0xFF0284C7))
                                                    .withValues(alpha: 0.15),
                                                border: Border.all(color: cardBorder, width: 1),
                                              ),
                                              child: hasAvatarImg
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(20),
                                                      child: Image.asset(
                                                        contact['avatar'] as String,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, _, _) => Center(
                                                          child: Text(
                                                            contact['initial'] as String? ?? 'C',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        contact['initial'] as String? ?? 'C',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: contact['avatarColor'] as Color? ?? const Color(0xFF10B981),
                                                        ),
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
                                                    border: Border.all(color: Colors.white, width: 1.8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),

                                        // Contact Info (Name, Verified Badge, Role Pill, Order Subtitle)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      contact['name'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: textMain,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.verified_rounded,
                                                    size: 14,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE8F5E9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      contact['role'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF2E7D32),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${contact['orderId']} • Verified Partner',
                                                style: const TextStyle(fontSize: 11, color: textSub),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // + Start Button
                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(dialogCtx);
                                            _startChatWithContact(contact);
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1EB),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: const Color(0xFFFFCCBC)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.person_add_alt_1_rounded, size: 13, color: Color(0xFFFF5722)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Start',
                                                  style: TextStyle(
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
    // Check if conversation already exists in inbox
    final existingIdx = _conversations.indexWhere((c) => c['shipmentId'] == contact['shipmentId']);
    Map<String, dynamic> convItem;
    if (existingIdx != -1) {
      convItem = _conversations[existingIdx];
    } else {
      convItem = {
        'id': 'conv_${DateTime.now().millisecondsSinceEpoch}',
        'name': contact['name'],
        'role': contact['role'],
        'roleType': contact['roleType'] ?? ChatChannelType.customerConsignee,
        'lastMessage': contact['lastMessage'] ?? 'Started a new thread',
        'time': 'Just now',
        'unreadCount': 0,
        'isOnline': contact['isOnline'] ?? true,
        'lastActive': contact['lastActive'] ?? 'Active now',
        'avatar': contact['avatar'] ?? 'assets/images/customer_avatar.png',
        'shipmentId': contact['shipmentId'],
        'originTitle': contact['originTitle'] ?? 'Facility',
        'destTitle': contact['destTitle'] ?? 'Destination Dock',
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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
                    // Circle Button for New Message (no text, pure circle)
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
                          child: Icon(Icons.add_rounded, size: 22, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Search Conversations Bar (100% Fully Rounded Stadium Shape)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
                        child: Icon(Icons.search_rounded, color: textSub, size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: textSub),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Filter Tabs (All / Unread matching screenshot)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    // All Pill
                    GestureDetector(
                      onTap: () => setState(() => _filterIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _filterIndex == 0 ? const Color(0xFFFFF1EB) : searchBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _filterIndex == 0 ? const Color(0xFFFF5722) : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'All (${_conversations.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _filterIndex == 0 ? FontWeight.bold : FontWeight.w600,
                            color: _filterIndex == 0 ? const Color(0xFFFF5722) : textSub,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Unread Pill
                    GestureDetector(
                      onTap: () => setState(() => _filterIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _filterIndex == 1 ? const Color(0xFFFFF1EB) : searchBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _filterIndex == 1 ? const Color(0xFFFF5722) : Colors.transparent,
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
                                fontWeight: _filterIndex == 1 ? FontWeight.bold : FontWeight.w600,
                                color: _filterIndex == 1 ? const Color(0xFFFF5722) : textSub,
                              ),
                            ),
                            if (unreadTotal > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5722),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$unreadTotal',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
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

            const SliverToBoxAdapter(
              child: SizedBox(height: 6),
            ),

            // 4. Empty State (matches screenshot) or Conversations List
            if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredList[index];
                    final isOnline = item['isOnline'] as bool? ?? false;
                    final unreadCount = item['unreadCount'] as int? ?? 0;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _openChat(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
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
                                        border: Border.all(color: cardBorder, width: 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.asset(
                                          item['avatar'] as String,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: primaryColor),
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
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Name & Last Message
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                          color: textMain,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['lastMessage'] as String,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                                color: unreadCount > 0 ? textMain : textSub,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item['time'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                              color: unreadCount > 0 ? primaryColor : textSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Unread Dot Indicator
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0284C7),
                                      shape: BoxShape.circle,
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
                  },
                  childCount: filteredList.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}
