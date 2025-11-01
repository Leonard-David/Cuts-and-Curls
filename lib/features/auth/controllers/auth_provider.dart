import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    _checkCurrentUser();
  }

  // Check if user is already logged in
  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    User? firebaseUser = FirebaseAuth.instance.currentUser;
    
    if (firebaseUser != null) {
      await _fetchUserData(firebaseUser.uid);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      _error = "Failed to fetch user data";
    }
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      await _fetchUserData(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up new user
  Future<bool> signUp(String email, String password, String fullName, String userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      // Create user document in Firestore
      _user = UserModel(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        userType: userType,
        createdAt: DateTime.now(),
        isOnline: true,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(_user!.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _error = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Helper method to get user-friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Email address is invalid';
      default:
        return 'An error occurred. Please try again';
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {}
}