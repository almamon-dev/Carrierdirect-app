import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/trips/data/models/shipment_item_model.dart';
import '../../services/location_service.dart';
import '../../services/order_gps_tracker_service.dart';

/// Mandatory, non-bypassable modal dialog displayed whenever a driver
/// turns off device GPS or revokes location permission during an active shipment.
class MandatoryGpsDialog extends StatefulWidget {
  final ShipmentItem? shipment;

  const MandatoryGpsDialog({super.key, this.shipment});

  static bool _isShowing = false;

  /// Show the dialog if not already open
  static Future<void> show(BuildContext context, {ShipmentItem? shipment}) async {
    if (_isShowing) return;
    _isShowing = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (ctx) => MandatoryGpsDialog(shipment: shipment),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<MandatoryGpsDialog> createState() => _MandatoryGpsDialogState();
}

class _MandatoryGpsDialogState extends State<MandatoryGpsDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  Timer? _autoCheckTimer;
  StreamSubscription<dynamic>? _statusSub;

  static const Color alertRed = Color(0xFFDC2626);
  static const Color orangePrimary = Color(0xFFFF5722);
  static const Color slateDark = Color(0xFF0F172A);
  static const Color slateMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-check periodically every 1.5 seconds in case user toggled GPS in quick settings
    _autoCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _checkGpsStatus();
    });

    // Listen to live hardware status stream
    _statusSub = LocationService().serviceStatusStream.listen((_) {
      _checkGpsStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGpsStatus();
    }
  }

  Future<void> _checkGpsStatus() async {
    if (!mounted) return;
    final isReady = await LocationService().isGpsReady();
    if (isReady && mounted) {
      OrderGpsTrackerService().isGpsDisabledNotifier.value = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _autoCheckTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderNum = widget.shipment?.id.isNotEmpty == true
        ? widget.shipment!.id
        : 'Active Trip';

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Warning Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const BoxDecoration(
                  color: alertRed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6.0),
                    topRight: Radius.circular(6.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MANDATORY GPS TRACKING',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Pulsing Red Satellite Icon
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: alertRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: alertRed.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_off_rounded,
                            color: alertRed,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      'Device Location Disabled',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: slateDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Order Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        orderNum,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: slateDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Explanation text
                    Text(
                      'Live GPS telemetry is required by CarrierDirect dispatch while completing an active freight trip. The app cannot proceed without active hardware GPS.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: slateMuted,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),

                    // Primary Action: Open Location Settings
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await LocationService().openLocationSettings();
                        },
                        icon: const Icon(
                          Icons.settings_suggest_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'Turn On Device GPS',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangePrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary Action: Re-check GPS
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _checkGpsStatus,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: Text(
                          'I Enabled GPS (Check Now)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: slateDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
