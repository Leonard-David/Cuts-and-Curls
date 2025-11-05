import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/repositories/payment_repository.dart';
import 'package:sheersync/data/repositories/service_repository.dart';
import 'package:sheersync/data/repositories/chat_repository.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static OfflineService get instance => _instance;

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

  final BookingRepository _bookingRepository = BookingRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final ChatRepository _chatRepository = ChatRepository();

  bool _isInitialized = false;

  // Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

     try {
      await Hive.initFlutter();
      
      // Register adapters only if not already registered
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
      
      // Open boxes with error handling
      _appointments = await Hive.openBox<AppointmentModel>(_appointmentsBox);
      _payments = await Hive.openBox<PaymentModel>(_paymentsBox);
      _services = await Hive.openBox<ServiceModel>(_servicesBox);
      _syncQueue = await Hive.openBox<Map<dynamic, dynamic>>(_syncQueueBox);
      _chatRooms = await Hive.openBox<ChatRoom>(_chatRoomsBox);
      _chatMessages = await Hive.openBox<ChatMessage>(_chatMessagesBox);
      _offlineMessages = await Hive.openBox<ChatMessage>(_offlineMessagesBox);
      
      _isInitialized = true;
      print('Offline service initialized successfully');
    } catch (e) {
      print('Error initializing offline service: $e');
      rethrow;
    }
  }

  // Check connectivity
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // CHAT METHODS

  // Save chat room locally
  Future<void> saveChatRoomLocally(ChatRoom chatRoom) async {
    try {
      await _chatRooms.put(chatRoom.id, chatRoom);
    } catch (e) {
      print('Error saving chat room locally: $e');
      throw Exception('Failed to save chat room locally: $e');
    }
  }

  // Get local chat rooms for user
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

  // Add offline message
  Future<void> addOfflineMessage(ChatMessage message) async {
    try {
      await _offlineMessages.put(message.id, message);
    } catch (e) {
      print('Error saving offline message: $e');
      throw Exception('Failed to save offline message: $e');
    }
  }

  // Get pending offline messages
  Future<List<ChatMessage>> getPendingOfflineMessages() async {
    try {
      return _offlineMessages.values.toList();
    } catch (e) {
      print('Error getting offline messages: $e');
      return [];
    }
  }

  // Remove offline message after sync
  Future<void> removeOfflineMessage(String messageId) async {
    try {
      await _offlineMessages.delete(messageId);
    } catch (e) {
      print('Error removing offline message: $e');
    }
  }

  // Get local messages for chat
  Future<List<ChatMessage>> getLocalMessages(String chatId) async {
    try {
      final allMessages = _chatMessages.values.toList();
      return allMessages.where((message) => message.chatId == chatId).toList();
    } catch (e) {
      print('Error getting local messages: $e');
      return [];
    }
  }

  // Update chat room last message locally
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

  // Mark messages as read locally
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

  // Delete message locally
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _chatMessages.delete(messageId);
    } catch (e) {
      print('Error deleting message locally: $e');
    }
  }

  // Delete chat room locally
  Future<void> deleteChatRoom(String chatId) async {
    try {
      final chatRoom = _chatRooms.get(chatId);
      if (chatRoom != null) {
        final updatedChatRoom = chatRoom.copyWith(isActive: false);
        await _chatRooms.put(chatId, updatedChatRoom);
      }
    } catch (e) {
      print('Error deleting chat room locally: $e');
    }
  }

  // Get local unread count - FIXED VERSION
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

  // APPOINTMENT METHODS (existing functionality)

  Future<void> saveAppointmentLocally(AppointmentModel appointment) async {
    try {
      await _appointments.put(appointment.id, appointment);
      
      if (!(await isConnected())) {
        await addToSyncQueue('appointments', 'create', appointment.toMap());
      }
    } catch (e) {
      print('Error saving appointment locally: $e');
      throw Exception('Failed to save appointment locally: $e');
    }
  }

  List<AppointmentModel> getLocalAppointments() {
    return _appointments.values.toList();
  }

  AppointmentModel? getAppointmentById(String id) {
    return _appointments.get(id);
  }

  Future<void> savePaymentLocally(PaymentModel payment) async {
    try {
      await _payments.put(payment.id, payment);
      
      if (!(await isConnected())) {
        await addToSyncQueue('payments', 'create', payment.toMap());
      }
    } catch (e) {
      print('Error saving payment locally: $e');
      throw Exception('Failed to save payment locally: $e');
    }
  }

  List<PaymentModel> getLocalPayments() {
    return _payments.values.toList();
  }

  Future<void> saveServicesLocally(List<ServiceModel> services) async {
    try {
      await _services.clear();
      for (final service in services) {
        await _services.put(service.id, service);
      }
    } catch (e) {
      print('Error saving services locally: $e');
      throw Exception('Failed to save services locally: $e');
    }
  }

  List<ServiceModel> getLocalServices() {
    return _services.values.toList();
  }

  ServiceModel? getServiceById(String id) {
    return _services.get(id);
  }

  Future<void> addToSyncQueue(String collection, String operation, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': 'sync_${DateTime.now().millisecondsSinceEpoch}',
        'collection': collection,
        'operation': operation,
        'data': data,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
      };
      
      await _syncQueue.put(syncItem['id'], syncItem);
    } catch (e) {
      print('Error adding to sync queue: $e');
      throw Exception('Failed to add to sync queue: $e');
    }
  }

  // Sync all pending operations when online
  Future<void> syncPendingOperations() async {
    if (!(await isConnected())) {
      print('No internet connection, skipping sync');
      return;
    }

    // Sync appointments and payments
    final syncItems = _syncQueue.values.toList();
    
    if (syncItems.isNotEmpty) {
      print('Syncing ${syncItems.length} pending operations...');

      for (final syncItem in syncItems) {
        try {
          await _processSyncItem(syncItem);
          await _syncQueue.delete(syncItem['id']);
          print('Successfully synced operation: ${syncItem['id']}');
        } catch (e) {
          print('Error syncing operation ${syncItem['id']}: $e');
          
          final attempts = (syncItem['attempts'] ?? 0) + 1;
          syncItem['attempts'] = attempts;
          syncItem['lastError'] = e.toString();
          syncItem['lastAttempt'] = DateTime.now().millisecondsSinceEpoch;
          
          await _syncQueue.put(syncItem['id'], syncItem);
          
          if (attempts >= 3) {
            await _syncQueue.delete(syncItem['id']);
            print('Removed operation ${syncItem['id']} after 3 failed attempts');
          }
        }
      }
    }

    // Sync offline chat messages
    await _chatRepository.syncOfflineMessages();
  }

  Future<void> _processSyncItem(Map<dynamic, dynamic> syncItem) async {
    final String collection = syncItem['collection'];
    final String operation = syncItem['operation'];
    final Map<String, dynamic> data = Map<String, dynamic>.from(syncItem['data']);

    switch (collection) {
      case 'appointments':
        if (operation == 'create') {
          final appointment = AppointmentModel.fromMap(data);
          await _bookingRepository.createAppointment(appointment);
        }
        break;
      case 'payments':
        if (operation == 'create') {
          final payment = PaymentModel.fromMap(data);
          await _paymentRepository.createPayment(payment);
        }
        break;
      case 'services':
        if (operation == 'create') {
          final service = ServiceModel.fromMap(data);
          await _serviceRepository.createService(service);
        }
        break;
      default:
        throw Exception('Unknown collection type: $collection');
    }
  }

  // Update local appointment
  Future<void> updateAppointmentLocally(AppointmentModel appointment) async {
    try {
      await _appointments.put(appointment.id, appointment);
    } catch (e) {
      print('Error updating appointment locally: $e');
      throw Exception('Failed to update appointment locally: $e');
    }
  }

  // Update local payment
  Future<void> updatePaymentLocally(PaymentModel payment) async {
    try {
      await _payments.put(payment.id, payment);
    } catch (e) {
      print('Error updating payment locally: $e');
      throw Exception('Failed to update payment locally: $e');
    }
  }

  // Delete appointment locally
  Future<void> deleteAppointmentLocally(String appointmentId) async {
    try {
      await _appointments.delete(appointmentId);
    } catch (e) {
      print('Error deleting appointment locally: $e');
      throw Exception('Failed to delete appointment locally: $e');
    }
  }

  // Delete payment locally
  Future<void> deletePaymentLocally(String paymentId) async {
    try {
      await _payments.delete(paymentId);
    } catch (e) {
      print('Error deleting payment locally: $e');
      throw Exception('Failed to delete payment locally: $e');
    }
  }

  // Clear all local data (for logout)
  Future<void> clearAllLocalData() async {
    try {
      await _appointments.clear();
      await _payments.clear();
      await _services.clear();
      await _syncQueue.clear();
      await _chatRooms.clear();
      await _chatMessages.clear();
      await _offlineMessages.clear();
      print('All local data cleared successfully');
    } catch (e) {
      print('Error clearing local data: $e');
      throw Exception('Failed to clear local data: $e');
    }
  }

  // Get sync queue size
  int getPendingSyncCount() {
    return _syncQueue.length;
  }

  // Check if there are pending sync operations
  bool hasPendingSync() {
    return _syncQueue.isNotEmpty || _offlineMessages.isNotEmpty;
  }

  // Get sync queue items (for debugging)
  List<Map<dynamic, dynamic>> getSyncQueueItems() {
    return _syncQueue.values.toList();
  }

  // Initialize sync timer (call this when app starts)
  void startSyncTimer() {
    // Check for pending sync operations every 30 seconds when online
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (await isConnected() && hasPendingSync()) {
        await syncPendingOperations();
      }
    });
  }

  // Dispose Hive boxes
  Future<void> dispose() async {
    try {
      await _appointments.close();
      await _payments.close();
      await _services.close();
      await _syncQueue.close();
      await _chatRooms.close();
      await _chatMessages.close();
      await _offlineMessages.close();
      print('Offline service disposed successfully');
    } catch (e) {
      print('Error disposing offline service: $e');
    }
  }
}