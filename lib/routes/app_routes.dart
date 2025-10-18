// lib/routes/app_routes.dart
import 'package:cutscurls/features/auth/screens/signin_screeen.dart';
import 'package:cutscurls/features/barber/earnings/barber_earning_screen.dart';
import 'package:cutscurls/features/barber/services/barber_services_screen.dart';
import 'package:cutscurls/features/client/bookings/select_barber_screen.dart';
import 'package:cutscurls/features/client/bookings/select_service_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// Auth Screens
import '../features/auth/screens/auth_wrapper.dart';
import '../features/auth/screens/signup_step1_screen.dart';
import '../features/auth/screens/signup_step2_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/auth/screens/final_touch_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/loader_screen.dart';

// Barber & Client Home
import '../features/barber/dashboard/dashboard_screen.dart';
import '../features/client/home/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    // Routes that don’t require authentication
    const publicRoutes = [
      '/signin',
      '/signup_step1',
      '/signup_step2',
      '/reset_password',
      '/verify_email',
    ];

    if (user == null && !publicRoutes.contains(state.matchedLocation)) {
      return '/signin';
    }

    if (user != null && publicRoutes.contains(state.matchedLocation)) {
      return '/';
    }

    return null;
  },

  routes: [
    // Root wrapper – decides where to go (signin, verify, home)
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),

    // Auth / Signup Flow or sign in
    GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
    GoRoute(path: '/signup_step1', builder: (context, state) => const SignUpStep1Screen()),
    GoRoute(path: '/signup_step2', builder: (context, state) => const SignUpStep2Screen(prevData: {})),
    GoRoute(path: '/verify_email', builder: (context, state) => const VerifyEmailScreen()),
    GoRoute(path: '/final_touch', builder: (context, state) => const FinalTouchScreen(userData: {})),
    GoRoute(path: '/reset_password', builder: (context, state) => const ResetPasswordScreen()),
    GoRoute(path: '/loader', builder: (context, state) => const LoaderScreen()),

    // Dashboards
    GoRoute(path: '/barber', builder: (context, state) => const BarberDashboardScreen()),
    GoRoute(path: '/client', builder: (context, state) => const ClientHomeScreen()),

    // Client booking flow
    GoRoute(path: '/select_barber', builder: (context, state) => const SelectBarberScreen()),
    GoRoute(path: '/select_service', builder: (_, state) => const SelectServiceScreen(barberId: '', barberData: {})),

    // Barber extras
    GoRoute(path: '/barber_earnings', builder: (context, state) => const BarberEarningsScreen()),
    GoRoute(path: '/barber_services', builder: (context, state) => const BarberServicesScreen()),
  ],
);
