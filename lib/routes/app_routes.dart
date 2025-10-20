import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:sheersync/features/auth/screens/auth_wrapper.dart';
import 'package:sheersync/features/auth/screens/final_touch_screen.dart';
import 'package:sheersync/features/auth/screens/reset_password_screen.dart';
import 'package:sheersync/features/auth/screens/signin_screeen.dart';
import 'package:sheersync/features/auth/screens/signup_step1_screen.dart';
import 'package:sheersync/features/auth/screens/signup_step2_screen.dart';
import 'package:sheersync/features/auth/screens/verify_email_screen.dart';
import 'package:sheersync/features/barber/appointments/appointment_details_screen.dart';
import 'package:sheersync/features/barber/barber_shell.dart';
import 'package:sheersync/features/barber/earnings/barber_earning_screen.dart';
import 'package:sheersync/features/barber/services/barber_services_screen.dart';
import 'package:sheersync/features/client/bookings/select_barber_screen.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';
import 'package:sheersync/features/client/home/home_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';
import '../features/auth/screens/loader_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true, // helpful for console debugging

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.uri.toString();

    // ✅ Public routes that don’t need auth
    final isPublicRoute = [
      '/signin',
      '/signup_step1',
      '/signup_step2',
      '/reset_password',
      '/verify_email',
    ].any((r) => location.startsWith(r));

    // No user — redirect to Sign In if not on a public route
    if (user == null && !isPublicRoute) {
      return '/signin';
    }

    // 🔵 Already signed in — redirect away from sign in/signup
    if (user != null && isPublicRoute) {
      return '/';
    }

    return null; // no redirect
  },

  routes: [
    // Root logic wrapper
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),

    // Authentication flow
    GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
    GoRoute(
      path: '/signup_step1',
      builder: (context, state) => const SignUpStep1Screen(),
    ),
    GoRoute(
      path: '/signup_step2',
      builder: (_, state) {
        final prevData = state.extra as Map<String, dynamic>? ?? {};
        return SignUpStep2Screen(prevData: prevData);
      },
    ),
    GoRoute(
      path: '/verify_email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    GoRoute(
      path: '/reset_password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/final_touch',
      builder: (context, state) => const FinalTouchScreen(userData: {}),
    ),
    GoRoute(path: '/loader', builder: (context, state) => const LoaderScreen()),

    // Barber & Client dashboards
    GoRoute(path: '/barber', builder: (context, state) => const BarberShell()),
    GoRoute(
      path: '/client',
      builder: (context, state) => const ClientHomeScreen(),
    ),

    // Client booking
    GoRoute(
      path: '/select_barber',
      builder: (context, state) => const SelectBarberScreen(),
    ),
    GoRoute(
      path: '/select_service',
      builder: (context, state) =>
          const SelectServiceScreen(barberId: '', barberData: {}),
    ),

    // Barber modules
    GoRoute(
      path: '/barber_earnings',
      builder: (context, state) => const BarberEarningsScreen(),
    ),
    GoRoute(
      path: '/barber_services',
      builder: (context, state) => const BarberServicesScreen(),
    ),

    // Appointment detail
    GoRoute(
      path: '/appointment/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        return AppointmentDetailScreen(appointmentId: id);
      },
    ),

    // Notifications
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),
  ],
);
