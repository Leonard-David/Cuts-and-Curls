import 'package:cutscurls/features/auth/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';

//import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedRole = 'client';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _signUp() async {
    // Simple validation
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final email = await _askForEmail();
    if (email == null) return;
    final password = await _askForPassword();
    if (password == null) return;

    final authRepo = AuthRepository();
    final userRepo = UserRepository();

    try {
      // 1️⃣ Create user account
      final user = await authRepo.signUpWithEmail(
        name: "${_firstNameController.text} ${_lastNameController.text}",
        email: email,
        password: password,
        role: _selectedRole,
      );

      // 2️⃣ Store additional data
      if (user != null) {
        await userRepo.createOrUpdateUser(user.uid, {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'dob': _dobController.text,
          'role': _selectedRole,
          'email': email,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign-up failed')));
    }
  }

  Future<String?> _askForEmail() async {
    String? email;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter your Email'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                email = controller.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return email;
  }

  Future<String?> _askForPassword() async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Set Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = controller.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Image.asset('lib/assets/images/logo/logo.png', height: 100),
                const SizedBox(height: 10),
                const SizedBox(height: 40),
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(hintText: 'First name'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(hintText: 'Last name'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _dobController,
                  readOnly: true,
                  decoration: const InputDecoration(hintText: 'Date of birth'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      initialDate: DateTime(2000),
                    );
                    if (date != null) {
                      _dobController.text =
                          '${date.year}-${date.month}-${date.day}';
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(hintText: 'Select role'),
                  items: const [
                    DropdownMenuItem(value: 'client', child: Text('Client')),
                    DropdownMenuItem(value: 'barber', child: Text('Barber')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
