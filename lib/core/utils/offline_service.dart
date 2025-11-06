import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/models/service_model.dart';


class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const String _appointmentsBox = 'appointments';
  static const String _paymentsBox = 'payments';
  static const String _servicesBox = 'services';
  static const String _syncQueueBox = 'sync_queue';
  static const String _chatRoomsBox = 'chat_rooms';
  static const String _chatMessagesBox = 'chat_messages';
  static const String _offlineMessagesBox = 'offline_messages';

  late Box<AppointmentModel> _appointments;
  late Box<PaymentModel> _payments;
  late Box<ServiceModel> _services;
  late Box<Map<dynamic, dynamic>> _syncQueue;
  late Box<ChatRoom> _chatRooms;
  late Box<ChatMessage> _chatMessages;
  late Box<ChatMessage> _offlineMessages;

  bool _isInitialized = false;

  // Initialize Hive with proper error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      // Register adapters safely
      _registerAdapters();
      
      // Open boxes with error handling
      await _openBoxes();
      
      _isInitialized = true;
      print('FixedOfflineService initialized successfully');
    } catch (e) {
      print('Error initializing FixedOfflineService: $e');
      rethrow;
    }
  }

  void _registerAdapters() {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(AppointmentModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PaymentModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ServiceModelAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatRoomAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ChatMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(MessageTypeAdapter());
      }
    } catch (e) {
      print('Error registering adapters: $e');
    }
  }

  Future<void> _openBoxes() async {
    try {
      _appointments = await Hive.openBox<AppointmentModel>(_appointmentsBox);
      _payments = await Hive.openBox<PaymentModel>(_paymentsBox);
      _services = await Hive.openBox<ServiceModel>(_servicesBox);
      _syncQueue = await Hive.openBox<Map<dynamic, dynamic>>(_syncQueueBox);
      _chatRooms = await Hive.openBox<ChatRoom>(_chatRoomsBox);
      _chatMessages = await Hive.openBox<ChatMessage>(_chatMessagesBox);
      _offlineMessages = await Hive.openBox<ChatMessage>(_offlineMessagesBox);
    } catch (e) {
      print('Error opening boxes: $e');
      rethrow;
    }
  }

  // CHAT METHODS - FIXED

  Future<void> saveChatRoomLocally(ChatRoom chatRoom) async {
    try {
      await _chatRooms.put(chatRoom.id, chatRoom);
    } catch (e) {
      print('Error saving chat room locally: $e');
      throw Exception('Failed to save chat room: $e');
    }
  }

  Future<List<ChatRoom>> getLocalChatRooms(String userId, String userType) async {
    try {
      final allChatRooms = _chatRooms.values.toList();
      
      return allChatRooms.where((chatRoom) {
        final fieldValue = userType == 'client' ? chatRoom.clientId : chatRoom.barberId;
        return fieldValue == userId && chatRoom.isActive;
      }).toList();
    } catch (e) {
      print('Error getting local chat rooms: $e');
      return [];
    }
  }

  Future<void> addOfflineMessage(ChatMessage message) async {
    try {
      await _offlineMessages.put(message.id, message);
    } catch (e) {
      print('Error saving offline message: $e');
      throw Exception('Failed to save offline message: $e');
    }
  }

  Future<List<ChatMessage>> getPendingOfflineMessages() async {
    try {
      return _offlineMessages.values.toList();
    } catch (e) {
      print('Error getting offline messages: $e');
      return [];
    }
  }

  Future<void> removeOfflineMessage(String messageId) async {
    try {
      await _offlineMessages.delete(messageId);
    } catch (e) {
      print('Error removing offline message: $e');
    }
  }

  Future<List<ChatMessage>> getLocalMessages(String chatId) async {
    try {
      final allMessages = _chatMessages.values.toList();
      return allMessages.where((message) => message.chatId == chatId).toList();
    } catch (e) {
      print('Error getting local messages: $e');
      return [];
    }
  }

  Future<void> updateChatRoomLastMessage(String chatId, ChatMessage message) async {
    try {
      final chatRoom = _chatRooms.get(chatId);
      if (chatRoom != null) {
        final updatedChatRoom = chatRoom.copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
          unreadCount: chatRoom.unreadCount + 1,
        );
        await _chatRooms.put(chatId, updatedChatRoom);
      }
    } catch (e) {
      print('Error updating chat room last message: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String readerId) async {
    try {
      final messages = _chatMessages.values.where((message) => 
        message.chatId == chatId && 
        message.senderId != readerId && 
        !message.isRead
      ).toList();

      final now = DateTime.now();
      for (final message in messages) {
        final updatedMessage = message.copyWith(
          isRead: true,
          readAt: now,
        );
        await _chatMessages.put(message.id, updatedMessage);
      }

      // Update chat room unread count
      final chatRoom = _chatRooms.get(chatId);
      if (chatRoom != null) {
        final updatedChatRoom = chatRoom.copyWith(unreadCount: 0);
        await _chatRooms.put(chatId, updatedChatRoom);
      }
    } catch (e) {
      print('Error marking messages as read locally: $e');
    }
  }

  Future<int> getLocalUnreadCount(String userId, String userType) async {
    try {
      final chatRooms = await getLocalChatRooms(userId, userType);
      int totalUnread = 0;
      for (final chatRoom in chatRooms) {
        totalUnread += chatRoom.unreadCount;
      }
      return totalUnread;
    } catch (e) {
      print('Error getting local unread count: $e');
      return 0;
    }
  }

  // Connectivity check
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Cleanup
  Future<void> dispose() async {
    try {
      await _appointments.close();
      await _payments.close();
      await _services.close();
      await _syncQueue.close();
      await _chatRooms.close();
      await _chatMessages.close();
      await _offlineMessages.close();
      print('FixedOfflineService disposed successfully');
    } catch (e) {
      print('Error disposing FixedOfflineService: $e');
    }
  }
}