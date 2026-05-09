// lib/shared/widgets/top_bar.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/global_websocket.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/features/home/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/notifications/screens/notification_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/profile/profile_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/notification_handler.dart';

class TopBar extends StatefulWidget {
  final User user;
  final VoidCallback onMenuTap;
  final String token;
  final VoidCallback? onPcwRideTap;

  const TopBar({
    required this.user,
    required this.onMenuTap,
    required this.token,
    this.onPcwRideTap,
    Key? key,
  }) : super(key: key);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  WebSocketManager get _webSocketManager => GlobalWebSocket.instance;
  late NotificationHandler _notificationHandler;

  int _unreadCount = 0;
  bool _isConnected = false;
  bool _isInitializing = false;
  bool _isReconnecting = false;

  // Simple popup variables
  OverlayEntry? _notificationOverlay;
  Timer? _notificationTimer;
  bool _showNotification = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('🎯 TopBar initialized - User ID: ${widget.user.id}');
    }

    _loadUnreadCount();
    _initializeNotificationHandler();
  }

  Future<void> _initializeNotificationHandler() async {
    try {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      // Create handler with global instance
      _notificationHandler = NotificationHandler();

      // Initialize the Global WebSocket if not already initialized
      GlobalWebSocket.initialize(
        token: widget.token,
        userId: widget.user.id.toString(),
      );

      // Add connection listener
      _webSocketManager.addConnectionListener('notifications', (isConnected) {
        if (kDebugMode) {
          print('🔌 Notification connection: $isConnected');
        }
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      });

      // Add message listener
      _webSocketManager.addMessageListener('notifications', (message) {
        final event = message['event']?.toString() ?? '';
        if (kDebugMode) {
          print('📨 Received notification event: $event');
        }

        if (event == 'notification' ||
            event == 'refresh' ||
            event == 'notification_update' ||
            event == 'notification_refresh') {
          _loadUnreadCount();

          if (event == 'notification' || event == 'notification_update') {

            int? newCount;
            if (message['data'] != null &&
                message['data']['unreadCount'] != null) {
              newCount = message['data']['unreadCount'];
            }

            _showSimpleNotificationPopup(newCount);
          }
        }
      });

      // Initialize notification handler
      await _notificationHandler.initialize(
        token: widget.token,
        userId: widget.user.id.toString(),
      );

      // Set up callbacks
      _notificationHandler.onUnreadCountUpdate = (count) {
        if (count == -1) {
          _loadUnreadCount();
        } else {
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        }
      };

      _notificationHandler.onNewNotification = (notificationData) {
        int? newCount = notificationData['unreadCount'];
        _showSimpleNotificationPopup(newCount);
        _loadUnreadCount();
      };

      // Connect to notifications namespace
      await _webSocketManager.connectToNamespace('notifications');

      // Check initial connection status
      final isConnected = _webSocketManager.isNamespaceConnected(
        'notifications',
      );

      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('❌ Failed to initialize notification handler: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notificationHandler.dispose();
    _webSocketManager.removeConnectionListener('notifications', (_) {});
    _webSocketManager.removeMessageListener('notifications', (_) {});
    _notificationTimer?.cancel();
    _removeNotificationPopup();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await ApiService.getUnreadCount();
      if (response['success'] == true && response['data'] != null) {
        final count = response['data']['count'] ?? 0;
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }

        _notificationHandler.setMaxCount(count > 9);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading unread count: $e');
      }
    }
  }

  Future<void> _handleNotificationTap() async {
    // Remove any existing popup
    _removeNotificationPopup();

    // If already connected and not in progress, navigate immediately
    if (_isConnected && !_isInitializing && !_isReconnecting) {
      _navigateToNotificationScreen();
      return;
    }

    // Show reconnecting state
    if (mounted) {
      setState(() {
        _isReconnecting = true;
      });
    }

    try {
      // Attempt to reconnect
      await _reconnectWebSocket();

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && _isConnected) {
        // Connection successful, navigate
        _navigateToNotificationScreen();
      } else {
        // Still not connected, show error
        _showConnectionError();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Reconnection failed: $e');
      }
      _showConnectionError();
    } finally {
      if (mounted) {
        setState(() {
          _isReconnecting = false;
        });
      }
    }
  }

  Future<void> _reconnectWebSocket() async {
    try {
      // Disconnect first if connected
      if (_webSocketManager.isNamespaceConnected('notifications')) {
        await _webSocketManager.disconnectFromNamespace('notifications');
      }

      // Reinitialize the handler
      await _notificationHandler.initialize(
        token: widget.token,
        userId: widget.user.id.toString(),
      );

      // Reconnect to namespace
      await _webSocketManager.connectToNamespace('notifications');

      // Wait for connection with timeout
      int attempts = 0;
      const maxAttempts = 5;
      const delay = Duration(milliseconds: 200);

      while (attempts < maxAttempts && !_isConnected) {
        await Future.delayed(delay);
        attempts++;
        if (kDebugMode) {
          print('🔄 Connection attempt $attempts/$maxAttempts');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket reconnection error: $e');
      }
      rethrow;
    }
  }

  void _navigateToNotificationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          userId: widget.user.id.toString(),
          token: widget.token,
        ),
      ),
    ).then((_) {
      _loadUnreadCount();
    });
  }

  void _showConnectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to connect to notifications. Please check your connection.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _refreshConnection() {
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    _reconnectWebSocket()
        .then((_) {
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
        })
        .catchError((e) {
          if (kDebugMode) {
            print('❌ Refresh connection failed: $e');
          }
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
        });
  }

  void _showSimpleNotificationPopup([int? newCount]) {
    if (!mounted || _showNotification) return;

    // Cancel any existing timer
    _notificationTimer?.cancel();

    // Remove existing overlay
    _removeNotificationPopup();

    // Create new overlay
    _createSimplePopup(newCount ?? _unreadCount + 1);

    // Auto-hide after 5 seconds
    _notificationTimer = Timer(const Duration(seconds: 5), () {
      _removeNotificationPopup();
    });
  }

  void _createSimplePopup([int displayCount = 0]) {
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    // Calculate position based on app bar height
    // AppBar height is 80 + status bar height
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 60.0;
    final double totalAppBarHeight = statusBarHeight;

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: statusBarHeight + 8, // Position below the app bar with small gap
        left: 16,
        right: 16,
        child: _buildSimplePopup(displayCount),
      ),
    );

    overlayState.insert(_notificationOverlay!);
    _showNotification = true;
  }

  Widget _buildSimplePopup(int displayCount) {
    return GestureDetector(
      onTap: () {
        // Remove popup first
        _removeNotificationPopup();
        // Navigate to notification screen
        _navigateToNotificationScreen();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Notification content
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Notification',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.none, // Add this
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${displayCount} unread notification${_unreadCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            decoration: TextDecoration.none, // Add this
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Close button
            GestureDetector(
              onTap: _removeNotificationPopup,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeNotificationPopup() {
    if (_notificationOverlay != null) {
      _notificationOverlay!.remove();
      _notificationOverlay = null;
    }
    _showNotification = false;
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  @override
  void didUpdateWidget(covariant TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.user.id != oldWidget.user.id ||
        widget.token != oldWidget.token) {
      if (kDebugMode) {
        print('🔄 User/token changed, reinitializing notification handler');
      }
      _initializeNotificationHandler();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /*
        Container(
          height: 10,
          color: Colors.black, // Match AppBar color
        ),
        */
        AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 55,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: widget.onMenuTap,
          ),
          title: GestureDetector(
            onTap: () {
              if (widget.onPcwRideTap != null) {
                widget.onPcwRideTap!();
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text(
              'PCW RIDE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            // Notification Icon
            Stack(
              children: [
                IconButton(
                  icon: _isInitializing || _isReconnecting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.notifications,
                          color: _isConnected
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                  onPressed: _handleNotificationTap,
                ),

                // Unread count badge
                if (_unreadCount > 0 && !_isInitializing && !_isReconnecting)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Connection status dot
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: _refreshConnection,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isReconnecting
                            ? Colors.orangeAccent
                            : _isInitializing
                            ? Colors.orangeAccent
                            : _isConnected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Avatar
            GestureDetector(
              onTap: () {
                _removeNotificationPopup();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.user),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: Colors.yellow[600],
                  child: Text(
                    _getAvatarText(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getAvatarText() {
    if (widget.user.profilePicture != null &&
        widget.user.profilePicture!.isNotEmpty) {
      return widget.user.profilePicture![0].toUpperCase();
    } else if (widget.user.displayname.isNotEmpty) {
      return widget.user.displayname[0].toUpperCase();
    }
    return 'U';
  }

}