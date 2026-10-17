import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../chat/presentation/screens/chat_inbox_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../onboarding/presentation/widgets/document_verification_modal.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../trips/presentation/screens/driver_reports_screen.dart';
import '../../../trips/presentation/screens/live_tracking_screen.dart';
import '../../../trips/presentation/screens/shipment_details_screen.dart';
import '../../../trips/presentation/screens/trips_screen.dart';
import '../../../../shared/widgets/dashed_vertical_line.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  bool _isComplianceVerified = false; // Driver Compliance Status

  static const Color primaryColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    // Enforce dark status bar icons (time, battery, wifi, network) on light theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Auto-prompt 3-Step Verification Modal on post-login first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isComplianceVerified) {
        _openVerificationModal();
      }
    });
  }

  void _openVerificationModal() {
    DocumentVerificationModal.show(
      context,
      onVerificationComplete: () {
        setState(() {
          _isComplianceVerified = true;
        });
      },
    );
  }

  void _handleTabTap(int index) {
    // If not verified and trying to access Shipments (1), Live Chat (2), or Notifications (3)
    if (!_isComplianceVerified && (index == 1 || index == 2 || index == 3)) {
      _showAccessDeniedModal(index);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Gatekeeper Bottom Sheet Modal when clicking locked tabs
  void _showAccessDeniedModal(int targetIndex) {
    String tabName = 'Shipments & Loads';
    if (targetIndex == 1) {
      tabName = 'Shipments & Loads';
    } else if (targetIndex == 2) {
      tabName = 'Live Dispatch & Customer Chat';
    } else if (targetIndex == 3) {
      tabName = 'Dispatch Notifications';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Color(0xFFD97706),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Driver Verification Required',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You must complete your mandatory compliance verification (Govt ID, CDL License & Medical Card) to access $tabName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openVerificationModal();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Complete Verification (3 Steps)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardHome(),
      const TripsScreen(showBackButton: false),
      const ChatInboxScreen(),
      const NotificationsScreen(),
      const ProfileScreen(showBackButton: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[_currentIndex >= screens.length ? 0 : _currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex >= screens.length ? 0 : _currentIndex,
          onTap: _handleTabTap,
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF65676B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.home_rounded, size: 22),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.local_shipping_outlined, size: 20),
              ),
              label: 'Shipments',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.forum_outlined, size: 20),
              ),
              label: 'Live Chat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.notifications_none_rounded, size: 20),
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.person_outline_rounded, size: 20),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Row (Driver Avatar, Greeting, Online Toggle & Notification Bell)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Avatar + Greeting & Name (Tapping opens Profile Tab)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleTabTap(4),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  'assets/images/driver_avatar.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: primaryColor.withValues(alpha: 0.12),
                                      child: const Icon(Icons.person_rounded, color: primaryColor, size: 24),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back,',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Driver ',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Captain 👋',
                                      style: TextStyle(
                                        color: Color(0xFFFF5722),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
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
                ),

                // Right: Status Pill & Notification Bell
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Pill Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isOnline = !_isOnline;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isOnline
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: _isOnline ? const Color(0xFF065F46) : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Direct Chat with Parties Button
                    GestureDetector(
                      onTap: () {
                        _handleTabTap(2); // Switch to Live Chat Tab
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.forum_outlined,
                                color: Color(0xFF334155),
                                size: 18,
                              ),
                            ),
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0284C7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Notification Bell Icon with Badge
                    GestureDetector(
                      onTap: () {
                        _handleTabTap(3); // Switch to Notifications Tab
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF0F172A),
                                size: 20,
                              ),
                            ),
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Today's Overview (4 Stat Cards)
            const Text(
              "Today's Overview",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Active Loads",
                    value: "2 Loads",
                    icon: Icons.inventory_2_outlined,
                    iconColor: Color(0xFFFF5722),
                    cardBgColor: Color(0xFFFFF7F2),
                    borderColor: Color(0xFFFFE5D8),
                    iconBgColor: Color(0xFFFFECE2),
                    subtitle: "In dispatch transit",
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: "Trips Completed",
                    value: "8 Orders",
                    icon: Icons.local_shipping_rounded,
                    iconColor: Color(0xFF059669),
                    cardBgColor: Color(0xFFF0FDF4),
                    borderColor: Color(0xFFDCFCE7),
                    iconBgColor: Color(0xFFDCFCE7),
                    subtitle: "2 scheduled",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Distance",
                    value: "142.6 km",
                    icon: Icons.route_rounded,
                    iconColor: Color(0xFF0284C7),
                    cardBgColor: Color(0xFFF0F9FF),
                    borderColor: Color(0xFFE0F2FE),
                    iconBgColor: Color(0xFFE0F2FE),
                    subtitle: "Today's drive",
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: "Driver Rating",
                    value: "4.95 ★",
                    icon: Icons.star_rounded,
                    iconColor: Color(0xFFD97706),
                    cardBgColor: Color(0xFFFFFBEB),
                    borderColor: Color(0xFFFEF3C7),
                    iconBgColor: Color(0xFFFEF3C7),
                    subtitle: "52 reviews",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Quick Logistics Shortcuts Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickToolButton(
                    icon: Icons.alt_route_rounded,
                    label: 'Navigation',
                    color: const Color(0xFF0284C7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveTrackingScreen(
                            shipment: ShipmentItem(
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickToolButton(
                    icon: Icons.local_shipping_outlined,
                    label: 'My Shipments',
                    color: const Color(0xFFFF5722),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TripsScreen(showBackButton: true),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickToolButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverReportsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. My Shipments Section (Hero Active Card)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Shipments",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1; // Switch to Shipments tab
                    });
                  },
                  child: const Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFFFF5722),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFFFF5722), size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Premium Hero Active Shipment Card
            _buildActiveShipmentHeroCard(),

            const SizedBox(height: 16),

            // 5. Today's Schedule Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Schedule",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1; // Switch to Shipments tab
                    });
                  },
                  child: const Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFFFF5722),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFFFF5722), size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Schedule Item (1 Card)
            _buildScheduleCard(
              time: '04:30 PM',
              tripId: 'TRP-4899',
              cargoType: 'Dry Van 53ft',
              origin: 'JFK Air Cargo Zone 3, Gate 5',
              destination: 'Brooklyn Logistics Center',
              status: 'Scheduled',
              statusColor: const Color(0xFFD97706),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveShipmentHeroCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          '#SHP-987654',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Text(
                          'Reefer -18°C',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text(
                    'In Transit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),

          // Route Visual Path
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.radio_button_checked_rounded, color: Color(0xFFEA580C), size: 15),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'ABC Warehouse Logistics (Bay 4)',
                             style: TextStyle(
                               fontSize: 13.5,
                               fontWeight: FontWeight.w700,
                               color: Color(0xFF0F172A),
                               letterSpacing: -0.2,
                             ),
                           ),
                           SizedBox(height: 2),
                           Text(
                             'Port Logistics Park, Seattle WA',
                             style: TextStyle(
                               fontSize: 12,
                               fontWeight: FontWeight.w400,
                               color: Color(0xFF64748B),
                               height: 1.3,
                             ),
                           ),
                         ],
                      ),
                    ),
                  ],
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: DashedVerticalLine(
                      iconWidth: 15,
                      height: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 15),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starlight Supermarket Central (Dock 12)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '742 Evergreen Terrace, Seattle WA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons Bar (5px radius)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(5.0)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveTrackingScreen(
                              shipment: ShipmentItem(
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
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text(
                        'GPS Navigation',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShipmentDetailsScreen(
                              shipment: ShipmentItem(
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
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 14),
                      label: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String time,
    required String tripId,
    required String cargoType,
    required String origin,
    required String destination,
    required String status,
    required Color statusColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipmentDetailsScreen(
              shipment: ShipmentItem(
                id: tripId,
                originTitle: origin,
                originAddress: 'Gate 5, Terminal Cargo Hub, NY',
                destTitle: destination,
                destAddress: '742 5th Avenue, New York, USA',
                distanceKm: 28.4,
                cargoType: cargoType,
                status: ShipmentFilter.scheduled,
                statusLabel: status,
                time: time,
                date: 'Today',
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EB),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFFF5722)),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Color(0xFFFF5722),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '#$tripId',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    cargoType,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.trip_origin_rounded, color: Color(0xFFFF5722), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    origin,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: DashedVerticalLine(
                  iconWidth: 14,
                  height: 12,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
