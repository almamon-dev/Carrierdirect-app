import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/map_launcher_helper.dart';
import '../../../../services/google_navigation_service.dart';
import '../../../../services/order_gps_tracker_service.dart';
import '../widgets/accept_handover_modal.dart';
import '../widgets/handover_modal.dart';
import '../widgets/load_delivered_modal.dart';
import '../widgets/shipment_bottom_action_bar.dart';
import '../widgets/map_skeleton_placeholder.dart';
import '../widgets/shipment_header_bar.dart';
import '../widgets/shipment_overview_tab.dart';
import '../widgets/shipment_route_tab.dart';
import 'trips_screen.dart';

class ShipmentDetailsScreen extends StatefulWidget {
  final ShipmentItem shipment;

  const ShipmentDetailsScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late ShipmentItem _shipment;
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  int _selectedTabIndex = 0; // 0: Overview, 1: Route

  AnimationController? _shimmerController;
  Animation<double>? _shimmerAnimation;

  // Dynamic API state
  final List<Map<String, dynamic>> _activityLog = [];
  List<LatLng> _dynamicRoutePoints = [];
  String? _podPhotoUrl;
  String? _signatureUrl;
  String? _receiverName;
  String? _podStatus;
  String _estimatedDuration = '';
  String? _cargoDimensions;
  String? _specialInstructions;

  late final PageController _pageController;

  static const Color primaryOrange = AppColors.primary;
  static const Color successGreen = AppColors.success;
  static const Color darkSlate = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color pageBg = AppColors.background;

  String? _cachedToken;

  Future<String?> _getAuthToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    _cachedToken = await SecureStorage().read(AppConstants.keyAuthToken);
    return _cachedToken;
  }

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
    // If shipment data already present from trips/dashboard, immediately show content without blocking
    final hasExistingData =
        _shipment.id.isNotEmpty &&
        (_shipment.originTitle.isNotEmpty || _shipment.destTitle.isNotEmpty);
    _isLoading = !hasExistingData;
    _pageController = PageController(initialPage: _selectedTabIndex);
    _initDynamicData();
    _initShimmer();
    _fetchShipmentDetails();
    if (_shipment.status == ShipmentFilter.inProgress) {
      OrderGpsTrackerService().startTracking(_shipment);
    }
  }

  void _initShimmer() {
    if (_shimmerController == null) {
      _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      );
      _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(
          parent: _shimmerController!,
          curve: Curves.easeInOutSine,
        ),
      );
      if (_isLoading) {
        _shimmerController!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController?.dispose();
    super.dispose();
  }

  void _initDynamicData() {
    if (_shipment.originLat != 0.0 && _shipment.destLat != 0.0) {
      _dynamicRoutePoints = [
        LatLng(_shipment.originLat, _shipment.originLng),
        LatLng(_shipment.destLat, _shipment.destLng),
      ];
    }
    if (_shipment.estimatedDuration.isNotEmpty) {
      _estimatedDuration = Formatters.formatCompactDuration(
        _shipment.estimatedDuration,
      );
    }
    // Defer the heavy road polyline network request so Overview tab opens instantly with zero frame drop
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fetchRealRoadRoute();
    });
  }

  Future<void> _fetchRealRoadRoute() async {
    try {
      final originQuery =
          (_shipment.originAddress.isNotEmpty && _shipment.originAddress != '—')
          ? _shipment.originAddress
          : _shipment.originTitle;
      final destQuery =
          (_shipment.destAddress.isNotEmpty && _shipment.destAddress != '—')
          ? _shipment.destAddress
          : _shipment.destTitle;

      final res = await GoogleNavigationService().fetchRouteByAddressOrCoords(
        originAddress: originQuery,
        originCoords: (_shipment.originLat != 0.0 && _shipment.originLng != 0.0)
            ? LatLng(_shipment.originLat, _shipment.originLng)
            : null,
        destinationAddress: destQuery,
        destinationCoords:
            (_shipment.destLat != 0.0 && _shipment.destLng != 0.0)
            ? LatLng(_shipment.destLat, _shipment.destLng)
            : null,
        destinationTitle: _shipment.destTitle,
      );
      if (mounted && res != null) {
        setState(() {
          if (res.polylinePoints.isNotEmpty) {
            _dynamicRoutePoints = res.polylinePoints;
          }
          final newDist = _shipment.distanceKm > 0
              ? _shipment.distanceKm
              : ((res.totalDistanceKm * 10).round() / 10.0);
          final newOLat = _shipment.originLat != 0.0
              ? _shipment.originLat
              : (res.resolvedOrigin?.latitude ?? 0.0);
          final newOLng = _shipment.originLng != 0.0
              ? _shipment.originLng
              : (res.resolvedOrigin?.longitude ?? 0.0);
          final newDLat = _shipment.destLat != 0.0
              ? _shipment.destLat
              : (res.resolvedDestination?.latitude ?? 0.0);
          final newDLng = _shipment.destLng != 0.0
              ? _shipment.destLng
              : (res.resolvedDestination?.longitude ?? 0.0);
          if (res.totalDurationText.isNotEmpty) {
            _estimatedDuration = Formatters.formatCompactDuration(
              res.totalDurationText,
            );
          }
          _shipment = _shipment.copyWith(
            distanceKm: newDist,
            originLat: newOLat,
            originLng: newOLng,
            destLat: newDLat,
            destLng: newDLng,
            estimatedDuration: _estimatedDuration,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchShipmentDetails() async {
    final rawDbId = _shipment.dbId.trim();
    final cleanOrderNum = _shipment.id.replaceAll('#', '').trim();
    final shipmentId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;

    try {
      final token = await _getAuthToken();

      if (token != null && token.isNotEmpty) {
        final endpoint = '${ApiConstants.baseUrl}/driver/shipments/$shipmentId';
        final response = await http
            .get(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'ngrok-skip-browser-warning': 'true',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final dynamic body = jsonDecode(response.body);
          if (body is Map<String, dynamic> &&
              body['data'] is Map<String, dynamic>) {
            _parseAndApplyApiData(body['data'] as Map<String, dynamic>);
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      _shimmerController?.stop();
    }
  }

  void _parseAndApplyApiData(Map<String, dynamic> data) {
    if (!mounted) return;
    try {
      Map<String, dynamic> safeMap(dynamic val) {
        if (val is Map<String, dynamic>) return val;
        if (val is Map) return Map<String, dynamic>.from(val);
        return <String, dynamic>{};
      }

      final parsed = ShipmentItem.fromJson(data);
      final cargo = safeMap(data['cargo']);
      final route = safeMap(data['route']);
      final tracking = safeMap(data['tracking']);

      final List<Map<String, dynamic>> newActivities = [];
      final dynamic rawActivities =
          data['timeline'] ??
          data['activities'] ??
          data['status_history'] ??
          tracking['history'] ??
          data['history'];
      if (rawActivities is List) {
        for (final item in rawActivities) {
          if (item is Map) {
            newActivities.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() {
        _shipment = parsed;
        _cargoDimensions = cargo['dimensions']?.toString();
        _specialInstructions = cargo['special_instructions']?.toString();
        _estimatedDuration = Formatters.formatCompactDuration(
          route['estimated_duration']?.toString() ?? '',
        );

        _podPhotoUrl =
            tracking['proof_of_delivery']?.toString() ??
            data['proof_of_delivery']?.toString() ??
            data['proof']?.toString();
        _signatureUrl =
            tracking['signature']?.toString() ?? data['signature']?.toString();
        _receiverName =
            tracking['receiver_name']?.toString() ??
            data['receiver_name']?.toString();
        _podStatus =
            tracking['pod_status']?.toString() ??
            data['pod_status']?.toString();

        _activityLog.clear();
        _activityLog.addAll(newActivities);
        _isLoading = false;
      });
      _shimmerController?.stop();

      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _fetchRealRoadRoute();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _shimmerController?.stop();
      }
    }
  }

  Future<void> _simulateRefresh() async {
    await _fetchShipmentDetails();
  }

  void _copyLoadId() {
    Clipboard.setData(ClipboardData(text: _shipment.id));
    AppToast.success(context, 'Load ID #${_shipment.id} copied to clipboard!');
  }

  Future<void> _openExternalGoogleMaps() async {
    OrderGpsTrackerService().startTracking(_shipment);

    final bool isToDelivery =
        _shipment.status == ShipmentFilter.inProgress ||
        _shipment.status == ShipmentFilter.completed;
    final targetLat = isToDelivery ? _shipment.destLat : _shipment.originLat;
    final targetLng = isToDelivery ? _shipment.destLng : _shipment.originLng;
    final targetAddr = isToDelivery
        ? _shipment.destAddress
        : _shipment.originAddress;
    final targetTitle = isToDelivery
        ? _shipment.destTitle
        : _shipment.originTitle;

    await MapLauncherHelper.openGoogleMaps(
      context,
      destinationAddress: targetAddr.isNotEmpty && targetAddr != '—'
          ? targetAddr
          : targetTitle,
      latitude: targetLat != 0.0 ? targetLat : null,
      longitude: targetLng != 0.0 ? targetLng : null,
      destinationTitle: targetTitle,
    );
  }

  void _showLoadDeliveredModal() {
    LoadDeliveredModal.show(
      context,
      onPodUploaded: (filePath, fileName) {},
      onPodFullSubmitted:
          ({
            required String receiverName,
            required String signatureData,
            String? pdfPath,
            String? pdfName,
            String? notes,
          }) {
            if (mounted) {
              final nowIso = DateTime.now().toIso8601String();
              setState(() {
                _receiverName = receiverName;
                _signatureUrl = signatureData;
                _podPhotoUrl = pdfPath ?? 'signature_captured';
                _podStatus = 'pending';
                _shipment = _shipment.copyWith(
                  status: ShipmentFilter.completed,
                  statusLabel: 'Delivered',
                  rawStatus: 'delivered',
                  signedBy: receiverName,
                  podDate: nowIso,
                );
              });
              OrderGpsTrackerService().stopTracking();
              _submitPodToBackend(
                receiverName: receiverName,
                signatureData: signatureData,
                pdfPath: pdfPath,
                notes: notes,
              );
            }
          },
    );
  }

  Future<void> _submitPodToBackend({
    required String receiverName,
    required String signatureData,
    String? pdfPath,
    String? notes,
  }) async {
    final rawDbId = _shipment.dbId.trim();
    final cleanOrderNum = _shipment.id.replaceAll('#', '').trim();
    final shipmentId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      final endpoint =
          '${ApiConstants.baseUrl}/driver/shipments/$shipmentId/status';
      final Map<String, dynamic> payload = {
        'status': 'delivered',
        'receiver_name': receiverName,
        'signature': signatureData,
        'notes': notes ?? 'Delivered with POD sign-off',
      };
      if (pdfPath != null && pdfPath.isNotEmpty) {
        try {
          final file = File(pdfPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final ext = pdfPath.split('.').last.toLowerCase();
            final mime = (ext == 'pdf')
                ? 'application/pdf'
                : (ext == 'png' ? 'image/png' : 'image/jpeg');
            payload['proof_of_delivery'] =
                'data:$mime;base64,${base64Encode(bytes)}';
          } else {
            payload['proof_of_delivery'] = pdfPath;
          }
        } catch (_) {
          payload['proof_of_delivery'] = pdfPath;
        }
      }
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final dynamic body = jsonDecode(res.body);
        if (body is Map<String, dynamic> &&
            body['data'] is Map<String, dynamic>) {
          _parseAndApplyApiData(body['data'] as Map<String, dynamic>);
        }
        if (mounted) {
          AppToast.success(context, 'Delivery marked & Proof of Delivery submitted');
        }
      } else {
        if (mounted) {
          String errMsg = 'Failed to submit POD (${res.statusCode})';
          try {
            final errBody = jsonDecode(res.body);
            if (errBody is Map && errBody['message'] != null) {
              errMsg = errBody['message'].toString();
            }
          } catch (_) {}
          AppToast.error(context, errMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Network error submitting POD');
      }
    }
  }

  void _viewPodPhoto() {
    final photoUrl = (_podPhotoUrl != null && _podPhotoUrl!.isNotEmpty)
        ? _podPhotoUrl!
        : ((_signatureUrl != null && _signatureUrl!.isNotEmpty)
              ? _signatureUrl!
              : null);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: successGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Proof of Delivery (POD)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkSlate,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  color: const Color(0xFF0F172A),
                  child: photoUrl != null
                      ? InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.5,
                          child: photoUrl.startsWith('http')
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      _buildPodFallbackCard(),
                                )
                              : Image.file(
                                  File(photoUrl),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      _buildPodFallbackCard(),
                                ),
                        )
                      : _buildPodFallbackCard(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodFallbackCard() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: 40,
              color: Colors.white54,
            ),
            SizedBox(height: 8),
            Text(
              'Proof of Delivery Attached',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHandoverModal() {
    HandoverModal.show(
      context,
      shipment: _shipment,
      onSuccess: () {
        _fetchShipmentDetails();
      },
    );
  }

  void _openAcceptHandoverModal() {
    AcceptHandoverModal.show(
      context,
      shipment: _shipment,
      onSuccess: () {
        _fetchShipmentDetails();
      },
    );
  }

  String _getSlideActionText() {
    final isRelay = _shipment.isRelay;
    final isLeg1 = _shipment.isLeg1;
    final isLeg2 = _shipment.isLeg2;
    final rawStatus = (_shipment.rawStatus.isNotEmpty
            ? _shipment.rawStatus
            : _shipment.statusLabel)
        .toLowerCase()
        .trim();

    final bool isPrePickup = rawStatus == 'assigned' ||
        rawStatus == 'driver_assigned' ||
        rawStatus == 'accepted' ||
        rawStatus == 'confirmed' ||
        rawStatus == 'scheduled' ||
        rawStatus == 'new' ||
        rawStatus == 'booked';
    final bool isPickedUpState = rawStatus == 'at_pickup' || rawStatus == 'picked_up';
    final bool isInTransitState = rawStatus == 'in_transit' || rawStatus == 'on_the_way';

    // 1. Relay Leg 1 (Pickup -> Hub)
    if (isRelay && isLeg1) {
      if (isPrePickup) {
        return 'Slide to confirm pickup';
      } else if (isPickedUpState) {
        final hub = _shipment.hubLocation.isNotEmpty ? _shipment.hubLocation : 'Hub';
        return 'Slide to start transit to $hub';
      } else if (isInTransitState) {
        final hub = _shipment.hubLocation.isNotEmpty ? _shipment.hubLocation : 'Hub';
        return 'Slide to arrive at $hub';
      }
      return 'Slide to update status';
    }

    // 2. Relay Leg 2 (Hub -> Destination)
    if (isRelay && isLeg2) {
      if (_shipment.isHandoverAccepted &&
          !isInTransitState &&
          rawStatus != 'at_delivery' &&
          rawStatus != 'arrived') {
        return 'Slide to start final transit';
      } else if (isInTransitState) {
        return 'Slide to arrive at Destination';
      }
      return 'Slide to update status';
    }

    // 3. Single Driver Shipment
    if (isPrePickup) {
      return 'Slide to confirm pickup';
    } else if (isPickedUpState) {
      return 'Slide to start transit';
    } else if (isInTransitState) {
      return 'Slide to arrive at Destination';
    }
    return 'Slide to update status';
  }

  String _getTargetStatus() {
    final isRelay = _shipment.isRelay;
    final isLeg1 = _shipment.isLeg1;
    final isLeg2 = _shipment.isLeg2;
    final rawStatus = (_shipment.rawStatus.isNotEmpty
            ? _shipment.rawStatus
            : _shipment.statusLabel)
        .toLowerCase()
        .trim();

    final bool isPrePickup = rawStatus == 'assigned' ||
        rawStatus == 'driver_assigned' ||
        rawStatus == 'accepted' ||
        rawStatus == 'confirmed' ||
        rawStatus == 'scheduled' ||
        rawStatus == 'new' ||
        rawStatus == 'booked';
    final bool isPickedUpState = rawStatus == 'at_pickup' || rawStatus == 'picked_up';
    final bool isInTransitState = rawStatus == 'in_transit' || rawStatus == 'on_the_way';

    // 1. Relay Leg 1 (Pickup -> Hub)
    if (isRelay && isLeg1) {
      if (isPrePickup) {
        return 'picked_up';
      } else if (isPickedUpState) {
        return 'in_transit';
      } else if (isInTransitState) {
        return 'at_hub';
      }
      return 'at_hub';
    }

    // 2. Relay Leg 2 (Hub -> Destination)
    if (isRelay && isLeg2) {
      if (_shipment.isHandoverAccepted &&
          !isInTransitState &&
          rawStatus != 'at_delivery' &&
          rawStatus != 'arrived') {
        return 'in_transit';
      } else if (isInTransitState) {
        return 'at_delivery';
      }
      return 'at_delivery';
    }

    // 3. Single Driver Shipment
    if (isPrePickup) {
      return 'picked_up';
    } else if (isPickedUpState) {
      return 'in_transit';
    } else if (isInTransitState) {
      return 'at_delivery';
    }
    return 'at_delivery';
  }

  Future<bool> _handleSlideToAct() async {
    if (_isUpdatingStatus) return false;
    setState(() => _isUpdatingStatus = true);

    final rawDbId = _shipment.dbId.trim();
    final cleanOrderNum = _shipment.id.replaceAll('#', '').trim();
    final shipmentId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;
    final targetStatus = _getTargetStatus();

    try {
      final token = await _getAuthToken();

      final isDeliveredTarget =
          targetStatus == 'completed' || targetStatus == 'delivered';

      if (token != null && token.isNotEmpty) {
        final endpoint =
            '${ApiConstants.baseUrl}/driver/shipments/$shipmentId/status';
        final res = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'ngrok-skip-browser-warning': 'true',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'status': targetStatus,
                'notes': 'Status updated via driver slide action',
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (res.statusCode == 200 || res.statusCode == 201) {
          final dynamic body = jsonDecode(res.body);
          if (body is Map<String, dynamic> &&
              body['data'] is Map<String, dynamic>) {
            _parseAndApplyApiData(body['data'] as Map<String, dynamic>);
            if (targetStatus.isNotEmpty && _shipment.rawStatus != targetStatus) {
              setState(() {
                _shipment = _shipment.copyWith(
                  status: (targetStatus == 'delivered' || targetStatus == 'completed')
                      ? ShipmentFilter.completed
                      : ShipmentFilter.inProgress,
                  statusLabel: _formatStatusLabel(targetStatus),
                  rawStatus: targetStatus,
                );
              });
            }
          } else {
            _applyLocalStatusTransition(targetStatus);
          }
          if (mounted) {
            AppToast.success(
              context,
              'Status updated: ${_formatStatusLabel(targetStatus)}',
            );
            if (isDeliveredTarget) {
              Future.delayed(const Duration(milliseconds: 350), () {
                if (mounted) _showLoadDeliveredModal();
              });
            }
          }
          return true;
        } else {
          debugPrint('Status update error: ${res.statusCode} ${res.body}');
          if (mounted) {
            String errorMsg = 'Failed to update (${res.statusCode})';
            try {
              final errJson = jsonDecode(res.body);
              if (errJson is Map && errJson['message'] != null) {
                errorMsg = errJson['message'].toString();
              }
            } catch (_) {}
            AppToast.error(context, errorMsg);
          }
          return false;
        }
      } else {
        if (mounted) {
          AppToast.error(context, 'Authentication required');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Status update exception: $e');
      if (mounted) {
        AppToast.error(context, 'Network timeout updating status');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _applyLocalStatusTransition(String targetStatus) {
    ShipmentFilter newFilter = _shipment.status;
    String newLabel = _shipment.statusLabel;

    setState(() {
      if (targetStatus == 'in_progress') {
        newFilter = ShipmentFilter.inProgress;
        newLabel = 'In Progress';
      } else if (targetStatus == 'picked_up') {
        newFilter = ShipmentFilter.inProgress;
        newLabel = 'Picked Up';
      } else if (targetStatus == 'in_transit') {
        newFilter = ShipmentFilter.inProgress;
        newLabel = 'In Transit';
      } else if (targetStatus == 'at_hub') {
        newFilter = ShipmentFilter.inProgress;
        newLabel = 'At Hub';
      } else if (targetStatus == 'at_delivery' || targetStatus == 'arrived') {
        newFilter = ShipmentFilter.inProgress;
        newLabel = 'At Delivery';
      } else if (targetStatus == 'completed' || targetStatus == 'delivered') {
        newFilter = ShipmentFilter.completed;
        newLabel = 'Delivered';
      }

      final nowIso = DateTime.now().toIso8601String();
      _activityLog.insert(0, {
        'status': targetStatus,
        'title': _formatStatusLabel(targetStatus),
        'created_at': nowIso,
        'time': nowIso,
        'date': nowIso,
      });

      _shipment = _shipment.copyWith(
        status: newFilter,
        statusLabel: newLabel,
        rawStatus: targetStatus,
      );
    });

    if (newFilter == ShipmentFilter.inProgress) {
      OrderGpsTrackerService().startTracking(_shipment);
    } else if (newFilter == ShipmentFilter.completed) {
      OrderGpsTrackerService().stopTracking();
    }
  }

  String _formatStatusLabel(String s) {
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildRouteSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        children: [
          // 1. Embedded Map Preview Skeleton (5px radius)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: const MapSkeletonPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          // 2. Route Summary Bottom Skeleton (Outer card removed, clean layout)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildShimmerBox(
                        height: 15,
                        width: 15,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      const SizedBox(width: 6),
                      _buildShimmerBox(
                        height: 14,
                        width: 60,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ],
                  ),
                  _buildShimmerBox(
                    height: 16,
                    width: 45,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      height: 38,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildShimmerBox(
                      height: 38,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildShimmerBox(
                      height: 38,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rounded pill button shimmer
              _buildShimmerBox(
                height: 38,
                borderRadius: BorderRadius.circular(24.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBody() {
    if (_selectedTabIndex == 1) {
      return _buildRouteSkeleton();
    }
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        // 1. Facility & Location Details Card Skeleton
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(
                    height: 20,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerBox(
                    height: 16,
                    width: 160,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildShimmerBox(
                height: 52,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              _buildShimmerBox(
                height: 52,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Shipment Information Card Skeleton (Grid of attributes)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(
                    height: 20,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerBox(
                    height: 16,
                    width: 150,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      height: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShimmerBox(
                      height: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      height: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShimmerBox(
                      height: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      height: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShimmerBox(
                      height: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Activity Timeline Skeleton Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(
                    height: 20,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerBox(
                    height: 16,
                    width: 140,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildShimmerBox(
                height: 40,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              _buildShimmerBox(
                height: 40,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              _buildShimmerBox(
                height: 40,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox({
    required double height,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
              stops: [
                (_shimmerAnimation?.value ?? 0.0) - 0.3,
                (_shimmerAnimation?.value ?? 0.0),
                (_shimmerAnimation?.value ?? 0.0) + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPodProof = (_podPhotoUrl != null && _podPhotoUrl!.isNotEmpty) ||
        (_signatureUrl != null && _signatureUrl!.isNotEmpty);
    final isDelivered =
        _shipment.status == ShipmentFilter.completed ||
        hasPodProof ||
        _shipment.rawStatus.toLowerCase() == 'delivered' ||
        _shipment.rawStatus.toLowerCase() == 'completed' ||
        (_podStatus != null &&
            (_podStatus == 'delivered' ||
                _podStatus == 'verified' ||
                _podStatus == 'approved' ||
                _podStatus == 'completed'));

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            ShipmentTopAppBar(
              shipment: _shipment,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            ShipmentOrderHeaderCard(shipment: _shipment, onCopyId: _copyLoadId),
            if (_shipment.isEmergency)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCF222E), width: 3.5),
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 15,
                          color: Color(0xFFCF222E),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Shift on Sick Leave / Emergency Hold',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            _shipment.emergencyReason.isNotEmpty
                                ? _shipment.emergencyReason.replaceAll('_', ' ').toUpperCase()
                                : 'SICK LEAVE',
                            style: const TextStyle(
                              color: Color(0xFFCF222E),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shipment.emergencyNotes.isNotEmpty
                          ? 'Notes: "${_shipment.emergencyNotes}"'
                          : 'Corridor reassignment is in progress by operations dispatch.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ShipmentTabBar(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() => _selectedTabIndex = index);
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonBody()
                  : PageView(
                      controller: _pageController,
                      physics: _selectedTabIndex == 1
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _selectedTabIndex = index);
                      },
                      children: [
                        RefreshIndicator(
                          onRefresh: _simulateRefresh,
                          color: primaryOrange,
                          child: ShipmentOverviewTab(
                            shipment: _shipment,
                            isDelivered: isDelivered,
                            podPhotoUrl: _podPhotoUrl,
                            receiverName: _receiverName,
                            podStatus: _podStatus,
                            signatureUrl: _signatureUrl,
                            cargoDimensions: _cargoDimensions,
                            specialInstructions: _specialInstructions,
                            activityLog: _activityLog,
                            onOpenPodModal: _showLoadDeliveredModal,
                            onViewPodPhoto: _viewPodPhoto,
                            onOpenHandover: _openHandoverModal,
                            onOpenAcceptHandover: _openAcceptHandoverModal,
                          ),
                        ),
                        ShipmentRouteTab(
                          shipment: _shipment,
                          estimatedDuration: _estimatedDuration,
                          routePoints: _dynamicRoutePoints,
                          onOpenExternalMaps: _openExternalGoogleMaps,
                          isActive: _selectedTabIndex == 1,
                        ),
                      ],
                    ),
            ),
            if (_selectedTabIndex == 0)
              ShipmentBottomActionBar(
                shipment: _shipment,
                isLoading: _isLoading,
                isUpdatingStatus: _isUpdatingStatus,
                isDelivered: isDelivered,
                podStatus: _podStatus,
                slideActionText: _getSlideActionText(),
                onSlideComplete: _handleSlideToAct,
                onOpenHandover: _openHandoverModal,
                onOpenAcceptHandover: _openAcceptHandoverModal,
                onOpenPodModal: _showLoadDeliveredModal,
              ),
          ],
        ),
      ),
    );
  }
}
