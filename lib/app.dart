import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/home_screen.dart';
import 'features/auth/providers/auth_provider.dart';

// Define GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    ],
    redirect: (context, state) {
      final user = authState.valueOrNull;
      // Not logged in
      if (user == null) {
        if (state.fullPath == '/signup' || state.fullPath == '/login') return null;
        return '/login';
      }
      // Logged in, always go to home
      if (state.fullPath == '/login' || state.fullPath == '/signup') {
        return '/home';
      }
      return null;
    },
  );
});
