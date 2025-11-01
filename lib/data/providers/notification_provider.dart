import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AppNotification> _notifications = [];
  bool _hasUnread = false;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get hasUnread => _hasUnread;
  bool get isLoading => _isLoading;

  // Load notifications for user
  // Load notifications for user
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        _notifications = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return AppNotification.fromMap(data);
            })
            .toList();
        
        _hasUnread = _notifications.any((notification) => !notification.isRead);
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Create notification
  Future<void> createNotification(AppNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Send appointment notification
  Future<void> sendAppointmentNotification({
    required String userId,
    required String appointmentId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
    
    // Also send push notification
    // FCMService.sendNotificationToUser(...)
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _notifications.clear();
      _hasUnread = false;
      notifyListeners();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}