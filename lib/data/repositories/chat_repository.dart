import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineService _offlineService = OfflineService.instance; // Use singleton instance
  final Map<String, StreamController<Set<String>>> _typingControllers = {};

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
          unreadCount: 0,
          isActive: true,
        );

        await _firestore
            .collection('chat_rooms')
            .doc(chatId)
            .set(newChatRoom.toMap());

        return newChatRoom;
      }
    } catch (e) {
      // If online fails, create local chat room for offline use
      final offlineChatRoom = ChatRoom(
        id: chatId,
        clientId: clientId,
        clientName: clientName,
        barberId: barberId,
        barberName: barberName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        unreadCount: 0,
        isActive: true,
      );
      
      await _offlineService.saveChatRoomLocally(offlineChatRoom);
      return offlineChatRoom;
    }
  }

  // ... rest of your existing ChatRepository methods remain exactly the same ...
  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    try {
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_$senderId';
      
      final chatMessage = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Check if online
      final isOnline = await _offlineService.isConnected();
      
      if (isOnline) {
        // Add message to Firestore
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
      } else {
        // Save message locally for offline sync
        await _offlineService.addOfflineMessage(chatMessage);
        
        // Update local chat room
        await _offlineService.updateChatRoomLastMessage(chatId, chatMessage);
      }

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
              final data = doc.data();
              return ChatMessage.fromMap(data);
            })
            .toList())
        .handleError((error) {
          // If online fails, try to get local messages
          return _offlineService.getLocalMessages(chatId);
        });
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
              final data = doc.data();
              return ChatRoom.fromMap(data);
            })
            .toList())
        .handleError((error) {
          // If online fails, return local chat rooms
          return _offlineService.getLocalChatRooms(userId, userType);
        });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String readerId) async {
    try {
      final isOnline = await _offlineService.isConnected();
      
      if (isOnline) {
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
      } else {
        // Mark messages as read locally
        await _offlineService.markMessagesAsRead(chatId, readerId);
      }

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
      final isOnline = await _offlineService.isConnected();
      
      if (!isOnline) {
        throw Exception('Image sharing requires internet connection');
      }

      // In a real app, you would upload the image to Firebase Storage
      final imageUrl = await _uploadImage(imageFile);
      
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_$senderId';
      
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
        isRead: false,
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

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final isOnline = await _offlineService.isConnected();
      
      if (isOnline) {
        await _firestore
            .collection('chat_rooms')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } else {
        await _offlineService.deleteMessage(chatId, messageId);
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(String chatId, String userId, bool isTyping) async {
    try {
      if (!_typingControllers.containsKey(chatId)) {
        _typingControllers[chatId] = StreamController<Set<String>>.broadcast();
      }

      final typingDoc = _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('typing_indicators')
          .doc(userId);

      if (isTyping) {
        await typingDoc.set({
          'userId': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await typingDoc.delete();
      }
    } catch (e) {
      // Silently fail for typing indicators
      print('Failed to send typing indicator: $e');
    }
  }

  // Get typing indicators stream
  Stream<Set<String>> getTypingIndicatorsStream(String chatId) {
    if (!_typingControllers.containsKey(chatId)) {
      _typingControllers[chatId] = StreamController<Set<String>>.broadcast();
    }

    // Listen to Firestore for typing indicators
    _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('typing_indicators')
        .snapshots()
        .listen((snapshot) {
          final typingUsers = snapshot.docs.map((doc) => doc.id).toSet();
          _typingControllers[chatId]!.add(typingUsers);
        });

    return _typingControllers[chatId]!.stream;
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
    try {
      // Get the other user's ID from chat room
      final chatDoc = await _firestore.collection('chat_rooms').doc(chatId).get();
      final chatRoom = ChatRoom.fromMap(chatDoc.data()!);
      
      final receiverId = message.senderId == chatRoom.clientId 
          ? chatRoom.barberId 
          : chatRoom.clientId;

      // In a real app, integrate with FCM here
      print('Sending notification to $receiverId: New message from ${message.senderName}');
    } catch (e) {
      // Silently fail for notifications
      print('Failed to send notification: $e');
    }
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
      final isOnline = await _offlineService.isConnected();
      
      if (isOnline) {
        await _firestore.collection('chat_rooms').doc(chatId).update({
          'isActive': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await _offlineService.deleteChatRoom(chatId);
      }
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
        }))
        .handleError((error) {
          // If online fails, return local unread count
          return _offlineService.getLocalUnreadCount(userId, userType);
        });
  }

  // Sync offline messages when coming online
  Future<void> syncOfflineMessages() async {
    try {
      final offlineMessages = await _offlineService.getPendingOfflineMessages();
      
      for (final message in offlineMessages) {
        await sendTextMessage(
          chatId: message.chatId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderType: message.senderType,
          message: message.message,
        );
        
        // Remove from offline storage after successful sync
        await _offlineService.removeOfflineMessage(message.id);
      }
    } catch (e) {
      throw Exception('Failed to sync offline messages: $e');
    }
  }

  // Dispose typing controllers
  void dispose() {
    for (final controller in _typingControllers.values) {
      controller.close();
    }
    _typingControllers.clear();
  }
}