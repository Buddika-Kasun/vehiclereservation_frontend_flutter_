// lib/screens/notification_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/navigation_helper.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/notification_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/home/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';

// Import new WebSocket structure
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/notification_handler.dart';

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

      // Initialize WebSocket manager (if not already initialized)
      _webSocketManager.initialize(token: widget.token, userId: widget.userId);

      // Connect to notifications namespace - this will increment reference count
      await _webSocketManager.connectToNamespace('notifications');

      // Initialize notification handler
      await _notificationHandler.initialize(
        token: widget.token,
        userId: widget.userId,
      );

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
          // Refresh notifications list when new notification arrives
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

  // Update the _handleWebSocketMessage method
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 NotificationScreen received event: $event');
    }

    // Handle different events
    switch (event) {
      case 'notification':
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

  // Update the _handleNotificationUpdate method
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

  // Update the dispose method in NotificationScreen
  @override
  void dispose() {
    // Only dispose the notification handler and remove listeners
    // The WebSocket connection will be maintained by reference counting
    _notificationHandler.dispose();
    // Remove listeners
    _webSocketManager.removeConnectionListener('notifications', (_) {});
    _webSocketManager.removeMessageListener('notifications', (_) {});
    // Decrement reference count but keep connection alive if TopBar is using it
    _webSocketManager.disconnectFromNamespace('notifications');
    super.dispose();
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
                await ApiService.deleteAllNotification(); // Assuming 'all' clears all
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
        NavigationHelper.toUserCreations('pending');
        break;
      case 'USER_APPROVED':
        NavigationHelper.toUserCreations('approved');
        break;
      case 'USER_REJECTED':
        NavigationHelper.toUserCreations('rejected');
        break;

      // Trip related notifications
      // REQUESTER or PASSENGER related notifications
      case 'TRIP_CREATED':
      case 'TRIP_CANCELLED':
      case 'TRIP_CANCELLED_REQUESTER':
      case 'TRIP_APPROVED':
      case 'TRIP_REJECTED':
      case 'TRIP_READING_START_FOR_PASSENGER':
      case 'TRIP_STARTED_FOR_PASSENGER':
      case 'TRIP_FINISHED_FOR_REQUESTER':
      case 'TRIP_COMPLETED_FOR_REQUESTER':
        NavigationHelper.toMyRideTripDetails(notification.data?.tripId ?? 0);
        break;
        
      // SUPERVISOR related notifications
      case 'TRIP_CREATED_AS_DRAFT':
      case 'TRIP_CONFIRMED':
      case 'TRIP_CANCELLED_SUPERVISOR':
      case 'TRIP_STARTED_FOR_SUPERVISOR':
      case 'TRIP_FINISHED_FOR_SUPERVISOR':
      case 'TRIP_COMPLETED_FOR_SUPERVISOR':
        NavigationHelper.toReviewTripDetails(notification.data?.tripId ?? 0);
        break;

      // APPROVER related notifications
      case 'TRIP_CONFIRMED_FOR_APPROVAL':
      case 'TRIP_APPROVED_BY_APPROVER':
      case 'TRIP_REJECTED_BY_APPROVER':
        NavigationHelper.toApprovalTripDetails(notification.data?.tripId ?? 0);
        break;

      // DRIVER related notifications
      case 'TRIP_APPROVED_FOR_DRIVER':
      case 'TRIP_READING_START_FOR_DRIVER':
      case 'TRIP_STARTED':
      case 'TRIP_FINISHED':
      case 'TRIP_COMPLETED_FOR_DRIVER':
        NavigationHelper.toAssignRideTripDetails(notification.data?.tripId ?? 0);
        break;

      // SECURITY related notifications
      case 'TRIP_APPROVED_FOR_SECURITY':
      case 'TRIP_READING_START':
      case 'TRIP_STARTED_FOR_SECURITY':
      case 'TRIP_COMPLETED':
        NavigationHelper.toMeterReading();
        break;

      // Vehicle related notifications
      case 'VEHICLE_ASSIGNED':
      case 'VEHICLE_UNASSIGNED':
        _showVehicleNotificationDialog(notification);
        break;

      case 'TRIP_PASSENGER_JOINED':
      case 'TRIP_PASSENGERS_ADDED':

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
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Message content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // View Trips button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'VIEW TRIPS',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 80.0; // Base height for app bar content

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 217, 217),
      body: Column(
        children: [
          // Top Bar with Black Background - FIXED VERSION
          Container(
            // Dynamic height based on status bar + app bar content
            height: statusBarHeight + appBarHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status bar spacer
                SizedBox(height: statusBarHeight),

                // Main app bar content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
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
                                    color: _isConnected
                                        ? Colors.green
                                        : Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isConnected
                                                    ? Colors.green
                                                    : Colors.red)
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
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
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.black,
                            ),
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
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading || _isInitializing) {
                  return _buildLoadingState();
                } else if (_hasError) {
                  return _buildErrorState();
                } else if (_notifications.isNotEmpty) {
                  return _buildNotificationsList();
                } else {
                  return _buildEmptyState();
                }
              },
            ),
          ),
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
    final int index = _notifications.indexOf(notification);

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.horizontal,

      // Left to right swipe background (Mark as Read)
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 30),
        decoration: BoxDecoration(
          color: notification.read ? Colors.blue : Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              notification.read ? Icons.mark_chat_read : Icons.mark_chat_read,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              notification.read ? 'Mark as Unread' : 'Mark as Read',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

      // Right to left swipe background (Delete)
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white, size: 28),
          ],
        ),
      ),

      onDismissed: (direction) {
        // Remove the item immediately
        setState(() {
          _notifications.removeAt(index);
        });

        if (direction == DismissDirection.startToEnd) {
          // Left swipe - Toggle read/unread
          if (notification.read) {
            _markAsUnread(notification.id);
          } else {
            _markAsRead(notification.id);
          }
        } else {
          // Right swipe - Delete
          _deleteNotification(notification.id);
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero, // Remove Card's margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: notification.read
                          ? Colors.grey[200]
                          : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: notification.read
                          ? Colors.grey[600]
                          : Colors.yellow[600],
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
                            fontWeight: notification.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                            color: notification.read
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: notification.read
                                ? Colors.grey[500]
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: notification.read
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                            Row(
                              children: [
                                if (notification.read)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'READ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.swipe,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                              ],
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
      ),
    );
  }

  void _markAsUnread(int notificationId) async {
    try {
      await ApiService.markNotificationAsUnread(notificationId.toString());
      _loadNotifications();
      _loadUnreadCount();

      /*
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as unread'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
      */
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark as unread: $e')));
    }
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
        return Icons.person_add;
      case 'USER_APPROVED':
        return Icons.person_add_alt_1;
      case 'USER_REJECTED':
        return Icons.person_remove;
      case 'TRIP_CREATED':
      case 'TRIP_CANCELLED':
      case 'TRIP_CANCELLED_REQUESTER':
      case 'TRIP_APPROVED':
      case 'TRIP_REJECTED':
      case 'TRIP_READING_START_FOR_PASSENGER':
      case 'TRIP_STARTED_FOR_PASSENGER':
      case 'TRIP_FINISHED_FOR_REQUESTER':
      case 'TRIP_COMPLETED_FOR_REQUESTER':
      case 'TRIP_CREATED_AS_DRAFT':
      case 'TRIP_CONFIRMED':
      case 'TRIP_CANCELLED_SUPERVISOR':
      case 'TRIP_STARTED_FOR_SUPERVISOR':
      case 'TRIP_FINISHED_FOR_SUPERVISOR':
      case 'TRIP_COMPLETED_FOR_SUPERVISOR':
      case 'TRIP_CONFIRMED_FOR_APPROVAL':
      case 'TRIP_APPROVED_BY_APPROVER':
      case 'TRIP_REJECTED_BY_APPROVER':
      case 'TRIP_APPROVED_FOR_DRIVER':
      case 'TRIP_READING_START_FOR_DRIVER':
      case 'TRIP_STARTED':
      case 'TRIP_FINISHED':
      case 'TRIP_COMPLETED_FOR_DRIVER':
      case 'TRIP_APPROVED_FOR_SECURITY':
      case 'TRIP_READING_START':
      case 'TRIP_STARTED_FOR_SECURITY':
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
