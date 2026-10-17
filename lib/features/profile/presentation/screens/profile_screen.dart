import 'package:flutter/material.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/file_upload_helper.dart';
import '../../../../shared/utils/logout_helper.dart';
import '../../../onboarding/presentation/widgets/document_verification_modal.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/dispatch_support_modal.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0; // 0: Personal Info, 1: Documents

  // Driver Status state
  bool _isOnline = true;
  String _driverStatus = 'Online';

  // Preferences state
  bool _pushNotifications = true;
  bool _locationSharing = true;

  // Driver info
  final String _driverName = 'Michael Smith';
  final String _driverRole = 'Driver';
  final String _phoneNumber = '+1 234 567 8900';
  final String _emailAddress = 'michael.smith@gmail.com';
  final String _physicalAddress = 'Dublin, Ireland';

  // Stats
  final String _totalTrips = '248';
  final String _rating = '4.95';
  final String _yearsExp = '1.2+';
  final String _completionRate = '100%';

  // Design Tokens (exact match to user mockup)
  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color orangeLightBg = Color(0xFFFFF7ED);
  static const Color orangeLightBorder = Color(0xFFFFEDD5);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  static const Color successGreen = Color(0xFF059669);
  static const Color successGreenLight = Color(0xFFECFDF5);
  static const Color successGreenBorder = Color(0xFFA7F3D0);

  // Exactly the 3 documents from user screenshot
  final List<Map<String, dynamic>> _documentsList = [
    {
      'title': 'Driver License',
      'fullTitle': 'Commercial Driver License',
      'icon': Icons.credit_card_outlined,
      'iconBg': const Color(0xFFEFF6FF),
      'iconBorder': const Color(0xFFBFDBFE),
      'iconColor': const Color(0xFF2563EB),
      'isVerified': true,
      'status': 'Verified',
      'number': 'TX-CDL-89420-A',
      'expiry': 'Oct 2028',
      'hasFrontBack': true,
    },
    {
      'title': 'Medical Certificate',
      'fullTitle': 'DOT Medical Examiner Certificate',
      'icon': Icons.article_outlined,
      'iconBg': const Color(0xFFECFDF5),
      'iconBorder': const Color(0xFFA7F3D0),
      'iconColor': const Color(0xFF059669),
      'isVerified': false,
      'status': 'Pending',
      'number': 'DOT-MED-Pending',
      'expiry': 'Pending Upload',
      'hasFrontBack': false,
    },
    {
      'title': 'Fleet Insurance',
      'fullTitle': 'Commercial Fleet Insurance',
      'icon': Icons.shield_outlined,
      'iconBg': const Color(0xFFF5F3FF),
      'iconBorder': const Color(0xFFDDD6FE),
      'iconColor': const Color(0xFF7C3AED),
      'isVerified': false,
      'status': 'Pending',
      'number': 'INS-COI-Pending',
      'expiry': 'Pending Upload',
      'hasFrontBack': false,
    },
  ];

  void _openDocumentSidePreview({required String title, required String side}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(Icons.credit_card_outlined, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title ($side Side)',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: slate900),
                          ),
                          const SizedBox(height: 2),
                          const Text('Verified & active on record', style: TextStyle(fontSize: 11.5, color: successGreen)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: slate500),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: slate50,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: slate200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge_outlined, size: 52, color: Color(0xFF2563EB)),
                      const SizedBox(height: 10),
                      Text(
                        'CDL Document ($side Side Preview)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate700),
                      ),
                      const SizedBox(height: 4),
                      const Text('Resolution: High Definition • Verified Clear', style: TextStyle(fontSize: 11, color: slate500)),
                    ],
                  ),
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
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDocumentPreview(Map<String, dynamic> doc) {
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: orangeLightBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(doc['icon'] as IconData, color: primaryOrange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (doc['fullTitle'] ?? doc['title']) as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc['isVerified'] == true ? 'Document Verified' : 'Pending Upload',
                            style: TextStyle(
                              fontSize: 12,
                              color: doc['isVerified'] == true ? successGreen : slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: successGreenLight,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: successGreenBorder),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: slate200),
                  ),
                  child: Column(
                    children: [
                      _buildModalInfoRow('Document Status', 'Active & Verified (Compliant)'),
                      const Divider(height: 16, color: slate200),
                      _buildModalInfoRow('Expiration / Validity', doc['expiry'] as String),
                      const Divider(height: 16, color: slate200),
                      _buildModalInfoRow('Verification Authority', 'CarrierDirect Fleet Compliance'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          DocumentVerificationModal.show(
                            context,
                            onVerificationComplete: () {
                              AppToast.success(context, 'Compliance updated!');
                            },
                          );
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Update Document'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryOrange,
                          side: const BorderSide(color: primaryOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: slate500)),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: slate900),
        ),
      ],
    );
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Driver Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: slate900,
                  ),
                ),
                const SizedBox(height: 14),
                _buildStatusOption(
                  title: 'Online',
                  subtitle: 'Available to receive new dispatch loads and orders',
                  color: const Color(0xFF10B981),
                  isSelected: _isOnline && _driverStatus == 'Online',
                  onTap: () {
                    setState(() {
                      _isOnline = true;
                      _driverStatus = 'Online';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildStatusOption(
                  title: 'Busy / On Trip',
                  subtitle: 'Currently delivering an active shipment',
                  color: const Color(0xFFF59E0B),
                  isSelected: _isOnline && _driverStatus == 'Busy / On Trip',
                  onTap: () {
                    setState(() {
                      _isOnline = true;
                      _driverStatus = 'Busy / On Trip';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildStatusOption(
                  title: 'Offline',
                  subtitle: 'Unavailable for new trips or notifications',
                  color: slate400,
                  isSelected: !_isOnline,
                  onTap: () {
                    setState(() {
                      _isOnline = false;
                      _driverStatus = 'Offline';
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : slate200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                      fontWeight: FontWeight.w700,
                      color: isSelected ? slate900 : slate700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: slate500)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildTopAppBar(),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver Profile Header Card
                    _buildProfileHeaderCard(),
                    const SizedBox(height: 12),

                    // 4-Column Stat Bar
                    _buildStatBar(),
                    const SizedBox(height: 16),

                    // Tab Segmented Selector (Personal Info & Documents)
                    _buildSegmentedTabBar(),
                    const SizedBox(height: 16),

                    // Content View based on Tab
                    if (_selectedTabIndex == 0) ...[
                      // Card 1: Personal Information
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 14),

                      // Card 2: Driver Status
                      _buildDriverStatusCard(),
                      const SizedBox(height: 14),

                      // Card 3: Documents & Verification
                      _buildDocumentsCard(),
                      const SizedBox(height: 14),

                      // Card 4: Account & Preferences
                      _buildAccountPreferencesCard(),
                      const SizedBox(height: 14),

                      // Card 5: Support Section (from mockup)
                      _buildSupportCard(),
                      const SizedBox(height: 18),
                    ] else ...[
                      // Dedicated Documents Tab View
                      _buildFullDocumentsView(),
                      const SizedBox(height: 18),
                    ],

                    // Log Out Action Button
                    _buildLogoutButton(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. TOP APP BAR
  // =========================================================================
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.showBackButton)
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 14.0),
                    child: Icon(Icons.arrow_back, size: 22, color: slate900),
                  ),
                ),
              const Text(
                'Driver Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: slate900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 22, color: slate900),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => LogoutHelper.showLogoutDialog(context),
                icon: const Icon(Icons.logout_rounded, size: 21, color: Color(0xFFDC2626)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Log Out',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Full-width Log Out Button (Clean, Red/Rose Accent)
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => LogoutHelper.showLogoutDialog(context),
          borderRadius: BorderRadius.circular(6.0),
          splashColor: const Color(0xFFFEE2E2),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. DRIVER PROFILE HEADER CARD
  // =========================================================================
  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with Camera Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: slate100,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/driver_avatar.png',
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_rounded, size: 38, color: primaryOrange);
                    },
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final file = await FileUploadHelper.pickFileOrPhoto(
                      context,
                      title: 'Update Profile Photo',
                    );
                    if (file != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Profile photo updated: ${file.name}')),
                      );
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: slate200, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_outlined, size: 12.5, color: slate600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name, Subtitle and Status Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _driverName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: slate900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _driverRole,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: slate500,
                  ),
                ),
                const SizedBox(height: 6),

                // Status Pill Dropdown
                GestureDetector(
                  onTap: _showStatusBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _isOnline ? successGreenLight : slate100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isOnline ? successGreenBorder : slate200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: BoxDecoration(
                            color: _isOnline ? const Color(0xFF10B981) : slate400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isOnline ? _driverStatus : 'Offline',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _isOnline ? successGreen : slate600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _isOnline ? successGreen : slate600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit Profile Action Button
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: orangeLightBg,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: orangeLightBorder, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 13, color: primaryOrange),
                  SizedBox(width: 4),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: primaryOrange,
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

  // =========================================================================
  // 3. STAT BAR (4 Metrics)
  // =========================================================================
  Widget _buildStatBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Trips
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFFEA580C),
              iconBg: const Color(0xFFFFF7ED),
              value: _totalTrips,
              label: 'Total Trips',
            ),
          ),
          _buildVerticalStatDivider(),

          // Rating
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_outline_rounded,
              iconColor: const Color(0xFFEAB308),
              iconBg: const Color(0xFFFEFCE8),
              value: _rating,
              label: 'Rating',
            ),
          ),
          _buildVerticalStatDivider(),

          // Years
          Expanded(
            child: _buildStatItem(
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFEFF6FF),
              value: _yearsExp,
              label: 'Years',
            ),
          ),
          _buildVerticalStatDivider(),

          // Completion
          Expanded(
            child: _buildStatItem(
              icon: Icons.verified_user_outlined,
              iconColor: successGreen,
              iconBg: successGreenLight,
              value: _completionRate,
              label: 'Completion',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: slate900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: slate100,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  // =========================================================================
  // 4. SEGMENTED TAB BAR
  // =========================================================================
  Widget _buildSegmentedTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: slate200, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Tab 1: Personal Info
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0 ? primaryOrange : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: _selectedTabIndex == 0 ? primaryOrange : slate500,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Personal Info',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedTabIndex == 0 ? primaryOrange : slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 2: Documents
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1 ? primaryOrange : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: _selectedTabIndex == 1 ? primaryOrange : slate500,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedTabIndex == 1 ? primaryOrange : slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. CARD 1: PERSONAL INFORMATION
  // =========================================================================
  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: primaryOrange, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: slate900,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: slate50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: slate200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 12, color: slate600),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: slate600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detail Rows
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: _driverName,
          ),
          const SizedBox(height: 13),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Number',
            value: _phoneNumber,
          ),
          const SizedBox(height: 13),
          _buildInfoRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: _emailAddress,
          ),
          const SizedBox(height: 13),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _physicalAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: slate500),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: slate500,
            ),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: slate800,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: slate900,
              height: 1.35,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 6. CARD 2: DRIVER STATUS
  // =========================================================================
  Widget _buildDriverStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: successGreen, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Driver Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: slate900,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _isOnline,
                      onChanged: (val) {
                        setState(() {
                          _isOnline = val;
                          _driverStatus = val ? 'Online' : 'Offline';
                        });
                      },
                      activeThumbColor: const Color(0xFF10B981),
                      activeTrackColor: successGreenBorder,
                      inactiveThumbColor: slate400,
                      inactiveTrackColor: slate200,
                    ),
                  ),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _isOnline ? successGreen : slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Informational Status Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _isOnline ? successGreenLight : slate50,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: _isOnline ? successGreenBorder : slate200,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF10B981) : slate400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline
                            ? 'You are online and available for new loads'
                            : 'You are currently offline',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isOnline
                            ? 'Turn off when you are not available'
                            : 'Turn on when you are ready to accept trips',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. CARD 3: DOCUMENTS & VERIFICATION
  // =========================================================================
  Widget _buildDocumentsCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.description_outlined, color: primaryOrange, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Documents & Verification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: slate900,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedTabIndex = 1);
                },
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryOrange,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: primaryOrange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Required App Documents: exactly the 3 documents from screenshot
          ..._documentsList.map((doc) => _buildDocumentItem(doc)),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final bool isVerified = doc['isVerified'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _openDocumentPreview(doc),
        borderRadius: BorderRadius.circular(6.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: doc['iconBg'] as Color,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: doc['iconBorder'] as Color, width: 1),
                ),
                child: Center(
                  child: Icon(doc['icon'] as IconData, size: 15, color: doc['iconColor'] as Color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: slate800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: successGreenLight,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: successGreenBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 11, color: successGreen),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: successGreen,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 11, color: Color(0xFFD97706)),
                      SizedBox(width: 3),
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 16, color: slate400),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 8. CARD 4: ACCOUNT & PREFERENCES
  // =========================================================================
  Widget _buildAccountPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: primaryOrange, size: 19),
                    SizedBox(width: 8),
                    Text(
                      'Account & Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: slate600),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Push Notifications
          _buildPreferenceSwitchRow(
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          const SizedBox(height: 10),

          // Location Sharing
          _buildPreferenceSwitchRow(
            icon: Icons.map_outlined,
            title: 'Location Sharing',
            value: _locationSharing,
            onChanged: (val) => setState(() => _locationSharing = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: slate600),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: slate700,
              ),
            ),
          ],
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primaryOrange,
            activeTrackColor: primaryOrange.withValues(alpha: 0.4),
            inactiveThumbColor: slate400,
            inactiveTrackColor: slate200,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 9. SUPPORT CARD (Minimal & Professional)
  // =========================================================================
  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: orangeLightBg,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: orangeLightBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: orangeLightBorder),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              size: 20,
              color: primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '24/7 Driver Support',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: slate900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reach dispatch anytime for assistance',
                  style: TextStyle(
                    fontSize: 11,
                    color: slate500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => DispatchSupportModal.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get Help',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================================
  // 10. DEDICATED DOCUMENTS TAB VIEW (Matches User Screenshot)
  // =========================================================================
  Widget _buildFullDocumentsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compliance Overview Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Compliance Status: 1/3 Verified',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: slate900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'CDL License is verified. DOT Medical & Fleet Insurance are pending upload.',
                      style: TextStyle(fontSize: 11.5, color: slate600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of the 3 required documents (exact layout of user's screenshot)
        ..._documentsList.map((doc) => _buildScreenshotDocumentRow(doc)),

        const SizedBox(height: 14),
        // Update / Upload Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              DocumentVerificationModal.show(
                context,
                onVerificationComplete: () {
                  AppToast.success(context, 'Compliance documentation refreshed!');
                },
              );
            },
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text(
              'Upload Missing Documents',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotDocumentRow(Map<String, dynamic> doc) {
    final bool isVerified = doc['isVerified'] as bool;
    final bool hasFrontBack = doc['hasFrontBack'] as bool? ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Icon Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: doc['iconBg'] as Color,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: doc['iconBorder'] as Color, width: 1),
            ),
            child: Center(
              child: Icon(
                doc['icon'] as IconData,
                size: 18,
                color: doc['iconColor'] as Color,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Document Title & Subtitle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doc['title'] as String,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isVerified ? 'Uploaded' : 'Pending upload',
                  style: TextStyle(
                    fontSize: 11,
                    color: isVerified ? successGreen : slate400,
                    fontWeight: isVerified ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge (Verified or Pending) with 4px radius
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: successGreenLight,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: successGreenBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 12, color: successGreen),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: successGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFD97706)),
                  SizedBox(width: 4),
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 4),

          // Three-Dot Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: slate600),
            tooltip: 'Options',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            onSelected: (action) {
              if (action == 'view') {
                _openDocumentPreview(doc);
              } else if (action == 'front') {
                _openDocumentSidePreview(title: doc['title'] as String, side: 'Front');
              } else if (action == 'back') {
                _openDocumentSidePreview(title: doc['title'] as String, side: 'Back');
              } else if (action == 'upload') {
                DocumentVerificationModal.show(
                  context,
                  onVerificationComplete: () {
                    AppToast.success(context, 'Document verification updated!');
                  },
                );
              } else if (action == 'download') {
                if (isVerified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${doc['title']}...')),
                  );
                } else {
                  AppToast.info(context, 'No document uploaded yet to download');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 16, color: slate700),
                    SizedBox(width: 10),
                    Text('View Document', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: slate900)),
                  ],
                ),
              ),
              if (hasFrontBack) ...[
                const PopupMenuItem<String>(
                  value: 'front',
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: primaryOrange),
                      SizedBox(width: 10),
                      Text('View Front Side', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: slate900)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'back',
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: primaryOrange),
                      SizedBox(width: 10),
                      Text('View Back Side', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: slate900)),
                    ],
                  ),
                ),
              ],
              const PopupMenuItem<String>(
                value: 'upload',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
                    Text('Upload / Re-verify', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: slate900)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 16, color: successGreen),
                    SizedBox(width: 10),
                    Text('Download Copy', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: slate900)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
