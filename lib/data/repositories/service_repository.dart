import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get services for barber (for barber's view)
  Stream<List<ServiceModel>> getBarberServices(String barberId) {
    return _getServicesQuery(barberId);
  }

  // Get all active services (for clients to view)
  Stream<List<ServiceModel>> getBarberServicesForClient(String barberId) {
    return _getServicesQuery(barberId);
  }

  // Get services with real-time updates for specific barber
  Stream<List<ServiceModel>> getBarberServicesStream(String barberId) {
    return _getServicesQuery(barberId);
  }

  // Private helper method to avoid code duplication
  Stream<List<ServiceModel>> _getServicesQuery(String barberId) {
    return _firestore
        .collection('services')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return ServiceModel.fromMap(data);
            })
            .toList());
  }

  // Get real-time service by ID
  Stream<ServiceModel?> getServiceByIdStream(String serviceId) {
    return _firestore
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return ServiceModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  // Create new service
  Future<void> createService(ServiceModel service) async {
    try {
      await _firestore
          .collection('services')
          .doc(service.id)
          .set(service.toMap());
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  // Update service
  Future<void> updateService(ServiceModel service) async {
    try {
      await _firestore
          .collection('services')
          .doc(service.id)
          .update(service.toMap());
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  // Delete service (soft delete)
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  // Get service by ID (one-time fetch)
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get service: $e');
    }
  }
}