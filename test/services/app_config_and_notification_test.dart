import 'dart:convert';

import 'package:driver_app/app/config/api_config.dart';
import 'package:driver_app/core/constants/api_constants.dart';
import 'package:driver_app/services/app_config_service.dart';
import 'package:driver_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    AppConfigService().resetToDefaults();
  });

  group('AppConfigService', () {
    test(
      'hydrates remote /api/v1/app-config values dynamically onto ApiConstants & ApiConfig',
      () async {
        AppConfigService().setApiBaseUrl('https://api.carrierdirect.test/api/v1/');
        expect(ApiConstants.baseUrl, 'https://api.carrierdirect.test/api/v1');
        expect(ApiConfig.baseUrl, 'https://api.carrierdirect.test/api/v1');

        final mockClient = MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.carrierdirect.test/api/v1/app-config',
          );
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'google_maps_api_key': 'DYNAMIC_TEST_KEY',
                'fcm_enabled': true,
                'fcm_project_id': 'carrierdirect-prod',
                'fcm_sender_id': '123456789',
                'driver_gps_interval_sec': 12,
                'driver_auto_offline_hours': 6,
                'force_update_enabled': true,
                'min_android_version': '2.0.0',
                'min_ios_version': '2.0.0',
                'maintenance_mode': true,
                'maintenance_message': 'Deploying v2',
              },
            }),
            200,
          );
        });

        final loaded = await AppConfigService().loadRemoteConfig(
          client: mockClient,
          syncGpsTracker: false,
        );

        expect(loaded, isTrue);
        expect(ApiConstants.googleMapsApiKey, 'DYNAMIC_TEST_KEY');
        expect(AppConfigService().fcmEnabled, isTrue);
        expect(AppConfigService().fcmProjectId, 'carrierdirect-prod');
        expect(AppConfigService().driverGpsIntervalSec, 12);
        expect(AppConfigService().maintenanceMode, isTrue);
        expect(AppConfigService().maintenanceMessage, 'Deploying v2');
        expect(AppConfigService().requiresForceUpdate, isTrue);
      },
    );

    test('handles failed /app-config fetch gracefully without throwing', () async {
      final failingClient = MockClient((_) async => http.Response('Error', 500));

      final loaded = await AppConfigService().loadRemoteConfig(
        client: failingClient,
        syncGpsTracker: false,
      );

      expect(loaded, isFalse);
      expect(AppConfigService().isRemoteLoaded, isFalse);
      expect(ApiConstants.googleMapsApiKey, isNotEmpty);
    });
  });

  group('NotificationService', () {
    test('initialize and getDeviceToken degrade safely when Firebase native config is absent', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      await NotificationService().initialize();
      final token = await NotificationService().getDeviceToken();

      expect(token, isNull);
      expect(NotificationService().isFirebaseAvailable, isFalse);
    });
  });
}
