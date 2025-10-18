import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'local_notification_service.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Request notification permissions and get FCM token
  static Future<void> initFCM() async {
    // iOS permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token for this device
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Store token in Firestore under user document (optional)
    // await FirebaseFirestore.instance.collection('users').doc(uid).update({'fcmToken': token});

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        LocalNotificationService.showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handle background & terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.data}');
    });
  }

  /// Send notification manually (from client or function)
  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This part will be handled by Cloud Function (backend)
    // Clients should NOT call FCM directly with server keys.
  }
}
