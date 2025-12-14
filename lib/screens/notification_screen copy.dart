import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [
    {
      'id': 1,
      'title': 'Booking Confirmed',
      'message': 'Your vehicle booking #VRB001 has been confirmed',
      'time': '2 hours ago',
      'read': false,
    },
    {
      'id': 2,
      'title': 'Payment Successful',
      'message': 'Payment of \$45.00 for booking #VRB001 was successful',
      'time': '5 hours ago',
      'read': false,
    },
    {
      'id': 3,
      'title': 'Reminder',
      'message': 'Your vehicle pickup is scheduled for tomorrow at 10:00 AM',
      'time': '1 day ago',
      'read': true,
    },
    {
      'id': 4,
      'title': 'New Vehicle Available',
      'message': 'New SUV has been added to our fleet. Book now!',
      'time': '2 days ago',
      'read': true,
    },
    {
      'id': 5,
      'title': 'Promotion',
      'message': 'Get 20% off on weekend bookings. Use code: WEEKEND20',
      'time': '3 days ago',
      'read': true,
    },
  ];

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Notifications'),
        content: Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notifications.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
    setState(() {
      for (var notification in notifications) {
        notification['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteNotification(int id) {
    setState(() {
      notifications.removeWhere((notification) => notification['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification removed'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 217, 217),
      body: Column(
        children: [
          // Custom Top Bar with BLACK Background
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black, // BLACK background
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
                  // Back Button with YELLOW background
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow[600], // YELLOW background
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                      ), // Black arrow
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.all(10),
                      iconSize: 24,
                      tooltip: 'Back',
                    ),
                  ),

                  // Notification Title in WHITE
                  Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text on black background
                      letterSpacing: 1.2,
                    ),
                  ),

                  // Clear Button with YELLOW background
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow[600], // YELLOW background
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.black,
                      ), // Black icon
                      onPressed: notifications.isNotEmpty
                          ? _clearAllNotifications
                          : null,
                      padding: EdgeInsets.all(10),
                      iconSize: 24,
                      tooltip: 'Clear All',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Statistics and Actions Row
          if (notifications.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Unread Count
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        SizedBox(width: 8),
                        Text(
                          '${notifications.where((n) => !n['read']).length} Unread',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mark All as Read Button with BLACK background
                  ElevatedButton.icon(
                    onPressed: _markAllAsRead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // BLACK background
                      foregroundColor: Colors.yellow[600], // YELLOW text/icon
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 3,
                    ),
                    icon: Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'Mark All as Read',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_off,
                            size: 60,
                            color: Colors.yellow[600],
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No Notifications',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Optional: Add refresh or go back action
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.yellow[600],
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          icon: Icon(Icons.arrow_back),
                          label: Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 30),
                          color: Colors.red,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete, color: Colors.white, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          _deleteNotification(notification['id']);
                        },
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: notification['read']
                                  ? Colors.grey[200]!
                                  : Colors.yellow[600]!.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          color: notification['read']
                              ? Colors.white
                              : Colors.yellow[50],
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: notification['read']
                                    ? Colors.grey[200]
                                    : Colors.black, // Black for unread
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getNotificationIcon(notification['title']),
                                color: notification['read']
                                    ? Colors.grey[600]
                                    : Colors.yellow[600], // Yellow for unread
                                size: 24,
                              ),
                            ),
                            title: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight: notification['read']
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 6),
                                Text(
                                  notification['message'],
                                  style: TextStyle(
                                    color: notification['read']
                                        ? Colors.grey[600]
                                        : Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      notification['time'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Spacer(),
                                    if (!notification['read'])
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.yellow[600],
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                            onTap: () {
                              setState(() {
                                notification['read'] = true;
                              });
                              // Handle notification tap - navigate to relevant screen
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('Booking') || title.contains('Confirmed')) {
      return Icons.confirmation_number_outlined;
    } else if (title.contains('Payment')) {
      return Icons.payment_outlined;
    } else if (title.contains('Reminder')) {
      return Icons.access_time;
    } else if (title.contains('Vehicle')) {
      return Icons.directions_car_outlined;
    } else if (title.contains('Promotion')) {
      return Icons.local_offer_outlined;
    }
    return Icons.notifications_outlined;
  }
}
