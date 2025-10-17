// lib/data/models/chat_message_model.dart
// Model for a single chat message stored inside:
// /conversations/{conversationId}/messages/{messageId}

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final List<String> readBy; // uids who read the message
  final String? attachmentUrl; // optional (image, etc)

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.readBy = const [],
    this.attachmentUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    final created = map['createdAt'] is Timestamp
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final readList = (map['readBy'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      createdAt: created,
      readBy: readList,
      attachmentUrl: map['attachmentUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'readBy': readBy,
        'attachmentUrl': attachmentUrl,
      }..removeWhere((k, v) => v == null);
}
