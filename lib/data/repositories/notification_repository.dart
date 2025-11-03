import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send appointment notification
  Future<void> sendAppointmentNotification({
    required String userId,
    required String appointmentId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: appointmentId,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      print('Notification sent to user $userId: $title');
    } catch (e) {
      print('Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }

  // Send notification to multiple users
  Future<void> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      for (final userId in userIds) {
        final notification = AppNotification(
          id: 'notif_${timestamp.millisecondsSinceEpoch}_$userId',
          userId: userId,
          title: title,
          message: message,
          type: type,
          isRead: false,
          createdAt: timestamp,
          data: data,
        );

        final docRef = _firestore
            .collection('notifications')
            .doc(notification.id);
        
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
      print('Bulk notifications sent to ${userIds.length} users');
    } catch (e) {
      print('Error sending bulk notifications: $e');
      throw Exception('Failed to send bulk notifications: $e');
    }
  }

  // Get notifications stream for a user
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return AppNotification.fromMap(data);
            })
            .toList());
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
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': now.millisecondsSinceEpoch,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing all notifications: $e');
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  // Get unread notifications count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get notification by ID
  Future<AppNotification?> getNotificationById(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return AppNotification.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting notification by ID: $e');
      throw Exception('Failed to get notification: $e');
    }
  }

  // Send reminder notification for upcoming appointments
  Future<void> sendAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String clientName,
    required DateTime appointmentTime,
    required String serviceName,
  }) async {
    final timeUntilAppointment = appointmentTime.difference(DateTime.now());
    final hoursUntil = timeUntilAppointment.inHours;

    String reminderMessage;
    if (hoursUntil <= 1) {
      reminderMessage = 'Your appointment with $clientName for $serviceName is in 1 hour';
    } else if (hoursUntil <= 24) {
      reminderMessage = 'Your appointment with $clientName for $serviceName is tomorrow';
    } else {
      reminderMessage = 'Your appointment with $clientName for $serviceName is in ${timeUntilAppointment.inDays} days';
    }

    await sendAppointmentNotification(
      userId: userId,
      appointmentId: appointmentId,
      title: 'Appointment Reminder',
      message: reminderMessage,
      type: NotificationType.reminder,
    );
  }

  // Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required String paymentId,
    required String title,
    required String message,
    required String status,
  }) async {
    await sendAppointmentNotification(
      userId: userId,
      appointmentId: paymentId,
      title: title,
      message: message,
      type: NotificationType.payment,
      data: {
        'paymentStatus': status,
        'paymentId': paymentId,
      },
    );
  }

  // Send promotion notification
  Future<void> sendPromotionNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required String promotionId,
  }) async {
    await sendBulkNotifications(
      userIds: userIds,
      title: title,
      message: message,
      type: NotificationType.promotion,
      data: {
        'promotionId': promotionId,
      },
    );
  }
}