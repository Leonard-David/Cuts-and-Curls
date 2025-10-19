// lib/data/repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Watch user state
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  // 🔹 Create account only (no Firestore yet)
  Future<User?> createUserWithEmail(String email, String password) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    // ignore: unused_catch_clause
    } on FirebaseAuthException catch (e) {
      rethrow; // handled by caller
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Save user details to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 Sign in
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // 🔹 Reset password
  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // 🔹 Sign out
  Future<void> signOut() async => _firebaseAuth.signOut();

  // 🔹 Get Firestore role
  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'];
  }
}
