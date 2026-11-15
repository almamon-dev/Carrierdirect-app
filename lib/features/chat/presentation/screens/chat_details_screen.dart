import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/chat_channel_model.dart';
import '../../data/models/chat_message_model.dart';

class ChatDetailsScreen extends StatefulWidget {
  final ChatChannel channel;
  final String shipmentId;
  final String originTitle;
  final String destTitle;
  final VoidCallback onClearChat;
  final Future<void> Function(ChatMessage msg)? onTogglePin;

  const ChatDetailsScreen({
    super.key,
    required this.channel,
    required this.shipmentId,
    required this.originTitle,
    required this.destTitle,
    required this.onClearChat,
    this.onTogglePin,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  int _activeTabIndex = 0; // 0: Profile, 1: Pinned, 2: Photos, 3: Docs

  static const Color primaryColor = AppColors.primary;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color verifiedGreen = Color(0xFF059669);
  static const Color tealGreen = Color(0xFF0D9488);
  static const Color accentOrange = Color(0xFFFF5722);

  bool _isNetworkUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String get _accountType {
    if (widget.channel.participantRoleTitle.isNotEmpty) {
      return widget.channel.participantRoleTitle;
    }
    switch (widget.channel.type) {
      case ChatChannelType.supplierWarehouse:
        return 'Supplier (Carrier)';
      case ChatChannelType.customerConsignee:
        return 'Customer (Shipper)';
      case ChatChannelType.centralDispatch:
        return 'Central Dispatch';
    }
  }

  Widget _buildAvatarContent() {
    final avatar = widget.channel.avatarUrl;
    if (_isNetworkUrl(avatar)) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 38,
              color: Color(0xFF475569),
            ),
          ),
        ),
      );
    }
    if (avatar.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          avatar,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 38,
              color: Color(0xFF475569),
            ),
          ),
        ),
      );
    }
    return const Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: 38,
        color: Color(0xFF475569),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: textMain,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.channel.participantName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Profile & Avatar Section (matching Web)
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F1F8),
                            shape: BoxShape.circle,
                          ),
                          child: _buildAvatarContent(),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: widget.channel.isOnline
                                  ? verifiedGreen
                                  : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.channel.participantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.channel.isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: verifiedGreen,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    Text(
                      _accountType,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: textSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Tab Navigation Icons (Profile, Pinned, Photos, Docs)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabItem(
                    index: 0,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                  _buildTabItem(
                    index: 1,
                    icon: Icons.push_pin_outlined,
                    activeIcon: Icons.push_pin_rounded,
                    label: 'Pinned',
                  ),
                  _buildTabItem(
                    index: 2,
                    icon: Icons.photo_outlined,
                    activeIcon: Icons.photo_rounded,
                    label: 'Photos',
                  ),
                  _buildTabItem(
                    index: 3,
                    icon: Icons.description_outlined,
                    activeIcon: Icons.description_rounded,
                    label: 'Docs',
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 18),

              // 3. Tab Content
              if (_activeTabIndex == 0) ...[
                const Text(
                  'Partner Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDetailRow(
                  icon: Icons.apartment_rounded,
                  label: 'Company',
                  valueWidget: Text(
                    widget.channel.companyName.isNotEmpty
                        ? widget.channel.companyName
                        : widget.channel.participantName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Rating',
                  valueWidget: const Row(
                    children: [
                      Text(
                        '5.0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '(Verified)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.inventory_2_outlined,
                  iconColor: tealGreen,
                  label: 'Orders Done',
                  valueWidget: Row(
                    children: [
                      Text(
                        widget.channel.type == ChatChannelType.supplierWarehouse
                            ? '94+'
                            : '42+',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        '(100% Fulfilled)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tealGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF0284C7),
                  label: 'On-Time Rate',
                  valueWidget: const Row(
                    children: [
                      Text(
                        '99.2%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        '(Reliable)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFFEA580C),
                  label: 'Response Time',
                  valueWidget: const Row(
                    children: [
                      Text(
                        '< 15 mins',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        '(Fast)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tealGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Account Type',
                  valueWidget: Text(
                    _accountType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: tealGreen,
                  label: 'Platform Status',
                  valueWidget: const Text(
                    'Active & Verified',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tealGreen,
                    ),
                  ),
                ),
                _buildDetailRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: tealGreen,
                  label: 'Coverage',
                  valueWidget: const Text(
                    '100% Insured Deals',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: tealGreen,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Platform Protected Communication',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: tealGreen,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'All quote requests, shipments, and messages transmitted inside CarrierDirect are secured with guaranteed payment and dispute protection.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_activeTabIndex == 1) ...[
                _buildPinnedTab(),
              ] else if (_activeTabIndex == 2) ...[
                _buildPhotosTab(),
              ] else ...[
                _buildDocsTab(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedTab() {
    final pinnedMsgs = widget.channel.messages
        .where((m) => m.isPinned && !m.isUnsent)
        .toList();

    if (pinnedMsgs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.push_pin_outlined,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 10),
              Text(
                'No Pinned Messages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pin important messages or order updates to find them easily.',
                style: TextStyle(fontSize: 11.5, color: textSub),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pinnedMsgs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final msg = pinnedMsgs[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.push_pin_rounded,
                size: 16,
                color: accentOrange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          msg.isFromDriver
                              ? 'You'
                              : widget.channel.participantName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                        Text(
                          msg.formattedTime,
                          style: const TextStyle(fontSize: 11, color: textSub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.message.isNotEmpty
                          ? msg.message
                          : (msg.attachmentName ?? 'Pinned Attachment'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onTogglePin != null)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: textSub,
                  ),
                  onPressed: () async {
                    await widget.onTogglePin!(msg);
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _activeTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? accentOrange : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? accentOrange : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: iconColor ?? const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    final List<String> photoUrls = [];
    for (final m in widget.channel.messages) {
      if (m.isUnsent) continue;
      if (m.attachments.isNotEmpty) {
        for (final a in m.attachments) {
          if (a.isImage && a.url.isNotEmpty) {
            photoUrls.add(a.url);
          }
        }
      } else if (m.attachmentType == MessageAttachmentType.image &&
          m.attachmentUrl != null &&
          m.attachmentUrl!.isNotEmpty) {
        photoUrls.add(m.attachmentUrl!);
      }
    }

    if (photoUrls.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_outlined, size: 36, color: Color(0xFF94A3B8)),
              SizedBox(height: 10),
              Text(
                'No Photos Shared',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Photos and dock images sent in this thread will appear here.',
                style: TextStyle(fontSize: 11.5, color: textSub),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photoUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final url = photoUrls[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _isNetworkUrl(url)
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: textSub,
                    ),
                  ),
                )
              : (url.startsWith('assets/')
                    ? Image.asset(url, fit: BoxFit.cover)
                    : Image.file(
                        File(url),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: textSub,
                          ),
                        ),
                      )),
        );
      },
    );
  }

  Widget _buildDocsTab() {
    final List<ChatAttachmentItem> docs = [];
    for (final m in widget.channel.messages) {
      if (m.isUnsent) continue;
      if (m.attachments.isNotEmpty) {
        for (final a in m.attachments) {
          if (!a.isImage) {
            docs.add(a);
          }
        }
      } else if (m.attachmentType == MessageAttachmentType.document) {
        docs.add(
          ChatAttachmentItem(
            name: m.attachmentName ?? 'Document',
            url: m.attachmentUrl ?? '',
            type: 'file',
          ),
        );
      }
    }

    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 10),
              Text(
                'No Documents Shared',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Freight documents, invoices, and BOLs sent in this thread will appear here.',
                style: TextStyle(fontSize: 11.5, color: textSub),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFEF4444),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.size != null && doc.size!.isNotEmpty
                          ? 'Shared document • ${doc.size}'
                          : 'Shared freight document',
                      style: const TextStyle(fontSize: 11, color: textSub),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.download_rounded, color: primaryColor, size: 20),
            ],
          ),
        );
      },
    );
  }
}
