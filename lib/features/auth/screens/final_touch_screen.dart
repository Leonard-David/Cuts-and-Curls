// lib/features/auth/presentation/final_touch_screen.dart
//
// --------------------------------------------------------
// Step 4: Upload profile picture to Firebase Storage
// --------------------------------------------------------

import 'dart:io';
import 'package:cutscurls/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class FinalTouchScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FinalTouchScreen({super.key, required this.userData});

  @override
  State<FinalTouchScreen> createState() => _FinalTouchScreenState();
}

class _FinalTouchScreenState extends State<FinalTouchScreen> {
  File? _image;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _upload() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // upload profile picture
    String? imageUrl;
    if (_image != null) {
      final ref = FirebaseStorage.instance.ref('profiles/$uid.jpg');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    }

    // save user details to Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...widget.userData,
      'profileImage': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    context.go('/'); // route handled by user role afterwards
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text('Final Touch',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.add, color: AppColors.primary, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add profile picture'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _upload,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
