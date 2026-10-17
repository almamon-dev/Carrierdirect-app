import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../trips/presentation/screens/trips_screen.dart';

class DispatchSupportModal extends StatelessWidget {
  const DispatchSupportModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DispatchSupportModal(),
    );
  }

  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              const Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: primaryOrange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Driver Support & Help Desk',
                    style: TextStyle(
                      color: slate900,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Instant access to live dispatch, email help, FAQs & safety guide.',
                style: TextStyle(color: slate500, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // 1. Live Chat
              _buildSupportOption(
                context: context,
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFF0F9FF),
                title: 'Live Dispatch Chat',
                subtitle: 'Real-time 24/7 messaging with your dispatcher',
                badgeText: 'ONLINE',
                badgeColor: const Color(0xFF059669),
                onTap: () {
                  Navigator.pop(context);
                  ChatScreen.openForShipment(
                    context,
                    shipment: const ShipmentItem(
                      id: 'SHP-987654',
                      status: ShipmentFilter.inProgress,
                      originTitle: 'ABC Warehouse Logistics',
                      originAddress: 'Bay 4, Port Logistics Park',
                      destTitle: 'Starlight Supermarket Central',
                      destAddress: 'Dock 12, 742 Evergreen Terrace',
                      date: 'Today',
                      time: '04:30 PM',
                      cargoType: 'Refrigerated Dairy & Goods',
                      distanceKm: 42.8,
                      statusLabel: 'In Transit',
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // 2. Support Email
              _buildSupportOption(
                context: context,
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF5F3FF),
                title: 'Support Email',
                subtitle: 'support@carrierdirect.com (Tap to copy)',
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'support@carrierdirect.com'));
                  Navigator.pop(context);
                  AppToast.success(context, 'Copied support@carrierdirect.com to clipboard');
                },
              ),
              const SizedBox(height: 10),

              // 3. Driver FAQ
              _buildSupportOption(
                context: context,
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFFFBEB),
                title: 'Frequently Asked Questions',
                subtitle: 'Answers for CDL, delay procedures & payouts',
                onTap: () {
                  Navigator.pop(context);
                  _showFaqSheet(context);
                },
              ),
              const SizedBox(height: 10),

              // 4. Safety Guide
              _buildSupportOption(
                context: context,
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFECFDF5),
                title: 'Driver Safety & Compliance Guide',
                subtitle: 'FMCSA rules, inspection checklist & emergency tips',
                onTap: () {
                  Navigator.pop(context);
                  _showSafetyGuideSheet(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: slate50,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: slate200),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6.0),
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
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: slate900,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? const Color(0xFF059669)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor ?? const Color(0xFF059669),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: slate500,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: slate500, size: 20),
          ],
        ),
      ),
    );
  }

  static void _showFaqSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      color: slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Driver FAQs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildGuideCard(
                  'How do I update my CDL or Fleet Insurance?',
                  'Go to your Profile screen, tap the Documents tab, and click the three dots (⋮) on any document to upload the latest copy.',
                ),
                const SizedBox(height: 8),
                _buildGuideCard(
                  'What should I do in case of delay or weather issue?',
                  'Open Live Dispatch Chat immediately to log your delay so detention pay and appointment rescheduling are handled automatically.',
                ),
                const SizedBox(height: 8),
                _buildGuideCard(
                  'When will my trip earnings be processed?',
                  'Earnings are released within 24 hours of uploading a clear Proof of Delivery (POD) photo with verified receiver signature.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                    ),
                    child: const Text('Got It'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showSafetyGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      color: slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Safety & Compliance Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildGuideCard(
                  'Pre-Trip Vehicle Inspection',
                  'Always check tire pressure, brake systems, cargo tie-downs, and trailer light connections before departure.',
                ),
                const SizedBox(height: 8),
                _buildGuideCard(
                  'Hours of Service (HOS) & Rest Breaks',
                  'Comply with the 11-hour driving limit and 10-hour off-duty rule. Take a 30-minute break after 8 hours of driving.',
                ),
                const SizedBox(height: 8),
                _buildGuideCard(
                  'Emergency Roadside Protocol',
                  'Turn on hazard lights immediately, place warning triangles 10ft, 100ft, and 200ft behind your truck, and notify dispatch via chat.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                    ),
                    child: const Text('Understood'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildGuideCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: slate50,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: slate500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
