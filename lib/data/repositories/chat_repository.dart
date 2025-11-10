import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use a map to track active listeners and prevent duplicates
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  final Map<String, StreamController<List<ChatMessage>>> _messageControllers =
      {};
  final Map<String, StreamController<List<ChatRoom>>> _chatRoomControllers = {};
  final List<Map<String, dynamic>> _offlineMessageQueue = [];
  // Create or get chat room efficiently
  Future<ChatRoom> getOrCreateChatRoom({
    required String clientId,
    required String clientName,
    required String barberId,
    required String barberName,
  }) async {
    final chatId = ChatRoom.generateChatId(clientId, barberId);

    try {
      final docRef = _firestore.collection('chat_rooms').doc(chatId);
      final doc = await docRef.get();

      if (doc.exists) {
        return ChatRoom.fromMap(doc.data()!);
      } else {
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

        await docRef.set(newChatRoom.toMap());
        return newChatRoom;
      }
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> setTypingStatus(
      String chatId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatId).update({
        'typingUsers.$userId': isTyping,
        'lastActivity': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  // Get typing status stream
  Stream<Map<String, bool>> getTypingStatusStream(String chatId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      final typingUsers = data?['typingUsers'] as Map<String, dynamic>? ?? {};
      return typingUsers.map((key, value) => MapEntry(key, value == true));
    });
  }

  // Send message with batch operation
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      final messageId = '${DateTime.now().millisecondsSinceEpoch}_$senderId';
      final chatMessage = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: message.trim(),
        timestamp: DateTime.now(),
        isRead: false,
        data: {'status': 'sent'},
      );

      final batch = _firestore.batch();

      // Add message to messages subcollection
      final messageRef = _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      batch.set(messageRef, chatMessage.toMap());

      // Update chat room with last message and delivery status
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatId);
      batch.update(chatRoomRef, {
        'lastMessage': chatMessage.toMap(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'unreadCount': FieldValue.increment(1),
        'lastActivity': DateTime.now().millisecondsSinceEpoch,
      });

      await batch.commit();

      // Update message status to delivered
      await messageRef.update({
        'data.status': 'delivered',
      });

      // Send push notification
      await _sendPushNotification(chatId, chatMessage);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream with proper cleanup
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    // Close existing subscription for this chat
    _activeSubscriptions[chatId]?.cancel();

    final controller = StreamController<List<ChatMessage>>.broadcast();
    _messageControllers[chatId] = controller;

    final subscription = _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      try {
        final messages = snapshot.docs.map((doc) {
          return ChatMessage.fromMap(doc.data());
        }).toList();
        controller.add(messages);
      } catch (e) {
        controller.addError(e);
      }
    }, onError: controller.addError);

    _activeSubscriptions[chatId] = subscription;

    return controller.stream;
  }

  // Get chat rooms for user with optimized query
  Stream<List<ChatRoom>> getChatRoomsForUser(String userId, String userType) {
    final field = userType == 'client' ? 'clientId' : 'barberId';
    final controllerId = '${userId}_$userType';

    // Close existing subscription
    _activeSubscriptions[controllerId]?.cancel();

    final controller = StreamController<List<ChatRoom>>.broadcast();
    _chatRoomControllers[controllerId] = controller;

    final subscription = _firestore
        .collection('chat_rooms')
        .where(field, isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      try {
        final chatRooms = snapshot.docs.map((doc) {
          return ChatRoom.fromMap(doc.data());
        }).toList();
        controller.add(chatRooms);
      } catch (e) {
        controller.addError(e);
      }
    }, onError: controller.addError);

    _activeSubscriptions[controllerId] = subscription;

    return controller.stream;
  }

  // Mark messages as read efficiently
  Future<void> markMessagesAsRead(String chatId, String readerId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: readerId)
          .where('isRead', isEqualTo: false)
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        final now = DateTime.now();

        for (final doc in messagesSnapshot.docs) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': now.millisecondsSinceEpoch,
          });
        }

        await batch.commit();

        // Update chat room unread count
        await _firestore.collection('chat_rooms').doc(chatId).update({
          'unreadCount': FieldValue.increment(-messagesSnapshot.docs.length),
        });
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadMessagesCount(String userId, String userType) {
    final field = userType == 'client' ? 'clientId' : 'barberId';

    return _firestore
        .collection('chat_rooms')
        .where(field, isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold(0, (sum, doc) {
        final chatRoom = ChatRoom.fromMap(doc.data());
        return sum + chatRoom.unreadCount;
      });
    });
  }

  // Send push notification
  Future<void> _sendPushNotification(String chatId, ChatMessage message) async {
    try {
      final chatDoc =
          await _firestore.collection('chat_rooms').doc(chatId).get();
      if (chatDoc.exists) {
        final chatRoom = ChatRoom.fromMap(chatDoc.data()!);
        final receiverName = message.senderId == chatRoom.clientId
            ? chatRoom.barberName
            : chatRoom.clientName;

        // Send via NotificationRepository for better handling
        // This integrates with your existing notification system
        print('FCM: New message from ${message.senderName} to $receiverName');

        // You can integrate with your NotificationProvider here
        // await NotificationProvider().sendChatNotification(...);
      }
    } catch (e) {
      print('FCM Notification error: $e');
    }
  }

  // Clean up resources
  void disposeChat(String chatId) {
    _activeSubscriptions[chatId]?.cancel();
    _activeSubscriptions.remove(chatId);
    _messageControllers[chatId]?.close();
    _messageControllers.remove(chatId);
  }

  void disposeUserChats(String userId, String userType) {
    final controllerId = '${userId}_$userType';
    _activeSubscriptions[controllerId]?.cancel();
    _activeSubscriptions.remove(controllerId);
    _chatRoomControllers[controllerId]?.close();
    _chatRoomControllers.remove(controllerId);
  }

  void dispose() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();

    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();

    for (final controller in _chatRoomControllers.values) {
      controller.close();
    }
    _chatRoomControllers.clear();
  }

  Future<void> queueOfflineMessage(Map<String, dynamic> messageData) async {
    _offlineMessageQueue.add(messageData);
    // Store in local storage (Hive/SQLite) for persistence
    await _saveOfflineQueue();
  }

  Future<void> syncOfflineMessages() async {
    for (final messageData in _offlineMessageQueue) {
      try {
        await sendMessage(
          chatId: messageData['chatId'],
          senderId: messageData['senderId'],
          senderName: messageData['senderName'],
          senderType: messageData['senderType'],
          message: messageData['message'],
        );
      } catch (e) {
        print('Failed to sync offline message: $e');
      }
    }
    _offlineMessageQueue.clear();
    await _clearOfflineQueue();
  }

  Future<void> _saveOfflineQueue() async {
    // Implement local storage saving
  }

  Future<void> _clearOfflineQueue() async {
    // Implement local storage clearing
  }
}
