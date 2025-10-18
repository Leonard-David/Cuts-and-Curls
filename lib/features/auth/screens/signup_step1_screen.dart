// lib/features/auth/screens/signup_step1_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../auth/controllers/auth_provider.dart';

class SignUpStep1Screen extends ConsumerStatefulWidget {
  const SignUpStep1Screen({super.key});

  @override
  ConsumerState<SignUpStep1Screen> createState() => _SignUpStep1ScreenState();
}

class _SignUpStep1ScreenState extends ConsumerState<SignUpStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _role = 'client'; // default role
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Basic validators
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your name';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter email';
    final email = v.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter password';
    if (v.trim().length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Defensive checks
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);

    try {
      // Create user and Firestore profile inside repository
      final user = await authRepo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        role: _role,
      );

      if (user == null) {
        // Unexpected null -> show generic error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup failed. Please try again.')),
        );
        return;
      }

      // On success: route to next signup step (collect additional info / verification)
      if (!mounted) return;
      context.go('/signup-step2'); // ensure this route is registered
    } on FirebaseAuthException catch (e) {
      // Map common firebase errors to friendly messages
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'Signup failed. Try again.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, st) {
      // Generic / unexpected errors
      debugPrint('Signup Step1 error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Small role toggle UI: easily extensible (e.g., later add role verification)
  Widget _roleSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            value: 'client',
            groupValue: _role,
            onChanged: (v) => setState(() => _role = v!),
            title: const Text('Client'),
            subtitle: const Text('Book services, pay, chat with barbers'),
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            value: 'barber',
            groupValue: _role,
            onChanged: (v) => setState(() => _role = v!),
            title: const Text('Barber / Hairdresser'),
            subtitle: const Text('Manage bookings & promote services'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Optional: brand logo
              Image.asset('lib/assets/images/logo/logo.png', height: 80),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Full name', hintText: 'John Doe'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'At least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),

                    // Role selector
                    _roleSelector(),

                    const SizedBox(height: 20),

                    // Submit button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                            child: const Text('Continue'),
                          ),

                    const SizedBox(height: 12),
                    // Link to sign in if they already have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: () {
                            context.go('/'); // should route to sign-in or auth wrapper
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
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
