// lib/features/auth/screens/signin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cutscurls/features/auth/screens/reset_password_screen.dart';
import 'package:cutscurls/features/auth/screens/signup_step1_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../auth/controllers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>(); // for validation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false; // show loading spinner

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Basic email validator
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  // Basic password validator
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.trim().length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _signIn() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);

    try {
      // Attempt to sign in with email & password
      final user = await authRepo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user == null) {
        // Unexpected null return
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
        return;
      }

      // Fetch role from Firestore (if not set, default to 'client')
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'client';

      // Role-based navigation using GoRouter
      if (!mounted) return;
      if (role == 'barber') {
        // Replace with GoRouter to clear backstack
        context.go('/barber');
      } else {
        context.go('/client');
      }
    } on FirebaseAuthException catch (e) {
      // Firebase-specific error messages
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email provided.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        default:
          message = e.message ?? 'Authentication failed.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, st) {
      // Generic / unexpected errors
      debugPrint('SignIn error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            // Prevent overflow if keyboard opens
            child: Column(
              children: [
                const SizedBox(height: 60),
                Image.asset('lib/assets/images/logo/logo.png', height: 100),
                const SizedBox(height: 40),
                const Text('Sign In', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 24),

                // Form with validators
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Email'),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(hintText: 'Password'),
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Navigate to reset password
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),

                // Sign-in button or loading indicator
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Sign In'),
                      ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account? "),
                    GestureDetector(
                      onTap: () {
                        // Navigate to signup flow
                        MaterialPageRoute(builder: (_) => const SignUpStep1Screen());
                      },
                      child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
