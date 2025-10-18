import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'services';

  Future<void> addService(ServiceModel service) async {
    await _firestore.collection(collectionPath).add(service.toMap());
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(id).update(data);
  }

  Future<void> deleteService(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  Stream<List<ServiceModel>> getServicesForBarber(String barberId) {
    return _firestore
        .collection(collectionPath)
        .where('barberId', isEqualTo: barberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
