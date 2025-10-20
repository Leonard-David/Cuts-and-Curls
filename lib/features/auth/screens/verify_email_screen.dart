// lib/features/auth/screens/verify_email_screen.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimens.dart';
import '../../../core/widgets/custom_dialogs.dart';

class VerifyEmailScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const VerifyEmailScreen({super.key, this.userData});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    // Check every 3 seconds if email is verified
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      // Reload user to get latest email verification status
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        _timer?.cancel();
        
        if (!mounted) return;
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            title: 'Email Verified!',
            message: 'Your email has been successfully verified. You can now proceed to complete your profile.',
            onConfirm: () {
              Navigator.of(context).pop();
              _proceedToFinalTouch();
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Verification check error: $e');
    }
  }

  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await user.sendEmailVerification();
      
      if (!mounted) return;
      _showTopNotification('Verification email sent! Check your inbox.', isError: false);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Failed to send verification email.';
      }
      if (!mounted) return;
      _showTopNotification(message, isError: true);
    } catch (e) {
      debugPrint('Send verification error: $e');
      if (!mounted) return;
      _showTopNotification('Failed to send verification email. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _proceedToFinalTouch() {
    context.go('/final_touch', extra: widget.userData);
  }

  void _signOut() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      context.go('/signin');
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTopNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, kToolbarHeight + 8, 16, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.borderRadiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Verify Email',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _signOut,
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.paddingXXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: Dimens.paddingXL),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.primary.withOpacity(0.8),
              ),
              const SizedBox(height: Dimens.paddingXXL),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimens.paddingLG),
              Text(
                'We sent a verification link to:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimens.paddingMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimens.paddingLG),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimens.borderRadiusMedium),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: Dimens.paddingXXL),
              const Text(
                'Please check your email and click the verification link to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: Dimens.paddingLG),
              const Text(
                "Didn't receive the email?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Dimens.paddingXXL),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isSending
                    ? ElevatedButton(
                        onPressed: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: Dimens.paddingMD),
                            const Text('Sending...'),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _sendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.borderRadiusMedium),
                          ),
                        ),
                        child: const Text(
                          'Resend Verification Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: Dimens.paddingLG),
              TextButton(
                onPressed: () {
                  _checkEmailVerification();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: Dimens.paddingSM),
                    Text('Check Verification Status'),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(Dimens.paddingLG),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(Dimens.borderRadiusMedium),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: Dimens.paddingMD),
                    Expanded(
                      child: Text(
                        'You must verify your email before proceeding to the app.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}