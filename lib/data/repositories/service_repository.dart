// lib/data/repositories/service_repository.dart
// CRUD & streaming for /services collection.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final CollectionReference _servicesRef = FirebaseFirestore.instance.collection('services');

  ServiceRepository();

  /// Create a new service for a barber. Returns generated document id.
  Future<String> createService(ServiceModel service) async {
    final docRef = await _servicesRef.add(service.toMap());
    return docRef.id;
  }

  /// Update existing service (partial update supported).
  Future<void> updateService(String serviceId, Map<String, dynamic> updates) async {
    await _servicesRef.doc(serviceId).update(updates);
  }

  /// Delete a service.
  Future<void> deleteService(String serviceId) async {
    await _servicesRef.doc(serviceId).delete();
  }

  /// Stream services for a barber (real-time).
  Stream<List<ServiceModel>> streamServicesForBarber(String barberId) {
    return _servicesRef.where('barberId', isEqualTo: barberId).snapshots().map((snap) {
      return snap.docs.map((d) => ServiceModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    });
  }

  /// Get services one-off for a barber.
  Future<List<ServiceModel>> getServicesForBarber(String barberId) async {
    final snap = await _servicesRef.where('barberId', isEqualTo: barberId).get();
    return snap.docs.map((d) => ServiceModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
  }
}
