import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _role = 'Client';
  bool _agree = false;
  bool _loading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || !_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and accept the terms.")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      // 1️ Create user in Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;

      // 2 Create user doc in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'role': _role,
        'profileImage': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️ Proceed to profile picture upload
      if (!mounted) return;
      context.go('/final_touch', extra: {
        'uid': uid,
        'firstName': _firstName.text,
        'lastName': _lastName.text,
        'email': _email.text,
        'role': _role,
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Sign up failed")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset( 'lib/assets/images/logo/logo.png',height: 100),
              const SizedBox(height: 16),
              const Text(
                "Join VerveBook",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // First Name
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (v) => v!.isEmpty ? "Enter first name" : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (v) => v!.isEmpty ? "Enter last name" : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) =>
                    v!.isEmpty || !v.contains("@") ? "Enter valid email" : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (v) =>
                    v!.length < 6 ? "Password must be at least 6 characters" : null,
              ),
              const SizedBox(height: 16),

              // Role Selector
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: "Select Role"),
                items: const [
                  DropdownMenuItem(value: 'Client', child: Text('Client')),
                  DropdownMenuItem(value: 'Barber', child: Text('Barber')),
                  DropdownMenuItem(value: 'Hair Stylist', child: Text('Hair Stylist')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),

              // Terms Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    onChanged: (v) => setState(() => _agree = v!),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the Terms & Conditions and Privacy Policy",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sign Up Button
              ElevatedButton(
                onPressed: _loading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),

              // Already have an account
              TextButton(
                onPressed: () => context.go('/signin'),
                child: const Text("Already have an account? Sign in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
