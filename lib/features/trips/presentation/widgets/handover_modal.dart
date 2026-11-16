import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../data/models/shipment_item_model.dart';

class HandoverModal extends StatefulWidget {
  final ShipmentItem shipment;
  final VoidCallback onSuccess;

  const HandoverModal({
    super.key,
    required this.shipment,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required ShipmentItem shipment,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HandoverModal(
        shipment: shipment,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<HandoverModal> createState() => _HandoverModalState();
}

class _HandoverModalState extends State<HandoverModal> {
  String _cargoCondition = 'good';
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCancelling = false;

  static const Color primaryOrange = AppColors.primary;
  static const Color darkSlate = AppColors.textPrimary;
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    final handover = widget.shipment.handover;
    if (handover != null) {
      _cargoCondition = handover['cargo_condition']?.toString() ?? 'good';
      _notesController.text =
          handover['cargo_condition_notes']?.toString() ??
          handover['notes']?.toString() ??
          '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return await SecureStorage().read(AppConstants.keyAuthToken);
  }

  Future<void> _handleInitiateHandover() async {
    setState(() => _isSubmitting = true);
    try {
      final token = await _getToken();
      final rawDbId = widget.shipment.dbId.trim();
      final cleanOrderNum = widget.shipment.id.replaceAll('#', '').trim();
      final shipmentId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;

      final hubLocation = widget.shipment.hubLocation.isNotEmpty
          ? widget.shipment.hubLocation
          : 'Intermediate Hub';

      final endpoint =
          '${ApiConstants.baseUrl}/driver/shipments/$shipmentId/handover';

      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'hub_location': hubLocation,
          'cargo_condition': _cargoCondition,
          'cargo_condition_notes': _notesController.text.trim(),
          'notes': _notesController.text.trim(),
        }),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        AppToast.success(
          context,
          'Handover initiated! Share the 6-digit OTP code with Driver 2.',
        );
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        final err = jsonDecode(res.body);
        final msg = err['message']?.toString() ?? 'Failed to initiate handover.';
        AppToast.error(context, msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.error(context, 'Network error: $e');
    }
  }

  Future<void> _handleCancelHandover() async {
    setState(() => _isCancelling = true);
    try {
      final token = await _getToken();
      final rawDbId = widget.shipment.dbId.trim();
      final cleanOrderNum = widget.shipment.id.replaceAll('#', '').trim();
      final shipmentId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;

      final endpoint =
          '${ApiConstants.baseUrl}/driver/shipments/$shipmentId/handover/cancel';

      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (!mounted) return;
      setState(() => _isCancelling = false);

      if (res.statusCode == 200) {
        AppToast.info(context, 'Handover cancelled. Shipment returned to transit.');
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        final err = jsonDecode(res.body);
        final msg = err['message']?.toString() ?? 'Failed to cancel handover.';
        AppToast.error(context, msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      AppToast.error(context, 'Error cancelling handover: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final handover = widget.shipment.handover;
    final isPending = widget.shipment.isHandoverPending;
    final otpCode = handover?['otp_code']?.toString() ?? '';
    final hubLocation = widget.shipment.hubLocation.isNotEmpty
        ? widget.shipment.hubLocation
        : (handover?['hub_location']?.toString() ?? 'Intermediate Hub');
    final partner = widget.shipment.partnerDriver;
    final partnerName = partner?['driver_name']?.toString() ?? 'Sean Murphy (Relay Driver)';
    final partnerPhone = partner?['driver_phone']?.toString() ?? '—';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF7C3AED),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPending
                                ? 'Cargo Handover Pending'
                                : 'Handover Cargo at Hub',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: darkSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Relay Point: $hubLocation',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: slate500),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Partner Driver Receiving Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: slate50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: slate200),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE0E7FF),
                        child: Icon(Icons.person, color: Color(0xFF4F46E5), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RECEIVING DRIVER (LEG 2)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: slate500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              partnerName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: darkSlate,
                              ),
                            ),
                            Text(
                              partnerPhone,
                              style: const TextStyle(fontSize: 11.5, color: slate500),
                            ),
                          ],
                        ),
                      ),
                      if (partnerPhone != '—')
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: partnerPhone));
                            AppToast.info(context, 'Phone copied: $partnerPhone');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: primaryOrange),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // If already pending -> Show prominent OTP
                if (isPending && otpCode.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'HANDOVER VERIFICATION OTP CODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6D28D9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              otpCode,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                color: const Color(0xFF5B21B6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: otpCode));
                                AppToast.success(context, 'OTP $otpCode copied!');
                              },
                              icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C3AED)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Share this 6-digit code with Driver 2. Once they enter this code on their app, Leg 1 will be completed automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF6D28D9)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : _handleCancelHandover,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                            )
                          : const Text(
                              'Cancel Handover & Return to Transit',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ] else ...[
                  // Cargo Condition Selector
                  const Text(
                    'Cargo Condition at Handover',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildConditionRadio('good', 'Good Condition', Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      _buildConditionRadio('minor_damage', 'Minor Wear', Icons.warning_amber_rounded),
                      const SizedBox(width: 8),
                      _buildConditionRadio('damaged', 'Damaged', Icons.error_outline),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Notes TextField
                  const Text(
                    'Handover Notes / Bay Location',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Unloaded at Dock 4, pallets intact & sealed...',
                      hintStyle: const TextStyle(fontSize: 12, color: slate500),
                      filled: true,
                      fillColor: slate50,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleInitiateHandover,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.qr_code_2_rounded, size: 20),
                      label: Text(
                        _isSubmitting
                            ? 'Generating Handover...'
                            : 'Generate OTP & Handover Load',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionRadio(String value, String label, IconData icon) {
    final isSelected = _cargoCondition == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _cargoCondition = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5F3FF) : slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF7C3AED) : slate200,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF7C3AED) : slate500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF7C3AED) : darkSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
