import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/features/notifications/screens/notification_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Background message received: ${message.messageId}");
    print("Payload: ${message.data}");
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Skip Firebase initialization on web for now (requires firebase config)
      if (kIsWeb) {
        if (kDebugMode) {
          print("⚠️ Firebase not configured for web - skipping initialization");
        }
        return;
      }

      // 1. Initialize Firebase
      // Note: This requires google-services.json / GoogleService-Info.plist to be present
      await Firebase.initializeApp();
      
      _fcm = FirebaseMessaging.instance;

      // 2. Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize Local Notifications for Foreground Presentation
      await _initLocalNotifications();

      // 4. Request Permissions (iOS/Android 13+)
      await requestPermissions();

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Handle Interaction when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
      
      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      _isInitialized = true;
      if (kDebugMode) {
        print("✅ Firebase Notification Service Initialized");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Firebase Notification Service Initialization Error: $e");
        print("   App will continue without Firebase notifications");
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification click
        if (response.payload != null) {
          // You can parse payload and navigate
          if (kDebugMode) {
            print("Local notification payload: ${response.payload}");
          }
        }
      },
    );
  }

  Future<void> requestPermissions() async {
    if (_fcm == null) return;
    
    NotificationSettings settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<String?> getToken() async {
    if (_fcm == null) return null;
    
    try {
      String? token = await _fcm!.getToken();
      if (kDebugMode) {
        print("FCM Token: $token");
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting FCM token: $e");
      }
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print("Foreground message received: ${message.messageId}");
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      print("Notification clicked! Data: ${message.data}");
    }

    final context = AuthManager.navigatorKey.currentContext;
    if (context != null) {
      // Logic for deep linking based on message.data
      final String? type = message.data['type'];
      
      // Default to Notification Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(
            userId: '', // Will be handled inside if needed or fetched from storage
            token: '',
          ),
        ),
      );
    }
  }
}
