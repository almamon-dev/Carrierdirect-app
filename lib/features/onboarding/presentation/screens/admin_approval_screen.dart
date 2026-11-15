import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/logout_helper.dart';
import '../widgets/document_verification_modal.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  // Brand Color Tokens
  static const Color primaryOrange = Color(0xFFFF4A1F);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);

  bool _isCheckingStatus = false;
  String _verificationStatus =
      'under_review'; // 'under_review', 'pending', 'rejected', 'verified'
  String? _rejectionReason;

  String _driverName = 'Driver Captain';
  String _driverMode = 'Company Driver';
  String _licenseClass = 'Class A CDL';

  bool _hasLicenseFront = true;
  bool _hasLicenseBack = true;
  bool _hasMedicalCard = false;
  bool _hasInsurance = false;
  Timer? _approvalPollTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _fetchCurrentStatus();
    _startApprovalPoller();
  }

  void _startApprovalPoller() {
    _approvalPollTimer?.cancel();
    _approvalPollTimer = Timer.periodic(const Duration(milliseconds: 2000), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkStatusSilently();
    });
  }

  Future<void> _checkStatusSilently() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return;

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverProfile}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as Map<String, dynamic>? ?? {};

        final verificationMap =
            data['verification'] as Map<String, dynamic>? ?? {};
        final isVerified =
            data['is_verified'] == true ||
            verificationMap['is_verified'] == true;
        final status =
            (data['verification_status'] ?? verificationMap['status'] ?? '')
                .toString()
                .toLowerCase();
        final reason =
            data['rejection_reason']?.toString() ??
            verificationMap['rejection_reason']?.toString();

        if (isVerified || status == 'verified' || status == 'approved') {
          _approvalPollTimer?.cancel();
          if (mounted) {
            setState(() {
              _verificationStatus = 'verified';
            });
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
          }
        } else if (status == 'rejected' && _verificationStatus != 'rejected') {
          if (mounted) {
            setState(() {
              _verificationStatus = 'rejected';
              _rejectionReason = reason;
            });
            AppToast.error(
              context,
              'Verification needs attention: ${reason ?? "Please review and re-submit your documents."}',
              title: 'Action Required',
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _approvalPollTimer?.cancel();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final token = await SecureStorage().read(AppConstants.keyAuthToken);
    if (token != null && token.isNotEmpty) return token;
    final localToken = await LocalStorage().getString(
      AppConstants.keyAuthToken,
    );
    if (localToken != null && localToken.isNotEmpty) return localToken;
    return null;
  }

  Future<void> _fetchCurrentStatus({bool showFeedbackToast = false}) async {
    setState(() => _isCheckingStatus = true);

    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() => _isCheckingStatus = false);
        return;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverProfile}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as Map<String, dynamic>? ?? {};

        final verificationMap =
            data['verification'] as Map<String, dynamic>? ?? {};
        final isVerified =
            data['is_verified'] == true ||
            verificationMap['is_verified'] == true;
        final status =
            (data['verification_status'] ??
                    verificationMap['status'] ??
                    'under_review')
                .toString()
                .toLowerCase();
        final reason =
            data['rejection_reason']?.toString() ??
            verificationMap['rejection_reason']?.toString();

        final name =
            data['name']?.toString() ?? data['full_name']?.toString() ?? '';

        final details = data['driver_details'] as Map<String, dynamic>? ?? {};
        final creds = data['credentials'] as Map<String, dynamic>? ?? {};

        final licenseFront =
            creds['license_front'] ?? creds['license_document'];
        final licenseBack =
            creds['license_back'] ?? creds['license_back_document'];
        final medCard = creds['medical_card'] ?? creds['medical_card_document'];
        final insurance = creds['insurance'] ?? creds['insurance_document'];

        if (mounted) {
          setState(() {
            _verificationStatus = status;
            _rejectionReason = reason;

            if (name.isNotEmpty) _driverName = name;

            if (details['driver_mode'] != null) {
              _driverMode = details['driver_mode'].toString();
            }
            if (details['license_class'] != null) {
              _licenseClass = details['license_class'].toString();
            }

            _hasLicenseFront =
                licenseFront != null && licenseFront.toString().isNotEmpty;
            _hasLicenseBack =
                licenseBack != null && licenseBack.toString().isNotEmpty;
            _hasMedicalCard = medCard != null && medCard.toString().isNotEmpty;
            _hasInsurance =
                insurance != null && insurance.toString().isNotEmpty;

            _isCheckingStatus = false;
          });

          // If Admin has approved the driver!
          if (isVerified || status == 'verified' || status == 'approved') {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
            return;
          }

          if (showFeedbackToast) {
            AppToast.info(
              context,
              status == 'rejected'
                  ? 'Verification needs attention. Please review and re-submit.'
                  : 'Profile is still under review by Admin. Please check back shortly.',
              title: 'Status Checked',
            );
          }
        }
      } else {
        if (mounted) setState(() => _isCheckingStatus = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  void _openUpdateModal() {
    DocumentVerificationModal.show(
      context,
      onVerificationComplete: () {
        _fetchCurrentStatus(showFeedbackToast: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _verificationStatus == 'rejected';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1),
          ),
          title: Image.asset(
            'assets/images/Logo.png',
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'CarrierDirect',
              style: TextStyle(
                color: slate900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: slate600, size: 21),
              tooltip: 'Sign Out',
              onPressed: () => LogoutHelper.showLogoutDialog(context),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: primaryOrange,
            onRefresh: () => _fetchCurrentStatus(showFeedbackToast: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Premium Elevated Status Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A)
                              .withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Static Hero Badge (No pulsing/vibrating)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Mid soft ring
                            Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRejected
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFFFF7ED),
                                border: Border.all(
                                  color: isRejected
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFFFEDD5),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Core Vibrant Gradient Badge
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isRejected
                                      ? [
                                          const Color(0xFFEF4444),
                                          const Color(0xFFDC2626),
                                        ]
                                      : [
                                          const Color(0xFFFF6D3B),
                                          const Color(0xFFFF4A1F),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isRejected
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFFFF4A1F))
                                            .withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isRejected
                                      ? Icons.warning_amber_rounded
                                      : Icons.shield_outlined,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Live Status Pill with Static Dot
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 5.5,
                          ),
                          decoration: BoxDecoration(
                            color: isRejected
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(
                              color: isRejected
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFFDE68A),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7.5,
                                height: 7.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRejected
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRejected
                                    ? 'ACTION REQUIRED'
                                    : 'UNDER ADMIN REVIEW',
                                style: TextStyle(
                                  color: isRejected
                                      ? const Color(0xFF991B1B)
                                      : const Color(0xFF92400E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title & Subtitle
                        Text(
                          isRejected
                              ? 'Application Needs Revision'
                              : 'Verification Under Review',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: slate900,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRejected
                              ? 'Admin compliance team requested revisions for your submitted documents. Please update and re-submit.'
                              : 'Your driver credentials & compliance files have been received. Our safety team is verifying your records before activating live dispatch access.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: slate600,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),

                        // Driver Profile Mini Dossier Card
                        Container(
                          margin: const EdgeInsets.only(top: 18),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: Image.asset(
                                  'assets/images/driver_avatar.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 40,
                                    height: 40,
                                    color: primaryOrange.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: primaryOrange,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _driverName,
                                      style: const TextStyle(
                                        color: slate900,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_licenseClass • $_driverMode',
                                      style: const TextStyle(
                                        color: slate500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isRejected
                                          ? Icons.error_rounded
                                          : Icons.hourglass_bottom_rounded,
                                      size: 12,
                                      color: isRejected
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isRejected ? 'Needs Fix' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isRejected
                                            ? const Color(0xFF991B1B)
                                            : const Color(0xFF92400E),
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
                  ),

                  // Rejection Notice Alert (if rejected)
                  if (isRejected &&
                      _rejectionReason != null &&
                      _rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Feedback From Compliance Team',
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _rejectionReason!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 2. Compliance Pipeline Tracker Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A)
                              .withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.alt_route_rounded,
                                  size: 16,
                                  color: primaryOrange,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Verification Pipeline',
                                  style: TextStyle(
                                    color: slate900,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: const Text(
                                'Step 3 of 4',
                                style: TextStyle(
                                  color: primaryOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPipelineStep(
                          stepNumber: 1,
                          title: 'Driver Profile & Identity',
                          subtitle:
                              'Personal details and verified contact info',
                          status: _PipelineStepStatus.completed,
                        ),
                        _buildPipelineConnector(isCompleted: true),
                        _buildPipelineStep(
                          stepNumber: 2,
                          title: 'Commercial Credentials',
                          subtitle: '$_licenseClass & vehicle specifications',
                          status: _PipelineStepStatus.completed,
                        ),
                        _buildPipelineConnector(isCompleted: false),
                        _buildPipelineStep(
                          stepNumber: 3,
                          title: 'Admin Compliance & DOT Review',
                          subtitle: isRejected
                              ? 'Attention required from driver'
                              : 'Under active review by safety officer',
                          status: isRejected
                              ? _PipelineStepStatus.alert
                              : _PipelineStepStatus.inProgress,
                        ),
                        _buildPipelineConnector(isCompleted: false),
                        _buildPipelineStep(
                          stepNumber: 4,
                          title: 'Dispatch Access & Load Board',
                          subtitle: 'Unlocks full loads, live routes & chat',
                          status: _PipelineStepStatus.locked,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Submitted Documents Dossier Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A)
                              .withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.folder_copy_outlined,
                              size: 16,
                              color: primaryOrange,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Submitted Credentials Dossier',
                              style: TextStyle(
                                color: slate900,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDocumentTile(
                          icon: Icons.badge_outlined,
                          title: 'Driving License (Front)',
                          subtitle: 'Commercial driver photo license',
                          isUploaded: _hasLicenseFront,
                          isRequired: true,
                        ),
                        const SizedBox(height: 10),
                        _buildDocumentTile(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Driving License (Back)',
                          subtitle: 'Barcode & endorsement verification',
                          isUploaded: _hasLicenseBack,
                          isRequired: true,
                        ),
                        const SizedBox(height: 10),
                        _buildDocumentTile(
                          icon: Icons.medical_services_outlined,
                          title: 'DOT Medical Certificate',
                          subtitle: 'Medical Examiner card compliance',
                          isUploaded: _hasMedicalCard,
                          isRequired: false,
                        ),
                        const SizedBox(height: 10),
                        _buildDocumentTile(
                          icon: Icons.shield_outlined,
                          title: 'Commercial Insurance',
                          subtitle: 'Certificate of liability coverage',
                          isUploaded: _hasInsurance,
                          isRequired: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Fast-Track SLA Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fast-Track Turnaround SLA',
                                style: TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Applications are processed continuously during operating hours (Mon–Sat, 7:00 AM – 7:00 PM EST). Typical turnaround is 1–2 hours.',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Action Buttons (Elevated & High-End)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFFF3D00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4A1F)
                              .withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isCheckingStatus
                          ? null
                          : () => _fetchCurrentStatus(showFeedbackToast: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCheckingStatus) ...[
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Checking Live Status...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Check Approval Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary Action: Update Profile / Re-upload
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openUpdateModal,
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: primaryOrange,
                      ),
                      label: const Text(
                        'Update Documents / Profile',
                        style: TextStyle(
                          color: slate800,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () => LogoutHelper.showLogoutDialog(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 15,
                        color: slate500,
                      ),
                      label: const Text(
                        'Sign out of this account',
                        style: TextStyle(
                          color: slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Visual Pipeline Step Helpers ---
  Widget _buildPipelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required _PipelineStepStatus status,
  }) {
    Color badgeBg;
    Widget iconChild;

    switch (status) {
      case _PipelineStepStatus.completed:
        badgeBg = const Color(0xFF10B981);
        iconChild = const Icon(
          Icons.check_rounded,
          size: 14,
          color: Colors.white,
        );
        break;
      case _PipelineStepStatus.inProgress:
        badgeBg = const Color(0xFFF59E0B);
        iconChild = const Icon(
          Icons.hourglass_bottom_rounded,
          size: 13,
          color: Colors.white,
        );
        break;
      case _PipelineStepStatus.alert:
        badgeBg = const Color(0xFFEF4444);
        iconChild = const Icon(
          Icons.priority_high_rounded,
          size: 14,
          color: Colors.white,
        );
        break;
      case _PipelineStepStatus.locked:
        badgeBg = const Color(0xFFCBD5E1);
        iconChild = const Icon(
          Icons.lock_outline_rounded,
          size: 12,
          color: Color(0xFF64748B),
        );
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeBg,
            boxShadow: status == _PipelineStepStatus.inProgress
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(child: iconChild),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: status == _PipelineStepStatus.locked
                            ? slate400
                            : slate900,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (status == _PipelineStepStatus.inProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: status == _PipelineStepStatus.alert
                      ? const Color(0xFFDC2626)
                      : slate500,
                  fontSize: 11,
                  fontWeight: status == _PipelineStepStatus.alert
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineConnector({required bool isCompleted}) {
    return Container(
      width: 2,
      height: 18,
      margin: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // --- Document Dossier Tile ---
  Widget _buildDocumentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUploaded,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                color: isUploaded
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isUploaded ? const Color(0xFF16A34A) : slate400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: slate900,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: slate500, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFFDCFCE7)
                  : (isRequired
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUploaded
                      ? Icons.check_circle_rounded
                      : (isRequired
                            ? Icons.error_outline_rounded
                            : Icons.radio_button_unchecked_rounded),
                  size: 12,
                  color: isUploaded
                      ? const Color(0xFF15803D)
                      : (isRequired ? const Color(0xFFDC2626) : slate400),
                ),
                const SizedBox(width: 4),
                Text(
                  isUploaded
                      ? 'Received'
                      : (isRequired ? 'Required' : 'Optional'),
                  style: TextStyle(
                    color: isUploaded
                        ? const Color(0xFF166534)
                        : (isRequired ? const Color(0xFF991B1B) : slate500),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PipelineStepStatus { completed, inProgress, alert, locked }
