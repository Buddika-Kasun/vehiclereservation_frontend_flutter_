// lib/data/services/ws/constants/websocket_constants.dart
class WebSocketConstants {
  static const String baseUrl = 'ws://localhost:3000'; // Change to your URL

  // Namespaces
  static const String notificationsNamespace = 'notifications';
  static const String usersNamespace = 'users';
  static const String tripsNamespace = 'trips';
  static const String dashboardNamespace = 'dashboard';

  // Event types
  static const String notificationUpdate = 'notification_update';
  static const String userUpdate = 'user_update';
  static const String tripRefresh = 'refresh';
  static const String dashboardRefresh = 'refresh';

  // Common actions
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String read = 'read';
  static const String statusChange = 'status_change';
}
