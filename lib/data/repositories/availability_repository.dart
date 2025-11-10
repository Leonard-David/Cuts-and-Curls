// Create availability_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/offline_service.dart';

class AvailabilityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineService _offlineService = OfflineService();

  // Save availability with offline support
  Future<void> saveAvailability(String barberId, Map<String, dynamic> availabilityData) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('barber_availability')
            .doc(barberId)
            .set(availabilityData, SetOptions(merge: true));
        print('Availability saved online for barber: $barberId');
      } else {
        // Save offline and add to sync queue
        await _offlineService.saveAvailabilityOffline(availabilityData);
        await _offlineService.addToSyncQueue('save_availability', {
          'type': 'availability',
          'barberId': barberId,
          'availabilityData': availabilityData,
        });
        print('Availability saved offline for sync: $barberId');
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Connection')) {
        await _offlineService.saveAvailabilityOffline( availabilityData);
        await _offlineService.addToSyncQueue('save_availability', {
          'type': 'availability',
          'barberId': barberId,
          'availabilityData': availabilityData,
        });
      } else {
        throw Exception('Failed to save availability: $e');
      }
    }
  }

  // Get availability with offline fallback
  Future<Map<String, dynamic>> getAvailability(String barberId) async {
    try {
      if (await _offlineService.isConnected()) {
        final doc = await _firestore
            .collection('barber_availability')
            .doc(barberId)
            .get();

        if (doc.exists) {
          final data = doc.data() ?? {};
          // Also save to offline storage for future use
          await _offlineService.saveAvailabilityOffline(data);
          return data;
        } else {
          // Return empty availability if not found
          return _getDefaultAvailability();
        }
      } else {
        // Return offline data
        final offlineData = await _offlineService.getOfflineAvailability(barberId);
        return offlineData ?? _getDefaultAvailability();
      }
    } catch (e) {
      print('Error getting availability, using offline data: $e');
      final offlineData = await _offlineService.getOfflineAvailability(barberId);
      return offlineData ?? _getDefaultAvailability();
    }
  }

  // Stream for real-time availability updates
  Stream<Map<String, dynamic>> getAvailabilityStream(String barberId) {
    return _firestore
        .collection('barber_availability')
        .doc(barberId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.exists) {
            final data = snapshot.data() ?? {};
            // Save to offline storage
            await _offlineService.saveAvailabilityOffline(data);
            return data;
          } else {
            return _getDefaultAvailability();
          }
        })
        .handleError((error) async {
          print('Online availability error, using offline data: $error');
          final offlineData = await _offlineService.getOfflineAvailability(barberId);
          return offlineData ?? _getDefaultAvailability();
        });
  }

  // Sync pending availability operations
  Future<void> syncPendingAvailabilityOperations() async {
    try {
      final pendingItems = await _offlineService.getPendingSyncItems();
      final availabilityItems = pendingItems.where((item) => item['type'] == 'availability').toList();
      
      for (final item in availabilityItems) {
        try {
          if (item['action'] == 'save_availability') {
            await _firestore
                .collection('barber_availability')
                .doc(item['data']['barberId'])
                .set(item['data']['availabilityData'], SetOptions(merge: true));
            
            await _offlineService.removeFromSyncQueue(item['id']);
            print('Synced availability for barber: ${item['data']['barberId']}');
          }
        } catch (e) {
          // Update attempt count and retry later
          final attempts = (item['attempts'] ?? 0) + 1;
          await _offlineService.updateSyncItemStatus(item['id'], 'pending', attempts: attempts);
          
          if (attempts >= 3) {
            await _offlineService.updateSyncItemStatus(item['id'], 'failed');
          }
          print('Failed to sync availability operation: $e');
        }
      }
    } catch (e) {
      print('Error syncing availability operations: $e');
    }
  }

  Map<String, dynamic> _getDefaultAvailability() {
    // Return default empty availability structure
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final defaultAvailability = <String, dynamic>{};
    
    for (final day in days) {
      defaultAvailability[day] = [];
    }
    
    return defaultAvailability;
  }
}