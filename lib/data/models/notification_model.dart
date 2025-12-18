// lib/models/notification_model.dart

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final NotificationData? data;
  final bool read;
  final String createdAt;
  final bool isPending;
  final NotificationMetadata? metadata;
  final bool isNew; // Local flag for UI

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    required this.createdAt,
    required this.isPending,
    this.metadata,
    this.isNew = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? NotificationData.fromJson(json['data'])
          : null,
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      isPending: json['isPending'] ?? false,
      metadata: json['metadata'] != null
          ? NotificationMetadata.fromJson(json['metadata'])
          : null,
      isNew: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data?.toJson(),
      'read': read,
      'createdAt': createdAt,
      'isPending': isPending,
      'metadata': metadata?.toJson(),
      'isNew': isNew,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    NotificationData? data,
    bool? read,
    String? createdAt,
    bool? isPending,
    NotificationMetadata? metadata,
    bool? isNew,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      metadata: metadata ?? this.metadata,
      isNew: isNew ?? this.isNew,
    );
  }
}

class NotificationData {
  final String? role;
  final String? email;
  final String? phone;
  final int? userId;
  final String? username;
  final String? displayname;
  final int? departmentId;
  final bool? actionRequired;
  final String? registrationDate;
  final String? message;
  final bool? requiresScreenRefresh;

  NotificationData({
    this.role,
    this.email,
    this.phone,
    this.userId,
    this.username,
    this.displayname,
    this.departmentId,
    this.actionRequired,
    this.registrationDate,
    this.message,
    this.requiresScreenRefresh,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      role: json['role'],
      email: json['email'],
      phone: json['phone'],
      userId: json['userId'],
      username: json['username'],
      displayname: json['displayname'],
      departmentId: json['departmentId'],
      actionRequired: json['actionRequired'],
      registrationDate: json['registrationDate'],
      message: json['message'],
      requiresScreenRefresh: json['requiresScreenRefresh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'email': email,
      'phone': phone,
      'userId': userId,
      'username': username,
      'displayname': displayname,
      'departmentId': departmentId,
      'actionRequired': actionRequired,
      'registrationDate': registrationDate,
      'message': message,
      'requiresScreenRefresh': requiresScreenRefresh,
    };
  }
}

class NotificationMetadata {
  final String? screen;
  final String? action;
  final bool? isBroadcast;
  final List<String>? targetRoles;
  final bool? refreshRequired;
  final int? userId;
  final bool? autoAssign;
  final bool? requiresScreenRefresh;

  NotificationMetadata({
    this.screen,
    this.action,
    this.isBroadcast,
    this.targetRoles,
    this.refreshRequired,
    this.userId,
    this.autoAssign,
    this.requiresScreenRefresh,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      screen: json['screen'],
      action: json['action'],
      isBroadcast: json['isBroadcast'],
      targetRoles: json['targetRoles'] != null
          ? List<String>.from(json['targetRoles'])
          : null,
      refreshRequired: json['refreshRequired'],
      userId: json['userId'],
      autoAssign: json['autoAssign'],
      requiresScreenRefresh: json['requiresScreenRefresh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen': screen,
      'action': action,
      'isBroadcast': isBroadcast,
      'targetRoles': targetRoles,
      'refreshRequired': refreshRequired,
      'userId': userId,
      'autoAssign': autoAssign,
      'requiresScreenRefresh': requiresScreenRefresh,
    };
  }
}

// Response models for WebSocket messages
class InitialNotificationsResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;

  InitialNotificationsResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory InitialNotificationsResponse.fromJson(Map<String, dynamic> json) {
    final notificationsJson = json['notifications'] as List<dynamic>? ?? [];
    final notifications = notificationsJson
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return InitialNotificationsResponse(
      notifications: notifications,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

