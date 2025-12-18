// lib/main.dart - UPDATED (Remove the extra parameter)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehiclereservation_frontend_flutter_/core/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/core/websocket_config.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/screens/splash_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/utils/notification_helper.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/firebase_notification_service.dart';

// Import the global manager
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/global_websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/websocket_navigator_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  if (kDebugMode) {
    print('🌍 Environment loaded');
    print(
      '   API Base URL: ${dotenv.get('API_BASE_URL', fallback: 'Not set')}',
    );
    print(
      '   WebSocket URL: ${dotenv.get('WS_BASE_URL', fallback: 'Not set')}',
    );
  }

  // 2. Initialize ApiConfig
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
  final GlobalWebSocketManager _webSocketManager = GlobalWebSocketManager();
  final WebSocketNavigatorObserver _navigatorObserver =
      WebSocketNavigatorObserver(); // FIXED: No parameter needed

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  // Connection state tracking
  bool _isWebSocketInitialized = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupWebSocketListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupWebSocketListeners();
    _webSocketManager.disconnect();
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
        // App went to background - keep WebSocket alive but stop pings
        if (kDebugMode) {
          print('📱 App backgrounded - WebSocket will stay alive');
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Clean up if needed
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state
        break;
    }
  }

  void _setupWebSocketListeners() {
    // Listen for connection status
    _connectionSubscription = _webSocketManager.connectionStatusStream.listen((
      isConnected,
    ) {
      if (kDebugMode) {
        print('🌐 Main App - WebSocket connection: $isConnected');
      }

      if (!isConnected && _isWebSocketInitialized) {
        // Try to reconnect if we were previously connected
        _scheduleReconnect();
      }
    });

    // Listen for unread count
    _unreadSubscription = _webSocketManager.unreadCountStream.listen((count) {
      if (kDebugMode) {
        print('📊 Main App - Unread count: $count');
      }
    });

    // Listen for global notifications
    _notificationSubscription = _webSocketManager.notificationStream.listen((
      notification,
    ) {
      _handleGlobalNotification(notification);
    });
  }

  void _cleanupWebSocketListeners() {
    _connectionSubscription?.cancel();
    _unreadSubscription?.cancel();
    _notificationSubscription?.cancel();
  }

  void _handleGlobalNotification(Map<String, dynamic> notification) {
    final type = notification['type'];

    if (kDebugMode) {
      print('🔔 Main App received notification: $type');
    }

    switch (type) {
      case 'connected':
        _handleWebSocketConnected(notification);
        break;
      case 'disconnected':
        _handleWebSocketDisconnected(notification);
        break;
      case 'error':
        _handleWebSocketError(notification);
        break;
      case 'new_notification':
        _handleNewNotification(notification);
        break;
      case 'user_registered':
        _showGlobalNotification(notification);
        break;
      case 'user_approved':
        _showGlobalNotification(notification);
        break;
      case 'user_rejected':
        _showGlobalNotification(notification);
        break;
    }
  }

  void _handleWebSocketConnected(Map<String, dynamic> data) {
    _isWebSocketInitialized = true;
    if (kDebugMode) {
      print('✅ WebSocket connected in main app');
      print('   Socket ID: ${data['socketId']}');
    }
  }

  void _handleWebSocketDisconnected(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('❌ WebSocket disconnected in main app');
    }
  }

  void _handleWebSocketError(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('⚠️ WebSocket error in main app: ${data['data']}');
    }
  }

  void _handleNewNotification(Map<String, dynamic> notification) {
    final data = notification['data'];
    final context = AuthManager.navigatorKey.currentContext;
    
    if (context != null && data != null) {
      NotificationHelper.showNotificationToast(
        context,
        title: data['title'] ?? 'New Notification',
        body: data['message'] ?? '',
        icon: Icons.notifications,
      );
    }
  }

  void _showGlobalNotification(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'];
    final context = AuthManager.navigatorKey.currentContext;

    if (context != null) {
      String title = 'Notification';
      String body = '';

      if (type == 'user_registered') {
        title = 'New User Registered';
        body = 'A new user has registered and needs approval.';
      } else if (type == 'user_approved') {
        title = 'User Approved';
        body = 'Your account has been approved.';
      } else if (type == 'user_rejected') {
        title = 'User Rejected';
        body = 'Your account request has been rejected.';
      }

      NotificationHelper.showNotificationToast(
        context,
        title: title,
        body: body,
        icon: type.contains('user') ? Icons.person : Icons.notifications,
        backgroundColor: type == 'user_rejected' ? Colors.red[900]! : Colors.black,
      );
    }
  }

  Future<void> _initializeWebSocketForUser(String token, String userId) async {
    if (_isWebSocketInitialized && _currentUserId == userId) {
      if (kDebugMode) {
        print('🔄 WebSocket already initialized for user: $userId');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🚀 Initializing WebSocket for user: $userId');
      }

      await _webSocketManager.initialize(token, userId);
      _currentUserId = userId;
      _isWebSocketInitialized = true;

      if (kDebugMode) {
        print('✅ WebSocket initialized successfully for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize WebSocket: $e');
      }
      _isWebSocketInitialized = false;
      _currentUserId = null;

      // Schedule retry
      _scheduleReconnect();
    }
  }

  Future<void> _reconnectWebSocketIfNeeded() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      final token = await SecureStorageService().accessToken;
      if (token != null) {
        if (!_webSocketManager.isConnected) {
          if (kDebugMode) {
            print('🔄 Attempting to reconnect WebSocket...');
          }
          await _initializeWebSocketForUser(token, _currentUserId!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket reconnection failed: $e');
      }
    }
  }

  void _scheduleReconnect() {
    // Don't schedule multiple reconnects
    if (!_isWebSocketInitialized || _currentUserId == null) {
      return;
    }

    Future.delayed(const Duration(seconds: 5), () async {
      await _reconnectWebSocketIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCW RIDE',
      navigatorKey: AuthManager.navigatorKey,
      navigatorObservers: [_navigatorObserver],
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
      // darkTheme: ThemeData.dark().copyWith(
      //   appBarTheme: const AppBarTheme(
      //     backgroundColor: Colors.black,
      //     elevation: 4,
      //   ),
      // ),
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
      debugShowCheckedModeBanner: false,
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

