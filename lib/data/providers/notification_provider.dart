import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository = NotificationRepository();
  
  List<AppNotification> _notifications = [];
  bool _hasUnread = false;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get hasUnread => _hasUnread;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load notifications for user with real-time updates
  void loadNotifications(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notificationRepository.getUserNotifications(userId).listen(
        (notifications) {
          _notifications = notifications;
          _hasUnread = _notifications.any((notification) => !notification.isRead);
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _error = 'Failed to load notifications: $error';
          notifyListeners();
          print('❌ Error loading notifications: $error');
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load notifications: $e';
      notifyListeners();
      print('❌ Error loading notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _hasUnread = _notifications.any((notification) => !notification.isRead);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark notification as read: $e';
      notifyListeners();
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationRepository.markAllAsRead(userId);
      
      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      _hasUnread = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark all notifications as read: $e';
      notifyListeners();
      print('❌ Error marking all notifications as read: $e');
    }
  }

  // Get unread count stream
  Stream<int> getUnreadCount(String userId) {
    return _notificationRepository.getUnreadCountStream(userId);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      await _notificationRepository.clearAllNotifications(userId);
      _notifications.clear();
      _hasUnread = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear notifications: $e';
      notifyListeners();
      print('❌ Error clearing notifications: $e');
    }
  }

  // Delete single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      
      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _hasUnread = _notifications.any((notification) => !notification.isRead);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete notification: $e';
      notifyListeners();
      print('❌ Error deleting notification: $e');
    }
  }

  // Send appointment notification
  Future<void> sendAppointmentNotification({
    required String userId,
    required String appointmentId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
    bool sendPush = true,
  }) async {
    try {
      await _notificationRepository.sendAppointmentNotification(
        userId: userId,
        appointmentId: appointmentId,
        title: title,
        message: message,
        type: type,
        data: data,
        sendPush: sendPush,
      );
    } catch (e) {
      _error = 'Failed to send notification: $e';
      notifyListeners();
      print('❌ Error sending appointment notification: $e');
    }
  }

  // Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required String paymentId,
    required String title,
    required String message,
    required String status,
    required double amount,
    required String paymentMethod,
    bool sendPush = true,
  }) async {
    try {
      await _notificationRepository.sendPaymentNotification(
        userId: userId,
        paymentId: paymentId,
        title: title,
        message: message,
        status: status,
        amount: amount,
        paymentMethod: paymentMethod,
        sendPush: sendPush,
      );
    } catch (e) {
      _error = 'Failed to send payment notification: $e';
      notifyListeners();
      print('❌ Error sending payment notification: $e');
    }
  }

  // Send chat notification
  Future<void> sendChatNotification({
    required String userId,
    required String chatId,
    required String senderName,
    required String message,
    required String chatType,
    bool sendPush = true,
  }) async {
    try {
      await _notificationRepository.sendChatNotification(
        userId: userId,
        chatId: chatId,
        senderName: senderName,
        message: message,
        chatType: chatType,
        sendPush: sendPush,
      );
    } catch (e) {
      _error = 'Failed to send chat notification: $e';
      notifyListeners();
      print('❌ Error sending chat notification: $e');
    }
  }

  // Send appointment reminder
  Future<void> sendAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String clientName,
    required String barberName,
    required DateTime appointmentTime,
    required String serviceName,
    required String userType,
    bool sendPush = true,
  }) async {
    try {
      await _notificationRepository.sendAppointmentReminder(
        userId: userId,
        appointmentId: appointmentId,
        clientName: clientName,
        barberName: barberName,
        appointmentTime: appointmentTime,
        serviceName: serviceName,
        userType: userType,
        sendPush: sendPush,
      );
    } catch (e) {
      _error = 'Failed to send reminder: $e';
      notifyListeners();
      print('❌ Error sending appointment reminder: $e');
    }
  }

  // Send appointment request
  Future<void> sendAppointmentRequest({
    required String barberId,
    required String appointmentId,
    required String clientName,
    required String serviceName,
    required DateTime appointmentTime,
    bool sendPush = true,
  }) async {
    try {
      await _notificationRepository.sendAppointmentRequest(
        barberId: barberId,
        appointmentId: appointmentId,
        clientName: clientName,
        serviceName: serviceName,
        appointmentTime: appointmentTime,
        sendPush: sendPush,
      );
    } catch (e) {
      _error = 'Failed to send appointment request: $e';
      notifyListeners();
      print('❌ Error sending appointment request: $e');
    }
  }

  // Send appointment status update
  Future<void> sendAppointmentStatusUpdate({
    required String userId,
    required String appointmentId,
    required String status,
    required String barberName,
    required String serviceName,
    required DateTime appointmentTime,
    required String userType,
    String? reason,
    bool sendPush = true,
  }) async {
    try {
      await _notificationRepository.sendAppointmentStatusUpdate(
        userId: userId,
        appointmentId: appointmentId,
        status: status,
        barberName: barberName,
        serviceName: serviceName,
        appointmentTime: appointmentTime,
        userType: userType,
        reason: reason,
        sendPush: sendPush,
      );
    } catch (e) {
      _error = 'Failed to send status update: $e';
      notifyListeners();
      print('❌ Error sending appointment status update: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh notifications
  void refreshNotifications(String userId) {
    _notifications.clear();
    _hasUnread = false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    loadNotifications(userId);
  }

  // Get notification by ID
  AppNotification? getNotificationById(String notificationId) {
    try {
      return _notifications.firstWhere(
        (notification) => notification.id == notificationId,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if notification exists
  bool hasNotification(String notificationId) {
    return _notifications.any((notification) => notification.id == notificationId);
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  // Get unread notifications
  List<AppNotification> get unreadNotifications {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  // Get read notifications
  List<AppNotification> get readNotifications {
    return _notifications.where((notification) => notification.isRead).toList();
  }

  // Get latest notifications (last 10)
  List<AppNotification> get latestNotifications {
    return _notifications.take(10).toList();
  }

  // Get today's notifications
  List<AppNotification> get todaysNotifications {
    final today = DateTime.now();
    return _notifications.where((notification) {
      return notification.createdAt.year == today.year &&
             notification.createdAt.month == today.month &&
             notification.createdAt.day == today.day;
    }).toList();
  }
}