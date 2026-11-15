import 'dart:async';
import 'dart:convert';

import 'package:driver_app/core/constants/app_constants.dart';
import 'package:driver_app/core/storage/secure_storage.dart';
import 'package:driver_app/features/trips/data/models/shipment_item_model.dart';
import 'package:driver_app/services/location_service.dart';
import 'package:driver_app/services/order_gps_tracker_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeLocationService extends LocationService {
  FakeLocationService() : super.testing();

  bool serviceEnabled = true;
  bool permissionGranted = true;
  bool requestPermissionResult = true;
  int streamListenCount = 0;
  LocationData? currentLoc;

  final StreamController<LocationData> locationController =
      StreamController<LocationData>.broadcast(
        onListen: () {},
      );
  final StreamController<ServiceStatus> statusController =
      StreamController<ServiceStatus>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> checkPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => requestPermissionResult;

  @override
  Future<LocationData?> getCurrentLocation() async => currentLoc;

  @override
  Stream<ServiceStatus> get serviceStatusStream => statusController.stream;

  @override
  Stream<LocationData> getLocationStream({int intervalSeconds = 10}) {
    streamListenCount++;
    return locationController.stream;
  }

  void dispose() {
    locationController.close();
    statusController.close();
  }
}

ShipmentItem buildTestShipment({
  String id = 'ORD-2026-10006',
  String dbId = '106',
  ShipmentFilter status = ShipmentFilter.inProgress,
  String rawStatus = 'in_transit',
}) {
  return ShipmentItem(
    id: id,
    dbId: dbId,
    originTitle: 'Dhaka Airport',
    originAddress: 'Airport Rd, Dhaka',
    destTitle: 'Progati Sarani',
    destAddress: 'Progati Sarani Rd, Dhaka',
    distanceKm: 14.5,
    cargoType: 'General Cargo',
    status: status,
    statusLabel: rawStatus,
    rawStatus: rawStatus,
    time: '09:30 AM',
    date: 'Nov 08, 2026',
    originLat: 23.8433,
    originLng: 90.3978,
    destLat: 23.8103,
    destLng: 90.4225,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocationService fakeLocation;
  late OrderGpsTrackerService tracker;

  setUp(() async {
    await SecureStorage().deleteAll();
    await SecureStorage().write(AppConstants.keyAuthToken, 'test-driver-token');
    await SecureStorage().write(
      AppConstants.keyUserData,
      jsonEncode({'id': 42, 'name': 'Test Driver'}),
    );

    fakeLocation = FakeLocationService();
    fakeLocation.currentLoc = LocationData(
      latitude: 23.8250,
      longitude: 90.4120,
      accuracy: 8.5,
      speed: 11.0,
      heading: 170.0,
      timestamp: DateTime.utc(2026, 11, 8, 15, 0, 0),
    );
    LocationService.instance = fakeLocation;

    tracker = OrderGpsTrackerService();
    tracker.stopTracking(clearQueue: true);
    tracker.lastLocationNotifier.value = null;
    tracker.configureInterval(10);
  });

  tearDown(() {
    tracker.stopTracking(clearQueue: true);
    debugDefaultTargetPlatformOverride = null;
    fakeLocation.dispose();
  });

  test('1. GPS permission handling denies start when permission is rejected and succeeds when granted', () async {
    int apiCalls = 0;
    tracker.httpClient = MockClient((req) async {
      apiCalls++;
      return http.Response(jsonEncode({'success': true}), 200);
    });

    // Denied permission -> returns false and marks GPS unavailable
    fakeLocation.permissionGranted = false;
    fakeLocation.requestPermissionResult = false;

    final deniedStarted = await tracker.startTracking(buildTestShipment());
    expect(deniedStarted, isFalse);
    expect(tracker.isGpsDisabledNotifier.value, isTrue);
    expect(apiCalls, 0);

    // Granted on prompt -> succeeds and sends initial location
    tracker.stopTracking(clearQueue: true);
    fakeLocation.permissionGranted = false;
    fakeLocation.requestPermissionResult = true;

    final grantedStarted = await tracker.startTracking(buildTestShipment());
    expect(grantedStarted, isTrue);
    expect(tracker.isTracking, isTrue);
    expect(tracker.isGpsDisabledNotifier.value, isFalse);
    expect(apiCalls, 1);
  });

  test('2. Tracking start and stop lifecycle respects shipment status and reassignment', () async {
    Map<String, dynamic>? sentBody;
    tracker.httpClient = MockClient((req) async {
      sentBody = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'success': true}), 200);
    });

    // Completed/delivered shipment must not start tracking
    final deliveredShipment = buildTestShipment(
      status: ShipmentFilter.completed,
      rawStatus: 'delivered',
    );
    expect(await tracker.startTracking(deliveredShipment), isFalse);
    expect(tracker.isTracking, isFalse);

    // Eligible active shipment starts tracking and transmits full telemetry payload
    final activeShipment = buildTestShipment(rawStatus: 'in_transit');
    expect(await tracker.startTracking(activeShipment), isTrue);
    expect(tracker.isTracking, isTrue);
    expect(sentBody, isNotNull);
    expect(sentBody!['driver_id'], 42);
    expect(sentBody!['order_id'], '106');
    expect(sentBody!['latitude'], 23.8250);
    expect(sentBody!['longitude'], 90.4120);
    expect(sentBody!['accuracy'], 8.5);
    expect(sentBody!['recorded_at'], isNotEmpty);

    // Server returning 403 (driver reassigned) automatically stops tracking
    tracker.httpClient = MockClient((req) async {
      return http.Response(
        jsonEncode({'success': false, 'message': 'Not assigned'}),
        403,
      );
    });
    await tracker.sendCurrentLocationNow();
    expect(tracker.isTracking, isFalse);
    expect(tracker.activeShipment, isNull);
  });

  test('3. Background tracking configuration sets Android ForegroundNotificationConfig and iOS background flags', () {
    final realService = LocationService.testing();

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final androidSettings = realService.buildPlatformLocationSettings(
      intervalSeconds: 15,
    );
    expect(androidSettings, isA<AndroidSettings>());
    final android = androidSettings as AndroidSettings;
    expect(android.intervalDuration, const Duration(seconds: 15));
    expect(android.foregroundNotificationConfig, isNotNull);
    expect(android.foregroundNotificationConfig!.enableWakeLock, isTrue);
    expect(android.foregroundNotificationConfig!.setOngoing, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final iosSettings = realService.buildPlatformLocationSettings(
      intervalSeconds: 15,
    );
    expect(iosSettings, isA<AppleSettings>());
    final apple = iosSettings as AppleSettings;
    expect(apple.allowBackgroundLocationUpdates, isTrue);
    expect(apple.pauseLocationUpdatesAutomatically, isFalse);
    expect(apple.showBackgroundLocationIndicator, isTrue);

    debugDefaultTargetPlatformOverride = null;

    // Interval clamping validation (5s..120s)
    tracker.configureInterval(2);
    expect(tracker.updateIntervalSeconds, 5);
    tracker.configureInterval(15);
    expect(tracker.updateIntervalSeconds, 15);
  });

  test('4. Network failure handling catches exceptions gracefully without crashing active session', () async {
    tracker.httpClient = MockClient((req) async {
      throw Exception('SocketException: Network unreachable');
    });

    final started = await tracker.startTracking(buildTestShipment());
    expect(started, isTrue);
    expect(tracker.isTracking, isTrue);
    expect(tracker.offlineQueue.length, 1);
  });

  test('5. Offline location queue buffers coordinates when offline and syncs batch without sending stale point as live', () async {
    bool isOffline = true;
    final List<Map<String, dynamic>> receivedPayloads = [];

    tracker.httpClient = MockClient((req) async {
      if (isOffline) {
        return http.Response('Service Unavailable', 503);
      }
      final decoded = jsonDecode(req.body) as Map<String, dynamic>;
      receivedPayloads.add(decoded);
      return http.Response(jsonEncode({'success': true}), 200);
    });

    // First point while offline -> queued locally
    fakeLocation.currentLoc = LocationData(
      latitude: 23.8100,
      longitude: 90.4000,
      accuracy: 10.0,
      timestamp: DateTime.utc(2026, 11, 8, 15, 0, 0),
    );
    await tracker.startTracking(buildTestShipment());
    expect(tracker.offlineQueue.length, 1);

    // Connectivity returns with a NEW live coordinate -> live coordinate is top-level, stale point is in batch
    isOffline = false;
    final newerLoc = LocationData(
      latitude: 23.8350,
      longitude: 90.4250,
      accuracy: 6.0,
      timestamp: DateTime.utc(2026, 11, 8, 15, 2, 0),
    );
    tracker.lastLocationNotifier.value = newerLoc;

    final synced = await tracker.sendCurrentLocationNow();
    expect(synced, isTrue);
    expect(tracker.offlineQueue, isEmpty);
    expect(receivedPayloads.length, 1);

    final syncedPayload = receivedPayloads.first;
    expect(syncedPayload['latitude'], 23.8350);
    expect(syncedPayload['longitude'], 90.4250);
    expect(syncedPayload['batch'], isA<List>());
    expect((syncedPayload['batch'] as List).length, 1);
    expect((syncedPayload['batch'] as List).first['latitude'], 23.8100);
  });

  test('6. Active shipment recovery resumes tracking on app restart and stops if delivered', () async {
    tracker.httpClient = MockClient((req) async {
      return http.Response(jsonEncode({'success': true}), 200);
    });

    // Simulate persisted active shipment ID before app restart
    await SecureStorage().write('cd_active_tracked_shipment', '106');

    final shipmentsOnBoot = [
      buildTestShipment(id: 'ORD-2026-10006', dbId: '106', rawStatus: 'in_transit'),
    ];

    final recovered = await tracker.recoverActiveShipmentTracking(shipmentsOnBoot);
    expect(recovered, isTrue);
    expect(tracker.isTracking, isTrue);
    expect(tracker.activeShipment?.dbId, '106');

    // If subsequent dashboard sync shows shipment was delivered, recovery stops tracking
    final deliveredList = [
      buildTestShipment(
        id: 'ORD-2026-10006',
        dbId: '106',
        status: ShipmentFilter.completed,
        rawStatus: 'delivered',
      ),
    ];
    final stillActive = await tracker.recoverActiveShipmentTracking(deliveredList);
    expect(stillActive, isFalse);
    expect(tracker.isTracking, isFalse);
  });

  test('7. Duplicate tracking and concurrent API request prevention', () async {
    final Completer<http.Response> inFlightCompleter = Completer<http.Response>();
    int httpCallCount = 0;

    tracker.httpClient = MockClient((req) async {
      httpCallCount++;
      if (!inFlightCompleter.isCompleted) {
        return inFlightCompleter.future;
      }
      return http.Response(jsonEncode({'success': true}), 200);
    });

    // Verify singleton instance
    expect(identical(OrderGpsTrackerService(), tracker), isTrue);

    // Complete initial startTracking quickly
    inFlightCompleter.complete(http.Response(jsonEncode({'success': true}), 200));
    final shipment = buildTestShipment();
    await tracker.startTracking(shipment);
    expect(fakeLocation.streamListenCount, 1);

    // Calling startTracking again with the same shipment must NOT create a duplicate stream subscription
    await tracker.startTracking(shipment);
    expect(fakeLocation.streamListenCount, 1);

    // Concurrent sendCurrentLocationNow calls while a request is in flight must not send duplicate HTTP posts
    final Completer<http.Response> slowRequest = Completer<http.Response>();
    httpCallCount = 0;
    tracker.httpClient = MockClient((req) {
      httpCallCount++;
      return slowRequest.future;
    });

    final firstFuture = tracker.sendCurrentLocationNow();
    final duplicateFuture = tracker.sendCurrentLocationNow();

    expect(await duplicateFuture, isFalse);

    slowRequest.complete(http.Response(jsonEncode({'success': true}), 200));
    expect(await firstFuture, isTrue);
    expect(httpCallCount, 1);
  });
}
