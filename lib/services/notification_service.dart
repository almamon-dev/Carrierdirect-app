import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../app/app.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/routes/app_routes.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import 'app_config_service.dart';

/// Top-level background FCM handler required by firebase_messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('FCM background init skipped: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _androidChannelId = 'carrierdirect_driver_channel';
  static const String _androidChannelName = 'CarrierDirect Driver Alerts';
  static const String _androidChannelDescription =
      'Dispatch assignments, handover OTPs, messages, and POD alerts.';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, dynamic>> _payloadController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _initialized = false;
  bool _firebaseAvailable = false;
  String? _cachedToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  bool get isFirebaseAvailable => _firebaseAvailable;
  String? get cachedToken => _cachedToken;
  Stream<Map<String, dynamic>> get onNotificationTap =>
      _payloadController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload == null || details.payload!.isEmpty) return;
          try {
            final decoded = jsonDecode(details.payload!);
            if (decoded is Map<String, dynamic>) {
              _handleNotificationTap(decoded);
            }
          } catch (_) {}
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            description: _androidChannelDescription,
            importance: Importance.high,
          ),
        );
      }
    } catch (e) {
      debugPrint('Local notifications init skipped: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseAvailable = true;

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final title =
            notification?.title ?? message.data['title']?.toString() ?? '';
        final body =
            notification?.body ?? message.data['body']?.toString() ?? '';

        if (title.isNotEmpty || body.isNotEmpty) {
          // On iOS, APNs foreground presentation options display the banner natively.
          if (kIsWeb || !Platform.isIOS) {
            showNotification(
              title: title.isNotEmpty ? title : 'CarrierDirect Alert',
              body: body,
              payload: message.data,
            );
          }
        }
      });

      _onMessageOpenedSub?.cancel();
      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        _handleNotificationTap(message.data);
      });

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage.data);
        });
      }

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) {
        _cachedToken = token;
        unawaited(syncTokenWithBackend(token: token));
      });
    } catch (e) {
      // Safe fallback when native google-services.json / GoogleService-Info.plist
      // has not been placed into android/app or ios/Runner yet.
      _firebaseAvailable = false;
      debugPrint('Firebase messaging unavailable (native config missing?): $e');
    }
  }

  /// Fetch current FCM device token safely for Android & Apple APNs devices.
  Future<String?> getDeviceToken() async {
    if (!_firebaseAvailable) return _cachedToken;
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        // Ensure APNs token negotiation is ready before asking FCM for token on Apple devices.
        await FirebaseMessaging.instance.getAPNSToken();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
      }
      return _cachedToken;
    } catch (e) {
      debugPrint('Failed to get FCM device token: $e');
      return _cachedToken;
    }
  }

  /// Register or refresh current device FCM token on backend `/api/v1/driver/device-token`.
  Future<bool> syncTokenWithBackend({String? token}) async {
    try {
      final authToken =
          await SecureStorage().read(AppConstants.keyAuthToken) ??
          await LocalStorage().getString(AppConstants.keyAuthToken);
      if (authToken == null || authToken.isEmpty) {
        return false;
      }

      final deviceToken = token ?? _cachedToken ?? await getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) {
        return false;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.deviceToken}',
      );
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'device_token': deviceToken,
              'device_type': AppConfigService().clientPlatform,
              'app_version': AppConfigService().appVersion,
            }),
          )
          .timeout(const Duration(seconds: 6));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('FCM device token backend sync failed: $e');
      return false;
    }
  }

  /// Check whether notification permission has already been granted.
  Future<bool> checkPermission() async {
    try {
      if (_firebaseAvailable && !kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        final settings = await FirebaseMessaging.instance
            .getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          return true;
        }
      }
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Request notification permission for both Android 13+ and iOS APNs.
  Future<bool> requestPermissions() async {
    try {
      bool granted = false;

      if (_firebaseAvailable) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        granted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }

      if (!granted) {
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        granted = status.isGranted || status.isLimited;
      }

      if (granted) {
        unawaited(syncTokenWithBackend());
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload != null ? jsonEncode(payload) : null,
      );
    } catch (e) {
      debugPrint('Show local notification failed: $e');
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    _payloadController.add(data);

    final nav = App.navigatorKey.currentState;
    if (nav == null) return;

    final authToken =
        await SecureStorage().read(AppConstants.keyAuthToken) ??
        await LocalStorage().getString(AppConstants.keyAuthToken);
    if (authToken == null || authToken.isEmpty) return;

    final type = (data['type'] ?? '').toString().toLowerCase();
    if (type == 'chat_message') {
      nav.push(MaterialPageRoute(builder: (_) => const ChatInboxScreen()));
    } else if (data['order_id'] != null &&
        data['order_id'].toString().isNotEmpty) {
      nav.pushNamed(AppRoutes.orderDetails);
    } else {
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _payloadController.close();
  }
}
