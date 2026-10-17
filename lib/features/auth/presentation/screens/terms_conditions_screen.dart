import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class TermsConditionsScreen extends StatefulWidget {
  final int initialTabIndex;

  const TermsConditionsScreen({super.key, this.initialTabIndex = 0});

  static Future<void> showModal(BuildContext context, {int initialTabIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: TermsConditionsScreen(initialTabIndex: initialTabIndex),
          ),
        ),
      ),
    );
  }

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryColor = AppColors.primary;
  static const Color cardBg = AppColors.surface;
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textMain, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Legal & Compliance',
          style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: textSub,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Terms of Use'),
                Tab(text: 'Privacy Policy'),
                Tab(text: 'Driver Rules'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsOfUseTab(),
          _buildPrivacyPolicyTab(),
          _buildDriverRulesTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('I Understand & Agree', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsOfUseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeaderCard(
          title: 'Carrier & Driver Terms of Service',
          version: 'v3.4 • Effective August 2026',
          icon: Icons.gavel_rounded,
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          number: '1',
          title: 'Acceptance of Terms',
          body:
              'By creating an account, logging into the Carrier Direct Driver Platform, or accepting any freight dispatch, you agree to be bound by these Terms of Service, all applicable state and federal laws (including FMCSA and DOT regulations), and our Safety Compliance standards.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Driver Eligibility & Compliance',
          body:
              'All drivers must maintain an active Commercial Driver’s License (CDL), valid DOT Medical Examiner Certificate, and clean safety record. Providing false, expired, or fraudulent credentials will result in immediate suspension and notification to carrier dispatch.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Cargo Care, BOL & Proof of Delivery (POD)',
          body:
              'Drivers are solely responsible for inspecting freight condition before departure. Upon delivery, drivers must capture a high-resolution photo of the signed Bill of Lading (BOL) and collect customer OTP/digital signature before closing the shipment.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Load Dispatch & Route Compliance',
          body:
              'Assigned freight dispatch and delivery schedules are tracked based on verified GPS timestamps and completed POD uploads. Drivers must adhere to approved commercial vehicle navigation routes.',
        ),
        _buildSectionCard(
          number: '5',
          title: 'Account Termination & Liability',
          body:
              'Carrier Direct reserves the right to restrict platform access for safety violations, cargo abandonment, reckless driving, or failure to upload mandatory compliance documents.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrivacyPolicyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeaderCard(
          title: 'Driver Privacy & Data Policy',
          version: 'Confidential & Encrypted',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          number: '1',
          title: 'Location & Telematics Tracking',
          body:
              'We collect real-time background and foreground GPS location data exclusively during active dispatches and on-duty driving shifts to provide shippers with live freight ETA, route monitoring, and emergency roadside response.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Document & Photo Storage',
          body:
              'Driver identification photos, CDL scans, medical cards, and POD document photos are encrypted using AES-256 and stored in compliance with federal freight record-keeping standards.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Information Sharing',
          body:
              'Your location and contact number are only shared with authorized dispatchers and the recipient customer during active shipment deliveries. We never sell driver personal information to third-party advertisers.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Data Retention & Deletion',
          body:
              'DOT compliance records and shipment invoices are retained for the statutory period required by transportation authorities. You may request account deactivation and personal data deletion via Support.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDriverRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeaderCard(
          title: 'Driver Code of Conduct',
          version: 'Safety First Protocol',
          icon: Icons.verified_user_rounded,
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          number: '1',
          title: 'Hours of Service (HOS) & Rest Breaks',
          body:
              'Strict adherence to electronic logging device (ELD) hours of service is mandatory. Operating a vehicle under fatigue or falsifying logs is grounds for immediate dispatch termination.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Pre-Trip Vehicle Inspection (DVIR)',
          body:
              'Drivers must conduct a thorough pre-trip and post-trip vehicle inspection, ensuring brakes, tires, lights, and trailer seals are secure before rolling out.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Professional Communication',
          body:
              'Maintain courteous and professional conduct at all shipper warehouses, receiver docks, and weigh stations. Report any detention delays promptly through in-app Dispatch Chat.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeaderCard({required String title, required String version, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  version,
                  style: const TextStyle(color: textSub, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String number, required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: textSub, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}
