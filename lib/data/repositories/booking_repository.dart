import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/firestore_helper.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/repositories/notification_repository.dart';

class BookingRepository {
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  final OfflineService _offlineService = OfflineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _appointmentsCollection =
      FirebaseFirestore.instance.collection('appointments');

  // Create appointment with offline support
  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      // Validate appointment data
      if (appointment.barberId.isEmpty || appointment.clientId.isEmpty) {
        throw Exception('Invalid appointment data: missing required fields');
      }

      // Check if barber exists and is active
      final barberDoc =
          await _firestore.collection('users').doc(appointment.barberId).get();
      if (!barberDoc.exists || (barberDoc.data()?['isActive'] != true)) {
        throw Exception('Barber not found or inactive');
      }

      if (await _offlineService.isConnected()) {
        // Check for duplicate appointments
        final existingAppointments = await _firestore
            .collection('appointments')
            .where('barberId', isEqualTo: appointment.barberId)
            .where('clientId', isEqualTo: appointment.clientId)
            .where('date', isEqualTo: appointment.date.millisecondsSinceEpoch)
            .where('status', whereIn: ['pending', 'confirmed']).get();

        if (existingAppointments.docs.isNotEmpty) {
          throw Exception('You already have an appointment at this time');
        }

        // Create appointment with transaction for data consistency
        await _firestore.runTransaction((transaction) async {
          transaction.set(
            _firestore.collection('appointments').doc(appointment.id),
            appointment.toMap(),
          );
        });

        // Send notification
        await _notificationRepository.sendAppointmentRequestToBarber(
          barberId: appointment.barberId,
          appointmentId: appointment.id,
          clientName: appointment.clientName ?? 'Client',
          serviceName: appointment.serviceName ?? 'Service',
          appointmentTime: appointment.date,
          sendPush: true,
        );

        print('✅ Appointment created successfully: ${appointment.id}');
      } else {
        // Offline fallback with enhanced error handling
        await _offlineService.saveAppointmentOffline(appointment);
        await _offlineService.addToSyncQueue('create_appointment', {
          'type': 'appointment',
          'appointmentData': appointment.toMap(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('📱 Appointment saved offline: ${appointment.id}');
      }
    } catch (e) {
      print('❌ Failed to create appointment: $e');
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  // Update appointment status with offline support
  // and status update with bidirectional notifications
  Future<void> updateAppointmentStatus(String appointmentId, String status,
      {String? reason, required String currentUserId}) async {
    // Add required parameter
    try {
      if (await _offlineService.isConnected()) {
        // Get appointment details
        final appointmentDoc = await _firestore
            .collection('appointments')
            .doc(appointmentId)
            .get();

        if (!appointmentDoc.exists) {
          throw Exception('Appointment not found');
        }

        final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);
        final barber = await _getUserById(appointment.barberId);
        final client = await _getUserById(appointment.clientId);

        // Update status in Firestore
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': status,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          if (reason != null) 'cancellationReason': reason,
        });

        // Determine who initiated the action and send appropriate notifications
        final isBarberAction = currentUserId == appointment.barberId;

        if (isBarberAction) {
          // Barber action → notify client
          await _notificationRepository.sendAppointmentStatusToClient(
            clientId: appointment.clientId,
            appointmentId: appointmentId,
            status: status,
            barberName: barber?.fullName ?? 'Professional',
            serviceName: appointment.serviceName ?? 'Service',
            reason: reason,
            sendPush: true,
          );
        } else {
          // Client action → notify barber
          if (status == 'cancelled') {
            await _notificationRepository.sendClientCancellationToBarber(
              barberId: appointment.barberId,
              appointmentId: appointmentId,
              clientName: client?.fullName ?? 'Client',
              serviceName: appointment.serviceName ?? 'Service',
              reason: reason,
              sendPush: true,
            );
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('network') ||
          e.toString().contains('Connection')) {
        await _offlineService.addToSyncQueue('update_appointment_status', {
          'type': 'appointment',
          'appointmentId': appointmentId,
          'status': status,
        });
      } else {
        throw Exception('Failed to update appointment status: $e');
      }
    }
  }

  // Sync pending appointment operations
  Future<void> syncPendingAppointmentOperations() async {
    try {
      final pendingItems = await _offlineService.getPendingSyncItems();
      final appointmentItems =
          pendingItems.where((item) => item['type'] == 'appointment').toList();

      for (final item in appointmentItems) {
        try {
          switch (item['action']) {
            case 'create_appointment':
              final appointmentData =
                  Map<String, dynamic>.from(item['data']['appointmentData']);
              await _firestore
                  .collection('appointments')
                  .doc(appointmentData['id'])
                  .set(appointmentData);
              await _offlineService.removeFromSyncQueue(item['id']);
              await _offlineService
                  .removeOfflineAppointment(appointmentData['id']);
              break;

            case 'update_appointment_status':
              await _firestore
                  .collection('appointments')
                  .doc(item['data']['appointmentId'])
                  .update({
                'status': item['data']['status'],
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              });
              break;
          }
          print('Synced appointment operation: ${item['action']}');
        } catch (e) {
          // Update attempt count and retry later
          final attempts = (item['attempts'] ?? 0) + 1;
          await _offlineService.updateSyncItemStatus(item['id'], 'pending',
              attempts: attempts);

          if (attempts >= 3) {
            await _offlineService.updateSyncItemStatus(item['id'], 'failed');
          }
          print('Failed to sync appointment operation ${item['action']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing appointment operations: $e');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Reschedule appointment
  // Enhanced reschedule with notifications
  // Enhanced reschedule with notifications
  Future<void> rescheduleAppointment(
      String appointmentId, DateTime newDate, String currentUserId) async {
    // Add required parameter
    try {
      // Get appointment details
      final appointmentDoc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);
      final barber = await _getUserById(appointment.barberId);
      final client = await _getUserById(appointment.clientId);

      // Update in Firestore
      await _firestore.collection('appointments').doc(appointmentId).update({
        'date': newDate.millisecondsSinceEpoch,
        'status': 'rescheduled',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Determine who initiated reschedule
      final isBarberAction = currentUserId == appointment.barberId;

      if (isBarberAction) {
        // Barber rescheduled → notify client
        await _notificationRepository.sendAppointmentStatusToClient(
          clientId: appointment.clientId,
          appointmentId: appointmentId,
          status: 'rescheduled',
          barberName: barber?.fullName ?? 'Professional',
          serviceName: appointment.serviceName ?? 'Service',
          newAppointmentTime: newDate,
          sendPush: true,
        );
      } else {
        // Client rescheduled → notify barber
        await _notificationRepository.sendClientRescheduleToBarber(
          barberId: appointment.barberId,
          appointmentId: appointmentId,
          clientName: client?.fullName ?? 'Client',
          serviceName: appointment.serviceName ?? 'Service',
          newAppointmentTime: newDate,
          sendPush: true,
        );
      }

      print('✅ Appointment rescheduled with notifications');
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  // Helper method to get user details
  Future<UserModel?> _getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? UserModel.fromMap(doc.data()!) : null;
    } catch (e) {
      return null;
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _appointmentsCollection.doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  // Get appointments with offline fallback
  Stream<List<AppointmentModel>> getBarberAppointments(String barberId) {
    return _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .orderBy('date', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        // Online data available
        return snapshot.docs.map((doc) {
          final data = FirestoreHelper.safeExtractQueryData(doc);
          return AppointmentModel.fromMap(data);
        }).toList();
      } else {
        // Fallback to offline data
        return await _offlineService.getOfflineAppointments(barberId, 'barber');
      }
    }).handleError((error) async {
      // On error, return offline data
      print('Online appointments error, using offline data: $error');
      return await _offlineService.getOfflineAppointments(barberId, 'barber');
    });
  }

  // Get all appointments for a client (real-time)
  Stream<List<AppointmentModel>> getClientAppointments(String clientId) {
    return _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreHelper.safeExtractQueryData(doc);
              return AppointmentModel.fromMap(data);
            }).toList());
  }

  // Get availble barbers
  Stream<List<UserModel>> getAvailableBarbers() {
    return _firestore
        .collection('users')
        .where('userType', whereIn: ['barber', 'hairstylist'])
        .where('isOnline', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Get appointment requests (pending appointments from clients for barber)
  Stream<List<AppointmentModel>> getAppointmentRequests(String barberId) {
    return _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'pending')
        .where('clientId', isNotEqualTo: null)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
  }

  // Get today's appointments for barber
  Stream<List<AppointmentModel>> getTodaysAppointments(String barberId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .where('date',
            isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .where('date', isLessThan: endOfDay.millisecondsSinceEpoch)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = FirestoreHelper.safeExtractQueryData(doc);
            return AppointmentModel.fromMap(data);
          }).toList();
        });
  }

  // Get today's appointments for client
  Stream<List<AppointmentModel>> getClientTodaysAppointments(String clientId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _appointmentsCollection
        .where('clientId', isEqualTo: clientId)
        .where('date',
            isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .where('date', isLessThan: endOfDay.millisecondsSinceEpoch)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = FirestoreHelper.safeExtractQueryData(doc);
            return AppointmentModel.fromMap(data);
          }).toList();
        });
  }

  // Get upcoming appointments for barber (excluding today)
  Stream<List<AppointmentModel>> getUpcomingAppointments(String barberId) {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

    return _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .where('date',
            isGreaterThanOrEqualTo: startOfTomorrow.millisecondsSinceEpoch)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = FirestoreHelper.safeExtractQueryData(doc);
            return AppointmentModel.fromMap(data);
          }).toList();
        });
  }

  // Get upcoming appointments for client (excluding today)
  Stream<List<AppointmentModel>> getClientUpcomingAppointments(
      String clientId) {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

    return _appointmentsCollection
        .where('clientId', isEqualTo: clientId)
        .where('date',
            isGreaterThanOrEqualTo: startOfTomorrow.millisecondsSinceEpoch)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = FirestoreHelper.safeExtractQueryData(doc);
            return AppointmentModel.fromMap(data);
          }).toList();
        });
  }

  // Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        final data = FirestoreHelper.safeExtractData(doc);
        return AppointmentModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  // Get appointments by status for barber
  Stream<List<AppointmentModel>> getBarberAppointmentsByStatus(
      String barberId, String status) {
    return _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: status)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
  }

  // Get appointments by status for client
  Stream<List<AppointmentModel>> getClientAppointmentsByStatus(
      String clientId, String status) {
    return _appointmentsCollection
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: status)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
  }

  // Get completed appointments for barber (for earnings)
  Stream<List<AppointmentModel>> getCompletedAppointments(String barberId,
      {DateTime? startDate, DateTime? endDate}) {
    var query = _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'completed');

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      query = query.where('date',
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
  }

  // Check barber availability for a specific time
  Future<bool> checkBarberAvailability(
      String barberId, DateTime dateTime) async {
    try {
      // Check if barber is online and available
      final barberDoc =
          await _firestore.collection('users').doc(barberId).get();
      if (!barberDoc.exists ||
          (barberDoc.data() as Map<String, dynamic>)['isOnline'] != true) {
        return false;
      }

      // Check for overlapping appointments
      final startTime = dateTime.subtract(const Duration(minutes: 29));
      final endTime = dateTime.add(const Duration(minutes: 29));

      final query = await _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('date',
              isGreaterThanOrEqualTo: startTime.millisecondsSinceEpoch)
          .where('date', isLessThanOrEqualTo: endTime.millisecondsSinceEpoch)
          .where('status',
              whereIn: ['pending', 'confirmed', 'rescheduled']).get();

      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }

  // Apply discount coupon
  Future<Map<String, dynamic>> applyDiscountCoupon(
      String couponCode, String barberId) async {
    try {
      final couponQuery = await _firestore
          .collection('discounts')
          .where('code', isEqualTo: couponCode.toUpperCase())
          .where('barberId', isEqualTo: barberId)
          .where('isActive', isEqualTo: true)
          .where('expiresAt',
              isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .get();

      if (couponQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid or expired coupon code',
        };
      }

      final coupon = couponQuery.docs.first.data();
      return {
        'success': true,
        'discount': coupon['discount'],
        'message': 'Coupon applied successfully',
        'couponData': coupon,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error applying coupon: $e',
      };
    }
  }

  // Get available time slots for a barber on a specific date
  Future<List<DateTime>> getAvailableTimeSlots(
      String barberId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get existing appointments for the day
      final appointments = await _appointmentsCollection
          .where('barberId', isEqualTo: barberId)
          .where('date',
              isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('date', isLessThan: endOfDay.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      final bookedSlots = appointments.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DateTime.fromMillisecondsSinceEpoch(data['date']);
      }).toList();

      // Generate available slots (every 30 minutes from 8 AM to 8 PM)
      final availableSlots = <DateTime>[];
      DateTime currentSlot = DateTime(date.year, date.month, date.day, 8, 0);
      final endTime = DateTime(date.year, date.month, date.day, 20, 0);

      while (currentSlot.isBefore(endTime)) {
        bool isSlotAvailable = true;

        // Check if slot overlaps with any booked appointment
        for (final bookedSlot in bookedSlots) {
          final timeDifference = currentSlot.difference(bookedSlot).abs();
          if (timeDifference.inMinutes < 30) {
            isSlotAvailable = false;
            break;
          }
        }

        if (isSlotAvailable && currentSlot.isAfter(DateTime.now())) {
          availableSlots.add(currentSlot);
        }

        currentSlot = currentSlot.add(const Duration(minutes: 30));
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to get available slots: $e');
    }
  }

  // FIXED: Offline service creation - accepts ServiceModel instead of Map
  Future<void> createServiceOffline(ServiceModel service) async {
    try {
      await _offlineService.saveServiceOffline(service);
      await _offlineService.addToSyncQueue('create_service', {
        'type': 'service',
        'serviceData': service.toMap(), // Convert to map for storage
      });
      print('Service saved offline for sync: ${service.id}');
    } catch (e) {
      throw Exception('Failed to save service offline: $e');
    }
  }

  // FIXED: Sync offline services - properly handles ServiceModel
  Future<void> syncOfflineServices() async {
    try {
      // Get offline services with barberId parameter
      final offlineServices = await _offlineService.getOfflineServices('');
      final pendingSyncItems = await _offlineService.getPendingSyncItems();

      for (final service in offlineServices) {
        // Service is already a ServiceModel, convert to map for Firestore
        await _firestore
            .collection('services')
            .doc(service.id)
            .set(service.toMap());

        await _offlineService.removeOfflineService(service.id);
      }

      // Process service sync queue
      final serviceSyncItems =
          pendingSyncItems.where((item) => item['type'] == 'service').toList();

      for (final item in serviceSyncItems) {
        try {
          switch (item['action']) {
            case 'create_service':
              final serviceData =
                  Map<String, dynamic>.from(item['data']['serviceData']);
              await _firestore
                  .collection('services')
                  .doc(serviceData['id'])
                  .set(serviceData);
              await _offlineService.removeFromSyncQueue(item['id']);
              break;
          }
        } catch (e) {
          print('Failed to sync service operation ${item['action']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing offline services: $e');
    }
  }

  // Availability management with offline support
  Future<void> setBarberAvailability(Map<String, dynamic> availability) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('barber_availability')
            .doc(availability['barberId'])
            .set(availability, SetOptions(merge: true));
      } else {
        // Save offline
        await _offlineService.saveAvailabilityOffline(availability);
        await _offlineService.addToSyncQueue('update_availability', {
          'type': 'availability',
          'availabilityData': availability,
        });
      }
    } catch (e) {
      throw Exception('Failed to set availability: $e');
    }
  }

  // Sync offline availability
  Future<void> syncOfflineAvailability() async {
    try {
      final pendingSyncItems = await _offlineService.getPendingSyncItems();
      final availabilitySyncItems = pendingSyncItems
          .where((item) => item['type'] == 'availability')
          .toList();

      for (final item in availabilitySyncItems) {
        try {
          final availabilityData =
              Map<String, dynamic>.from(item['data']['availabilityData']);
          await _firestore
              .collection('barber_availability')
              .doc(availabilityData['barberId'])
              .set(availabilityData, SetOptions(merge: true));

          await _offlineService.removeFromSyncQueue(item['id']);
        } catch (e) {
          print('Failed to sync availability: $e');
        }
      }
    } catch (e) {
      print('Error syncing offline availability: $e');
    }
  }

  // Marketing data with offline support
  Future<void> createMarketingCampaign(
      Map<String, dynamic> campaignData) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('marketing_campaigns')
            .doc(campaignData['id'])
            .set(campaignData);
      } else {
        // Save offline
        await _offlineService.saveMarketingDataOffline(campaignData);
        await _offlineService.addToSyncQueue('create_marketing', {
          'type': 'marketing',
          'campaignData': campaignData,
        });
      }
    } catch (e) {
      throw Exception('Failed to create marketing campaign: $e');
    }
  }

  // Get discount information
  Stream<List<Map<String, dynamic>>> getActiveDiscounts(String barberId) {
    return _firestore
        .collection('discounts')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .where('expiresAt',
            isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Sync all offline data
  Future<void> syncAllOfflineData() async {
    await syncPendingAppointmentOperations();
    await syncOfflineServices();
    await syncOfflineAvailability();

    // Sync marketing data
    final pendingSyncItems = await _offlineService.getPendingSyncItems();
    final marketingSyncItems =
        pendingSyncItems.where((item) => item['type'] == 'marketing').toList();

    for (final item in marketingSyncItems) {
      try {
        final campaignData =
            Map<String, dynamic>.from(item['data']['campaignData']);
        await _firestore
            .collection('marketing_campaigns')
            .doc(campaignData['id'])
            .set(campaignData);

        await _offlineService.removeFromSyncQueue(item['id']);
      } catch (e) {
        print('Failed to sync marketing campaign: $e');
      }
    }
  }
}
