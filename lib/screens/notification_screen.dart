// lib/screens/notification_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/notification_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/ws/global_websocket_manager.dart';

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
  final GlobalWebSocketManager _webSocketManager = GlobalWebSocketManager();

  // Unique listener IDs
  final String _connectionListenerId;
  final String _unreadListenerId;
  final String _notificationListenerId;

  _NotificationScreenState()
    : _connectionListenerId = UniqueKey().toString(),
      _unreadListenerId = UniqueKey().toString(),
      _notificationListenerId = UniqueKey().toString();

  final List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _unreadCount = 0;
  bool _isConnected = false;
  bool _hasRequestedInitialData = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('📱 NotificationScreen initialized for user: ${widget.userId}');
    }

    _setupListeners();
    _initializeWebSocket();
  }

  void _setupListeners() {
    // Connection status listener
    _webSocketManager.addConnectionListener(_connectionListenerId, (
      isConnected,
    ) {
      if (kDebugMode) {
        print('🔌 NotificationScreen connection: $isConnected');
      }
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });

        if (isConnected && !_hasRequestedInitialData) {
          _requestInitialNotifications();
          _hasRequestedInitialData = true;
        }
      }
    });

    // Unread count listener
    _webSocketManager.addUnreadListener(_unreadListenerId, (count) {
      if (kDebugMode) {
        print('📊 NotificationScreen unread: $count');
      }
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });

    // Notification listener
    _webSocketManager.addNotificationListener(_notificationListenerId, (
      notification,
    ) {
      if (kDebugMode) {
        print('📨 NotificationScreen received message');
        print('📨 Type: ${notification['type']}');
        print('📨 Data keys: ${notification['data']?.keys}');
      }
      _handleWebSocketMessage(notification);
    });
  }

  Future<void> _initializeWebSocket() async {
    try {
      if (kDebugMode) {
        print('🔄 NotificationScreen initializing WebSocket...');
      }

      if (!_webSocketManager.isInitializedForUser(widget.userId)) {
        await _webSocketManager.initialize(widget.token, widget.userId);
      }

      if (mounted) {
        setState(() {
          _isConnected = _webSocketManager.isConnected;
          _unreadCount = _webSocketManager.unreadCount;
          _isLoading = false;
        });

        if (_isConnected && !_hasRequestedInitialData) {
          _requestInitialNotifications();
          _hasRequestedInitialData = true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationScreen WebSocket error: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isConnected = false;
        });
      }
    }
  }

  void _requestInitialNotifications() {
    if (!_webSocketManager.isConnected) {
      if (kDebugMode) {
        print('⚠️ Not connected, cannot request initial notifications');
      }
      return;
    }

    if (kDebugMode) {
      print('📥 Requesting initial notifications and unread count...');
    }

    _webSocketManager.getInitialNotifications();
    _webSocketManager.getUnreadCount();
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final String eventType = message['type'] ?? '';
    final dynamic eventData = message['data'];

    if (kDebugMode) {
      print('🔔 Processing event type: $eventType');
    }

    switch (eventType) {
      case 'initial-notifications':
        _handleInitialNotifications(eventData);
        break;
      case 'unread-count':
        _handleUnreadCount(eventData);
        break;
      case 'new_notification':
        _handleNewNotification(eventData);
        break;
      case 'notification_read':
        _handleNotificationRead(eventData);
        break;
      case 'notification_deleted':
        _handleNotificationDeleted(eventData);
        break;
      case 'all_read':
        _handleAllRead();
        break;
      case 'all_cleared':
        _handleAllCleared();
        break;
      case 'connected':
        if (kDebugMode) {
          print('✅ Connected to notification server');
        }
        _requestInitialNotifications();
        break;
      case 'error':
        if (kDebugMode) {
          print('❌ WebSocket error: $eventData');
        }
        break;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown event type: $eventType');
        }
    }
  }

  void _handleInitialNotifications(dynamic data) {
    if (kDebugMode) {
      print('📋 Processing initial notifications in UI');
      print('📋 Data type: ${data.runtimeType}');
      print('📋 Data: $data');
    }

    try {
      if (data is Map<String, dynamic>) {
        // The data should have 'notifications' array and 'unreadCount'
        if (kDebugMode) {
          print('📋 Data keys: ${data.keys}');
        }

        final response = InitialNotificationsResponse.fromJson(data);

        if (kDebugMode) {
          print('✅ Parsed ${response.notifications.length} notifications');
          print('📊 Unread count: ${response.unreadCount}');
        }

        setState(() {
          _notifications.clear();
          _notifications.addAll(response.notifications);
          _unreadCount = response.unreadCount;
          _isLoading = false;
          _hasError = false;
        });

        if (kDebugMode) {
          print('✅ UI updated with ${_notifications.length} notifications');
        }
      } else if (data is List) {
        // If it comes as a list directly
        if (kDebugMode) {
          print('📋 Data is a list with ${data.length} items');
        }

        final notifications = data
            .map(
              (item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        setState(() {
          _notifications.clear();
          _notifications.addAll(notifications);
          _isLoading = false;
          _hasError = false;
        });
      } else {
        if (kDebugMode) {
          print('⚠️ Unexpected data format: ${data.runtimeType}');
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error parsing initial notifications: $e');
        print('❌ Stack trace: $stackTrace');
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _handleUnreadCount(dynamic data) {
    if (data is Map<String, dynamic>) {
      final count = data['count'] ?? 0;
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
      if (kDebugMode) {
        print('📊 Updated unread count: $count');
      }
    }
  }

  void _handleNewNotification(dynamic data) {
    if (data is Map<String, dynamic>) {
      try {
        final notification = NotificationModel.fromJson(
          data,
        ).copyWith(isNew: true);

        setState(() {
          _notifications.insert(0, notification);
          if (!notification.read) {
            _unreadCount++;
          }
        });

        if (!notification.isPending) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📢 ${notification.title}'),
              backgroundColor: Colors.black,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.yellow[600],
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error handling new notification: $e');
        }
      }
    }
  }

  void _handleNotificationRead(dynamic data) {
    if (data is Map<String, dynamic>) {
      final notificationId = data['notificationId'] ?? data['id'];

      setState(() {
        final index = _notifications.indexWhere(
          (n) => n.id.toString() == notificationId.toString(),
        );
        if (index != -1 && !_notifications[index].read) {
          _notifications[index] = _notifications[index].copyWith(read: true);
          if (_unreadCount > 0) {
            _unreadCount--;
          }
        }
      });
    }
  }

  void _handleNotificationDeleted(dynamic data) {
    if (data is Map<String, dynamic>) {
      final notificationId = data['notificationId'] ?? data['id'];

      setState(() {
        final index = _notifications.indexWhere(
          (n) => n.id.toString() == notificationId.toString(),
        );
        if (index != -1) {
          if (!_notifications[index].read && _unreadCount > 0) {
            _unreadCount--;
          }
          _notifications.removeAt(index);
        }
      });
    }
  }

  void _handleAllRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
      _unreadCount = 0;
    });
  }

  void _handleAllCleared() {
    setState(() {
      _notifications.clear();
      _unreadCount = 0;
    });
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
            onPressed: () {
              _webSocketManager.clearAllNotifications();
              Navigator.pop(context);
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

  void _markAllAsRead() {
    _webSocketManager.markAllAsRead();
  }

  void _deleteNotification(int notificationId) {
    _webSocketManager.deleteNotification(notificationId.toString());
  }

  void _markAsRead(int notificationId) {
    _webSocketManager.markAsRead(notificationId.toString());
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
      _hasRequestedInitialData = false;
      _notifications.clear();
    });

    _requestInitialNotifications();

    // Give it a moment to receive data
    await Future.delayed(Duration(seconds: 2));

    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _webSocketManager.removeConnectionListener(_connectionListenerId);
    _webSocketManager.removeUnreadListener(_unreadListenerId);
    _webSocketManager.removeNotificationListener(_notificationListenerId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 217, 217),
      body: Column(
        children: [
          _buildTopBar(),
          if (_isLoading)
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
              _isConnected
                  ? 'Loading notifications...'
                  : 'Connecting to server...',
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshNotifications,
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
          onTap: () {
            if (!notification.read) {
              _markAsRead(notification.id);
            }
          },
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
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
        return Icons.person_add;
      case 'TRIP_CREATED':
        return Icons.directions_car;
      default:
        return Icons.notifications;
    }
  }
}
