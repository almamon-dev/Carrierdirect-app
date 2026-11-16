import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../app/config/app_config.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/local_storage.dart';
import 'order_gps_tracker_service.dart';

/// Holds compile-time `--dart-define` defaults merged with runtime configuration
/// hydrated from the backend `/api/v1/app-config` endpoint.
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  static const String _cacheKey = 'app_runtime_config';
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
    'https://roster-iso-temporal-contacted.trycloudflare.com/api/v1',
  );
  static const String _defaultMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCpMW2SPdb1R3vzV3FsxqM2VEBM4iWhDZk',
  );

  String _apiBaseUrl = _normalizeBaseUrl(_defaultBaseUrl);
  String _googleMapsApiKey = _defaultMapsApiKey;

  bool fcmEnabled = false;
  String fcmProjectId = '';
  String fcmSenderId = '';
  String playStoreUrl = '';
  String appStoreUrl = '';
  String androidPackageName = 'com.carrierdirect.driver';
  String iosBundleId = 'com.carrierdirect.driver';
  int driverGpsIntervalSec = 30;
  int driverAutoOfflineHours = 8;
  bool forceUpdateEnabled = false;
  String minAndroidVersion = '1.0.0';
  String minIosVersion = '1.0.0';
  String latestAndroidVersion = '1.0.0';
  String latestIosVersion = '1.0.0';
  bool maintenanceMode = false;
  String maintenanceMessage = 'App is undergoing scheduled maintenance.';
  bool isRemoteLoaded = false;

  String get apiBaseUrl => _apiBaseUrl;
  String get googleMapsApiKey => _googleMapsApiKey;
  String get appVersion => AppConfig.appVersion;

  String get clientPlatform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  String get minSupportedVersion =>
      clientPlatform == 'ios' ? minIosVersion : minAndroidVersion;

  String get storeUrl => clientPlatform == 'ios' ? appStoreUrl : playStoreUrl;

  bool get requiresForceUpdate =>
      forceUpdateEnabled && isVersionBelow(appVersion, minSupportedVersion);

  void setApiBaseUrl(String url) {
    final normalized = _normalizeBaseUrl(url);
    if (normalized.isNotEmpty) {
      _apiBaseUrl = normalized;
    }
  }

  /// Reset back to compile-time defaults (useful for unit tests).
  void resetToDefaults() {
    _apiBaseUrl = _normalizeBaseUrl(_defaultBaseUrl);
    _googleMapsApiKey = _defaultMapsApiKey;
    fcmEnabled = false;
    fcmProjectId = '';
    fcmSenderId = '';
    playStoreUrl = '';
    appStoreUrl = '';
    androidPackageName = 'com.carrierdirect.driver';
    iosBundleId = 'com.carrierdirect.driver';
    driverGpsIntervalSec = 30;
    driverAutoOfflineHours = 8;
    forceUpdateEnabled = false;
    minAndroidVersion = '1.0.0';
    minIosVersion = '1.0.0';
    latestAndroidVersion = '1.0.0';
    latestIosVersion = '1.0.0';
    maintenanceMode = false;
    maintenanceMessage = 'App is undergoing scheduled maintenance.';
    isRemoteLoaded = false;
  }

  /// Fetch `/api/v1/app-config` without throwing so offline startup still works.
  Future<bool> loadRemoteConfig({
    http.Client? client,
    Duration timeout = const Duration(seconds: 4),
    bool syncGpsTracker = true,
  }) async {
    await _hydrateFromCache(syncGpsTracker: false);

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    try {
      final uri = Uri.parse('$_apiBaseUrl${ApiConstants.appConfig}');
      final response = await httpClient
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final payload = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;

      applyConfigJson(payload, syncGpsTracker: syncGpsTracker);
      isRemoteLoaded = true;
      await LocalStorage().setString(_cacheKey, jsonEncode(payload));
      return true;
    } catch (e) {
      debugPrint('AppConfigService remote load skipped: $e');
      return false;
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  void applyConfigJson(
    Map<String, dynamic> data, {
    bool syncGpsTracker = true,
  }) {
    final mapsKey = (data['google_maps_api_key'] ?? '').toString().trim();
    if (mapsKey.isNotEmpty) {
      _googleMapsApiKey = mapsKey;
    }

    fcmEnabled = _parseBool(data['fcm_enabled'], fallback: fcmEnabled);
    fcmProjectId = (data['fcm_project_id'] ?? fcmProjectId).toString();
    fcmSenderId = (data['fcm_sender_id'] ?? fcmSenderId).toString();
    playStoreUrl = (data['play_store_url'] ?? playStoreUrl).toString();
    appStoreUrl = (data['app_store_url'] ?? appStoreUrl).toString();

    final pkg = (data['android_package_name'] ?? '').toString().trim();
    if (pkg.isNotEmpty) androidPackageName = pkg;

    final bundle = (data['ios_bundle_id'] ?? '').toString().trim();
    if (bundle.isNotEmpty) iosBundleId = bundle;

    driverGpsIntervalSec = _parseInt(
      data['driver_gps_interval_sec'],
      fallback: driverGpsIntervalSec,
    );
    driverAutoOfflineHours = _parseInt(
      data['driver_auto_offline_hours'],
      fallback: driverAutoOfflineHours,
    );
    forceUpdateEnabled = _parseBool(
      data['force_update_enabled'],
      fallback: forceUpdateEnabled,
    );
    minAndroidVersion =
        (data['min_android_version'] ?? minAndroidVersion).toString();
    minIosVersion = (data['min_ios_version'] ?? minIosVersion).toString();
    latestAndroidVersion =
        (data['latest_android_version'] ?? latestAndroidVersion).toString();
    latestIosVersion =
        (data['latest_ios_version'] ?? latestIosVersion).toString();
    maintenanceMode = _parseBool(
      data['maintenance_mode'],
      fallback: maintenanceMode,
    );

    final maintMsg = (data['maintenance_message'] ?? '').toString().trim();
    if (maintMsg.isNotEmpty) {
      maintenanceMessage = maintMsg;
    }

    if (syncGpsTracker) {
      OrderGpsTrackerService().configureInterval(driverGpsIntervalSec);
    }
  }

  Future<void> _hydrateFromCache({bool syncGpsTracker = false}) async {
    try {
      final raw = await LocalStorage().getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        applyConfigJson(decoded, syncGpsTracker: syncGpsTracker);
      }
    } catch (_) {}
  }

  static bool isVersionBelow(String current, String minimum) {
    final cParts = current.split('+').first.split('.');
    final mParts = minimum.split('+').first.split('.');
    final maxLen = cParts.length > mParts.length ? cParts.length : mParts.length;
    for (int i = 0; i < maxLen; i++) {
      final c = i < cParts.length ? (int.tryParse(cParts[i]) ?? 0) : 0;
      final m = i < mParts.length ? (int.tryParse(mParts[i]) ?? 0) : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _parseBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return fallback;
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }
}
