// lib/data/repositories/user_repository.dart
// CRUD and streaming helpers for /users collection.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  // ignore: unused_field
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection('users');

  UserRepository();

  /// Fetch user document once by uid.
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Create or update a user profile. Overwrites fields in the document with provided map.
  Future<void> createOrUpdateUser(String uid, Map<String, dynamic> data) async {
    // Keep createdAt if already present
    final snapshot = await _usersRef.doc(uid).get();
    if (!snapshot.exists) {
      data['createdAt'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _usersRef.doc(uid).set(data);
    } else {
      await _usersRef.doc(uid).update(data);
    }
  }

  /// Stream realtime updates for a user document.
  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  /// Query barbers near a location or by search. This is a simple example: fetch barbers, filter client-side.
  /// For production use consider GeoFire / geohashing.
  Future<List<UserModel>> fetchAllBarbers() async {
    final snapshot = await _usersRef.where('role', isEqualTo: 'barber').get();
    return snapshot.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
  }
}
