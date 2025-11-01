import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static StreamController<Map<String, dynamic>> _messageStream = StreamController.broadcast();
  static Stream<Map<String, dynamic>> get messageStream => _messageStream.stream;

  // Initialize FCM and local notifications
  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Configure FCM message handling
    await _configureFCM();
    
    // Get device token and save to user profile
    await _saveDeviceToken();
  }

  static Future<void> _requestPermissions() async {
    // New permission request API for Firebase Messaging v16+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  static Future<void> _configureFCM() async {
    // Handle foreground messages with new API
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle background messages with new API
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleBackgroundMessage(message);
    });

    // Get initial message
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessage(initialMessage);
    }
  }

  static Future<void> _saveDeviceToken() async {
    try {
      // Get the device token
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Token will be saved to user profile after login
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        // Update token in user profile
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification
    _showLocalNotification(message);
    
    // Add to stream for UI updates
    _messageStream.add({
      'type': 'foreground',
      'data': message.data,
      'notification': message.notification != null ? {
        'title': message.notification!.title,
        'body': message.notification!.body,
      } : null,
    });
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Received background message: ${message.messageId}');
    _handleNotificationNavigation(message.data);
  }

  static void _handleTerminatedMessage(RemoteMessage message) {
    print('Received terminated message: ${message.messageId}');
    _handleNotificationNavigation(message.data);
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        // Handle notification tap
        print('Notification tapped with payload: $payload');
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    _messageStream.add({
      'type': 'navigation',
      'data': data,
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = 
        AndroidNotificationDetails(
      'barber_app_channel',
      'Barber App Notifications',
      channelDescription: 'Notifications for appointments and payments',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics = 
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Barber App',
      message.notification?.body ?? 'New notification',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final String? fcmToken = userData?['fcmToken'];

        if (fcmToken != null) {
          // In a real app, you would call a Cloud Function or your backend
          // to send the push notification
          print('Would send notification to $fcmToken: $title - $body');
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Subscribe to topics
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Save FCM token to user profile
  static Future<void> saveTokenToUserProfile(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('FCM token saved to user profile');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static void dispose() {
    _messageStream.close();
  }
}