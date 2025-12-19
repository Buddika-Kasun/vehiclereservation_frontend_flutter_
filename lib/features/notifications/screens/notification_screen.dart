// lib/screens/notification_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/notification_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';

// Import new WebSocket structure
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/handlers/notification_handler.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final String token;

  const NotificationScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final WebSocketManager _webSocketManager = WebSocketManager();
  final NotificationHandler _notificationHandler = NotificationHandler();

  final List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _unreadCount = 0;
  bool _isConnected = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('📱 NotificationScreen initialized for user: ${widget.userId}');
    }

    _loadInitialData();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    try {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      // Initialize WebSocket manager
      _webSocketManager.initialize(token: widget.token, userId: widget.userId);

      // Initialize notification handler
      await _notificationHandler.initialize(
        token: widget.token,
        userId: widget.userId,
      );

      // Connect to notifications namespace
      await _webSocketManager.connectToNamespace('notifications');

      // Set up notification handler callbacks
      _notificationHandler.onUnreadCountUpdate = (count) {
        if (mounted) {
          if (count == -1) {
            // Refresh unread count via API
            _loadUnreadCount();
          } else {
            // Update with specific count
            setState(() {
              _unreadCount = count;
            });
          }
        }
      };

      _notificationHandler.onNewNotification = (notification) {
        if (mounted) {
          // Show snackbar for new notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New notification: ${notification['title'] ?? 'Notification'}',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          // Refresh notifications list
          _loadNotifications();
        }
      };

      // Set up connection listener
      _webSocketManager.addConnectionListener('notifications', (isConnected) {
        if (kDebugMode) {
          print('🔌 NotificationScreen connection: $isConnected');
        }
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
            _isInitializing = false;
          });
        }
      });

      // Set up message listener
      _webSocketManager.addMessageListener('notifications', (message) {
        _handleWebSocketMessage(message);
      });

      if (mounted) {
        setState(() {
          _isConnected = _webSocketManager.isNamespaceConnected(
            'notifications',
          );
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationScreen WebSocket error: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isConnected = false;
          _isInitializing = false;
        });
      }
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 NotificationScreen received event: $event');
    }

    // Handle different events
    switch (event) {
      case 'notification_update':
        _handleNotificationUpdate(data);
        break;
      case 'refresh':
        _handleRefreshEvent(data);
        break;
      case 'connected':
        _handleConnected(data);
        break;
      case 'disconnected':
        _handleDisconnected(data);
        break;
    }
  }

  void _handleNotificationUpdate(Map<String, dynamic> data) {
    final action = data['action']?.toString() ?? '';
    final notificationData = data['data'];

    if (kDebugMode) {
      print('📨 Notification update action: $action');
    }

    // Refresh notifications when updates come
    _loadNotifications();
    _loadUnreadCount();
  }

  void _handleRefreshEvent(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('🔄 Refresh event received, reloading notifications...');
    }
    _loadNotifications();
    _loadUnreadCount();
  }

  void _handleConnected(dynamic data) {
    if (mounted) {
      setState(() {
        _isConnected = true;
      });
    }
  }

  void _handleDisconnected(dynamic data) {
    if (mounted) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    await _loadNotifications();
    await _loadUnreadCount();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await ApiService.getNotifications();
      if (response['success'] == true && response['data'] != null) {
        final notificationsData =
            response['data']['notifications'] as List<dynamic>? ?? [];
        final notifications = notificationsData
            .map((item) => NotificationModel.fromJson(item))
            .toList();

        if (mounted) {
          setState(() {
            _notifications.clear();
            _notifications.addAll(notifications);
            _hasError = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notifications: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
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
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading unread count: $e');
      }
    }
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteNotification(
                  'all',
                ); // Assuming 'all' clears all
                _loadNotifications();
                _loadUnreadCount();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear notifications: $e')),
                );
              }
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      _loadNotifications();
      _loadUnreadCount();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark all as read: $e')));
    }
  }

  void _deleteNotification(int notificationId) async {
    try {
      await ApiService.deleteNotification(notificationId.toString());
      _loadNotifications();
      _loadUnreadCount();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  void _markAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId.toString());
      _loadNotifications();
      _loadUnreadCount();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.read) {
      _markAsRead(notification.id);
    }

    // Get metadata
    final NotificationMetadata? metadata = notification.metadata;

    switch (notification.type) {
      // User registration notifications - go to user creations screen
      case 'USER_REGISTERED':
      case 'USER_APPROVED':
      case 'USER_REJECTED':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(screenName: 'user_creations'),
          ),
        );
        break;

      // Trip related notifications
      case 'TRIP_CREATED':
      case 'TRIP_APPROVED':
      case 'TRIP_REJECTED':
      case 'TRIP_CANCELLED':
      case 'TRIP_COMPLETED':
        _showTripNotificationDialog(notification);
        break;

      // Vehicle related notifications
      case 'VEHICLE_ASSIGNED':
      case 'VEHICLE_UNASSIGNED':
        _showVehicleNotificationDialog(notification);
        break;

      // Default case for other notifications
      default:
        // Show notification details in a dialog
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showTripNotificationDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to trips screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      screenName: 'my_rides',
                      screenData: {'userId': widget.userId},
                    ),
                  ),
                );
              },
              child: Text('View Trips'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showVehicleNotificationDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to vehicles screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(screenName: 'my_vehicles'),
                  ),
                );
              },
              child: Text('View Vehicles'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show notification details in a dialog
  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              if (notification.data != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    Text(
                      'Notification Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatNotificationData(notification.data!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              if (notification.metadata != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    Text(
                      'Metadata:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatMetadata(notification.metadata!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  // Format NotificationData for display
  String _formatNotificationData(NotificationData data) {
    final List<String> entries = [];

    if (data.userId != null) entries.add('User ID: ${data.userId}');
    if (data.username != null) entries.add('Username: ${data.username}');
    if (data.displayname != null)
      entries.add('Display Name: ${data.displayname}');
    if (data.email != null) entries.add('Email: ${data.email}');
    if (data.phone != null) entries.add('Phone: ${data.phone}');
    if (data.role != null) entries.add('Role: ${data.role}');
    if (data.departmentId != null)
      entries.add('Department ID: ${data.departmentId}');
    if (data.actionRequired != null)
      entries.add('Action Required: ${data.actionRequired}');
    if (data.registrationDate != null)
      entries.add('Registration Date: ${data.registrationDate}');
    if (data.message != null) entries.add('Message: ${data.message}');
    if (data.requiresScreenRefresh != null)
      entries.add('Refresh Required: ${data.requiresScreenRefresh}');

    return entries.join('\n');
  }

  // Format NotificationMetadata for display
  String _formatMetadata(NotificationMetadata metadata) {
    final List<String> entries = [];

    if (metadata.screen != null) entries.add('Screen: ${metadata.screen}');
    if (metadata.action != null) entries.add('Action: ${metadata.action}');
    if (metadata.userId != null) entries.add('User ID: ${metadata.userId}');
    if (metadata.autoAssign != null)
      entries.add('Auto Assign: ${metadata.autoAssign}');
    if (metadata.requiresScreenRefresh != null)
      entries.add('Refresh Required: ${metadata.requiresScreenRefresh}');
    if (metadata.isBroadcast != null)
      entries.add('Is Broadcast: ${metadata.isBroadcast}');
    if (metadata.refreshRequired != null)
      entries.add('Refresh Required: ${metadata.refreshRequired}');

    if (metadata.targetRoles != null && metadata.targetRoles!.isNotEmpty) {
      entries.add('Target Roles: ${metadata.targetRoles!.join(', ')}');
    }

    return entries.join('\n');
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
      _notifications.clear();
    });

    await _loadNotifications();
    await _loadUnreadCount();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _reconnectWebSocket() {
    setState(() {
      _isInitializing = true;
    });
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationHandler.dispose();
    _webSocketManager.disconnectFromNamespace('notifications');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 217, 217),
      body: Column(
        children: [
          _buildTopBar(),
          if (_isLoading || _isInitializing)
            _buildLoadingState()
          else if (_hasError)
            _buildErrorState()
          else if (_notifications.isNotEmpty)
            _buildNotificationsList()
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow[600],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
                iconSize: 24,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Colors.green : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (_isConnected ? Colors.green : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow[600],
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black),
                onPressed: _notifications.isNotEmpty
                    ? _clearAllNotifications
                    : null,
                padding: const EdgeInsets.all(10),
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.black),
            const SizedBox(height: 16),
            Text(
              _isInitializing
                  ? 'Connecting to notifications...'
                  : 'Loading notifications...',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Connection Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to connect to notifications',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reconnectWebSocket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow[600],
              ),
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.red, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        '$_unreadCount Unread',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_unreadCount > 0)
                  ElevatedButton.icon(
                    onPressed: _markAllAsRead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.yellow[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark All as Read'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isConnected ? Icons.notifications_off : Icons.wifi_off,
                size: 60,
                color: Colors.yellow[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isConnected ? 'No Notifications' : 'Connection Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isConnected
                  ? 'You\'re all caught up!\nNo notifications at the moment.'
                  : 'Connect to server to see notifications',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        color: !notification.read ? Colors.yellow[50] : Colors.white,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: !notification.read ? Colors.black : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: !notification.read
                        ? Colors.yellow[600]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: !notification.read
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'USER_REGISTERED':
      case 'USER_APPROVED':
      case 'USER_REJECTED':
        return Icons.person_add;
      case 'TRIP_CREATED':
      case 'TRIP_APPROVED':
      case 'TRIP_REJECTED':
      case 'TRIP_CANCELLED':
      case 'TRIP_COMPLETED':
        return Icons.directions_car;
      case 'VEHICLE_ASSIGNED':
      case 'VEHICLE_UNASSIGNED':
        return Icons.directions_car_filled;
      default:
        return Icons.notifications;
    }
  }
}
