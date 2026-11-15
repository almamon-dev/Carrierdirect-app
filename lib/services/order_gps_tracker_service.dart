import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/secure_storage.dart';
import '../features/trips/data/models/shipment_item_model.dart';
import 'location_service.dart';

class OrderGpsTrackerService {
  static final OrderGpsTrackerService _instance =
      OrderGpsTrackerService._internal();
  factory OrderGpsTrackerService() => _instance;
  OrderGpsTrackerService._internal();

  static const String _storageKeyActiveShipment = 'cd_active_tracked_shipment';
  static const String _storageKeyOfflineQueue = 'cd_offline_gps_queue';
  static const int _maxOfflineQueueSize = 50;

  ShipmentItem? _activeShipment;
  bool _isTracking = false;
  bool _isRequestInFlight = false;
  int _updateIntervalSeconds = 10;
  Timer? _syncTimer;
  StreamSubscription<LocationData>? _locationSub;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  final List<Map<String, dynamic>> _offlineQueue = [];

  http.Client _httpClient = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _httpClient = client;

  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<LocationData?> lastLocationNotifier =
      ValueNotifier<LocationData?>(null);
  final ValueNotifier<bool> isGpsDisabledNotifier = ValueNotifier<bool>(false);

  bool get isTracking => _isTracking;
  int get updateIntervalSeconds => _updateIntervalSeconds;
  ShipmentItem? get activeShipment => _activeShipment;
  List<Map<String, dynamic>> get offlineQueue =>
      List.unmodifiable(_offlineQueue);

  /// Configure GPS update interval dynamically (default 10 seconds)
  void configureInterval(int seconds) {
    _updateIntervalSeconds = seconds.clamp(5, 120);
    if (_isTracking && _activeShipment != null) {
      _restartPeriodicTimer();
    }
  }

  /// Check whether a shipment status is eligible for live GPS tracking
  static bool isShipmentEligibleForTracking(ShipmentItem shipment) {
    final raw = shipment.rawStatus.trim().toLowerCase();
    if (raw == 'delivered' ||
        raw == 'pod_uploaded' ||
        raw == 'pod_review' ||
        raw == 'completed' ||
        raw == 'cancelled') {
      return false;
    }
    return shipment.status == ShipmentFilter.inProgress ||
        raw == 'driver_assigned' ||
        raw == 'assigned' ||
        raw == 'in_progress' ||
        raw == 'picked_up' ||
        raw == 'in_transit' ||
        raw == 'on_the_way' ||
        raw == 'arrived';
  }

  /// Start streaming live GPS telemetry for a specific order to the backend
  Future<bool> startTracking(
    ShipmentItem shipment, {
    int? intervalSeconds,
  }) async {
    try {
      if (!isShipmentEligibleForTracking(shipment)) {
        stopTracking();
        return false;
      }

      if (intervalSeconds != null) {
        _updateIntervalSeconds = intervalSeconds.clamp(5, 120);
      }

      // Prevent duplicate tracking initialization if already tracking the same shipment
      final sameOrder = _isTracking &&
          _activeShipment != null &&
          (_activeShipment!.dbId == shipment.dbId &&
              _activeShipment!.id == shipment.id);

      _activeShipment = shipment;
      _isTracking = true;
      isTrackingNotifier.value = true;
      await _persistActiveShipmentState(shipment);
      await _restoreOfflineQueue();

      if (sameOrder && _locationSub != null && _syncTimer != null) {
        return true;
      }

      // 1. Check whether device location services (hardware GPS) are turned on
      final isServiceEnabled =
          await LocationService().isLocationServiceEnabled();
      isGpsDisabledNotifier.value = !isServiceEnabled;

      // 2. Check & request runtime permissions
      final hasPerm = await LocationService().checkPermission();
      if (!hasPerm) {
        final granted = await LocationService().requestPermission();
        if (!granted) {
          isGpsDisabledNotifier.value = true;
          return false;
        }
      }

      // 3. Monitor live hardware GPS status stream in real time
      await _serviceStatusSub?.cancel();
      _serviceStatusSub = LocationService().serviceStatusStream.listen((status) {
        if (status == ServiceStatus.disabled) {
          isGpsDisabledNotifier.value = true;
          _notifyGpsSignalStatus(isAvailable: false);
        } else if (status == ServiceStatus.enabled) {
          isGpsDisabledNotifier.value = false;
          _startLocationListening();
          _sendCurrentLocation();
          _notifyGpsSignalStatus(isAvailable: true);
        }
      });

      // 4. Listen to continuous GPS hardware position updates (Android Foreground Service / iOS Background)
      _startLocationListening();

      // 5. Send initial location immediately if GPS is active
      if (!isGpsDisabledNotifier.value) {
        await _sendCurrentLocation();
      }

      // 6. Synchronize location to backend API online at configurable interval (default 10s)
      _restartPeriodicTimer();

      return true;
    } catch (_) {
      return false;
    }
  }

  void _restartPeriodicTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: _updateIntervalSeconds),
      (_) {
        if (!isGpsDisabledNotifier.value && _isTracking) {
          _sendCurrentLocation();
        }
      },
    );
  }

  void _startLocationListening() {
    _locationSub?.cancel();
    try {
      _locationSub = LocationService()
          .getLocationStream(intervalSeconds: _updateIntervalSeconds)
          .listen(
            (loc) {
              if (!loc.isValid) return;
              lastLocationNotifier.value = loc;
              if (isGpsDisabledNotifier.value) {
                isGpsDisabledNotifier.value = false;
              }
            },
            onError: (err) {
              isGpsDisabledNotifier.value = true;
            },
          );
    } catch (_) {
      isGpsDisabledNotifier.value = true;
    }
  }

  /// Stop tracking when trip is delivered, completed, canceled, or driver reassigned
  void stopTracking({bool clearQueue = false}) {
    _syncTimer?.cancel();
    _syncTimer = null;
    _serviceStatusSub?.cancel();
    _serviceStatusSub = null;
    _locationSub?.cancel();
    _locationSub = null;
    _isTracking = false;
    _isRequestInFlight = false;
    _activeShipment = null;
    isTrackingNotifier.value = false;
    isGpsDisabledNotifier.value = false;
    SecureStorage().delete(_storageKeyActiveShipment);
    if (clearQueue) {
      _offlineQueue.clear();
      SecureStorage().delete(_storageKeyOfflineQueue);
    }
  }

  /// Recover active shipment tracking after app restart if an active shipment exists
  Future<bool> recoverActiveShipmentTracking(
    List<ShipmentItem> currentShipments,
  ) async {
    try {
      if (_isTracking && _activeShipment != null) {
        // Verify active shipment is still in currentShipments and eligible
        final match = currentShipments.where((s) =>
            (s.dbId.isNotEmpty && s.dbId == _activeShipment!.dbId) ||
            s.id == _activeShipment!.id);
        if (match.isNotEmpty) {
          final updated = match.first;
          if (!isShipmentEligibleForTracking(updated)) {
            stopTracking();
            return false;
          }
          _activeShipment = updated;
          return true;
        }
      }

      // Check persisted active shipment ID or find any active inProgress shipment
      final savedId = await SecureStorage().read(_storageKeyActiveShipment);
      ShipmentItem? target;

      if (savedId != null && savedId.isNotEmpty) {
        for (final s in currentShipments) {
          if ((s.dbId == savedId || s.id == savedId) &&
              isShipmentEligibleForTracking(s)) {
            target = s;
            break;
          }
        }
      }

      target ??= currentShipments
          .where((s) => isShipmentEligibleForTracking(s))
          .firstOrNull;

      if (target != null) {
        return await startTracking(target);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistActiveShipmentState(ShipmentItem shipment) async {
    try {
      final key = shipment.dbId.trim().isNotEmpty
          ? shipment.dbId.trim()
          : shipment.id.trim();
      if (key.isNotEmpty) {
        await SecureStorage().write(_storageKeyActiveShipment, key);
      }
    } catch (_) {}
  }

  Future<void> _enqueueOfflineLocation(Map<String, dynamic> payload) async {
    final entry = {
      'latitude': payload['latitude'],
      'longitude': payload['longitude'],
      'accuracy': payload['accuracy'],
      'speed': payload['speed'],
      'heading': payload['heading'],
      'recorded_at': payload['recorded_at'],
      'order_id': payload['order_id'],
    };
    _offlineQueue.add(entry);
    if (_offlineQueue.length > _maxOfflineQueueSize) {
      _offlineQueue.removeAt(0);
    }
    try {
      await SecureStorage().write(
        _storageKeyOfflineQueue,
        jsonEncode(_offlineQueue),
      );
    } catch (_) {}
  }

  Future<void> _restoreOfflineQueue() async {
    if (_offlineQueue.isNotEmpty) return;
    try {
      final raw = await SecureStorage().read(_storageKeyOfflineQueue);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              _offlineQueue.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<int?> _resolveAuthenticatedDriverId() async {
    try {
      final rawUser = await SecureStorage().read(AppConstants.keyUserData);
      if (rawUser != null && rawUser.isNotEmpty) {
        final map = jsonDecode(rawUser);
        if (map is Map && map['id'] != null) {
          return int.tryParse(map['id'].toString());
        }
      }
    } catch (_) {}
    return null;
  }

  /// Notify backend dispatch whether GPS is live or signal was interrupted
  Future<void> _notifyGpsSignalStatus({required bool isAvailable}) async {
    if (_activeShipment == null) return;
    try {
      final token = await SecureStorage().read(AppConstants.keyAuthToken);
      if (token == null || token.isEmpty) return;

      final rawDbId = _activeShipment!.dbId.trim();
      final cleanOrderNum =
          _activeShipment!.id.replaceAll(RegExp(r'[^0-9]'), '');
      final orderId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.updateLocation}',
      );

      final loc = lastLocationNotifier.value;
      if (loc == null || !loc.isValid) return;

      await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'latitude': loc.latitude,
              'longitude': loc.longitude,
              'accuracy': loc.accuracy,
              'speed': 0.0,
              'heading': loc.heading ?? 0.0,
              'order_id': orderId.isNotEmpty ? orderId : null,
              'recorded_at': DateTime.now().toUtc().toIso8601String(),
              'address': isAvailable
                  ? 'GPS Signal Restored'
                  : 'GPS Signal Lost / Location Disabled by Driver',
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Send coordinates to backend `POST /api/v1/driver/location`
  Future<bool> sendCurrentLocationNow() => _sendCurrentLocation();

  Future<bool> _sendCurrentLocation() async {
    if (!_isTracking ||
        _activeShipment == null ||
        isGpsDisabledNotifier.value ||
        _isRequestInFlight) {
      return false;
    }

    _isRequestInFlight = true;
    Map<String, dynamic>? payload;

    try {
      final token = await SecureStorage().read(AppConstants.keyAuthToken);
      if (token == null || token.isEmpty) {
        return false;
      }

      LocationData? loc = lastLocationNotifier.value;
      loc ??= await LocationService().getCurrentLocation();
      if (loc == null || !loc.isValid) {
        return false;
      }

      final rawDbId = _activeShipment!.dbId.trim();
      final cleanOrderNum =
          _activeShipment!.id.replaceAll(RegExp(r'[^0-9]'), '');
      final orderId = rawDbId.isNotEmpty ? rawDbId : cleanOrderNum;
      final driverId = await _resolveAuthenticatedDriverId();

      final speedKmH = (loc.speed != null && loc.speed! > 0)
          ? (loc.speed! * 3.6)
          : 0.0;

      final recordedIso = loc.timestamp.toUtc().toIso8601String();

      payload = {
        'driver_id': ?driverId,
        'order_id': orderId.isNotEmpty ? orderId : null,
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'accuracy': ?loc.accuracy,
        'speed': speedKmH,
        'heading': loc.heading ?? 0.0,
        'recorded_at': recordedIso,
        if (_offlineQueue.isNotEmpty)
          'batch': List<Map<String, dynamic>>.from(_offlineQueue),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.updateLocation}',
      );

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (_offlineQueue.isNotEmpty) {
          _offlineQueue.clear();
          await SecureStorage().delete(_storageKeyOfflineQueue);
        }
        return true;
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        // Driver was unassigned/reassigned from this shipment -> stop tracking immediately
        stopTracking(clearQueue: true);
        return false;
      } else if (response.statusCode == 422) {
        // Check if shipment is no longer eligible (delivered/completed/cancelled)
        final bodyStr = response.body.toLowerCase();
        if (bodyStr.contains('not eligible')) {
          stopTracking(clearQueue: true);
        }
        return false;
      } else {
        await _enqueueOfflineLocation(payload);
        return false;
      }
    } catch (_) {
      if (payload != null) {
        await _enqueueOfflineLocation(payload);
      }
      return false;
    } finally {
      _isRequestInFlight = false;
    }
  }
}
