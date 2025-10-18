// lib/features/auth/screens/verify_email_screen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../auth/controllers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isVerified = false;
  bool _isSending = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    // Check every 3 seconds for verification update
    if (!_isVerified) {
      _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerificationStatus());
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload(); // refresh user from Firebase
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser != null && refreshedUser.emailVerified) {
      setState(() => _isVerified = true);
      _checkTimer?.cancel();

      // Fetch role and redirect
      final role = await ref.read(authRepositoryProvider).getUserRole(refreshedUser.uid);
      if (!mounted) return;
      if (role == 'barber') {
        context.go('/barber');
      } else {
        context.go('/client');
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _isSending = true);
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
      );
    } catch (e) {
      debugPrint('Email resend error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send verification email. Try again later.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify your email'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isVerified
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'Email verified! Redirecting...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 80, color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      'A verification email has been sent to:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Please verify your email to continue.\nOnce verified, this screen will update automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isSending ? null : _resendVerificationEmail,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Resend Verification Email'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _checkVerificationStatus,
                      child: const Text('Refresh Status'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
