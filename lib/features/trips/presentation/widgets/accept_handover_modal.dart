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

class AcceptHandoverModal extends StatefulWidget {
  final ShipmentItem shipment;
  final VoidCallback onSuccess;

  const AcceptHandoverModal({
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
      builder: (ctx) => AcceptHandoverModal(
        shipment: shipment,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AcceptHandoverModal> createState() => _AcceptHandoverModalState();
}

class _AcceptHandoverModalState extends State<AcceptHandoverModal> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  static const Color successGreen = Color(0xFF059669);
  static const Color darkSlate = AppColors.textPrimary;
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _otpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return await SecureStorage().read(AppConstants.keyAuthToken);
  }

  Future<void> _handleAccept() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      AppToast.error(context, 'Please enter the 6-digit OTP code provided by Driver 1.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await _getToken();
      final rawDbId = widget.shipment.dbId.trim();
      final cleanOrderNum = widget.shipment.id.replaceAll('#', '').trim();
      final shipmentId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;

      final endpoint =
          '${ApiConstants.baseUrl}/driver/shipments/$shipmentId/handover/accept';

      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'otp_code': code,
          'notes': _notesController.text.trim(),
        }),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        AppToast.success(context, 'Handover accepted! Leg 2 final transit is now active.');
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        final err = jsonDecode(res.body);
        final msg = err['message']?.toString() ?? 'Invalid OTP code. Please check with Driver 1.';
        AppToast.error(context, msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.error(context, 'Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final handover = widget.shipment.handover;
    final partner = widget.shipment.partnerDriver;
    final partnerName = partner?['driver_name']?.toString() ??
        (handover?['driver_from_name']?.toString() ?? 'Driver 1');
    final partnerPhone = partner?['driver_phone']?.toString() ??
        (handover?['driver_from_phone']?.toString() ?? '—');
    final hubLocation = widget.shipment.hubLocation.isNotEmpty
        ? widget.shipment.hubLocation
        : (handover?['hub_location']?.toString() ?? 'Intermediate Hub');
    final cargoCondition = handover?['cargo_condition']?.toString() ?? 'good';
    final handoverNotes = handover?['cargo_condition_notes']?.toString() ??
        handover?['notes']?.toString() ??
        '';

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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: successGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accept Cargo from Driver 1',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: darkSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hub Handover Point: $hubLocation',
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

                // Driver 1 Information Card
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
                              'ORIGIN PICKUP DRIVER (LEG 1)',
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Cargo Condition Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: slate200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: slate500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reported Condition: ${cargoCondition.replaceAll('_', ' ').toUpperCase()}${handoverNotes.isNotEmpty ? ' ($handoverNotes)' : ''}',
                          style: const TextStyle(fontSize: 12, color: darkSlate),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6-digit OTP Code Input
                const Text(
                  'Enter 6-Digit Handover OTP',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ask Driver 1 for their 6-digit verification code to confirm cargo transfer.',
                  style: TextStyle(fontSize: 11.5, color: slate500),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: darkSlate,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: GoogleFonts.sourceCodePro(
                      fontSize: 26,
                      letterSpacing: 10,
                      color: slate200,
                    ),
                    filled: true,
                    fillColor: slate50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                      borderSide: const BorderSide(color: successGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Inspection Notes
                const Text(
                  'Inspection Notes (Optional)',
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
                    hintText: 'e.g. Inspected cargo seals, loaded into trailer...',
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
                      borderSide: const BorderSide(color: successGreen, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Accept Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'Verifying OTP...' : 'Verify OTP & Accept Cargo',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
