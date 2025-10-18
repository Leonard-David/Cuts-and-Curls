import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.sentAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String docId) {
    return ChatMessageModel(
      id: docId,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
