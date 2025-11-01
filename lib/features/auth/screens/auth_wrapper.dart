import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/auth/screens/signin_screeen.dart';
import 'package:sheersync/features/barber/barber_shell.dart';
import 'package:sheersync/features/client/client_shell.dart';
import '../controllers/auth_provider.dart';
import 'loader_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Show loader while checking auth state
    if (authProvider.isLoading) {
      return const LoaderScreen();
    }
    
    // If user is not authenticated, show sign in screen
    if (!authProvider.isAuthenticated) {
      return const SignInScreen();
    }
    
    // Route user based on their role
    if (authProvider.user?.userType == 'barber') {
      return const BarberShell(); // We'll create this next
    } else {
      return const ClientShell(); // We'll create this next
    }
  }
}