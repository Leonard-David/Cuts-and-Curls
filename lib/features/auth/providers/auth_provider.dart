import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

// Provide repo (swap with mock for tests)
final authRepoProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// auth state provider (exposes AppUser?)
final authStateProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(authRepoProvider);
  return repo.authStateChanges();
});
