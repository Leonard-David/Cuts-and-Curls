// lib/main.dart
//
// --------------------------------------------------------
// Entry point for the SheerSync (Verve Book) App
// Handles Firebase, Notifications, Stripe, and Riverpod setup.
// --------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sheersync/core/notifications/fcm_service.dart';
import 'package:sheersync/core/notifications/local_notification_service.dart';
import 'package:sheersync/firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // Ensure bindings are initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env file)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment loaded successfully");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }

  // Initialize Stripe securely
  try {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? const String.fromEnvironment('STRIPE_KEY');
    Stripe.publishableKey = publishableKey;
    Stripe.merchantIdentifier = 'SheerSyncMerchant';
    Stripe.urlScheme = 'sheersync';
    debugPrint("Stripe initialized");
  } catch (e) {
    debugPrint("Stripe init failed: $e");
  }

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized");
  } catch (e, stack) {
    debugPrint("Firebase initialization failed: $e");
    debugPrintStack(stackTrace: stack);
  }

  // Initialize Notifications
  try {
    await LocalNotificationService.initialize();
    await FCMService.initFCM();
    debugPrint("Notification services initialized");
  } catch (e) {
    debugPrint(" Notification service init failed: $e");
  }

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  // Launch the app wrapped in Riverpod
  runApp(const ProviderScope(child: MyApp()));
}
