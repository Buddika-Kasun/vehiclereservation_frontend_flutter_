// lib/shared/widgets/top_bar.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/global_websocket.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/notifications/screens/notification_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/profile/profile_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/handlers/notification_handler.dart';

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
  //final NotificationHandler _notificationHandler = NotificationHandler();
  //final WebSocketManager _webSocketManager = WebSocketManager();
  WebSocketManager get _webSocketManager => GlobalWebSocket.instance;
  late NotificationHandler _notificationHandler;

  int _unreadCount = 0;
  bool _isConnected = false;
  bool _isInitializing = false;

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
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      });

      // Add message listener
      _webSocketManager.addMessageListener('notifications', (message) {
        final event = message['event']?.toString() ?? '';
        print('📨 Received notification event: $event');

        if (event == 'notification' ||
            event == 'refresh' ||
            event == 'notification_update') {
          _loadUnreadCount();

          if (event == 'notification' || event == 'notification_update') {
            _showSimpleNotificationPopup();
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
        _showSimpleNotificationPopup();
        _loadUnreadCount();
      };

      // Connect to notifications namespace (will use reference counting)
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
    // Only dispose handler, don't disconnect WebSocket
    _notificationHandler.dispose();
    _webSocketManager.removeConnectionListener('notifications', (_) {});
    _webSocketManager.removeMessageListener('notifications', (_) {});
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

  void _showSimpleNotificationPopup() {
    if (!mounted || _showNotification) return;

    // Cancel any existing timer
    _notificationTimer?.cancel();

    // Remove existing overlay
    _removeNotificationPopup();

    // Create new overlay
    _createSimplePopup();

    // Auto-hide after 3 seconds
    _notificationTimer = Timer(const Duration(seconds: 5), () {
      _removeNotificationPopup();
    });
  }

  void _createSimplePopup() {
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 10, // Adjust based on your AppBar height
        left: 16,
        right: 16,
        child: _buildSimplePopup(),
      ),
    );

    overlayState.insert(_notificationOverlay!);
    _showNotification = true;
  }

  Widget _buildSimplePopup() {
    return Container(
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
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'New Notification',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($_unreadCount unread)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          GestureDetector(
            onTap: _removeNotificationPopup,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
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

  void _refreshConnection() {
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }
    _initializeNotificationHandler();
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
                          _removeNotificationPopup();
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
