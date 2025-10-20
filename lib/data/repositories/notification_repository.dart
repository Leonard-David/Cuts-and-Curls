// lib/data/repositories/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'notifications';

  /// Stream notifications for a user in realtime, sorted newest first.
  Stream<List<AppNotification>> streamForUser(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromDoc(d)).toList());
  }

  /// Stream by type (optional)
  Stream<List<AppNotification>> streamForUserAndType(String userId, String type) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromDoc(d)).toList());
  }

  /// Mark a notification as read
  Future<void> markRead(String id) {
    return _firestore.collection(collection).doc(id).update({'read': true});
  }

  /// Batch mark many read
  Future<void> markAllReadForUser(String userId) async {
    final snap = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) batch.update(doc.reference, {'read': true});
    await batch.commit();
  }

  /// Delete notification
  Future<void> delete(String id) => _firestore.collection(collection).doc(id).delete();

  /// Create notification (for backend or test)
  Future<void> create(AppNotification n) async {
    await _firestore.collection(collection).add(n.toMap());
  }
}
