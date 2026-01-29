// lib/shared/widgets/top_bar.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/notifications/screens/notification_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/profile/profile_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/notification_handler.dart';

class TopBar extends StatefulWidget {
  final User user;
  final VoidCallback onMenuTap;
  final String token;

  const TopBar({
    required this.user,
    required this.onMenuTap,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final NotificationHandler _notificationHandler = NotificationHandler();
  final WebSocketManager _webSocketManager = WebSocketManager();
  int _unreadCount = 0;
  bool _isConnected = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('🎯 TopBar initialized - User ID: ${widget.user.id}');
    }

    _loadUnreadCount(); // Initial API call
    _initializeNotificationHandler();
  }

  // In TopBar, update the connection method:
  // lib/shared/widgets/top_bar.dart (updated _initializeNotificationHandler method)

  Future<void> _initializeNotificationHandler() async {
    try {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      // Add connection listener BEFORE connecting
      _webSocketManager.addConnectionListener('notifications', (isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
            if (isConnected) {
              print('✅ WebSocket connection status: Connected');
            } else {
              print('❌ WebSocket connection status: Disconnected');
            }
          });
        }
      });

      // Add message listener to handle notifications
      _webSocketManager.addMessageListener('notifications', (message) {
        final event = message['event']?.toString() ?? '';
        print('📨 Received notification event: $event');

        // Handle specific notification events
        if (event == 'notification') {
          // Update unread count when new notification arrives
          _loadUnreadCount();
        }
      });

      // Initialize WebSocketManager first
      _webSocketManager.initialize(
        token: widget.token,
        userId: widget.user.id.toString(),
      );

      // Then connect to notifications namespace
      await _webSocketManager.connectToNamespace('notifications');

      // Initialize notification handler with Socket.IO
      await _notificationHandler.initialize(
        token: widget.token,
        userId: widget.user.id.toString(),
      );

      // Set up callbacks
      _notificationHandler.onUnreadCountUpdate = (count) {
        if (count == -1) {
          // -1 means refresh via API
          _loadUnreadCount();
        } else {
          // Specific count provided
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        }
      };

      _notificationHandler.onNewNotification = (notification) {
        // Handle new notification if needed
        print('New notification: $notification');
      };

      // Set max count flag
      _notificationHandler.setMaxCount(_unreadCount > 9);

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

      // Print connection status
      if (kDebugMode) {
        print('🔔 Connection status after initialization: $isConnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize notification handler: $e');
      }
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isInitializing = false;
        });
      }
    }
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

        // Update max count flag in handler
        _notificationHandler.setMaxCount(count > 9);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading unread count: $e');
      }
    }
  }

  void _refreshConnection() {
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    // Reinitialize handler
    _initializeNotificationHandler();
  }

  @override
  void didUpdateWidget(covariant TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If user or token changed, reinitialize
    if (widget.user.id != oldWidget.user.id ||
        widget.token != oldWidget.token) {
      if (kDebugMode) {
        print('🔄 User/token changed, reinitializing notification handler');
      }
      _initializeNotificationHandler();
    }
  }

  @override
  void dispose() {
    _notificationHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 80,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: widget.onMenuTap,
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false,
              );
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
                  icon: _isInitializing
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
                  onPressed: _isConnected
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationScreen(
                                userId: widget.user.id.toString(),
                                token: widget.token,
                              ),
                            ),
                          );
                        }
                      : null,
                ),

                // Unread count badge
                if (_unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
                        color: _isInitializing
                            ? Colors.orange
                            : _isConnected
                            ? Colors.green
                            : Colors.red,
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
