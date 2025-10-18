// lib/routes/app_routes.dart
//
// --------------------------------------------------------
// GoRouter setup for Cuts & Curls
// --------------------------------------------------------
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
    if (user == null && state.matchedLocation != '/signin') {
      return '/signin';
    }
    return null;
  },

  routes: [
    //Root wrapper – decides where to go (signin, verify, home)
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),

    //Auth / Signup Flow or sign in
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/signup-step1',
      builder: (context, state) => const SignUpStep1Screen(),
    ),
    GoRoute(
      path: '/signup-step2',
      builder: (context, state) => const SignUpStep2Screen(prevData: {}),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    GoRoute(
      path: '/final-touch',
      builder: (context, state) => const FinalTouchScreen(userData: {}),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(path: '/loader', builder: (context, state) => const LoaderScreen()),

    // 🔹 Dashboards
    GoRoute(
      path: '/barber',
      builder: (context, state) => const BarberDashboardScreen(),
    ),
    GoRoute(
      path: '/client',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/select-barber',
      builder: (context, state) => const SelectBarberScreen(),
    ),
    GoRoute(
      path: '/select-service',
      builder: (_, state) =>
          const SelectServiceScreen(barberId: '', barberData: {}),
    ),
    GoRoute(
      path: '/barber',
      builder: (context, state) => const BarberDashboardScreen(),
    ),
    GoRoute(
      path: '/barber-earnings',
      builder: (context, state) => const BarberEarningsScreen(),
    ),
    GoRoute(
      path: '/barber-services',
      builder: (context, state) => const BarberServicesScreen(),
    ),
  ],
);
