// lib/widgets/common/top_bar.dart - FIXED
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/notification_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/profile_screens/profile_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/ws/global_websocket_manager.dart';

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
  final GlobalWebSocketManager _webSocketManager = GlobalWebSocketManager();
  int _unreadCount = 0;
  bool _isConnected = false;
  bool _isInitializing = false;

  // Unique listener IDs for this widget instance
  late final String _connectionListenerId;
  late final String _unreadListenerId;

  @override
  void initState() {
    super.initState();

    _connectionListenerId = UniqueKey().toString();
    _unreadListenerId = UniqueKey().toString();

    if (kDebugMode) {
      print('🎯 TopBar initialized - User ID: ${widget.user.id}');
      print(
        '🎯 Listener IDs - Connection: $_connectionListenerId, Unread: $_unreadListenerId',
      );
    }

    _setupListeners();
    _initializeWebSocket();
  }

  void _setupListeners() {
    // Listen for connection status updates
    _webSocketManager.addConnectionListener(_connectionListenerId, (
      isConnected,
    ) {
      if (kDebugMode) {
        print('🔌 TopBar connection update: $isConnected');
      }
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _isInitializing = false;
        });
      }
    });

    // Listen for unread count updates
    _webSocketManager.addUnreadListener(_unreadListenerId, (count) {
      if (kDebugMode) {
        print('📊 TopBar unread update: $count');
      }
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  Future<void> _initializeWebSocket() async {
    try {
      // Convert user.id to string
      final userId = widget.user.id.toString();

      // Check if already initialized for this user
      if (_webSocketManager.isInitializedForUser(userId)) {
        if (kDebugMode) {
          print('🔄 WebSocket already initialized for user: $userId');
        }

        // Just sync current state
        if (mounted) {
          setState(() {
            _isConnected = _webSocketManager.isConnected;
            _unreadCount = _webSocketManager.unreadCount;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      if (kDebugMode) {
        print('🚀 Initializing WebSocket for user: $userId');
      }

      // Initialize global WebSocket
      await _webSocketManager.initialize(widget.token, userId);

      // Sync state after initialization
      if (mounted) {
        setState(() {
          _isConnected = _webSocketManager.isConnected;
          _unreadCount = _webSocketManager.unreadCount;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize WebSocket: $e');
      }
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isInitializing = false;
        });
      }
    }
  }

  void _refreshConnection() {
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    // Reinitialize WebSocket
    _initializeWebSocket();
  }

  @override
  void didUpdateWidget(covariant TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If user changed, reinitialize
    if (widget.user.id != oldWidget.user.id) {
      if (kDebugMode) {
        print('🔄 User changed, reinitializing WebSocket');
      }
      _initializeWebSocket();
    }
  }

  @override
  void dispose() {
    // Remove listeners but DON'T disconnect WebSocket (global manager handles it)
    _webSocketManager.removeConnectionListener(_connectionListenerId);
    _webSocketManager.removeUnreadListener(_unreadListenerId);

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
            // Notification Icon with Badge and Connection Dot
            GestureDetector(
              onLongPress: () {
                if (kDebugMode) {
                  final info = _webSocketManager.getConnectionInfo();
                  print('📡 Connection debug:');
                  print('  UI _isConnected: $_isConnected');
                  print('  Global isConnected: ${info['isConnected']}');
                  print('  Socket ID: ${info['socketId']}');
                  print('  Unread count: ${info['unreadCount']}');
                  print('  User ID: ${widget.user.id}');
                  print('  Initialized: ${info['isInitialized']}');
                }
              },
              child: Stack(
                children: [
                  // Notification icon
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
                            final userId = widget.user.id.toString();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationScreen(
                                  userId: userId,
                                  token: widget.token,
                                ),
                              ),
                            );
                          }
                        : () {
                            // Show connection status on tap when not connected
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isInitializing
                                      ? 'Connecting to notifications...'
                                      : 'Notifications offline. Tap and hold to reconnect.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
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

                  // Connection status dot (bottom right of icon)
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
            ),

            // Avatar with click functionality
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
