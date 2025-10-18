// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign in user with email & password.
  /// Returns Firebase [User] on success, or throws FirebaseAuthException.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  /// Create user (signup) and write initial profile to Firestore.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'client' | 'barber'
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) return null;

    // Create user profile in Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      // add any initial fields e.g., photoUrl, bio, rating, etc.
    });

    return user;
  }

  /// Get role from users collection; returns 'client' if not set.
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return 'client';
    return (data['role'] as String?) ?? 'client';
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream of Firebase user for auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
