import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/theme/app_theme.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import 'package:sheersync/core/utils/stripe_helper.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/data/providers/settings_provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/features/auth/screens/auth_wrapper.dart';
import 'package:sheersync/firebase_options.dart';
import 'core/notifications/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting app initialization...');

  try {
    // Initialize Hive and register adapters
    await Hive.initFlutter();
    print('Hive initialized');

    // Register adapters
    Hive.registerAdapter(AppointmentModelAdapter());
    Hive.registerAdapter(PaymentModelAdapter());
    Hive.registerAdapter(MessageTypeAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(ChatRoomAdapter());
    Hive.registerAdapter(ServiceModelAdapter());
    print('Hive adapters registered');

    // Initialize Firebase with new API
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized');

    // Initialize offline service with error handling
    try {
      await OfflineService().initialize();
      OfflineService();
      print('Offline service initialized successfully');
    } catch (e) {
      print('Offline service initialization warning: $e');
      // Continue without offline service
    }

    // Initialize FCM
    await FCMService.initialize();
    print('FCM initialized');

    // Initialize Stripe with error handling
    //try {
     // await StripeHelper.initialize();
    //  print('Stripe initialized');
    //} catch (e) {
      //print('Stripe initialization failed: $e');
      // Continue without Stripe for now
    //}

    print('All services initialized successfully');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('CRITICAL: App initialization failed: $e');
    print('Stack trace: $stackTrace');

    // Fallback app without dependencies
    runApp(const FallbackApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'SheerSync',
            theme: settingsProvider.settings.isDarkMode
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Fallback app in case of initialization failures
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Please restart the app. If the problem persists, contact support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Try to restart
                  main();
                },
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
