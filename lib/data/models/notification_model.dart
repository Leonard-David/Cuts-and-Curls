// lib/data/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String? fromUserId;
  final String type; // appointment, earning, promotion, feedback, system
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? meta;

  AppNotification({
    required this.id,
    required this.userId,
    this.fromUserId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.meta,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      fromUserId: data['fromUserId'] as String?,
      type: data['type'] as String? ?? 'system',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meta: data['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'fromUserId': fromUserId,
        'type': type,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
        'meta': meta,
      };
}
