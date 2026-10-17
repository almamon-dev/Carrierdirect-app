import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../data/datasources/notifications_mock_data_source.dart';
import '../../data/models/notification_model.dart';
import 'notification_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0;
  List<NotificationModel> _notifications = [];

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color searchBg = Color(0xFFF1F5F9);
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;
  static const Color accentOrange = Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = NotificationsMockDataSource.getNotifications();
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get _filteredNotifications {
    var list = _notifications;

    // Filter by Tab
    switch (_selectedFilterIndex) {
      case 1: // Unread
        list = list.where((n) => !n.isRead).toList();
        break;
      case 2: // Dock & Bay
        list = list.where((n) => n.category == NotificationCategory.dockSecurity).toList();
        break;
      case 3: // Paperwork (BOL)
        list = list.where((n) => n.category == NotificationCategory.paperworkBol).toList();
        break;
      case 4: // Loads
        list = list.where((n) => n.category == NotificationCategory.loadAssignment).toList();
        break;
      case 5: // Alerts
        list = list.where((n) =>
            n.category == NotificationCategory.trafficAlert ||
            n.category == NotificationCategory.complianceSafety).toList();
        break;
      default: // 0 -> All
        break;
    }

    // Filter by Search Query
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((n) {
      final title = n.title.toLowerCase();
      final msg = n.message.toLowerCase();
      final body = n.detailedBody.toLowerCase();
      final shipId = (n.shipmentId ?? '').toLowerCase();
      final sender = (n.senderName ?? '').toLowerCase();
      final loc = (n.locationName ?? '').toLowerCase();
      return title.contains(q) ||
          msg.contains(q) ||
          body.contains(q) ||
          shipId.contains(q) ||
          sender.contains(q) ||
          loc.contains(q);
    }).toList();
  }

  void _openDetails(NotificationModel notif) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailsScreen(
          notification: notif,
          onDeleted: () => _loadNotifications(),
        ),
      ),
    ).then((_) => _loadNotifications());
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.dockSecurity:
        return const Color(0xFFEA580C);
      case NotificationCategory.paperworkBol:
        return const Color(0xFF0284C7);
      case NotificationCategory.trafficAlert:
        return const Color(0xFFEF4444);
      case NotificationCategory.loadAssignment:
        return const Color(0xFFD97706);
      case NotificationCategory.complianceSafety:
        return const Color(0xFF10B981);
      case NotificationCategory.chatMessage:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.dockSecurity:
        return Icons.warehouse_rounded;
      case NotificationCategory.paperworkBol:
        return Icons.description_rounded;
      case NotificationCategory.trafficAlert:
        return Icons.warning_amber_rounded;
      case NotificationCategory.loadAssignment:
        return Icons.local_shipping_rounded;
      case NotificationCategory.complianceSafety:
        return Icons.verified_user_rounded;
      case NotificationCategory.chatMessage:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _getCategoryPillName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.dockSecurity:
        return 'Dock & Bay';
      case NotificationCategory.paperworkBol:
        return 'Digital BOL';
      case NotificationCategory.trafficAlert:
        return 'Traffic Alert';
      case NotificationCategory.loadAssignment:
        return 'Load Assigned';
      case NotificationCategory.complianceSafety:
        return 'Safety & DVIR';
      case NotificationCategory.chatMessage:
        return 'Live Dispatch';
    }
  }

  void _markAllAsRead() {
    setState(() {
      NotificationsMockDataSource.markAllAsRead();
      _loadNotifications();
    });
    AppToast.info(context, 'All notifications marked as read');
  }

  Widget _buildFilterPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1EB) : searchBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentOrange : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? accentOrange : textSub,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: accentOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadTotal = _unreadCount;
    final displayList = _filteredNotifications;

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header: Notifications Title + Circle Button (matching Messages Header)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (unreadTotal > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadTotal',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Circular Action Button (Mark All Read)
                    InkWell(
                      onTap: unreadTotal > 0 ? _markAllAsRead : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: unreadTotal > 0 ? primaryColor : searchBg,
                          shape: BoxShape.circle,
                          boxShadow: unreadTotal > 0
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.done_all_rounded,
                            size: 20,
                            color: unreadTotal > 0 ? Colors.white : textSub,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Search Notifications Bar (100% Fully Rounded Stadium Shape)
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
                      hintText: 'Search notifications or loads',
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

            // 3. Filter Tabs (All / Unread / Categories matching Messages style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterPill(
                        title: 'All (${_notifications.length})',
                        isSelected: _selectedFilterIndex == 0,
                        onTap: () => setState(() => _selectedFilterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        title: 'Unread',
                        count: unreadTotal,
                        isSelected: _selectedFilterIndex == 1,
                        onTap: () => setState(() => _selectedFilterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        title: 'Dock & Bay',
                        isSelected: _selectedFilterIndex == 2,
                        onTap: () => setState(() => _selectedFilterIndex = 2),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        title: 'Paperwork',
                        isSelected: _selectedFilterIndex == 3,
                        onTap: () => setState(() => _selectedFilterIndex = 3),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        title: 'Loads',
                        isSelected: _selectedFilterIndex == 4,
                        onTap: () => setState(() => _selectedFilterIndex = 4),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        title: 'Alerts',
                        isSelected: _selectedFilterIndex == 5,
                        onTap: () => setState(() => _selectedFilterIndex = 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 6),
            ),

            // 4. Notifications List or Empty State
            if (displayList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No notifications found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You are all caught up with your logistics\nalerts, dock clearances and load updates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSub,
                            height: 1.4,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedFilterIndex != 0) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilterIndex = 0;
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset filters'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: const BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notif = displayList[index];
                    final catColor = _getCategoryColor(notif.category);
                    final catIcon = _getCategoryIcon(notif.category);
                    final isUrgent = notif.priority == NotificationPriority.urgent;

                    return Column(
                      children: [
                        Dismissible(
                          key: Key(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: const Color(0xFFEF4444),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            NotificationsMockDataSource.deleteNotification(notif.id);
                            _loadNotifications();
                            AppToast.info(context, 'Notification removed');
                          },
                          child: InkWell(
                            onTap: () => _openDetails(notif),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Leading Category Icon Container (48x48)
                                  Stack(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: catColor.withValues(alpha: 0.12),
                                          border: Border.all(
                                            color: notif.isRead ? cardBorder : catColor.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(catIcon, color: catColor, size: 22),
                                        ),
                                      ),
                                      if (isUrgent)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.priority_high_rounded, size: 9, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Notification Content & Metadata
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Row 1: Title + Timestamp
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                  color: textMain,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              notif.timeAgo,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                                color: notif.isRead ? textSub : primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),

                                        // Row 2: Message preview
                                        Text(
                                          notif.message,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w500,
                                            color: notif.isRead ? textSub : textMain.withValues(alpha: 0.9),
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 7),

                                        // Row 3: Meta Tag Pills + Unread Dot
                                        Row(
                                          children: [
                                            // Category Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: catColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(catIcon, size: 10.5, color: catColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _getCategoryPillName(notif.category),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: catColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (notif.shipmentId != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: searchBg,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '#${notif.shipmentId}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: textSub,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            // Unread Dot Indicator (matching Messages)
                                            if (!notif.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: accentOrange,
                                                  shape: BoxShape.circle,
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
                        ),
                        // Separator matching Messages
                        const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 1,
                          thickness: 1,
                          indent: 76,
                        ),
                      ],
                    );
                  },
                  childCount: displayList.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
