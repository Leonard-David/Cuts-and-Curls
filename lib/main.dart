// lib/main.dart
//
// --------------------------------------------------------
// Entry point for the Verve Book App
// Handles Firebase, Notifications, Stripe, and Riverpod setup.
// --------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sheersync/core/notifications/fcm_service.dart';
import 'package:sheersync/core/notifications/local_notification_service.dart';
import 'package:sheersync/firebase_options.dart';
//import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // Ensure all Flutter bindings and plugins are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe Configuration (loaded securely from environment)
  // Use --dart-define for production: flutter run --dart-define=STRIPE_KEY=pk_test_XXXX
  const stripeKey = String.fromEnvironment(
    'STRIPE_KEY',
    defaultValue: 'pk_test_XXXXXXXXXXXXXXXXXXXX', // fallback for dev
  );
  Stripe.publishableKey = stripeKey;
  Stripe.merchantIdentifier = 'VerveBookMerchant';
  Stripe.urlScheme = 'VerveBook';

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase init failed: $e');
    debugPrintStack(stackTrace: stack);
  }

  // Initialize Local + Push Notifications
  await LocalNotificationService.initialize();
  await FCMService.initFCM();

  // Global Error Handler (for debugging & Crashlytics)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  // Run the App (Riverpod + MaterialApp.router)
  runApp(const ProviderScope(child: MyApp()));
}
