// lib/features/auth/screens/signup_step2_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class SignUpStep2Screen extends ConsumerStatefulWidget {
  const SignUpStep2Screen({super.key, required Map<String, dynamic> prevData});

  @override
  ConsumerState<SignUpStep2Screen> createState() => _SignUpStep2ScreenState();
}

class _SignUpStep2ScreenState extends ConsumerState<SignUpStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  File? _profileImage;
  List<File> _portfolioImages = [];
  bool _isUploading = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _pickPortfolioImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _portfolioImages = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No authenticated user found. Please log in again.'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      String? profileImageUrl;
      final storage = FirebaseStorage.instance;

      // Upload profile image if selected
      if (_profileImage != null) {
        final ref = storage.ref().child('profile_images/${user.uid}.jpg');
        await ref.putFile(_profileImage!);
        profileImageUrl = await ref.getDownloadURL();
      }

      // Upload portfolio images
      final List<String> portfolioUrls = [];
      for (var i = 0; i < _portfolioImages.length; i++) {
        final file = _portfolioImages[i];
        final ref = storage.ref().child('portfolio/${user.uid}/image_$i.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        portfolioUrls.add(url);
      }

      // Update Firestore user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'phone': _phoneController.text.trim(),
            'bio': _bioController.text.trim(),
            'profileImage': profileImageUrl,
            'portfolio': portfolioUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Optionally send email verification here
      await user.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved! Please verify your email.'),
        ),
      );

      // Navigate to email verification screen next
      context.go('/verify-email');
    } catch (e, st) {
      debugPrint('Profile upload error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete your profile'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Add your details and portfolio to complete your account setup.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Profile image picker
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.border,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+264 81 234 5678',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter phone number';
                        if (v.trim().length < 7) return 'Invalid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Short bio',
                        hintText: 'Describe yourself or your services...',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter a short bio';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Portfolio images picker
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickPortfolioImages,
                  icon: const Icon(Icons.collections, color: AppColors.primary),
                  label: const Text('Add Portfolio Images'),
                ),
              ),

              if (_portfolioImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _portfolioImages.length,
                    separatorBuilder: (context, state) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _portfolioImages[i],
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 30),

              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Finish Setup'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}