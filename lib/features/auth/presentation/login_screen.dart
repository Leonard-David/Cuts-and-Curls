// lib/features/auth/presentation/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

/// Colors (from your spec)
class AppColors {
  static const Color text = Color(0xFF6D6D6D);
  static const Color accent = Color(0xFFFBA506);
  static const Color bg = Color(0xFFF4F5FF);
  static const Color button = Color(0xFF0F2E4A);
  static const Color notify = Color(0xFF2BFF00);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // Sign in using Firebase Auth and ensure a minimal user doc in Firestore
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      final user = cred.user;
      if (user != null) {
        // Ensure user doc exists (backend)
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? '',
            'role': 'client', // default role on sign-in if not present
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // success - try to route to /home (you can replace '/home' with your route)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Welcome ${user.email}'),
          backgroundColor: AppColors.notify.withOpacity(0.12),
          behavior: SnackBarBehavior.floating,
        ));

        // If you use named routes, pushReplacementNamed('/home'), otherwise fallback to popping.
        // We attempt to navigate to '/home' but if that's not registered we'll just pop.
        try {
          Navigator.of(context).pushReplacementNamed('/home');
        } catch (_) {
          // route not defined yet — just pop if possible
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } on fb.FirebaseAuthException catch (e) {
      String msg = 'Authentication error';
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found for that email.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'invalid-email':
          msg = 'Email address is invalid.';
          break;
        case 'user-disabled':
          msg = 'This user has been disabled.';
          break;
        default:
          msg = e.message ?? e.code;
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_email.isEmpty || !_email.contains('@')) {
      setState(() => _error = 'Enter your email first to receive reset link.');
      return;
    }
    setState(() => _loading = true);
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset link sent to your email.'),
        behavior: SnackBarBehavior.floating,
      ));
    } on fb.FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Could not send reset email.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo + Title (matches uploaded design)
                  Column(
                    children: [
                      Image.asset('assets/images/logo.png', height: 92, fit: BoxFit.contain),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF6D6D6D)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(color: AppColors.text.withOpacity(0.9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Card container
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const Key('email-field'),
                              decoration: const InputDecoration(hintText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                              onSaved: (v) => _email = v!.trim(),
                              onChanged: (v) => _email = v.trim(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('password-field'),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                              obscureText: _obscure,
                              validator: (v) => v == null || v.length < 6 ? 'Password must be >= 6 chars' : null,
                              onSaved: (v) => _password = v!.trim(),
                              onChanged: (v) => _password = v.trim(),
                            ),
                            const SizedBox(height: 12),

                            // Error text
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(_error!, style: const TextStyle(color: Colors.red)),
                              ),

                            // Sign in button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.button,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _loading ? null : _signIn,
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _sendPasswordReset,
                                child: const Text('Forgot password?', style: TextStyle(fontSize: 14)),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Divider + sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?", style: TextStyle(color: Color(0xFF6D6D6D))),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          // push to '/signup' route if defined, otherwise push named route
                                          try {
                                            Navigator.of(context).pushNamed('/signup');
                                          } catch (_) {
                                            // fallback: do nothing (signup screen not yet created)
                                          }
                                        },
                                  child: Text('Create account', style: TextStyle(color: AppColors.button)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Minimal footer / loader per the uploaded screens
                  if (_loading)
                    Column(
                      children: const [
                        SizedBox(height: 8),
                        CircularProgressIndicator(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
