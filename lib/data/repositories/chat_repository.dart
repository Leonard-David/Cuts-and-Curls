import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'chats';

  String _chatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }

  /// Send a message
  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    final chatId = _chatId(senderId, receiverId);
    final messageRef = _firestore
        .collection(collectionPath)
        .doc(chatId)
        .collection('messages')
        .doc();

    final chatMessage = ChatMessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      sentAt: DateTime.now(),
    );

    await messageRef.set(chatMessage.toMap());
  }

  /// Stream chat messages in order
  Stream<List<ChatMessageModel>> getChatMessages(String userA, String userB) {
    final chatId = _chatId(userA, userB);
    return _firestore
        .collection(collectionPath)
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
