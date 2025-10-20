import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimens.dart';

class FinalTouchScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const FinalTouchScreen({super.key, this.userData});

  @override
  State<FinalTouchScreen> createState() => _FinalTouchScreenState();
}

class _FinalTouchScreenState extends State<FinalTouchScreen> {
  File? _image;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  // Upload image and save to Firestore
  Future<void> _uploadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if email is verified
    if (!user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email before proceeding.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      String? imageUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref().child('profiles/${user.uid}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      // Update Firestore record
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImage': imageUrl,
        'emailVerified': true, // Mark as verified in Firestore too
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate based on user role
      final role = widget.userData?['role'] ?? 'Client';
      if (role == 'Barber' || role == 'barber' || role == 'hairdresser') {
        context.go('/barber');
      } else {
        context.go('/client');
      }
    } catch (e, st) {
      debugPrint('Profile upload error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload profile picture. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isVerified = user?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Final Touch'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.paddingXXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isVerified) ...[
                Container(
                  padding: const EdgeInsets.all(Dimens.paddingLG),
                  margin: const EdgeInsets.only(bottom: Dimens.paddingXXL),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(Dimens.borderRadiusMedium),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: Dimens.paddingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Not Verified',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please verify your email to complete profile setup.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  user?.sendEmailVerification();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Verification email sent!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[700],
                                  side: BorderSide(color: Colors.orange[700]!),
                                ),
                                child: const Text('Resend Verification Email'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Text(
                "Add a profile picture",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This helps others recognize you on SheerSync.",
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Profile Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.add_a_photo, color: AppColors.primary, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 40),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _loading
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
                            const Text('Uploading...'),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isVerified ? _uploadProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isVerified ? AppColors.primary : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.borderRadiusMedium),
                          ),
                        ),
                        child: Text(
                          isVerified ? "Complete Profile" : "Verify Email First",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}