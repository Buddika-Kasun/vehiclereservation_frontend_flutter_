// lib/main.dart - UPDATED for new WebSocket structure
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/websocket_config.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/screens/splash_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/firebase_notification_service.dart';

// Import new WebSocket structure
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/notification_handler.dart';

// Import notification observer if you have it
// import 'package:vehiclereservation_frontend_flutter_/core/utils/websocket_navigator_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  if (kDebugMode) {
    print('🌍 Environment loaded');
    print('   API URL: ${dotenv.get('API_URL', fallback: 'Not set')}');
    print('   WebSocket URL: ${dotenv.get('WS_URL', fallback: 'Not set')}');
  }

  // 2. Initialize configurations
  await ApiConfig.init();
  await WebSocketConfig.init();

  // 3. Initialize storage
  await StorageService.init();

  // 4. Initialize SecureStorage
  await SecureStorageService().init();

  // 5. Initialize Firebase Notifications
  await FirebaseNotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Use the new WebSocket manager
  final WebSocketManager _webSocketManager = WebSocketManager();

  // Notification handler for global notifications
  final NotificationHandler _notificationHandler = NotificationHandler();

  // Stream subscriptions
  StreamSubscription? _notificationSubscription;

  // User state tracking
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
    if (kDebugMode) {
      print('📱 App lifecycle state changed: $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - ensure WebSocket is connected
        _reconnectWebSocketIfNeeded();
        break;
      case AppLifecycleState.paused:
        // App went to background
        if (kDebugMode) {
          print('📱 App backgrounded');
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }

  // In your main.dart, update the WebSocket initialization:

  Future<void> _initializeWebSocketForUser(String token, String userId) async {
    if (_currentUserId == userId && _currentToken == token) {
      if (kDebugMode) {
        print('🔄 WebSocket already initialized for user: $userId');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🚀 Initializing Socket.IO for user: $userId');
      }

      // Initialize WebSocket manager
      _webSocketManager.initialize(token: token, userId: userId);

      // Initialize notification handler
      await _notificationHandler.initialize(token: token, userId: userId);

      // Connect to notifications namespace for global notifications
      await _webSocketManager.connectToNamespace('notifications');

      _currentUserId = userId;
      _currentToken = token;

      if (kDebugMode) {
        print('✅ Socket.IO initialized successfully for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Socket.IO: $e');
      }
      _currentUserId = null;
      _currentToken = null;

      // Schedule retry
      _scheduleReconnect();
    }
  }
  
  Future<void> _reconnectWebSocketIfNeeded() async {
    if (_currentUserId == null || _currentToken == null) {
      return;
    }

    try {
      // Check if notifications namespace is connected
      if (!_webSocketManager.isNamespaceConnected('notifications')) {
        if (kDebugMode) {
          print('🔄 Reconnecting to notifications namespace...');
        }
        await _webSocketManager.connectToNamespace('notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket reconnection failed: $e');
      }
    }
  }

  void _scheduleReconnect() {
    if (_currentUserId == null || _currentToken == null) {
      return;
    }

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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up WebSocket: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCW RIDE',
      navigatorKey: AuthManager.navigatorKey,
      // If you have navigator observers, add them here
      // navigatorObservers: [_navigatorObserver],
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
      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkAndInitializeSession(),
        builder: (context, snapshot) {
          // Show splash screen while checking session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // Handle errors gracefully
          if (snapshot.hasError) {
            if (kDebugMode) {
              print('Session check error: ${snapshot.error}');
            }
            return const LoginScreen();
          }

          // Redirect based on session status
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final hasSession = data['hasSession'] as bool;

            // Initialize WebSocket if user is logged in
            if (hasSession) {
              final user = data['user'] as Map<String, dynamic>;
              final token = data['token'] as String;
              final userId = user['id'].toString();

              // Initialize WebSocket in the background
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeWebSocketForUser(token, userId);
              });
            }

            return hasSession ? HomeScreen() : const LoginScreen();
          }

          // Default fallback
          return const LoginScreen();
        },
      ),
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Hide keyboard when tapping outside text fields
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

  Future<Map<String, dynamic>> _checkAndInitializeSession() async {
    try {
      final hasSession = await StorageService.hasValidSession;

      if (hasSession) {
        final user = StorageService.userData;
        final token = await SecureStorageService().accessToken;

        if (token == null || user == null) {
          if (kDebugMode) {
            print('⚠️ Session exists but token or user data is missing');
          }
          return {'hasSession': false};
        }

        if (kDebugMode) {
          print('🔑 Session check successful');
          print('   User ID: ${user.id}');
          print('   Username: ${user.username}');
        }

        return {'hasSession': true, 'user': user.toJson(), 'token': token};
      }

      if (kDebugMode) {
        print('🔑 No valid session found');
      }

      return {'hasSession': false};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Session check error: $e');
      }
      return {'hasSession': false};
    }
  }
}
