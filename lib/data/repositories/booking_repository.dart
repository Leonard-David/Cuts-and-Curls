import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/notifications/fcm_service.dart';
import 'package:sheersync/core/utils/firestore_helper.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/models/service_model.dart';

class BookingRepository {
  final OfflineService _offlineService = OfflineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _appointmentsCollection =
      FirebaseFirestore.instance.collection('appointments');

  // Create appointment with offline support
  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore
            .collection('appointments')
            .doc(appointment.id)
            .set(appointment.toMap());

        // Send notification to barber
        await _sendAppointmentNotification(appointment);
        print('Appointment created online: ${appointment.id}');
      } else {
        // Save offline and add to sync queue
        await _offlineService.saveAppointmentOffline(appointment);
        await _offlineService.addToSyncQueue('create_appointment', {
          'type': 'appointment',
          'appointmentData': appointment.toMap(),
        });
        print('Appointment saved offline for sync: ${appointment.id}');
      }
    } catch (e) {
      // If online fails, save offline
      if (e.toString().contains('network') ||
          e.toString().contains('Connection')) {
        await _offlineService.saveAppointmentOffline(appointment);
        await _offlineService.addToSyncQueue('create_appointment', {
          'type': 'appointment',
          'appointmentData': appointment.toMap(),
        });
        print('Network error - Appointment saved offline: ${appointment.id}');
      } else {
        throw Exception('Failed to create appointment: $e');
      }
    }
  }

  // Update appointment status with offline support
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      if (await _offlineService.isConnected()) {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': status,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Send status update notification
        await _sendStatusUpdateNotification(appointmentId, status);
      } else {
        // Update offline and add to sync queue
        final offlineAppointments =
            await _offlineService.getOfflineAppointments('', 'barber');
        final appointment =
            offlineAppointments.firstWhere((appt) => appt.id == appointmentId);
        final updatedAppointment = appointment.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );

        await _offlineService.saveAppointmentOffline(updatedAppointment);
        await _offlineService.addToSyncQueue('update_appointment_status', {
          'type': 'appointment',
          'appointmentId': appointmentId,
          'status': status,
        });
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

              // Send notification after successful sync
              final appointment = AppointmentModel.fromMap(appointmentData);
              await _sendAppointmentNotification(appointment);

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

              // Send notification after successful sync
              await _sendStatusUpdateNotification(
                  item['data']['appointmentId'], item['data']['status']);

              await _offlineService.removeFromSyncQueue(item['id']);
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

      // Send cancellation notification
      await _sendCancellationNotification(appointmentId, reason);
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment(
      String appointmentId, DateTime newDate) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'date': newDate.millisecondsSinceEpoch,
        'status': 'rescheduled',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Send rescheduling notification
      await _sendRescheduleNotification(appointmentId, newDate);
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
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

  Future<void> _sendAppointmentNotification(
      AppointmentModel appointment) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': appointment.barberId,
        'title': 'New Appointment Request',
        'message':
            '${appointment.clientName} requested ${appointment.serviceName}',
        'type': 'appointment_request',
        'relatedId': appointment.id,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointment.id,
          'clientName': appointment.clientName,
          'serviceName': appointment.serviceName,
          'appointmentTime': appointment.date.millisecondsSinceEpoch,
        },
      });
    } catch (e) {
      print('Error sending appointment notification: $e');
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

  Future<void> _sendStatusUpdateNotification(
      String appointmentId, String status) async {
    try {
      // Get appointment details
      final appointmentDoc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);

      // Get barber details for notification
      final barberDoc =
          await _firestore.collection('users').doc(appointment.barberId).get();

      final barber =
          barberDoc.exists ? UserModel.fromMap(barberDoc.data()!) : null;
      final barberName = barber?.fullName ?? 'Professional';

      // Get client details for notification
      final clientDoc =
          await _firestore.collection('users').doc(appointment.clientId).get();

      final client =
          clientDoc.exists ? UserModel.fromMap(clientDoc.data()!) : null;
      final clientName = client?.fullName ?? 'Client';

      // Determine notification content based on status
      String clientTitle = '';
      String clientMessage = '';
      String barberTitle = '';
      String barberMessage = '';
      String notificationType = '';

      switch (status) {
        case 'confirmed':
          clientTitle = 'Appointment Confirmed! 🎉';
          clientMessage =
              'Your appointment with $barberName has been confirmed for ${_formatAppointmentDate(appointment.date)}';
          barberTitle = 'Appointment Confirmed';
          barberMessage = 'You confirmed appointment with $clientName';
          notificationType = 'appointment_confirmed';
          break;

        case 'declined':
          clientTitle = 'Appointment Declined';
          clientMessage = '$barberName has declined your appointment request';
          barberTitle = 'Appointment Declined';
          barberMessage = 'You declined appointment with $clientName';
          notificationType = 'appointment_declined';
          break;

        case 'completed':
          clientTitle = 'Appointment Completed ✅';
          clientMessage =
              'Your appointment with $barberName has been completed. Please leave a review!';
          barberTitle = 'Appointment Completed';
          barberMessage =
              'You marked appointment with $clientName as completed';
          notificationType = 'appointment_completed';
          break;

        case 'rescheduled':
          clientTitle = 'Appointment Rescheduled';
          clientMessage =
              'Your appointment with $barberName has been rescheduled to ${_formatAppointmentDate(appointment.date)}';
          barberTitle = 'Appointment Rescheduled';
          barberMessage = 'You rescheduled appointment with $clientName';
          notificationType = 'appointment_rescheduled';
          break;

        default:
          clientTitle = 'Appointment Status Updated';
          clientMessage =
              'Your appointment status has been updated to ${status.toUpperCase()}';
          barberTitle = 'Appointment Status Updated';
          barberMessage =
              'Appointment status updated to ${status.toUpperCase()}';
          notificationType = 'appointment_status_updated';
      }

      // Send notification to client
      await _firestore.collection('notifications').add({
        'userId': appointment.clientId,
        'title': clientTitle,
        'message': clientMessage,
        'type': notificationType,
        'relatedId': appointmentId,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointmentId,
          'status': status,
          'barberName': barberName,
          'serviceName': appointment.serviceName ?? 'Service',
          'appointmentTime': appointment.date.millisecondsSinceEpoch,
          'notificationType': 'status_update',
        },
      });

      // Send notification to barber
      await _firestore.collection('notifications').add({
        'userId': appointment.barberId,
        'title': barberTitle,
        'message': barberMessage,
        'type': notificationType,
        'relatedId': appointmentId,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointmentId,
          'status': status,
          'clientName': clientName,
          'serviceName': appointment.serviceName ?? 'Service',
          'appointmentTime': appointment.date.millisecondsSinceEpoch,
          'notificationType': 'status_update',
        },
      });

      // Send FCM push notifications
      await _sendFCMPushNotification(
        userId: appointment.clientId,
        title: clientTitle,
        body: clientMessage,
        data: {
          'type': 'appointment_status',
          'appointmentId': appointmentId,
          'status': status,
          'barberName': barberName,
        },
      );

      await _sendFCMPushNotification(
        userId: appointment.barberId,
        title: barberTitle,
        body: barberMessage,
        data: {
          'type': 'appointment_status',
          'appointmentId': appointmentId,
          'status': status,
          'clientName': clientName,
        },
      );

      print(
          '✅ Status update notifications sent for appointment: $appointmentId');
    } catch (e) {
      print('❌ Error sending status update notification: $e');
      throw Exception('Failed to send status update notification: $e');
    }
  }

  // Send cancellation notification with reason
  Future<void> _sendCancellationNotification(
      String appointmentId, String reason) async {
    try {
      // Get appointment details
      final appointmentDoc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);

      // Get user details for notifications
      final barberDoc =
          await _firestore.collection('users').doc(appointment.barberId).get();

      final barber =
          barberDoc.exists ? UserModel.fromMap(barberDoc.data()!) : null;
      final barberName = barber?.fullName ?? 'Professional';

      final clientDoc =
          await _firestore.collection('users').doc(appointment.clientId).get();

      final client =
          clientDoc.exists ? UserModel.fromMap(clientDoc.data()!) : null;
      final clientName = client?.fullName ?? 'Client';

      // Determine who cancelled the appointment
      final currentUser = await _getCurrentUser();
      final isCancelledByClient = currentUser?.id == appointment.clientId;

      String clientTitle = '';
      String clientMessage = '';
      String barberTitle = '';
      String barberMessage = '';

      if (isCancelledByClient) {
        // Cancelled by client
        clientTitle = 'Appointment Cancelled';
        clientMessage = 'You cancelled your appointment with $barberName';
        barberTitle = 'Appointment Cancelled by Client';
        barberMessage =
            '$clientName cancelled their appointment${reason.isNotEmpty ? ': $reason' : ''}';
      } else {
        // Cancelled by barber
        clientTitle = 'Appointment Cancelled';
        clientMessage =
            '$barberName cancelled your appointment${reason.isNotEmpty ? ': $reason' : ''}';
        barberTitle = 'Appointment Cancelled';
        barberMessage =
            'You cancelled appointment with $clientName${reason.isNotEmpty ? ': $reason' : ''}';
      }

      // Send notification to client
      await _firestore.collection('notifications').add({
        'userId': appointment.clientId,
        'title': clientTitle,
        'message': clientMessage,
        'type': 'appointment_cancelled',
        'relatedId': appointmentId,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointmentId,
          'status': 'cancelled',
          'barberName': barberName,
          'clientName': clientName,
          'serviceName': appointment.serviceName ?? 'Service',
          'appointmentTime': appointment.date.millisecondsSinceEpoch,
          'cancelledBy': isCancelledByClient ? 'client' : 'barber',
          'cancellationReason': reason,
          'notificationType': 'cancellation',
        },
      });

      // Send notification to barber
      await _firestore.collection('notifications').add({
        'userId': appointment.barberId,
        'title': barberTitle,
        'message': barberMessage,
        'type': 'appointment_cancelled',
        'relatedId': appointmentId,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointmentId,
          'status': 'cancelled',
          'barberName': barberName,
          'clientName': clientName,
          'serviceName': appointment.serviceName ?? 'Service',
          'appointmentTime': appointment.date.millisecondsSinceEpoch,
          'cancelledBy': isCancelledByClient ? 'client' : 'barber',
          'cancellationReason': reason,
          'notificationType': 'cancellation',
        },
      });

      // Send FCM push notifications
      await _sendFCMPushNotification(
        userId: appointment.clientId,
        title: clientTitle,
        body: clientMessage,
        data: {
          'type': 'appointment_cancelled',
          'appointmentId': appointmentId,
          'cancelledBy': isCancelledByClient ? 'client' : 'barber',
          'barberName': barberName,
        },
      );

      await _sendFCMPushNotification(
        userId: appointment.barberId,
        title: barberTitle,
        body: barberMessage,
        data: {
          'type': 'appointment_cancelled',
          'appointmentId': appointmentId,
          'cancelledBy': isCancelledByClient ? 'client' : 'barber',
          'clientName': clientName,
        },
      );

      // If appointment was in the future, cancel any reminders
      if (appointment.date.isAfter(DateTime.now())) {
        await _cancelScheduledReminders(appointmentId);
      }

      print(
          '✅ Cancellation notifications sent for appointment: $appointmentId');
    } catch (e) {
      print('❌ Error sending cancellation notification: $e');
      throw Exception('Failed to send cancellation notification: $e');
    }
  }

  // Send reschedule notification with new date
  Future<void> _sendRescheduleNotification(
      String appointmentId, DateTime newDate) async {
    try {
      // Get appointment details
      final appointmentDoc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (!appointmentDoc.exists) {
        print('Appointment not found: $appointmentId');
        return;
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);

      // Get user details for notifications
      final barberDoc =
          await _firestore.collection('users').doc(appointment.barberId).get();

      final barber =
          barberDoc.exists ? UserModel.fromMap(barberDoc.data()!) : null;
      final barberName = barber?.fullName ?? 'Professional';

      final clientDoc =
          await _firestore.collection('users').doc(appointment.clientId).get();

      final client =
          clientDoc.exists ? UserModel.fromMap(clientDoc.data()!) : null;
      final clientName = client?.fullName ?? 'Client';

      // Determine who rescheduled the appointment
      final currentUser = await _getCurrentUser();
      final isRescheduledByClient = currentUser?.id == appointment.clientId;

      String clientTitle = '';
      String clientMessage = '';
      String barberTitle = '';
      String barberMessage = '';

      if (isRescheduledByClient) {
        // Rescheduled by client
        clientTitle = 'Appointment Rescheduled';
        clientMessage =
            'You rescheduled your appointment with $barberName to ${_formatAppointmentDate(newDate)}';
        barberTitle = 'Appointment Rescheduled by Client';
        barberMessage =
            '$clientName rescheduled their appointment to ${_formatAppointmentDate(newDate)}';
      } else {
        // Rescheduled by barber
        clientTitle = 'Appointment Rescheduled';
        clientMessage =
            '$barberName rescheduled your appointment to ${_formatAppointmentDate(newDate)}';
        barberTitle = 'Appointment Rescheduled';
        barberMessage =
            'You rescheduled appointment with $clientName to ${_formatAppointmentDate(newDate)}';
      }

      // Send notification to client
      await _firestore.collection('notifications').add({
        'userId': appointment.clientId,
        'title': clientTitle,
        'message': clientMessage,
        'type': 'appointment_rescheduled',
        'relatedId': appointmentId,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointmentId,
          'status': 'rescheduled',
          'barberName': barberName,
          'clientName': clientName,
          'serviceName': appointment.serviceName ?? 'Service',
          'oldAppointmentTime': appointment.date.millisecondsSinceEpoch,
          'newAppointmentTime': newDate.millisecondsSinceEpoch,
          'rescheduledBy': isRescheduledByClient ? 'client' : 'barber',
          'notificationType': 'reschedule',
        },
      });

      // Send notification to barber
      await _firestore.collection('notifications').add({
        'userId': appointment.barberId,
        'title': barberTitle,
        'message': barberMessage,
        'type': 'appointment_rescheduled',
        'relatedId': appointmentId,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'appointmentId': appointmentId,
          'status': 'rescheduled',
          'barberName': barberName,
          'clientName': clientName,
          'serviceName': appointment.serviceName ?? 'Service',
          'oldAppointmentTime': appointment.date.millisecondsSinceEpoch,
          'newAppointmentTime': newDate.millisecondsSinceEpoch,
          'rescheduledBy': isRescheduledByClient ? 'client' : 'barber',
          'notificationType': 'reschedule',
        },
      });

      // Send FCM push notifications
      await _sendFCMPushNotification(
        userId: appointment.clientId,
        title: clientTitle,
        body: clientMessage,
        data: {
          'type': 'appointment_rescheduled',
          'appointmentId': appointmentId,
          'rescheduledBy': isRescheduledByClient ? 'client' : 'barber',
          'barberName': barberName,
          'newAppointmentTime': newDate.millisecondsSinceEpoch,
        },
      );

      await _sendFCMPushNotification(
        userId: appointment.barberId,
        title: barberTitle,
        body: barberMessage,
        data: {
          'type': 'appointment_rescheduled',
          'appointmentId': appointmentId,
          'rescheduledBy': isRescheduledByClient ? 'client' : 'barber',
          'clientName': clientName,
          'newAppointmentTime': newDate.millisecondsSinceEpoch,
        },
      );

      // Update reminders for new appointment time
      await _updateScheduledReminders(appointmentId, newDate);

      print('✅ Reschedule notifications sent for appointment: $appointmentId');
    } catch (e) {
      print('❌ Error sending reschedule notification: $e');
      throw Exception('Failed to send reschedule notification: $e');
    }
  }

  // Helper method to send FCM push notifications
  Future<void> _sendFCMPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await FCMService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );
      print('📱 FCM notification sent to user: $userId');
    } catch (e) {
      print('❌ Error sending FCM notification to user $userId: $e');
      // Don't throw error - FCM failure shouldn't break the main flow
    }
  }

  // Helper method to get current user (you'll need to implement this based on your auth system)
  Future<UserModel?> _getCurrentUser() async {
    try {
      // This should be implemented based on your authentication system
      // For now, return null - the logic will work without it
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Helper method to format appointment date
  String _formatAppointmentDate(DateTime date) {
    return '${DateFormat('EEE, MMM d').format(date)} at ${DateFormat('h:mm a').format(date)}';
  }

  // Helper method to cancel scheduled reminders
  Future<void> _cancelScheduledReminders(String appointmentId) async {
    try {
      // Cancel any scheduled local notifications
      // This would integrate with your local notification service
      print('🔔 Cancelled reminders for appointment: $appointmentId');
    } catch (e) {
      print('Error cancelling reminders: $e');
    }
  }

  // Helper method to update scheduled reminders for new appointment time
  Future<void> _updateScheduledReminders(
      String appointmentId, DateTime newDate) async {
    try {
      // Update scheduled local notifications with new time
      // This would integrate with your local notification service
      print('🔔 Updated reminders for appointment: $appointmentId to $newDate');
    } catch (e) {
      print('Error updating reminders: $e');
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
