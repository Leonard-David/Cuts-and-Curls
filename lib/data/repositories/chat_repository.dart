import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat room
  Future<ChatRoom> getOrCreateChatRoom({
    required String clientId,
    required String clientName,
    required String barberId,
    required String barberName,
  }) async {
    final chatId = ChatRoom.generateChatId(clientId, barberId);

    try {
      final doc = await _firestore.collection('chat_rooms').doc(chatId).get();

      if (doc.exists) {
        return ChatRoom.fromMap(doc.data()!);
      } else {
        // Create new chat room
        final newChatRoom = ChatRoom(
          id: chatId,
          clientId: clientId,
          clientName: clientName,
          barberId: barberId,
          barberName: barberName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('chat_rooms')
            .doc(chatId)
            .set(newChatRoom.toMap());

        return newChatRoom;
      }
    } catch (e) {
      throw Exception('Failed to get or create chat room: $e');
    }
  }

  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    try {
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      
      final chatMessage = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: message,
        timestamp: DateTime.now(),
      );

      // Add message to messages subcollection
      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update chat room last message and timestamp
      await _updateChatRoomLastMessage(chatId, chatMessage);

      // Send push notification to the other user
      await _sendMessageNotification(chatId, chatMessage);

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream for a chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return ChatMessage.fromMap(data);
            })
            .toList());
  }

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRoomsForUser(String userId, String userType) {
    final field = userType == 'client' ? 'clientId' : 'barberId';
    
    return _firestore
        .collection('chat_rooms')
        .where(field, isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return ChatRoom.fromMap(data);
            })
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String readerId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: readerId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': now.millisecondsSinceEpoch,
        });
      }

      await batch.commit();

      // Update unread count in chat room
      await _updateUnreadCount(chatId, 0);

    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required XFile imageFile,
  }) async {
    try {
      // In a real app, you would upload the image to Firebase Storage
      // For now, we'll simulate the process
      final imageUrl = await _uploadImage(imageFile);
      
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      
      final chatMessage = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: 'Sent an image',
        type: MessageType.image,
        timestamp: DateTime.now(),
        attachmentUrl: imageUrl,
        attachmentType: 'image',
      );

      // Add message to messages subcollection
      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update chat room last message and timestamp
      await _updateChatRoomLastMessage(chatId, chatMessage);

      // Send push notification
      await _sendMessageNotification(chatId, chatMessage);

    } catch (e) {
      throw Exception('Failed to send image message: $e');
    }
  }

  // Update chat room last message
  Future<void> _updateChatRoomLastMessage(String chatId, ChatMessage message) async {
    await _firestore.collection('chat_rooms').doc(chatId).update({
      'lastMessage': message.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Update unread count in chat room
  Future<void> _updateUnreadCount(String chatId, int count) async {
    await _firestore.collection('chat_rooms').doc(chatId).update({
      'unreadCount': count,
    });
  }

  // Send push notification for new message
  Future<void> _sendMessageNotification(String chatId, ChatMessage message) async {
    // Get the other user's ID from chat room
    final chatDoc = await _firestore.collection('chat_rooms').doc(chatId).get();
    final chatRoom = ChatRoom.fromMap(chatDoc.data()!);
    
    final receiverId = message.senderId == chatRoom.clientId 
        ? chatRoom.barberId 
        : chatRoom.clientId;

    // Send notification (you would integrate with your notification service)
    print('Sending notification to $receiverId: New message from ${message.senderName}');
  }

  // Simulate image upload
  Future<String> _uploadImage(XFile imageFile) async {
    // In a real app, upload to Firebase Storage and return download URL
    await Future.delayed(const Duration(seconds: 2)); // Simulate upload time
    return 'https://example.com/uploaded-image.jpg';
  }

  // Delete chat room (soft delete)
  Future<void> deleteChatRoom(String chatId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to delete chat room: $e');
    }
  }

  // Get unread messages count for a user
  Stream<int> getUnreadMessagesCount(String userId, String userType) {
    final field = userType == 'client' ? 'clientId' : 'barberId';
    
    return _firestore
        .collection('chat_rooms')
        .where(field, isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0, (sum, doc) {
          final chatRoom = ChatRoom.fromMap(doc.data());
          return sum + chatRoom.unreadCount;
        }));
  }
}