// Create marketing_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/offline_service.dart';

class MarketingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineService _offlineService = OfflineService();

  // Create marketing offer with offline support
  Future<void> createMarketingOffer(Map<String, dynamic> offerData) async {
    try {
      final offerId = offerData['id'] ?? 'offer_${DateTime.now().millisecondsSinceEpoch}';
      final completeOfferData = {
        ...offerData,
        'id': offerId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
      };

      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('marketing_offers')
            .doc(offerId)
            .set(completeOfferData);
        print('Marketing offer created online: $offerId');
      } else {
        // Save offline and add to sync queue
        await _offlineService.saveMarketingOfferOffline(completeOfferData);
        await _offlineService.addToSyncQueue('create_marketing_offer', {
          'type': 'marketing',
          'offerData': completeOfferData,
        });
        print('Marketing offer saved offline for sync: $offerId');
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Connection')) {
        await _offlineService.saveMarketingOfferOffline(offerData);
        await _offlineService.addToSyncQueue('create_marketing_offer', {
          'type': 'marketing',
          'offerData': offerData,
        });
      } else {
        throw Exception('Failed to create marketing offer: $e');
      }
    }
  }

  // Get marketing offers with offline fallback (for barbers)
  Stream<List<Map<String, dynamic>>> getBarberMarketingOffers(String barberId) {
    return _firestore
        .collection('marketing_offers')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            // Online data available
            final onlineOffers = snapshot.docs.map((doc) {
              final data = doc.data();
              // Save to offline storage
              _offlineService.saveMarketingOfferOffline(data);
              return data;
            }).toList();
            return onlineOffers;
          } else {
            // Fallback to offline data
            return await _offlineService.getOfflineMarketingOffers(barberId);
          }
        })
        .handleError((error) async {
          print('Online marketing offers error, using offline data: $error');
          return await _offlineService.getOfflineMarketingOffers(barberId);
        });
  }

  // Get marketing offers for clients (active offers only)
  Stream<List<Map<String, dynamic>>> getClientMarketingOffers(String barberId) {
    return _firestore
        .collection('marketing_offers')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.map((doc) => doc.data()).toList();
          } else {
            // Fallback to offline data, filter expired offers
            final offlineOffers = await _offlineService.getOfflineMarketingOffers(barberId);
            return offlineOffers.where((offer) {
              final expiresAt = offer['expiresAt'] ?? 0;
              return expiresAt > DateTime.now().millisecondsSinceEpoch;
            }).toList();
          }
        })
        .handleError((error) async {
          print('Online client offers error, using offline data: $error');
          final offlineOffers = await _offlineService.getOfflineMarketingOffers(barberId);
          return offlineOffers.where((offer) {
            final expiresAt = offer['expiresAt'] ?? 0;
            return expiresAt > DateTime.now().millisecondsSinceEpoch;
          }).toList();
        });
  }

  // Create discount with offline support
  Future<void> createDiscount(Map<String, dynamic> discountData) async {
    try {
      final discountId = discountData['id'] ?? 'discount_${DateTime.now().millisecondsSinceEpoch}';
      final completeDiscountData = {
        ...discountData,
        'id': discountId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
        'redemptionCount': 0,
      };

      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('discounts')
            .doc(discountId)
            .set(completeDiscountData);
        print('Discount created online: $discountId');
      } else {
        // Save offline and add to sync queue
        await _offlineService.saveDiscountOffline(completeDiscountData);
        await _offlineService.addToSyncQueue('create_discount', {
          'type': 'discount',
          'discountData': completeDiscountData,
        });
        print('Discount saved offline for sync: $discountId');
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Connection')) {
        await _offlineService.saveDiscountOffline(discountData);
        await _offlineService.addToSyncQueue('create_discount', {
          'type': 'discount',
          'discountData': discountData,
        });
      } else {
        throw Exception('Failed to create discount: $e');
      }
    }
  }

  // Get discounts for clients (viewable from Firebase)
  Stream<List<Map<String, dynamic>>> getActiveDiscounts(String barberId) {
    return _firestore
        .collection('discounts')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            final onlineDiscounts = snapshot.docs.map((doc) {
              final data = doc.data();
              // Save to offline storage
              _offlineService.saveDiscountOffline(data);
              return data;
            }).toList();
            return onlineDiscounts;
          } else {
            // Fallback to offline data
            return await _offlineService.getAllDiscountsForClient(barberId);
          }
        })
        .handleError((error) async {
          print('Online discounts error, using offline data: $error');
          return await _offlineService.getAllDiscountsForClient(barberId);
        });
  }

  // Deactivate marketing offer
  Future<void> deactivateMarketingOffer(String offerId) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('marketing_offers')
            .doc(offerId)
            .update({'isActive': false});
      } else {
        await _offlineService.addToSyncQueue('deactivate_offer', {
          'type': 'marketing',
          'offerId': offerId,
        });
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Connection')) {
        await _offlineService.addToSyncQueue('deactivate_offer', {
          'type': 'marketing',
          'offerId': offerId,
        });
      } else {
        throw Exception('Failed to deactivate offer: $e');
      }
    }
  }

  // Sync pending marketing operations
  Future<void> syncPendingMarketingOperations() async {
    try {
      final pendingItems = await _offlineService.getPendingSyncItems();
      final marketingItems = pendingItems.where((item) => 
        item['type'] == 'marketing' || item['type'] == 'discount').toList();
      
      for (final item in marketingItems) {
        try {
          switch (item['action']) {
            case 'create_marketing_offer':
              final offerData = Map<String, dynamic>.from(item['data']['offerData']);
              await _firestore
                  .collection('marketing_offers')
                  .doc(offerData['id'])
                  .set(offerData);
              
              await _offlineService.removeFromSyncQueue(item['id']);
              await _offlineService.removeOfflineMarketingOffer(offerData['id']);
              break;
              
            case 'create_discount':
              final discountData = Map<String, dynamic>.from(item['data']['discountData']);
              await _firestore
                  .collection('discounts')
                  .doc(discountData['id'])
                  .set(discountData);
              
              await _offlineService.removeFromSyncQueue(item['id']);
              await _offlineService.removeOfflineDiscount(discountData['id']);
              break;
              
            case 'deactivate_offer':
              await _firestore
                  .collection('marketing_offers')
                  .doc(item['data']['offerId'])
                  .update({'isActive': false});
              
              await _offlineService.removeFromSyncQueue(item['id']);
              break;
          }
          print('Synced marketing operation: ${item['action']}');
        } catch (e) {
          // Update attempt count and retry later
          final attempts = (item['attempts'] ?? 0) + 1;
          await _offlineService.updateSyncItemStatus(item['id'], 'pending', attempts: attempts);
          
          if (attempts >= 3) {
            await _offlineService.updateSyncItemStatus(item['id'], 'failed');
          }
          print('Failed to sync marketing operation ${item['action']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing marketing operations: $e');
    }
  }
}