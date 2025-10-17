// lib/data/repositories/auth_repository.dart
// Handles authentication (email/password + simple wrappers).
// Uses FirebaseAuth and keeps user creation minimal — user profile stored in Firestore via UserRepository.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepository();

  /// Register with email & password and create a basic user document in `users/{uid}`.
  /// Returns the created `UserCredential.user`.
  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role, // 'client' | 'barber'
    String? phone,
  }) async {
    try {
      // Create user in Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw FirebaseAuthException(code: 'USER_NULL', message: 'User creation failed');

      // Create initial Firestore profile
      final userDoc = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'photoUrl': null,
        'bio': null,
        'rating': 0.0,
        'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      await _firestore.collection('users').doc(user.uid).set(userDoc);

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      // Wrap unknown errors as FirebaseAuthException for consistency
      throw FirebaseAuthException(code: 'SIGNUP_FAILED', message: e.toString());
    }
  }

  /// Sign in with email and password.
  Future<User?> signInWithEmail({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'SIGNIN_FAILED', message: e.toString());
    }
  }

  /// Sign out current user.
  Future<void> signOut() => _auth.signOut();

  /// Returns current Firebase user (nullable).
  User? getCurrentUser() => _auth.currentUser;

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) => _auth.sendPasswordResetEmail(email: email);
}
