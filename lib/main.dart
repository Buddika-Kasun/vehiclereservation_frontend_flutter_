// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/websocket_config.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/welcome/welcome_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/firebase_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

// WebSocket
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
    if (kDebugMode) {
      print('🌍 Environment loaded');
      print('API URL: ${dotenv.get('API_URL', fallback: 'Not set')}');
      print('WebSocket URL: ${dotenv.get('WS_URL', fallback: 'Not set')}');
    }
  } catch (e, st) {
    if (kDebugMode) print('❌ Env load error: $e\n$st');
  }

  // Request permissions
  await _requestPermissions();

  // Initialize configs safely
  try {
    await ApiConfig.init();
  } catch (e, st) {
    if (kDebugMode) print('❌ API Config init error: $e\n$st');
  }

  try {
    await WebSocketConfig.init();
  } catch (e, st) {
    if (kDebugMode) print('❌ WebSocket Config init error: $e\n$st');
  }

  // Initialize storage
  try {
    await StorageService.init();
  } catch (e, st) {
    if (kDebugMode) print('❌ StorageService init error: $e\n$st');
  }

  // Initialize secure storage
  try {
    await SecureStorageService().init();
  } catch (e, st) {
    if (kDebugMode) print('❌ SecureStorage init error: $e\n$st');
  }

  // Initialize Firebase notifications
  try {
    await FirebaseNotificationService().initialize();
  } catch (e, st) {
    if (kDebugMode) print('❌ Firebase init error: $e\n$st');
  }

  runApp(const MyApp());
}

// Permissions helper
Future<void> _requestPermissions() async {
  final permissions = [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.notification,
  ];

  for (var permission in permissions) {
    if (!await permission.isGranted) {
      await permission.request();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final WebSocketManager _webSocketManager = WebSocketManager();
  final NotificationHandler _notificationHandler = NotificationHandler();
  StreamSubscription? _notificationSubscription;

  String? _currentUserId;
  String? _currentToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupSubscriptions();
    _cleanupWebSocket();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) print('📱 App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _reconnectWebSocketIfNeeded();
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) print('📱 App backgrounded');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeWebSocketForUser(String token, String userId) async {
    if (_currentUserId == userId && _currentToken == token) {
      if (kDebugMode)
        print('🔄 WebSocket already initialized for user: $userId');
      return;
    }

    try {
      if (kDebugMode) print('🚀 Initializing WebSocket for user: $userId');

      _webSocketManager.initialize(token: token, userId: userId);
      await _notificationHandler.initialize(token: token, userId: userId);
      await _webSocketManager.connectToNamespace('notifications');

      _currentUserId = userId;
      _currentToken = token;

      if (kDebugMode)
        print('✅ WebSocket initialized successfully for user: $userId');
    } catch (e, st) {
      if (kDebugMode) print('❌ Failed to initialize WebSocket: $e\n$st');
      _currentUserId = null;
      _currentToken = null;
      _scheduleReconnect();
    }
  }

  Future<void> _reconnectWebSocketIfNeeded() async {
    if (_currentUserId == null || _currentToken == null) return;

    try {
      if (!_webSocketManager.isNamespaceConnected('notifications')) {
        if (kDebugMode) print('🔄 Reconnecting to notifications namespace...');
        await _webSocketManager.connectToNamespace('notifications');
      }
    } catch (e, st) {
      if (kDebugMode) print('❌ WebSocket reconnection failed: $e\n$st');
    }
  }

  void _scheduleReconnect() {
    if (_currentUserId == null || _currentToken == null) return;

    Future.delayed(const Duration(seconds: 5), () async {
      await _reconnectWebSocketIfNeeded();
    });
  }

  void _cleanupSubscriptions() {
    _notificationSubscription?.cancel();
  }

  Future<void> _cleanupWebSocket() async {
    try {
      await _notificationHandler.dispose();
      await _webSocketManager.disconnectAll();
    } catch (e, st) {
      if (kDebugMode) print('❌ Error cleaning up WebSocket: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCW RIDE',
      navigatorKey: AuthManager.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.yellow[600],
          foregroundColor: Colors.black,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(color: Colors.yellow[600]),
          actionTextColor: Colors.yellow[600],
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              currentFocus.focusedChild?.unfocus();
            }
          },
          child: child,
        );
      },
    );
  }
}
