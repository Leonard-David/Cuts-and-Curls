import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/data/repositories/notification_repository.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  // ignore: unused_field
  static final NotificationRepository _notificationRepository =
      NotificationRepository();

  static StreamController<Map<String, dynamic>> _messageStream =
      StreamController.broadcast();
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageStream.stream;

  // Initialize FCM and local notifications
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM message handling
      await _configureFCM();

      // Get device token and save to user profile
      await _saveDeviceToken();

      print('FCM Service initialized successfully');
    } catch (e) {
      print('FCM Service initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );

      print('Local notifications initialized');
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  static Future<void> _configureFCM() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleBackgroundMessage(message);
      });

      // Handle terminated messages
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleTerminatedMessage(initialMessage);
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _updateDeviceToken(newToken);
      });

      print('FCM configured successfully');
    } catch (e) {
      print('Error configuring FCM: $e');
    }
  }

  static Future<void> _saveDeviceToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Token will be saved to user profile after login
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  static Future<void> _updateDeviceToken(String newToken) async {
    try {
      print('FCM Token refreshed: $newToken');
      // Update token in user profile when user is logged in
    } catch (e) {
      print('Error updating FCM token: $e');
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
      'notification': message.notification != null
          ? {
              'title': message.notification!.title,
              'body': message.notification!.body,
            }
          : null,
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
        print('Notification tapped with payload: $payload');
        // Handle notification navigation based on payload
        _handleNotificationNavigation({'payload': payload});
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

  ////////////////////////
  // Handle different notification types
  static void _handleNotificationByType(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'appointment_status':
        _handleAppointmentStatusNotification(data);
        break;
      case 'appointment_cancelled':
        _handleAppointmentCancelledNotification(data);
        break;
      case 'appointment_rescheduled':
        _handleAppointmentRescheduledNotification(data);
        break;
      case 'new_message':
        _handleNewMessageNotification(data);
        break;
      default:
        print('📢 Unknown notification type: $type');
    }
  }


  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'barber_app_channel',
        'Barber App Notifications',
        channelDescription:
            'Notifications for appointments, payments, and messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        autoCancel: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? 'SheerSync',
        message.notification?.body ?? 'New notification',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );

      print('Local notification shown');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
    String? channelId,
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

        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Prepare notification payload
          final message = {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
              if (imageUrl != null) 'image': imageUrl,
            },
            'data': {
              ...data,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'userId': userId,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': channelId ?? 'barber_app_channel',
                'sound': 'default',
                'icon': '@mipmap/ic_launcher',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                },
              },
            },
          };

          // In a real app, you would send this via your backend server
          // or Firebase Cloud Functions
          print('FCM Message Prepared:');
          print('  To: $fcmToken');
          print('  Title: $title');
          print('  Body: $body');
          print('  Data: $data');

          // For now, show local notification as fallback
          await _showCustomLocalNotification(title, body, data);
        } else {
          print('No FCM token for user $userId');
          // Fallback to local notification
          await _showCustomLocalNotification(title, body, data);
        }
      } else {
        print('User $userId not found');
        // Fallback to local notification
        await _showCustomLocalNotification(title, body, data);
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
      // Fallback to local notification
      await _showCustomLocalNotification(title, body, data);
    }
  }

  static Future<void> _showCustomLocalNotification(
      String title, String body, Map<String, dynamic> data) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'barber_app_channel',
        'Barber App Notifications',
        channelDescription:
            'Notifications for appointments, payments, and messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        autoCancel: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: data.toString(),
      );
    } catch (e) {
      print('❌ Error showing custom local notification: $e');
    }
  }

  // Subscribe to topics
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
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
        print('✅ FCM token saved to user profile');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  static void dispose() {
    _messageStream.close();
  }
  static void _handleAppointmentStatusNotification(Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'];
    final status = data['status'];
    final barberName = data['barberName'];
    
    print('📅 Appointment status update: $appointmentId - $status with $barberName');
    
    // You can trigger UI updates or refresh data here
    // For example, refresh appointments list
  }

  static void _handleAppointmentCancelledNotification(Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'];
    final cancelledBy = data['cancelledBy'];
    
    print('❌ Appointment cancelled: $appointmentId by $cancelledBy');
    
    // Refresh appointments list or show specific UI
  }

  static void _handleAppointmentRescheduledNotification(Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'];
    final newAppointmentTime = data['newAppointmentTime'];
    
    print('🔄 Appointment rescheduled: $appointmentId to $newAppointmentTime');
    
    // Update local appointment data
  }

  static void _handleNewMessageNotification(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final senderName = data['senderName'];
    
    print('💬 New message in chat: $chatId from $senderName');
    
    // Refresh chat list or show message preview
  }
}
