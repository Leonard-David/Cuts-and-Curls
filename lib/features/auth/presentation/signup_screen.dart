import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  UserRole role = UserRole.client;
  bool loading = false;
  String? error;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final repo = ref.read(authRepoProvider);
      final user = await repo.signUpWithEmail(email, password, role);
      // On success -> navigate to appropriate screen (hook into router)
      // For now pop back to login
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${user.email} — role: ${user.role.name}')),
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Column(
                          children: [
                            Image.asset('assets/images/logo.png', height: 84, fit: BoxFit.contain),
                            const SizedBox(height: 12),
                            const Text('Create account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                              onSaved: (v) => email = v!.trim(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Password'),
                              obscureText: true,
                              validator: (v) => (v == null || v.length < 6) ? 'Password >= 6 chars' : null,
                              onSaved: (v) => password = v!.trim(),
                            ),
                            const SizedBox(height: 12),

                            // Role selector
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Client'),
                                    selected: role == UserRole.client,
                                    selectedColor: const Color(0xFFFBA506),
                                    onSelected: (s) => setState(() => role = UserRole.client),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Barber / Hairdresser'),
                                    selected: role == UserRole.barber,
                                    selectedColor: const Color(0xFFFBA506),
                                    onSelected: (s) => setState(() => role = UserRole.barber),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                            ElevatedButton(
                              onPressed: loading ? null : _submit,
                              child: loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Create account'),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                              child: const Text('Already have an account? Log in'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
