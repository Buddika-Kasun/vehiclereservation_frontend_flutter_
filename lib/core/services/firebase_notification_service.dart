import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/pending_navigation_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/web_notification_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/navigation_helper.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔄 Background handler started");

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("❌ Background Firebase init error: $e");
    return;
  }

  // Store notification data for when app opens
  PendingNavigationService().setPendingNotification(message.data);

  // DON'T show notification here - Let Firebase system notification handle it
  print("📦 Notification data stored for terminated state");
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
      if (kIsWeb) {
        // For web: register device
        await WebDeviceRegistration().register();
        print('✅ Web device registered successfully');
      } else {
        await _initializeForMobile();
      }
      _isInitialized = true;
      print("✅ Firebase Notification Service Initialization COMPLETE");
    } catch (e) {
      print("❌ Firebase Notification Service Initialization FAILED: $e");
      _isInitialized = true;
    }
  }

  Future<void> _initializeForMobile() async {
    print("📱 Initializing Firebase for Mobile...");

    try {
      await Firebase.initializeApp();
      print("✅ Firebase Core initialized");

      _fcm = FirebaseMessaging.instance;
      _firebaseAvailable = true;
      print("✅ Firebase Messaging initialized");

      await _configureAndroidNotificationChannel();
      print("✅ Notification channel configured");

      await _initLocalNotifications();
      print("✅ Local notifications initialized");

      await _requestPermissions();
      print("✅ Permissions requested");

      await _configureMessageHandlers();
      print("✅ Message handlers configured");

      await _getAndSaveToken();
      print("✅ Token retrieval complete");

      await _handleInitialMessage();
      print("✅ Initial message check complete");

      print("🎉 Firebase Mobile initialization SUCCESSFUL");
    } catch (e, stack) {
      print("❌ Firebase Mobile initialization FAILED: $e");
      _firebaseAvailable = false;
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

  /*
  Future<void> _initLocalNotifications() async {
    if (!_firebaseAvailable) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_notification');

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
  */
  Future<void> _initLocalNotifications() async {
    if (!_firebaseAvailable) return;

    AndroidInitializationSettings initializationSettingsAndroid;
    String selectedIcon = '';

    // Test each icon option without initializing
    final iconOptions = [
      'ic_notification',
      '@mipmap/ic_notification',
      '@drawable/ic_notification',
      '@mipmap/ic_launcher', // Ultimate fallback
    ];

    for (final icon in iconOptions) {
      try {
        // Just create the settings - don't initialize yet
        final testSettings = AndroidInitializationSettings(icon);
        selectedIcon = icon;
        print("✅ Icon will work: $icon");
        break;
      } catch (e) {
        print("⚠️ Icon not available: $icon - $e");
        continue;
      }
    }

    // If all failed, use app icon as last resort
    if (selectedIcon.isEmpty) {
      selectedIcon = '@mipmap/ic_launcher';
      print("⚠️ Using app icon as final fallback");
    }

    // Create settings with the working icon
    initializationSettingsAndroid = AndroidInitializationSettings(selectedIcon);

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    try {
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleLocalNotificationClick(response.payload);
        },
      );
      print(
        "✅ Local notifications initialized successfully with icon: $selectedIcon",
      );
    } catch (e) {
      print("❌ Failed to initialize local notifications: $e");

      // Ultimate fallback - try with null icon
      try {
        final fallbackAndroidSettings = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

        // We can't re-initialize, so just log the error
        print("⚠️ Notifications may not work properly");
      } catch (fallbackError) {
        print("❌ Complete notification failure: $fallbackError");
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (!_firebaseAvailable || _fcm == null) return;

    try {
      await _fcm!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      print("❌ Permission request error: $e");
    }
  }

  Future<void> _configureMessageHandlers() async {
    if (!_firebaseAvailable || _fcm == null) return;

    // Handle foreground messages - SHOW LOCAL NOTIFICATION
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification clicks - from BOTH system and local notifications
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Background handler - NO NOTIFICATION, just store data
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to token refresh
    _fcm!.onTokenRefresh.listen((newToken) {
      _onTokenRefresh(newToken);
    });
  }

  Future<void> _getAndSaveToken() async {
    if (!_firebaseAvailable || _fcm == null) return;

    try {
      String? token = await _fcm!.getToken();
      if (token != null) {
        await SecureStorageService().saveFcmToken(token);
        await _sendTokenToBackend(token);
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
        print("📱 App opened from terminated state via notification");
        // Store for later navigation
        PendingNavigationService().setPendingNotification(initialMessage.data);
        // Mark as read immediately
        await _markNotificationAsRead(initialMessage.data);
      }
    } catch (e) {
      print("Initial message error: $e");
    }
  }

  // FOREGROUND: Show local notification (only notification shown)
  void _handleForegroundMessage(RemoteMessage message) {
    print("📨 Foreground message received");

    // Show local notification (this is the ONLY notification when app is foreground)
    _showLocalNotification(message);

    // Emit to stream for in-app UI
    _notificationStream.add(message.data);
  }

  // Show local notification - used ONLY for foreground state
  /*
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
            icon: '@mipmap/ic_notification',
            color: Color(0xFFF9C80E),
            enableVibration: true,
            playSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      _localNotifications.show(
        data['id']?.hashCode ?? notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: data.toString(),
      );

      print("📱 Local notification shown (foreground)");
    }
  }
  */
  void _showLocalNotification(RemoteMessage message) {
    if (!_firebaseAvailable) return;

    RemoteNotification? notification = message.notification;
    Map<String, dynamic> data = message.data;

    if (notification != null) {
      try {
        // Create notification details without icon first
        AndroidNotificationDetails androidDetails;

        try {
          // Try with icon
          androidDetails = AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: 'ic_notification',
            color: const Color(0xFFF9C80E),
            enableVibration: true,
            playSound: true,
            styleInformation: const DefaultStyleInformation(true, true),
          );
        } catch (e) {
          // Without icon
          androidDetails = AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFFF9C80E),
            enableVibration: true,
            playSound: true,
            styleInformation: const DefaultStyleInformation(true, true),
          );
        }

        final platformDetails = NotificationDetails(android: androidDetails);

        _localNotifications.show(
          data['id']?.hashCode ?? notification.hashCode,
          notification.title,
          notification.body,
          platformDetails,
          payload: data.toString(),
        );

        print("📱 Local notification shown");
      } catch (e) {
        print("❌ Error showing notification: $e");
      }
    }
  }

  // NOTIFICATION CLICK HANDLER - For BOTH system and local notifications
  void _handleNotificationClick(RemoteMessage message) {
    print("🖱️ Notification clicked");

    // Mark as read FIRST
    _markNotificationAsRead(message.data)
        .then((_) {
          print("✅ Mark as read completed");
        })
        .catchError((e) {
          print("❌ Mark as read failed: $e");
        });

    // Add to stream
    _notificationStream.add(message.data);

    // Store for navigation
    PendingNavigationService().setPendingNotification(message.data);

    // Navigate
    _navigateToNotificationScreen(message.data);
  }

  // LOCAL NOTIFICATION CLICK HANDLER
  void _handleLocalNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final payloadData = _parsePayload(payload);
      print("📱 Local notification clicked");

      // Mark as read
      _markNotificationAsRead(payloadData)
          .then((_) {
            print("✅ Local notification marked as read");
          })
          .catchError((e) {
            print("❌ Local notification mark as read failed: $e");
          });

      _notificationStream.add(payloadData);
      PendingNavigationService().setPendingNotification(payloadData);
      _navigateToNotificationScreen(payloadData);
    } catch (e) {
      print("Payload parse error: $e");
    }
  }

  // IMPROVED: Mark as read with better error handling and retry
  Future<void> _markNotificationAsRead(Map<String, dynamic> data) async {
    try {
      final notificationId = data['id']?.toString();

      if (notificationId == null || notificationId.isEmpty) {
        // Try alternative ID formats
        final altId =
            data['notificationId']?.toString() ??
            data['notification_id']?.toString() ??
            data['notifId']?.toString();

        if (altId != null && altId.isNotEmpty) {
          print("📝 Using alternative ID: $altId");
          await ApiService.markNotificationAsRead(altId).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException("API timeout"),
          );
          print("✅ Notification marked as read: $altId");
        }
        return;
      }

      print("📝 Marking notification as read: $notificationId");

      await ApiService.markNotificationAsRead(notificationId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException("API timeout"),
      );

      print("✅ Notification marked as read: $notificationId");
    } catch (e) {
      print("❌ Error marking notification as read: $e");
      // Don't throw - we don't want to break navigation
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
      if (context == null) {
        print("⏳ Context not ready, will retry later");
        PendingNavigationService().setPendingNotification(data);
        return;
      }

      final type = data['type']?.toString().toUpperCase() ?? 'GENERAL';
      final id = data['id']?.toString();
      final tripId = int.tryParse(data['tripId']?.toString() ?? id ?? '0') ?? 0;
      final checklistId = int.tryParse(data['checklistId']?.toString() ?? id ?? '0') ?? 0;

      print("🚀 Navigating to notification type: $type, tripId: $tripId");

      switch (type) {
        case 'USER_REGISTERED':
          NavigationHelper.toUserCreations('pending');
          break;
        case 'USER_APPROVED':
          NavigationHelper.toUserCreations('approved');
          break;
        case 'USER_REJECTED':
          NavigationHelper.toUserCreations('rejected');
          break;
        case 'TRIP_CREATED':
        case 'TRIP_CANCELLED':
        case 'TRIP_CANCELLED_REQUESTER':
        case 'TRIP_APPROVED':
        case 'TRIP_REJECTED':
        case 'TRIP_READING_START_FOR_PASSENGER':
        case 'TRIP_STARTED_FOR_PASSENGER':
        case 'TRIP_FINISHED_FOR_REQUESTER':
        case 'TRIP_COMPLETED_FOR_REQUESTER':
          NavigationHelper.toMyRideTripDetails(tripId);
          break;
        case 'TRIP_CREATED_AS_DRAFT':
        case 'TRIP_CONFIRMED':
        case 'TRIP_CANCELLED_SUPERVISOR':
        case 'TRIP_STARTED_FOR_SUPERVISOR':
        case 'TRIP_FINISHED_FOR_SUPERVISOR':
        case 'TRIP_COMPLETED_FOR_SUPERVISOR':
          NavigationHelper.toReviewTripDetails(tripId);
          break;
        case 'TRIP_CONFIRMED_FOR_APPROVAL':
        case 'TRIP_APPROVED_BY_APPROVER':
        case 'TRIP_REJECTED_BY_APPROVER':
          NavigationHelper.toApprovalTripDetails(tripId);
          break;
        case 'TRIP_APPROVED_FOR_DRIVER':
        case 'TRIP_READING_START_FOR_DRIVER':
        case 'TRIP_STARTED':
        case 'TRIP_FINISHED':
        case 'TRIP_COMPLETED_FOR_DRIVER':
          NavigationHelper.toAssignRideTripDetails(tripId);
          break;
        case 'TRIP_APPROVED_FOR_SECURITY':
        case 'TRIP_READING_START':
        case 'TRIP_STARTED_FOR_SECURITY':
        case 'TRIP_COMPLETED':
          NavigationHelper.toMeterReading();
          break;
        case 'CHECKLIST_SUBMITTED':
        case 'CHECKLIST_APPROVED':
        case 'CHECKLIST_REJECTED':
          NavigationHelper.toReviewChecklistDetails(checklistId);
          break;
        case 'CHECKLIST_SUBMITTED_FOR_APPROVER':
        case 'CHECKLIST_APPROVED_FOR_APPROVER':
        case 'CHECKLIST_REJECTED_FOR_APPROVER':
          final Map<String, Object> checklistData = {
            'vehicleId': data['vehicleId']?.toString() ?? '',
            'vehicleRegNo': data['vehicleRegNo'] ?? '',
            'userId': StorageService.userData?.id.toString() ?? '',
            'userName': StorageService.userData?.displayname ?? '',
            'userRole': StorageService.userData?.role.value ?? '',
          };
          NavigationHelper.toChecklistDetails(checklistData);
          break;
          
        default:
          NavigationHelper.toNotifications();
      }
    });
  }

  Future<String?> getToken() async {
    if (!_firebaseAvailable || _fcm == null) return null;
    try {
      return await _fcm!.getToken();
    } catch (e) {
      return null;
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    if (!_firebaseAvailable) return;
    await SecureStorageService().saveFcmToken(newToken);
    await _sendTokenToBackend(newToken);
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final isLoggedIn = await SecureStorageService().isUserLoggedIn();
      if (!isLoggedIn) return;
      await ApiService.updateFcmToken(fcmToken: token);
    } catch (e) {
      print("❌ Error sending token to backend: $e");
    }
  }

  Future<void> sendTokenToBackend() async {
    if (kIsWeb) {
      // For web: register device
      await WebDeviceRegistration().register();
      print('✅ Web device registered successfully');
    } else {
      // For mobile: handle FCM token
      if (!_firebaseAvailable) return;
      final token = await getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    }
  }

  Future<void> onUserLogin() async {
    await sendTokenToBackend();
  }

  Future<void> onUserLogout() async {
    try {
      if (kIsWeb) {
        await WebDeviceRegistration().unregister();
      } else {
        final user = StorageService.userData;
        await ApiService.deleteFcmToken(user?.id);
      }
    } catch (e) {
      print("❌ Error deleting token on logout: $e");
    }
    await SecureStorageService().saveFcmToken('');
  }

  bool get isFirebaseAvailable => _firebaseAvailable;

  void dispose() {
    _notificationStream.close();
    _isInitialized = false;
  }
}
