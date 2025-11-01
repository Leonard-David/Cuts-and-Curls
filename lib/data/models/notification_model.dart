enum NotificationType {
  appointment,
  payment,
  system,
  promotion,
  reminder,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedId; // appointmentId, paymentId, etc.
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  // Convert model to map for Firestore
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
      'readAt': readAt?.millisecondsSinceEpoch,
      'data': data,
    };
  }

  // Create model from Firestore data
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      readAt: map['readAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
      data: map['data'] != null 
          ? Map<String, dynamic>.from(map['data'])
          : null,
    );
  }

  // Create copy with method for updates
  AppNotification copyWith({
    String? title,
    String? message,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }
}