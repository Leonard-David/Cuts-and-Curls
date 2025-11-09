import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  appointment,
  payment,
  reminder,
  promotion,
  system,
  marketing,
  availability,
  discount
}

enum NotificationCategory {
  today,
  thisWeek,
  thisMonth,
  older,
  all
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final bool isSynced;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
    this.data,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'data': data,
      'isSynced': isSynced,
      'createdAtTimestamp': FieldValue.serverTimestamp(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      isSynced: map['isSynced'] ?? true,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    bool? isSynced,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  NotificationCategory get category {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    final difference = today.difference(notificationDate).inDays;

    if (difference == 0) {
      return NotificationCategory.today;
    } else if (difference <= 7) {
      return NotificationCategory.thisWeek;
    } else if (difference <= 30) {
      return NotificationCategory.thisMonth;
    } else {
      return NotificationCategory.older;
    }
  }
}