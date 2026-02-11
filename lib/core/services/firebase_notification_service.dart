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
  print("🔄 Background handler started");

  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized in background");
  } catch (e) {
    print("❌ Background Firebase init error: $e");
    return;
  }

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
    print("📨 Background notification shown");
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _firebaseAvailable = false;
  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStream.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print("🚀 Starting Firebase Notification Service initialization...");

    try {
      await _initializeForMobile();
      _isInitialized = true;

      print("✅ Firebase Notification Service Initialization COMPLETE");
      print("   Firebase Available: $_firebaseAvailable");
    } catch (e) {
      print("❌ Firebase Notification Service Initialization FAILED: $e");
      _isInitialized = true; // Mark as initialized anyway
    }
  }

  Future<void> _initializeForMobile() async {
    print("📱 Initializing Firebase for Mobile...");

    try {
      // 1. Initialize Firebase
      print("Step 1: Initializing Firebase Core...");
      await Firebase.initializeApp();
      print("✅ Firebase Core initialized");

      // 2. Initialize Firebase Messaging
      print("Step 2: Initializing Firebase Messaging...");
      _fcm = FirebaseMessaging.instance;
      _firebaseAvailable = true;
      print("✅ Firebase Messaging initialized");

      // 3. Configure Android notification channel
      print("Step 3: Configuring notification channel...");
      await _configureAndroidNotificationChannel();
      print("✅ Notification channel configured");

      // 4. Initialize Local Notifications
      print("Step 4: Initializing local notifications...");
      await _initLocalNotifications();
      print("✅ Local notifications initialized");

      // 5. Request Permissions
      print("Step 5: Requesting permissions...");
      await _requestPermissions();
      print("✅ Permissions requested");

      // 6. Configure message handlers
      print("Step 6: Configuring message handlers...");
      await _configureMessageHandlers();
      print("✅ Message handlers configured");

      // 7. Get and save token
      print("Step 7: Getting FCM token...");
      await _getAndSaveToken();
      print("✅ Token retrieval complete");

      // 8. Handle initial message
      print("Step 8: Checking initial messages...");
      await _handleInitialMessage();
      print("✅ Initial message check complete");

      print("🎉 Firebase Mobile initialization SUCCESSFUL");
    } catch (e, stack) {
      print("❌ Firebase Mobile initialization FAILED");
      print("Error: $e");
      print("Stack trace: $stack");
      print("\n⚠️ TROUBLESHOOTING:");
      print("1. Check if google-services.json exists in android/app/");
      print("2. Verify Firebase packages in pubspec.yaml");
      print("3. Check Android build.gradle files");
      print("4. Ensure correct package name in Firebase Console");

      _firebaseAvailable = false;
      // Don't rethrow - let app continue without Firebase
    }
  }

  Future<void> _configureAndroidNotificationChannel() async {
    if (!_firebaseAvailable) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initLocalNotifications() async {
    if (!_firebaseAvailable) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationClick(response.payload);
      },
    );
  }

  Future<void> _requestPermissions() async {
    if (!_firebaseAvailable || _fcm == null) return;

    try {
      NotificationSettings settings = await _fcm!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📋 Permission Status: ${settings.authorizationStatus}');
    } catch (e) {
      print("❌ Permission request error: $e");
    }
  }

  Future<void> _configureMessageHandlers() async {
    if (!_firebaseAvailable || _fcm == null) return;

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification clicks
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to token refresh
    _fcm!.onTokenRefresh.listen((newToken) {
      print("🔄 FCM Token Refreshed: ${newToken.substring(0, 20)}...");
      _onTokenRefresh(newToken);
    });
  }

  Future<void> _getAndSaveToken() async {
    if (!_firebaseAvailable || _fcm == null) {
      print("⚠️ Firebase not available, skipping token retrieval");
      return;
    }

    try {
      print("🔍 Requesting FCM token...");
      String? token = await _fcm!.getToken();

      if (token != null) {
        print("✅ FCM Token received (${token.length} chars)");
        print("   First 20 chars: ${token.substring(0, 20)}...");

        await SecureStorageService().saveFcmToken(token);
        print("✅ Token saved to secure storage");

        await _sendTokenToBackend(token);
      } else {
        print("❌ No FCM token received from Firebase");
      }
    } catch (e) {
      print("❌ Error getting FCM token: $e");
    }
  }

  Future<void> _handleInitialMessage() async {
    if (!_firebaseAvailable || _fcm == null) return;

    try {
      RemoteMessage? initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        print("📱 App opened from notification");
        _handleNotificationClick(initialMessage);
      }
    } catch (e) {
      print("Initial message error: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print("📨 Foreground message: ${message.messageId}");
    print("   Title: ${message.notification?.title}");
    print("   Body: ${message.notification?.body}");
    print("   Data: ${message.data}");

    // Emit to stream
    _notificationStream.add(message.data);

    // Create local notification
    _showLocalNotification(message);
  }

  void _showLocalNotification(RemoteMessage message) {
    if (!_firebaseAvailable) return;

    RemoteNotification? notification = message.notification;
    Map<String, dynamic> data = message.data;

    if (notification != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
            color: Colors.blue,
            enableVibration: true,
            playSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: data.toString(),
      );

      print("📱 Local notification shown");
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print("🖱️ Notification clicked: ${message.data}");

    _notificationStream.add(message.data);
    _navigateToNotificationScreen(message.data);
  }

  void _handleLocalNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final payloadData = _parsePayload(payload);
      print("📱 Local notification clicked: $payloadData");

      _notificationStream.add(payloadData);
      _navigateToNotificationScreen(payloadData);
    } catch (e) {
      print("Payload parse error: $e");
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
        final type = data['type']?.toString() ?? 'general';
        final id = data['id']?.toString();

        switch (type) {
          case 'trip_approved':
          case 'trip_rejected':
          case 'new_trip':
            Navigator.pushNamed(context, '/trips/${id ?? ''}');
            break;
          case 'approval':
            Navigator.pushNamed(context, '/approvals/${id ?? ''}');
            break;
          case 'message':
            Navigator.pushNamed(context, '/messages');
            break;
          default:
            Navigator.pushNamed(context, '/notifications');
        }
      }
    });
  }

  Future<String?> getToken() async {
    if (!_firebaseAvailable || _fcm == null) {
      print("⚠️ Firebase not available, cannot get token");
      return null;
    }

    try {
      return await _fcm!.getToken();
    } catch (e) {
      print("❌ Error getting token: $e");
      return null;
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    if (!_firebaseAvailable) return;

    print("🔄 Token refresh detected");

    await SecureStorageService().saveFcmToken(newToken);
    await _sendTokenToBackend(newToken);
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final isLoggedIn = await SecureStorageService().isUserLoggedIn();
      if (!isLoggedIn) {
        print("⚠️ User not logged in, saving token for later");
        return;
      }

      print("📤 Sending token to backend...");
      await ApiService.updateFcmToken(fcmToken: token);
      print("✅ Token sent to backend successfully");
    } catch (e) {
      print("❌ Error sending token to backend: $e");
    }
  }

  Future<void> sendTokenToBackend() async {
    if (!_firebaseAvailable) {
      print("❌ Firebase not available, cannot send token to backend");
      return;
    }

    final token = await getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    } else {
      print("❌ No token available to send to backend");
    }
  }

  Future<void> onUserLogin() async {
    print("👤 User logged in - sending token to backend");
    await sendTokenToBackend();
  }

  Future<void> onUserLogout() async {
    try {
      await ApiService.deleteFcmToken();
      print("✅ Token deleted from backend on logout");
    } catch (e) {
      print("❌ Error deleting token on logout: $e");
    }

    await SecureStorageService().saveFcmToken('');
    print("✅ Local FCM token cleared");
  }

  bool get isFirebaseAvailable => _firebaseAvailable;

  void dispose() {
    _notificationStream.close();
    _isInitialized = false;
  }
}
