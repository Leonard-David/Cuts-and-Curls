import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified =>
      FirebaseAuth.instance.currentUser?.emailVerified ?? false;
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

      // If user exists but email is not verified, sign them out
      if (!firebaseUser.emailVerified && _user != null) {
        await signOut();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

        // Update email verification status in Firestore if it changed
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null &&
            currentUser.emailVerified != _user!.isEmailVerified) {
          await _updateEmailVerificationStatus(currentUser.emailVerified);
        }
      }
    } catch (e) {
      _error = "Failed to fetch user data";
      debugPrint('Error fetching user data: $e');
    }
    notifyListeners();
  }

  // Update email verification status in Firestore
  Future<void> _updateEmailVerificationStatus(bool isVerified) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update({
        'isEmailVerified': isVerified,
      });

      // Update local user model
      _user = _user!.copyWith(isEmailVerified: isVerified);
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
    }
  }

  // Sign in with email and password,
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if email is verified
      if (!credential.user!.emailVerified) {
        _error =
            'Please verify your email before signing in. Check your inbox for the verification link.';
        _isLoading = false;
        notifyListeners();

        // This allows the AuthWrapper to redirect to VerifyEmailScreen
        await _fetchUserData(credential.user!.uid);
        return false;
      }


      await _fetchUserData(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      //HANDLING FOR PASSWORD CHANGE SCENARIO
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        _error =
            'Invalid credentials. If you recently changed your password, please use the new password.';
      } else {
        _error = _getAuthErrorMessage(e);
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error =
          'An unexpected error occurred. Please check your internet connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up new user
  Future<bool> signUp(
      String email, String password, String fullName, String userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send email verification
      await credential.user!.sendEmailVerification();

      // Create user document in Firestore
      _user = UserModel(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        userType: userType,
        createdAt: DateTime.now(),
        isOnline: true,
        isEmailVerified: false,
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
    } catch (e) {
      _error = 'An unexpected error occurred during sign up';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check email verification status and update Firestore
  Future<bool> checkEmailVerification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      await currentUser.reload();
      final isVerified = currentUser.emailVerified;

      // Update Firestore if verification status changed
      if (_user != null && isVerified != _user!.isEmailVerified) {
        await _updateEmailVerificationStatus(isVerified);
      }

      return isVerified;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      await currentUser.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to resend verification email';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update user offline status before signing out
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.id)
            .update({
          'isOnline': false,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await FirebaseAuth.instance.signOut();
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Still clear local state even if Firestore update fails
      _user = null;
      _error = null;
      notifyListeners();
    }
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
    } catch (e) {
      _error = 'Failed to send password reset email';
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? profileImage,
  }) async {
    try {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        fullName: fullName,
        phone: phone,
        bio: bio,
        profileImage: profileImage,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update(updatedUser.toMap());

      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      if (_user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update({
        'isOnline': isOnline,
        if (!isOnline) 'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });

      _user = _user!.copyWith(isOnline: isOnline);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  // Map FirebaseAuthException codes to user-friendly messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please sign in or use a different email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
      case 'invalid-email':
        return 'Email address is invalid. Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again in a few minutes.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      default:
        return 'An unexpected authentication error occurred. Please try again.';
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
