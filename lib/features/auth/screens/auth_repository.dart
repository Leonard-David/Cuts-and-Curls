import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

enum UserRole { client, barber }

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  AppUser({required this.uid, required this.email, required this.role});
  Map<String, dynamic> toMap() => {'uid': uid, 'email': email, 'role': role.name, 'createdAt': FieldValue.serverTimestamp()};
  static UserRole roleFromString(String s) => s == 'barber' ? UserRole.barber : UserRole.client;
}

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signUpWithEmail(String email, String password, UserRole role);
  Future<AppUser> signInWithEmail(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.userChanges().asyncMap((fb.User? u) async {
      if (u == null) return null;
      final doc = await _firestore.collection('users').doc(u.uid).get();
      if (!doc.exists) {
        // no role saved yet -> default to client
        return AppUser(uid: u.uid, email: u.email ?? '', role: UserRole.client);
      }
      final data = doc.data()!;
      return AppUser(uid: u.uid, email: data['email'] ?? '', role: AppUser.roleFromString(data['role'] ?? 'client'));
    });
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password, UserRole role) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final u = cred.user!;
    final userMap = {'uid': u.uid, 'email': email, 'role': role.name, 'createdAt': FieldValue.serverTimestamp()};
    await _firestore.collection('users').doc(u.uid).set(userMap);
    return AppUser(uid: u.uid, email: email, role: role);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final u = cred.user!;
    final doc = await _firestore.collection('users').doc(u.uid).get();
    final role = doc.exists ? AppUser.roleFromString(doc.data()?['role'] ?? 'client') : UserRole.client;
    return AppUser(uid: u.uid, email: u.email ?? '', role: role);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
