import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/notifications/fcm_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send comprehensive appointment notification
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
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: appointmentId,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      // Save to Firestore
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Send push notification if enabled
      if (sendPush) {
        await FCMService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: message,
          data: data ?? {},
        );
      }

      print('📱 Notification sent to user $userId: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
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
      final notification = AppNotification(
        id: 'payment_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.payment,
        relatedId: paymentId,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'paymentStatus': status,
          'paymentId': paymentId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      if (sendPush) {
        await FCMService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: message,
          data: {
            'type': 'payment',
            'paymentId': paymentId,
            'status': status,
            'amount': amount.toString(),
          },
        );
      }

      print('💰 Payment notification sent to user $userId: $title');
    } catch (e) {
      print('❌ Error sending payment notification: $e');
      throw Exception('Failed to send payment notification: $e');
    }
  }

  // Send chat message notification
  Future<void> sendChatNotification({
    required String userId,
    required String chatId,
    required String senderName,
    required String message,
    required String chatType,
    bool sendPush = true,
  }) async {
    try {
      final notification = AppNotification(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: 'New message from $senderName',
        message: message.length > 100 ? '${message.substring(0, 100)}...' : message,
        type: NotificationType.system,
        relatedId: chatId,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'chatId': chatId,
          'senderName': senderName,
          'messageType': chatType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      if (sendPush) {
        await FCMService.sendNotificationToUser(
          userId: userId,
          title: 'New message from $senderName',
          body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
          data: {
            'type': 'chat',
            'chatId': chatId,
            'senderName': senderName,
          },
        );
      }

      print('💬 Chat notification sent to user $userId');
    } catch (e) {
      print('❌ Error sending chat notification: $e');
      throw Exception('Failed to send chat notification: $e');
    }
  }

  // Send appointment reminder notification
  Future<void> sendAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String clientName,
    required String barberName,
    required DateTime appointmentTime,
    required String serviceName,
    required String userType, // 'client' or 'barber'
    bool sendPush = true,
  }) async {
    try {
      final timeUntilAppointment = appointmentTime.difference(DateTime.now());
      final hoursUntil = timeUntilAppointment.inHours;

      String title, message;
      
      if (userType == 'client') {
        title = 'Appointment Reminder';
        message = 'Your appointment with $barberName for $serviceName is ';
      } else {
        title = 'Appointment Reminder';
        message = 'Your appointment with $clientName for $serviceName is ';
      }

      if (hoursUntil <= 1) {
        message += 'in 1 hour';
      } else if (hoursUntil <= 24) {
        message += 'tomorrow';
      } else {
        message += 'in ${timeUntilAppointment.inDays} days';
      }

      final notification = AppNotification(
        id: 'reminder_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.reminder,
        relatedId: appointmentId,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'appointmentId': appointmentId,
          'appointmentTime': appointmentTime.millisecondsSinceEpoch,
          'serviceName': serviceName,
          'reminderType': 'appointment',
          'userType': userType,
        },
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      if (sendPush) {
        await FCMService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: message,
          data: {
            'type': 'reminder',
            'appointmentId': appointmentId,
            'userType': userType,
          },
        );
      }

      print('⏰ Reminder notification sent to $userType $userId');
    } catch (e) {
      print('❌ Error sending reminder notification: $e');
      throw Exception('Failed to send reminder notification: $e');
    }
  }

  // Send appointment request notification
  Future<void> sendAppointmentRequest({
    required String barberId,
    required String appointmentId,
    required String clientName,
    required String serviceName,
    required DateTime appointmentTime,
    bool sendPush = true,
  }) async {
    try {
      final notification = AppNotification(
        id: 'request_${DateTime.now().millisecondsSinceEpoch}_$barberId',
        userId: barberId,
        title: 'New Appointment Request',
        message: '$clientName requested $serviceName on ${_formatDate(appointmentTime)}',
        type: NotificationType.appointment,
        relatedId: appointmentId,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'appointmentId': appointmentId,
          'clientName': clientName,
          'serviceName': serviceName,
          'appointmentTime': appointmentTime.millisecondsSinceEpoch,
          'notificationType': 'appointment_request',
        },
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      if (sendPush) {
        await FCMService.sendNotificationToUser(
          userId: barberId,
          title: 'New Appointment Request',
          body: '$clientName requested $serviceName',
          data: {
            'type': 'appointment_request',
            'appointmentId': appointmentId,
            'clientName': clientName,
          },
        );
      }

      print('📅 Appointment request sent to barber $barberId');
    } catch (e) {
      print('❌ Error sending appointment request: $e');
      throw Exception('Failed to send appointment request: $e');
    }
  }

  // Send appointment status update notification
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
      String title, message;

      switch (status) {
        case 'confirmed':
          title = 'Appointment Confirmed!';
          message = userType == 'client'
              ? 'Your appointment with $barberName for $serviceName has been confirmed'
              : 'You confirmed an appointment for $serviceName';
          break;
        case 'cancelled':
          title = 'Appointment Cancelled';
          message = userType == 'client'
              ? 'Your appointment with $barberName has been cancelled${reason != null ? ': $reason' : ''}'
              : 'You cancelled an appointment${reason != null ? ': $reason' : ''}';
          break;
        case 'completed':
          title = 'Appointment Completed';
          message = userType == 'client'
              ? 'Your appointment with $barberName has been completed'
              : 'You marked an appointment as completed';
          break;
        default:
          title = 'Appointment Updated';
          message = 'Your appointment status has been updated to $status';
      }

      final notification = AppNotification(
        id: 'status_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.appointment,
        relatedId: appointmentId,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'appointmentId': appointmentId,
          'status': status,
          'serviceName': serviceName,
          'appointmentTime': appointmentTime.millisecondsSinceEpoch,
          'userType': userType,
          if (reason != null) 'reason': reason,
        },
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      if (sendPush) {
        await FCMService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: message,
          data: {
            'type': 'appointment_status',
            'appointmentId': appointmentId,
            'status': status,
            'userType': userType,
          },
        );
      }

      print('📊 Appointment status update sent to $userType $userId');
    } catch (e) {
      print('❌ Error sending appointment status update: $e');
      throw Exception('Failed to send appointment status update: $e');
    }
  }

  // Get notifications stream for a user with real-time updates
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return AppNotification.fromMap(data);
              } catch (e) {
                print('❌ Error parsing notification: $e');
                // Return a default notification in case of error
                return AppNotification(
                  id: doc.id,
                  userId: userId,
                  title: 'Notification',
                  message: 'Unable to load notification',
                  type: NotificationType.system,
                  isRead: false,
                  createdAt: DateTime.now(),
                );
              }
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
      print('❌ Error marking notification as read: $e');
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
      print('✅ Marked all notifications as read for user $userId');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
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

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
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
      print('✅ Cleared all notifications for user $userId');
    } catch (e) {
      print('❌ Error clearing all notifications: $e');
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}