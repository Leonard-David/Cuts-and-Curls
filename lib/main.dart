import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/theme/app_theme.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/data/providers/settings_provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/features/auth/screens/auth_wrapper.dart';
import 'package:sheersync/firebase_options.dart';
import 'core/notifications/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with new API
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize offline service
  try {
    await OfflineService().initialize();
    print('Offline service initialized successfully');
  } catch (e) {
    print('Error initializing offline service: $e');
  }
  
  // Initialize FCM
  await FCMService.initialize();
  
  runApp(const MyApp());
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
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Student Barber App',
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