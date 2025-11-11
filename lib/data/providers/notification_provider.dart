import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final OfflineService _offlineService = OfflineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppNotification> _notifications = [];
  bool _hasUnread = false;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get hasUnread => _hasUnread;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get todaysCount => _notifications
      .where((n) => n.category == NotificationCategory.today)
      .length;

  // Load notifications for user with real-time updates
  // Load notifications with offline support
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await _offlineService.isConnected()) {
        // Load from Firestore
        final snapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();

        _notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return AppNotification.fromMap(data);
        }).toList();

        // Sync any offline notifications
        await _syncOfflineNotifications(userId);
      } else {
        // Load from offline storage
        _notifications = await _offlineService.getOfflineNotifications(userId);
      }
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      // Fallback to offline data
      _notifications = await _offlineService.getOfflineNotifications(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Real-time notifications stream
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final onlineNotifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return AppNotification.fromMap(data);
        }).toList();

        // Merge with offline notifications
        final offlineNotifications =
            await _offlineService.getOfflineNotifications(userId);

        final allNotifications = [
          ...onlineNotifications,
          ...offlineNotifications
        ];

        // Remove duplicates and sort
        final uniqueNotifications = allNotifications
            .fold<Map<String, AppNotification>>({}, (map, notification) {
              if (!map.containsKey(notification.id) ||
                  notification.createdAt
                      .isAfter(map[notification.id]!.createdAt)) {
                map[notification.id] = notification;
              }
              return map;
            })
            .values
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _notifications = uniqueNotifications;
        notifyListeners();
        return uniqueNotifications;
      } else {
        // Fallback to offline only
        final offlineNotifications =
            await _offlineService.getOfflineNotifications(userId);
        _notifications = offlineNotifications;
        notifyListeners();
        return offlineNotifications;
      }
    });
  }

  // Create notification with offline support
  Future<void> createNotification(AppNotification notification) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toMap());

        _notifications.insert(0, notification);
      } else {
        // Save offline
        final offlineNotification = notification.copyWith(isSynced: false);
        await _offlineService.saveNotificationOffline(offlineNotification);
        _notifications.insert(0, offlineNotification);

        // Add to sync queue
        await _offlineService.addToSyncQueue('create_notification', {
          'type': 'notification',
          'notificationData': offlineNotification.toMap(),
        });
      }

      notifyListeners();
    } catch (e) {
      // Fallback to offline storage
      final offlineNotification = notification.copyWith(isSynced: false);
      await _offlineService.saveNotificationOffline(offlineNotification);
      _notifications.insert(0, offlineNotification);
      notifyListeners();
    }
  }

  /// Mark as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      // Immediate UI update
      final updatedNotification = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _notifications[index] = updatedNotification;
      notifyListeners();

      try {
        if (await _offlineService.isConnected()) {
          await _firestore
              .collection('notifications')
              .doc(notificationId)
              .update({
            'isRead': true,
            'readAt': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          // Update offline and queue sync
          await _offlineService.saveNotificationOffline(updatedNotification);
          await _offlineService.addToSyncQueue('update_notification', {
            'type': 'notification',
            'notificationId': notificationId,
            'updates': {
              'isRead': true,
              'readAt': DateTime.now().millisecondsSinceEpoch,
            },
          });
        }
      } catch (e) {
        // Revert on error
        _notifications[index] = _notifications[index].copyWith(
          isRead: false,
          readAt: null,
        );
        notifyListeners();
        throw Exception('Failed to mark as read: $e');
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();

    // Immediate UI update
    for (final notification in unreadNotifications) {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      _notifications[index] = notification.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    notifyListeners();

    try {
      if (await _offlineService.isConnected()) {
        final batch = _firestore.batch();
        final now = DateTime.now();
        for (final notification in unreadNotifications) {
          final docRef =
              _firestore.collection('notifications').doc(notification.id);
          batch.update(docRef, {
            'isRead': true,
            'readAt': now.millisecondsSinceEpoch,
          });
        }
        await batch.commit();
      } else {
        // Update offline and queue sync
        for (final notification in unreadNotifications) {
          final updatedNotification = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          await _offlineService.saveNotificationOffline(updatedNotification);
        }

        await _offlineService.addToSyncQueue('mark_all_read', {
          'type': 'notification_batch',
          'userId': userId,
          'action': 'mark_all_read',
        });
      }
    } catch (e) {
      // Revert on error
      for (final notification in unreadNotifications) {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        _notifications[index] = notification.copyWith(
          isRead: false,
          readAt: null,
        );
      }
      notifyListeners();
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // Get unread count stream
  Stream<int> getUnreadCount(String userId) {
    return _notificationRepository.getUnreadCountStream(userId);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    final notificationsToDelete = List<AppNotification>.from(_notifications);
    _notifications.clear();
    notifyListeners();

    try {
      if (await _offlineService.isConnected()) {
        final batch = _firestore.batch();
        for (final notification in notificationsToDelete) {
          final docRef =
              _firestore.collection('notifications').doc(notification.id);
          batch.delete(docRef);
        }
        await batch.commit();
      } else {
        // Clear offline storage and queue sync
        await _offlineService.clearAllOfflineNotifications(userId);
        await _offlineService.addToSyncQueue('clear_all_notifications', {
          'type': 'notification_batch',
          'userId': userId,
          'action': 'clear_all',
        });
      }
    } catch (e) {
      // Restore on error
      _notifications.addAll(notificationsToDelete);
      notifyListeners();
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  // Sync offline notifications
  Future<void> _syncOfflineNotifications(String userId) async {
    try {
      final offlineNotifications =
          await _offlineService.getOfflineNotifications(userId);
      final pendingSyncItems = await _offlineService.getPendingSyncItems();

      for (final notification in offlineNotifications) {
        if (!notification.isSynced) {
          await _firestore
              .collection('notifications')
              .doc(notification.id)
              .set(notification.toMap());

          await _offlineService.removeOfflineNotification(notification.id);
        }
      }

      // Process sync queue
      final notificationSyncItems = pendingSyncItems
          .where((item) => item['type'] == 'notification')
          .toList();

      for (final item in notificationSyncItems) {
        try {
          switch (item['action']) {
            case 'create_notification':
              final notificationData =
                  Map<String, dynamic>.from(item['data']['notificationData']);
              await _firestore
                  .collection('notifications')
                  .doc(notificationData['id'])
                  .set(notificationData);
              break;

            case 'update_notification':
              await _firestore
                  .collection('notifications')
                  .doc(item['data']['notificationId'])
                  .update(item['data']['updates']);
              break;

            case 'delete_notification':
              await _firestore
                  .collection('notifications')
                  .doc(item['data']['notificationId'])
                  .delete();
              break;

            case 'mark_all_read':
              final userNotifications = await _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .where('isRead', isEqualTo: false)
                  .get();

              final batch = _firestore.batch();
              for (final doc in userNotifications.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
              break;

            case 'clear_all':
              final userNotifications = await _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .get();

              final batch = _firestore.batch();
              for (final doc in userNotifications.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
              break;
          }

          await _offlineService.removeFromSyncQueue(item['id']);
        } catch (e) {
          print('Failed to sync notification operation ${item['action']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing offline notifications: $e');
    }
  }

  Future<void> permanentlyDeleteNotification(String notificationId) async {
    final notification =
        _notifications.firstWhere((n) => n.id == notificationId);

    // Immediate UI removal
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    try {
      if (await _offlineService.isConnected()) {
        // Delete from Firestore
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }

      // Always delete from local storage
      await _offlineService.removeOfflineNotification(notificationId);

      // Queue sync for other devices
      await _offlineService.addToSyncQueue('delete_notification', {
        'type': 'notification',
        'notificationId': notificationId,
      });
    } catch (e) {
      // Restore on error
      _notifications.add(notification);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete single notification
  Future<void> deleteNotification(String notificationId) async {
    final notification =
        _notifications.firstWhere((n) => n.id == notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete();
      } else {
        // Remove from offline storage and queue sync
        await _offlineService.removeOfflineNotification(notificationId);
        await _offlineService.addToSyncQueue('delete_notification', {
          'type': 'notification',
          'notificationId': notificationId,
        });
      }
    } catch (e) {
      // Restore on error
      _notifications.add(notification);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      throw Exception('Failed to delete notification: $e');
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
      print('Error sending appointment notification: $e');
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
      print('Error sending payment notification: $e');
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
      print('Error sending chat notification: $e');
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
      print('Error sending appointment reminder: $e');
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
      await _notificationRepository.sendAppointmentRequestToBarber(
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
      print('Error sending appointment request: $e');
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
      await _notificationRepository.sendAppointmentStatusToClient(
        appointmentId: appointmentId,
        status: status,
        barberName: barberName,
        serviceName: serviceName,
        reason: reason,
        sendPush: sendPush, clientId: userId,
      );
    } catch (e) {
      _error = 'Failed to send status update: $e';
      notifyListeners();
      print('Error sending appointment status update: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh notifications
  Future<void> refreshNotifications(String userId) async {
    await loadNotifications(userId);
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
    return _notifications
        .any((notification) => notification.id == notificationId);
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  // Get unread notifications
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get todaysNotifications => _notifications
      .where((n) => n.category == NotificationCategory.today)
      .toList();

  // Categorized notifications
  Map<NotificationCategory, List<AppNotification>>
      get categorizedNotifications {
    final categorized = <NotificationCategory, List<AppNotification>>{};

    for (final category in NotificationCategory.values) {
      categorized[category] = _notifications
          .where((notification) => notification.category == category)
          .toList();
    }

    return categorized;
  }

  // Get read notifications
  List<AppNotification> get readNotifications {
    return _notifications.where((notification) => notification.isRead).toList();
  }

  // Get latest notifications (last 10)
  List<AppNotification> get latestNotifications {
    return _notifications.take(10).toList();
  }

  // Get notification counts by category
  Map<NotificationCategory, int> get notificationCountsByCategory {
    final counts = <NotificationCategory, int>{};

    for (final category in NotificationCategory.values) {
      counts[category] =
          _notifications.where((n) => n.category == category).length;
    }

    return counts;
  }
}
