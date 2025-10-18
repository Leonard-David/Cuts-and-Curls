import 'package:cutscurls/features/auth/screens/signin_screeen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../barber/dashboard/dashboard_screen.dart';
import '../../client/home/home_screen.dart';
import '../controllers/auth_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = ref.watch(firebaseUserProvider);
    final userRole = ref.watch(userRoleProvider);

    // 🔹 1. Handle loading and error states for Firebase user
    if (firebaseUser.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (firebaseUser.hasError) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error loading user')),
      );
    }

    // 🔹 2. No user logged in → go to Sign In
    final user = firebaseUser.value;
    if (user == null) {
      return const SignInScreen();
    }

    // 🔹 3. Handle role state
    if (userRole.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userRole.hasError) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error loading user role')),
      );
    }

    final role = userRole.value;

    // 🔹 4. Navigate based on role
    if (role == 'barber') {
      return const BarberDashboardScreen();
    } else if (role == 'client') {
      return const ClientHomeScreen();
    } else {
      // Unknown or missing role → fallback
      return const SignInScreen();
    }
  }
}
