import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart'
    hide AppointmentModelAdapter;
import 'package:sheersync/data/models/appointment_model.dart'
    hide PaymentModelAdapter, ServiceModelAdapter;
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/models/notification_model.dart';
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
  static const String _availabilityBox = 'barber_availability';
  static const String _marketingOffersBox = 'marketing_offers';
  static const String _discountsBox = 'discounts';

  late Box<Map<dynamic, dynamic>> _availability;
  late Box<Map<dynamic, dynamic>> _marketingOffers;
  late Box<Map<dynamic, dynamic>> _discounts;
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

      // boxes for availability and marketing
      _availability =
          await Hive.openBox<Map<dynamic, dynamic>>(_availabilityBox);
      _marketingOffers =
          await Hive.openBox<Map<dynamic, dynamic>>(_marketingOffersBox);
      _discounts = await Hive.openBox<Map<dynamic, dynamic>>(_discountsBox);
    } catch (e) {
      print('Error opening boxes: $e');
      rethrow;
    }
  }

  // CHAT METHODS

  Future<void> saveChatRoomLocally(ChatRoom chatRoom) async {
    try {
      await _chatRooms.put(chatRoom.id, chatRoom);
    } catch (e) {
      print('Error saving chat room locally: $e');
      throw Exception('Failed to save chat room: $e');
    }
  }

  Future<List<ChatRoom>> getLocalChatRooms(
      String userId, String userType) async {
    try {
      final allChatRooms = _chatRooms.values.toList();

      return allChatRooms.where((chatRoom) {
        final fieldValue =
            userType == 'client' ? chatRoom.clientId : chatRoom.barberId;
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

  Future<void> updateChatRoomLastMessage(
      String chatId, ChatMessage message) async {
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
      final messages = _chatMessages.values
          .where((message) =>
              message.chatId == chatId &&
              message.senderId != readerId &&
              !message.isRead)
          .toList();

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

  Future<void> addToSyncQueue(String action, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': 'sync_${DateTime.now().millisecondsSinceEpoch}',
        'action': action,
        'data': data,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
        'status': 'pending',
      };

      await _syncQueue.put(syncItem['id'], syncItem);
      print('Added to sync queue: $action');
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      final allItems = _syncQueue.values.toList();
      return allItems
          .where((item) => item['status'] == 'pending')
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error getting sync items: $e');
      return [];
    }
  }

  Future<void> updateSyncItemStatus(String id, String status,
      {int? attempts}) async {
    try {
      final item = _syncQueue.get(id);
      if (item != null) {
        item['status'] = status;
        if (attempts != null) item['attempts'] = attempts;
        await _syncQueue.put(id, item);
      }
    } catch (e) {
      print('Error updating sync item: $e');
    }
  }

  Future<void> removeFromSyncQueue(String id) async {
    try {
      await _syncQueue.delete(id);
    } catch (e) {
      print('Error removing from sync queue: $e');
    }
  }

  // Service-specific offline methods
  Future<void> saveServiceOffline(ServiceModel service) async {
    try {
      final box = await Hive.openBox<Map<String, dynamic>>('offline_services');
      await box.put(service.id, service.toHiveMap());
      print('Service saved offline: ${service.name}');
    } catch (e) {
      print('Error saving service offline: $e');
      throw Exception('Failed to save service offline: $e');
    }
  }

  Future<List<ServiceModel>> getOfflineServices(String barberId) async {
    try {
      final box = await Hive.openBox<Map<String, dynamic>>('offline_services');
      final allServices = box.values.toList();

      final barberServices = allServices
          .where((serviceMap) => serviceMap['barberId'] == barberId)
          .map((serviceMap) => ServiceModel.fromHiveMap(serviceMap))
          .toList();

      print(
          'Loaded ${barberServices.length} offline services for barber: $barberId');
      return barberServices;
    } catch (e) {
      print('Error loading offline services: $e');
      return [];
    }
  }

  // Appointment-specific offline methods
  Future<void> saveAppointmentOffline(AppointmentModel appointment) async {
    try {
      await _appointments.put(appointment.id, appointment);
      print('Appointment saved offline: ${appointment.id}');
    } catch (e) {
      print('Error saving appointment offline: $e');
      throw Exception('Failed to save appointment offline: $e');
    }
  }

  Future<List<AppointmentModel>> getOfflineAppointments(
      String userId, String userType) async {
    try {
      final allAppointments = _appointments.values.toList();
      if (userType == 'barber' || userType == 'hairstylist') {
        return allAppointments
            .where((appt) => appt.barberId == userId)
            .toList();
      } else {
        return allAppointments
            .where((appt) => appt.clientId == userId)
            .toList();
      }
    } catch (e) {
      print('Error getting offline appointments: $e');
      return [];
    }
  }

  Future<void> removeOfflineAppointment(String appointmentId) async {
    try {
      await _appointments.delete(appointmentId);
    } catch (e) {
      print('Error removing offline appointment: $e');
    }
  }

  Future<void> removeOfflineService(String serviceId) async {
    try {
      final box = await Hive.openBox<Map<String, dynamic>>('offline_services');
      await box.delete(serviceId);
      print('Removed offline service: $serviceId');
    } catch (e) {
      print('Error removing offline service: $e');
    }
  }

  //Availability methods

  // Availability schedule offline methods
  Future<void> saveAvailabilityOffline(
      Map<String, dynamic> availability) async {
    final box =
        await Hive.openBox<Map<String, dynamic>>('offline_availability');
    await box.put(availability['barberId'], availability);
  }

  Future<Map<String, dynamic>?> getOfflineAvailability(String barberId) async {
    final box =
        await Hive.openBox<Map<String, dynamic>>('offline_availability');
    return box.get(barberId);
  }

  Future<void> removeOfflineAvailability(String barberId) async {
    try {
      await _availability.delete(barberId);
    } catch (e) {
      print('Error removing offline availability: $e');
    }
  }

  Future<void> saveMarketingOfferOffline(Map<String, dynamic> offerData) async {
    try {
      final offerId =
          offerData['id'] ?? 'offer_${DateTime.now().millisecondsSinceEpoch}';
      await _marketingOffers.put(offerId, offerData);
      print('Marketing offer saved offline: $offerId');
    } catch (e) {
      print('Error saving marketing offer offline: $e');
      throw Exception('Failed to save marketing offer offline: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineMarketingOffers(
      String barberId) async {
    try {
      final allOffers = _marketingOffers.values.toList();
      return allOffers
          .where((offer) => offer['barberId'] == barberId)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error getting offline marketing offers: $e');
      return [];
    }
  }

  Future<void> removeOfflineMarketingOffer(String offerId) async {
    try {
      await _marketingOffers.delete(offerId);
    } catch (e) {
      print('Error removing offline marketing offer: $e');
    }
  }

  // ========== DISCOUNTS METHODS ==========

  Future<void> saveDiscountOffline(Map<String, dynamic> discountData) async {
    try {
      final discountId = discountData['id'] ??
          'discount_${DateTime.now().millisecondsSinceEpoch}';
      await _discounts.put(discountId, discountData);
      print('Discount saved offline: $discountId');
    } catch (e) {
      print('Error saving discount offline: $e');
      throw Exception('Failed to save discount offline: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineDiscounts(
      String barberId) async {
    try {
      final allDiscounts = _discounts.values.toList();
      return allDiscounts
          .where((discount) =>
              discount['barberId'] == barberId && discount['isActive'] == true)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error getting offline discounts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllDiscountsForClient(
      String barberId) async {
    try {
      // Combine online and offline discounts for client view
      final offlineDiscounts = await getOfflineDiscounts(barberId);

      // In a real implementation, you'd merge with online discounts
      return offlineDiscounts;
    } catch (e) {
      print('Error getting all discounts: $e');
      return [];
    }
  }

  Future<void> removeOfflineDiscount(String discountId) async {
    try {
      await _discounts.delete(discountId);
    } catch (e) {
      print('Error removing offline discount: $e');
    }
  }

  // Notification offline methods
  Future<void> saveNotificationOffline(AppNotification notification) async {
    final box = await Hive.openBox<AppNotification>('offline_notifications');
    await box.put(notification.id, notification);
  }

  Future<List<AppNotification>> getOfflineNotifications(String userId) async {
    final box = await Hive.openBox<AppNotification>('offline_notifications');
    final allNotifications = box.values.toList();

    return allNotifications
        .where((notification) => notification.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> removeOfflineNotification(String notificationId) async {
    final box = await Hive.openBox<AppNotification>('offline_notifications');
    await box.delete(notificationId);
  }

  Future<void> clearAllOfflineNotifications(String userId) async {
    final box = await Hive.openBox<AppNotification>('offline_notifications');
    final userNotifications = box.values
        .where((notification) => notification.userId == userId)
        .toList();

    for (final notification in userNotifications) {
      await box.delete(notification.id);
    }
  }

  Future<void> clearAllOfflineServices(String barberId) async {
    try {
      final box = await Hive.openBox<Map<String, dynamic>>('offline_services');
      final barberServices = box.values
          .where((serviceMap) => serviceMap['barberId'] == barberId)
          .toList();

      for (final service in barberServices) {
        await box.delete(service['id']);
      }
      print('Cleared all offline services for barber: $barberId');
    } catch (e) {
      print('Error clearing offline services: $e');
    }
  }

  // Marketing data offline methods
  Future<void> saveMarketingDataOffline(Map<String, dynamic> data) async {
    final box = await Hive.openBox<Map<String, dynamic>>('offline_marketing');
    await box.put(
        data['id'] ?? 'marketing_${DateTime.now().millisecondsSinceEpoch}',
        data);
  }

  Future<List<Map<String, dynamic>>> getOfflineMarketingData() async {
    final box = await Hive.openBox<Map<String, dynamic>>('offline_marketing');
    return box.values.toList();
  }
}
