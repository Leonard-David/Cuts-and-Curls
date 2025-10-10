import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    ],
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        if (state.uri.toString() == '/signup' || state.uri.toString() == '/login') return null;
        return '/login';
      }
      // Redirect based on role
      // return user.role == UserRole.client ? '/client/book' : '/barber/appointments';
      return null;
    },
  );
});
YDuio6+_<,.cx