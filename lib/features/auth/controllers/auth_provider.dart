// lib/features/auth/controllers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';

/// Provide the repository (singleton style)
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Stream of FirebaseAuth user
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Fetches the user's role from Firestore (only when signed in)
final userRoleProvider = FutureProvider<String?>((ref) async {
  // Use `whenData` to wait for the stream’s latest value
  final userAsync = ref.watch(firebaseUserProvider);

  // If still loading or error, just return null for now
  if (userAsync.isLoading || userAsync.hasError) return null;

  final user = userAsync.value;
  if (user == null) return null;

  final repo = ref.read(authRepositoryProvider);
  final role = await repo.getUserRole(user.uid);
  return role;
});
