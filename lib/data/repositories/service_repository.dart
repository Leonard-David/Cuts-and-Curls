import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineService _offlineService = OfflineService();

  // Get services with offline fallback
  Stream<List<ServiceModel>> getBarberServices(String barberId) {
    return _firestore
        .collection('services')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        // Online data available 
        final onlineServices = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return ServiceModel.fromMap({...data, 'id': doc.id});
        }).toList();
        return onlineServices;
      } else {
        // Fallback to offline data 
        final offlineServices = await _offlineService.getOfflineServices(barberId);
        return offlineServices.where((service) => service.isActive).toList();
      }
    }).handleError((error) async {
      // On error, return offline data 
      print('Online services error, using offline data: $error');
      final offlineServices = await _offlineService.getOfflineServices(barberId);
      return offlineServices.where((service) => service.isActive).toList();
    });
  }

  // Get all services (including inactive) for barber
  Stream<List<ServiceModel>> getAllBarberServices(String barberId) {
    return _firestore
        .collection('services')
        .where('barberId', isEqualTo: barberId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return ServiceModel.fromMap({...data, 'id': doc.id});
        }).toList());
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
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return ServiceModel.fromMap({...data, 'id': doc.id});
            }).toList());
  }

  // Get real-time service by ID
  Stream<ServiceModel?> getServiceByIdStream(String serviceId) {
    return _firestore
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        return ServiceModel.fromMap({...data, 'id': snapshot.id});
      }
      return null;
    });
  }

  // Create service with offline support
  Future<void> createService(ServiceModel service) async {
    try {
      // First try to save online
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('services')
            .doc(service.id)
            .set(service.toMap());
        print('Service created online: ${service.name}');
      } else {
        // Save offline and add to sync queue
        await _offlineService.saveServiceOffline(service);
        await _offlineService.addToSyncQueue('create_service', {
          'type': 'service',
          'serviceData': service.toMap(),
        });
        print('Service saved offline for sync: ${service.name}');
      }
    } catch (e) {
      // If online fails, save offline
      if (_isNetworkError(e)) {
        await _offlineService.saveServiceOffline(service);
        await _offlineService.addToSyncQueue('create_service', {
          'type': 'service',
          'serviceData': service.toMap(),
        });
        print('Network error - Service saved offline: ${service.name}');
      } else {
        throw Exception('Failed to create service: $e');
      }
    }
  }

  // Update service
  Future<void> updateService(ServiceModel service) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('services')
            .doc(service.id)
            .update(service.toMap());
        print('Service updated online: ${service.name}');
      } else {
        await _offlineService.saveServiceOffline(service);
        await _offlineService.addToSyncQueue('update_service', {
          'type': 'service',
          'serviceId': service.id,
          'serviceData': service.toMap(),
        });
        print('Service update saved offline: ${service.name}');
      }
    } catch (e) {
      if (_isNetworkError(e)) {
        await _offlineService.saveServiceOffline(service);
        await _offlineService.addToSyncQueue('update_service', {
          'type': 'service',
          'serviceId': service.id,
          'serviceData': service.toMap(),
        });
      } else {
        throw Exception('Failed to update service: $e');
      }
    }
  }

  // Delete service with offline support
  Future<void> deleteService(String serviceId) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore.collection('services').doc(serviceId).update({
          'isActive': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('Service deleted online: $serviceId');
      } else {
        // Mark as inactive offline and add to sync queue
        final offlineServices = await _offlineService.getOfflineServices('');
        final service = offlineServices.firstWhere(
          (s) => s.id == serviceId,
          orElse: () => throw Exception('Service not found offline: $serviceId')
        );
        
        final updatedService = service.copyWith(isActive: false);
        await _offlineService.saveServiceOffline(updatedService);
        await _offlineService.addToSyncQueue('delete_service', {
          'type': 'service',
          'serviceId': serviceId,
        });
        print('Service deletion saved offline: $serviceId');
      }
    } catch (e) {
      if (_isNetworkError(e)) {
        await _offlineService.addToSyncQueue('delete_service', {
          'type': 'service',
          'serviceId': serviceId,
        });
      } else {
        throw Exception('Failed to delete service: $e');
      }
    }
  }

  // Get service by ID (one-time fetch)
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return ServiceModel.fromMap({...data, 'id': doc.id});
      }
      
      // Fallback to offline data
      final offlineServices = await _offlineService.getOfflineServices('');
      return offlineServices.firstWhere(
        (service) => service.id == serviceId,
        orElse: () => throw Exception('Service not found: $serviceId')
      );
    } catch (e) {
      print('Error getting service by ID: $e');
      return null;
    }
  }

  // Sync pending operations when back online
  Future<void> syncPendingOperations() async {
    try {
      final pendingItems = await _offlineService.getPendingSyncItems();
      final serviceItems = pendingItems.where((item) => item['type'] == 'service').toList();

      print('Syncing ${serviceItems.length} service operations...');

      for (final item in serviceItems) {
        try {
          switch (item['action']) {
            case 'create_service':
              final serviceData = Map<String, dynamic>.from(item['data']['serviceData']);
              await _firestore
                  .collection('services')
                  .doc(serviceData['id'])
                  .set(serviceData);
              await _offlineService.removeFromSyncQueue(item['id']);
              await _offlineService.removeOfflineService(serviceData['id']);
              print('Synced service creation: ${serviceData['name']}');
              break;

            case 'update_service':
              final serviceData = Map<String, dynamic>.from(item['data']['serviceData']);
              await _firestore
                  .collection('services')
                  .doc(item['data']['serviceId'])
                  .update(serviceData);
              await _offlineService.removeFromSyncQueue(item['id']);
              await _offlineService.removeOfflineService(item['data']['serviceId']);
              print('Synced service update: ${serviceData['name']}');
              break;

            case 'delete_service':
              await _firestore
                  .collection('services')
                  .doc(item['data']['serviceId'])
                  .update({
                'isActive': false,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              });
              await _offlineService.removeFromSyncQueue(item['id']);
              await _offlineService.removeOfflineService(item['data']['serviceId']);
              print('Synced service deletion: ${item['data']['serviceId']}');
              break;
          }
        } catch (e) {
          // Update attempt count and retry later
          final attempts = (item['attempts'] ?? 0) + 1;
          await _offlineService.updateSyncItemStatus(item['id'], 'pending', attempts: attempts);

          if (attempts >= 3) {
            // Mark as failed after 3 attempts
            await _offlineService.updateSyncItemStatus(item['id'], 'failed');
            print('Failed to sync service operation after 3 attempts: ${item['action']}');
          }
          print('Failed to sync service operation ${item['action']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing service operations: $e');
    }
  }

  // Helper method to check for network errors
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('network') ||
        errorString.contains('Connection') ||
        errorString.contains('Socket') ||
        errorString.contains('timed out');
  }

  // Get services by category
  Stream<List<ServiceModel>> getServicesByCategory(String barberId, String category) {
    return _firestore
        .collection('services')
        .where('barberId', isEqualTo: barberId)
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return ServiceModel.fromMap({...data, 'id': doc.id});
        }).toList());
  }

  // Search services
  Stream<List<ServiceModel>> searchServices(String barberId, String query) {
    return _firestore
        .collection('services')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                final name = data['name']?.toString().toLowerCase() ?? '';
                final description = data['description']?.toString().toLowerCase() ?? '';
                final searchQuery = query.toLowerCase();
                return name.contains(searchQuery) || description.contains(searchQuery);
              })
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return ServiceModel.fromMap({...data, 'id': doc.id});
              })
              .toList();
        });
  }
}