import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  bool get isValid {
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return false;
    }
    if (latitude.abs() < 0.00001 && longitude.abs() < 0.00001) {
      return false;
    }
    if (accuracy != null && accuracy! > 500.0) {
      return false;
    }
    return true;
  }
}

class LocationService {
  static LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  @visibleForTesting
  LocationService.testing();

  @visibleForTesting
  static set instance(LocationService mock) => _instance = mock;

  /// Check whether location permission has already been granted
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Request runtime location permission from the Android/iOS system
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return true;
    }
  }

  /// Check if permission is permanently denied (requiring app settings)
  Future<bool> isPermanentlyDenied() async {
    try {
      final status = await Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Open application settings so user can grant permission manually
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Return real current GPS location from device hardware
  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        await requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        heading: pos.heading,
        speed: pos.speed,
        timestamp: pos.timestamp,
      );
    } catch (_) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return LocationData(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            accuracy: lastKnown.accuracy,
            heading: lastKnown.heading,
            speed: lastKnown.speed,
            timestamp: lastKnown.timestamp,
          );
        }
      } catch (_) {}
      return null;
    }
  }

  /// Check whether device location services (hardware GPS) are turned on
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Direct access to open device location settings (GPS toggle page)
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Stream changes to device location service status (enabled / disabled)
  Stream<ServiceStatus> get serviceStatusStream {
    return Geolocator.getServiceStatusStream();
  }

  /// Verify whether both permission is granted AND GPS hardware is switched on
  Future<bool> isGpsReady() async {
    final enabled = await isLocationServiceEnabled();
    if (!enabled) return false;
    final permitted = await checkPermission();
    return permitted;
  }

  /// Build platform-specific background/foreground location settings
  LocationSettings buildPlatformLocationSettings({int intervalSeconds = 10}) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: Duration(seconds: intervalSeconds),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'CarrierDirect Active Shipment',
          notificationText:
              'Live GPS tracking is active for your assigned shipment.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  /// Stream live location updates from GPS hardware (with Android Foreground Service & iOS Background Mode)
  Stream<LocationData> getLocationStream({int intervalSeconds = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: buildPlatformLocationSettings(
        intervalSeconds: intervalSeconds,
      ),
    ).map(
      (pos) => LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        heading: pos.heading,
        speed: pos.speed,
        timestamp: pos.timestamp,
      ),
    );
  }

  Stream<LocationData> get locationStream => getLocationStream();
}
