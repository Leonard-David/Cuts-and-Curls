// lib/routes/app_routes.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// 🔹 Auth Screens
import 'package:sheersync/features/auth/screens/auth_wrapper.dart';
import 'package:sheersync/features/auth/screens/final_touch_screen.dart';
import 'package:sheersync/features/auth/screens/reset_password_screen.dart';
import 'package:sheersync/features/auth/screens/signin_screeen.dart';
import 'package:sheersync/features/auth/screens/loader_screen.dart';
import 'package:sheersync/features/auth/screens/signup_screen.dart';
import 'package:sheersync/features/auth/screens/verify_email_screen.dart';

// 🔹 Barber & Client
import 'package:sheersync/features/barber/barber_shell.dart';
import 'package:sheersync/features/barber/appointments/appointment_details_screen.dart';
import 'package:sheersync/features/barber/earnings/barber_earning_screen.dart';
import 'package:sheersync/features/barber/services/barber_services_screen.dart';
import 'package:sheersync/features/client/client_shell.dart';
import 'package:sheersync/features/client/bookings/select_barber_screen.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.uri.toString();

    final publicRoutes = [
      '/signin',
      '/signup',
      '/verify_email',
      '/reset_password',
    ];

    if (user == null && !publicRoutes.contains(location)) {
      return '/signin';
    }

    if (user != null && publicRoutes.contains(location)) {
      return '/';
    }

    return null;
  },

  routes: [
    // Root wrapper
    GoRoute(path: '/', builder: (context , state) => const AuthWrapper()),

    // 🔹 Auth Flow
    GoRoute(path: '/signin', builder: (context , state) => const SignInScreen()),
    GoRoute(path: '/signup', builder: (context , state) => const SignUpScreen()),
    GoRoute(path: '/verify_email', builder: (context , state) => const VerifyEmailScreen()),

    // New OTP verification route
    
    GoRoute(
      path: '/final_touch',
      builder: (context, state) {
        return FinalTouchScreen();
      },
    ),

    GoRoute(path: '/reset_password', builder: (context , state) => const ResetPasswordScreen()),
    GoRoute(path: '/loader', builder: (context , state) => const LoaderScreen()),

    // Barber and Client dashboards
    GoRoute(path: '/barber', builder: (context , state) => const BarberShell()),
    GoRoute(path: '/client', builder: (_, __) => const ClientShell()),

    // Client booking flow
    GoRoute(path: '/select_barber', builder: (context , state) => const SelectBarberScreen()),
    GoRoute(
      path: '/select_service',
      builder: (context , state) => const SelectServiceScreen(barberId: '', barberData: {}),
    ),

    // Barber modules
    GoRoute(path: '/barber_earnings', builder: (context , state) => const BarberEarningsScreen()),
    GoRoute(path: '/barber_services', builder: (context , state) => const BarberServicesScreen()),

    // Appointment details
    GoRoute(
      path: '/appointment/:id',
      builder: (_, state) => AppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
    ),

    // Notifications
    GoRoute(path: '/notifications', builder: (context , state) => const NotificationCenterScreen()),
  ],
);
