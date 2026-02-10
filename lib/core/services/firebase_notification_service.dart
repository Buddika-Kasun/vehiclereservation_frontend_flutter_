import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Initialize local notifications
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android notification details
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  // Show notification
  if (message.notification != null) {
    await localNotifications.show(
      0,
      message.notification!.title,
      message.notification!.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  if (kDebugMode) {
    print("Background message: ${message.messageId}");
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  late FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStream.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();

      // 2. Initialize Firebase Messaging
      _fcm = FirebaseMessaging.instance;

      // 3. Configure Android notification channel
      await _configureAndroidNotificationChannel();

      // 4. Initialize Local Notifications
      await _initLocalNotifications();

      // 5. Request Permissions
      await _requestPermissions();

      // 6. Configure message handlers
      await _configureMessageHandlers();

      // 7. Get and save token
      await _getAndSaveToken();

      // 8. Handle initial message (if app opened from notification)
      await _handleInitialMessage();

      _isInitialized = true;

      if (kDebugMode) {
        print("✅ Firebase Notification Service Initialized");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Firebase Notification Service Error: $e");
      }
    }
  }

  Future<void> _configureAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationClick(response.payload);
      },
    );
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _configureMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification clicks
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Token refresh handler
    _fcm.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> _getAndSaveToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await SecureStorageService().saveFcmToken(token);
        await _sendTokenToBackend(token);

        if (kDebugMode) {
          print("📱 FCM Token: ${token.substring(0, 15)}...");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting FCM token: $e");
      }
    }
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print("📨 Foreground message: ${message.messageId}");
    }

    // Emit to stream
    _notificationStream.add(message.data);

    // Show local notification
    _showLocalNotification(message);
  }

  void _showLocalNotification(RemoteMessage message) {
    if (message.notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    _localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      platformDetails,
      payload: message.data.toString(),
    );
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      print("🖱️ Notification clicked: ${message.data}");
    }

    _notificationStream.add(message.data);
    _navigateToNotificationScreen(message.data);
  }

  void _handleLocalNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final payloadData = _parsePayload(payload);
      _notificationStream.add(payloadData);
      _navigateToNotificationScreen(payloadData);
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing payload: $e");
      }
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      final cleanPayload = payload.replaceAll('{', '').replaceAll('}', '');
      final pairs = cleanPayload.split(', ');
      final Map<String, dynamic> result = {};

      for (final pair in pairs) {
        final split = pair.split(': ');
        if (split.length == 2) {
          result[split[0].trim()] = split[1].trim();
        }
      }
      return result;
    } catch (e) {
      return {'raw_payload': payload};
    }
  }

  void _navigateToNotificationScreen(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AuthManager.navigatorKey.currentContext;
      if (context != null) {
        // Navigate to your notification screen
        // You can customize this based on your app structure
        Navigator.pushNamed(context, '/notifications');
      }
    });
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) {
        print("Error getting token: $e");
      }
      return null;
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    await SecureStorageService().saveFcmToken(newToken);
    await _sendTokenToBackend(newToken);

    if (kDebugMode) {
      print("🔄 Token refreshed: ${newToken.substring(0, 15)}...");
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await SecureStorageService().isUserLoggedIn();
      if (!isLoggedIn) return;

      await ApiService.updateFcmToken(fcmToken: token);

      if (kDebugMode) {
        print("✅ Token sent to backend");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending token to backend: $e");
      }
    }
  }

  // Public method to manually send token
  Future<void> sendTokenToBackend() async {
    final token = await getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }
  }

  Future<void> onUserLogin() async {
    await sendTokenToBackend();
  }

  Future<void> onUserLogout() async {
    try {
      await ApiService.deleteFcmToken();
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting token on logout: $e");
      }
    }
    await SecureStorageService().saveFcmToken('');
  }

  // Clean up
  void dispose() {
    _notificationStream.close();
    _isInitialized = false;
  }
  
}
