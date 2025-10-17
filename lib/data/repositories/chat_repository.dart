// lib/data/repositories/chat_repository.dart
// Conversation metadata stored in /conversations/{convId}
// Messages stored in /conversations/{convId}/messages/{msgId}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final CollectionReference _convRef = FirebaseFirestore.instance.collection('conversations');

  ChatRepository();

  /// Ensure a conversation exists between two participants and return its id.
  /// Simple implementation: search for a conversation with same participants array.
  Future<String> getOrCreateConversationId(List<String> participants) async {
    // Normalize participants (sort) to make deterministic
    final normalized = List<String>.from(participants)..sort();
    final snap = await _convRef
        .where('participants', isEqualTo: normalized) // requires exact array order; hence normalized
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return snap.docs.first.id;

    // create a new conversation doc
    final docRef = await _convRef.add({
      'participants': normalized,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageText': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    return docRef.id;
  }

  /// Send a message to a conversation (adds doc in subcollection and updates parent).
  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    final messagesRef = _convRef.doc(conversationId).collection('messages');
    final parentRef = _convRef.doc(conversationId);

    // Use a batched write for atomicity: add message + update parent metadata
    final batch = FirebaseFirestore.instance.batch();
    final newMsgRef = messagesRef.doc();
    batch.set(newMsgRef, message.toMap());
    batch.update(parentRef, {
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageText': message.text,
    });

    await batch.commit();
  }

  /// Stream messages for a conversation (ordered by createdAt ascending).
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    final messagesRef = _convRef.doc(conversationId).collection('messages');
    return messagesRef.orderBy('createdAt', descending: false).snapshots().map((snap) {
      // ignore: unnecessary_cast
      return snap.docs.map((d) => ChatMessage.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    });
  }

  /// Stream conversations for a user (where they are a participant).
  Stream<List<Map<String, dynamic>>> streamConversationsForUser(String uid) {
    // Using array-contains to find conversations the user participates in.
    return _convRef.where('participants', arrayContains: uid).orderBy('lastMessageAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }
}
