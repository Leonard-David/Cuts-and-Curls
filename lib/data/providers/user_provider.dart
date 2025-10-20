// lib/data/providers/user_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides current FirebaseAuth User object (nullable)
final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provides current user's Firestore document as Map<String, dynamic>
final currentUserDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  return docRef.snapshots().map((snap) {
    if (!snap.exists) return null;
    return {...snap.data()!, 'uid': snap.id};
  });
});
