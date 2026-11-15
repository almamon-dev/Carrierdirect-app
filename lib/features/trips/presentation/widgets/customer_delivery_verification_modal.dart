import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/utils/app_toast.dart';
import '../screens/trips_screen.dart';

class CustomerDeliveryVerificationModal extends StatefulWidget {
  final ShipmentItem shipment;
  final String podFileName;
  final VoidCallback onVerified;

  const CustomerDeliveryVerificationModal({
    super.key,
    required this.shipment,
    required this.podFileName,
    required this.onVerified,
  });

  static Future<void> show(
    BuildContext context, {
    required ShipmentItem shipment,
    required String podFileName,
    required VoidCallback onVerified,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomerDeliveryVerificationModal(
        shipment: shipment,
        podFileName: podFileName,
        onVerified: onVerified,
      ),
    );
  }

  @override
  State<CustomerDeliveryVerificationModal> createState() =>
      _CustomerDeliveryVerificationModalState();
}

class _CustomerDeliveryVerificationModalState
    extends State<CustomerDeliveryVerificationModal> {
  final List<Offset?> _points = [];
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _isSigning = false;

  // Colors exactly matching Facebook-style light design
  static const Color lightBg = Colors.white;
  static const Color cardBg = Color(0xFFF0F2F5);
  static const Color cardBorder = Color(0xFFE4E6EB);
  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color textMain = Color(0xFF050505);
  static const Color textMuted = Color(0xFF65676B);
  static const Color textDarkMuted = Color(0xFF8A8D91);

  bool get _hasSignature => _points.where((p) => p != null).length > 5;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _otpController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    _startResendTimer();
    AppToast.success(
      context,
      '📨 Fresh 6-digit verification code sent to customer',
      icon: Icons.send_rounded,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCED0D4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Header (Shield Icon + Title + Verified Pill)
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF6E40), Color(0xFFE64A19)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Verification',
                            style: TextStyle(
                              color: textMain,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Verify delivery with customer OTP\nand signature',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pending Verification Amber Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFFD97706),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Pending',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Code Sent to Customer Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.mail_outline_rounded,
                            color: primaryOrange,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code sent to customer',
                              style: TextStyle(
                                color: textMain,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verification code for consignee sign-off',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Countdown / Resend
                      if (_secondsRemaining > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: primaryOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const Text(
                              'Resend in',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: _resendOtp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: primaryOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryOrange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 13,
                                  color: primaryOrange,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: primaryOrange,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Enter 6-Digit Code Section
                const Text(
                  'Enter 6-Digit Code',
                  style: TextStyle(
                    color: textMain,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // 6 OTP Digit Boxes
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _otpFocusNode.requestFocus(),
                      child: Row(
                        children: List.generate(6, (index) {
                          final text = _otpController.text;
                          final char = index < text.length ? text[index] : '';
                          final isFocused =
                              _otpFocusNode.hasFocus && index == text.length;

                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index == 5 ? 0 : 7,
                              ),
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFocused
                                      ? primaryOrange
                                      : char.isNotEmpty
                                      ? primaryOrange.withValues(alpha: 0.7)
                                      : cardBorder,
                                  width: isFocused || char.isNotEmpty ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: char.isNotEmpty
                                    ? Text(
                                        char,
                                        style: const TextStyle(
                                          color: textMain,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : isFocused
                                    ? Container(
                                        width: 2,
                                        height: 22,
                                        color: primaryOrange,
                                      )
                                    : const Text(
                                        '—',
                                        style: TextStyle(
                                          color: textDarkMuted,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Hidden Native Number Keyboard
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          cursorColor: Colors.transparent,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please enter the 6-digit code sent to the customer',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
                const SizedBox(height: 16),

                // 5. Receiver Signature Section
                const Text(
                  'Receiver Signature',
                  style: TextStyle(
                    color: textMain,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Signature Card Box
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasSignature
                          ? const Color(0xFF22C55E)
                          : cardBorder,
                      width: _hasSignature ? 1.4 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 1. Center Placeholder: Pencil + Sign above
                      if (!_hasSignature && !_isSigning)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: textMuted,
                                size: 24,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Sign above',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2. Dashed signing line at bottom
                      Positioned(
                        bottom: 34,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                height: 1,
                                color: index % 2 == 0
                                    ? const Color(0xFFCBD5E1)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3. Touch Drawing Area (Rendered underneath the Clear button)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _isSigning = true;
                                _points.add(details.localPosition);
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _points.add(details.localPosition);
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                _points.add(null);
                              });
                            },
                            child: CustomPaint(
                              painter: _OrangeSignaturePainter(_points),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ),

                      // 4. Clear Button at Bottom Right (Rendered ON TOP of touch canvas)
                      Positioned(
                        bottom: 6,
                        right: 10,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _points.clear();
                              _isSigning = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: _points.isNotEmpty
                                        ? primaryOrange
                                        : textDarkMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.refresh_rounded,
                                  color: _points.isNotEmpty
                                      ? primaryOrange
                                      : textDarkMuted,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Orange Action Button (Verify Code & Complete Delivery)
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_otpController.text.length < 6) {
                        AppToast.warning(
                          context,
                          'Please enter the complete 6-digit code sent to customer!',
                          icon: Icons.key_rounded,
                        );
                        _otpFocusNode.requestFocus();
                        return;
                      }
                      if (!_hasSignature) {
                        AppToast.warning(
                          context,
                          'Please ask receiver to sign above before completing!',
                          icon: Icons.draw_rounded,
                        );
                        return;
                      }

                      Navigator.pop(context);
                      widget.onVerified();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: primaryOrange,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Verify Code & Complete Delivery',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

class _OrangeSignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _OrangeSignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFF25722)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = 2.8;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_OrangeSignaturePainter oldDelegate) => true;
}
