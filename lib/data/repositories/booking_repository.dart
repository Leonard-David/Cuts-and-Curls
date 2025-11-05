import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/firestore_helper.dart';
import '../models/appointment_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _appointmentsCollection = FirebaseFirestore.instance.collection('appointments');

  // Create a new appointment
  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      await _appointmentsCollection.doc(appointment.id).set(appointment.toMap());
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
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

  // Get all appointments for a barber (real-time)
  Stream<List<AppointmentModel>> getBarberAppointments(String barberId) {
    return _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
  }

  // Get all appointments for a client (real-time)
  Stream<List<AppointmentModel>> getClientAppointments(String clientId) {
    return _appointmentsCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
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
        .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
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
        .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
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
        .where('date', isGreaterThanOrEqualTo: startOfTomorrow.millisecondsSinceEpoch)
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
  Stream<List<AppointmentModel>> getClientUpcomingAppointments(String clientId) {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

    return _appointmentsCollection
        .where('clientId', isEqualTo: clientId)
        .where('date', isGreaterThanOrEqualTo: startOfTomorrow.millisecondsSinceEpoch)
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

  // Check barber availability for a specific time
  Future<bool> checkBarberAvailability(String barberId, DateTime dateTime) async {
    try {
      // Check if barber is online
      final barberDoc = await _firestore.collection('users').doc(barberId).get();
      if (!barberDoc.exists || (barberDoc.data() as Map<String, dynamic>)['isOnline'] != true) {
        return false;
      }

      // Check for overlapping appointments (30-minute buffer)
      final startTime = dateTime.subtract(const Duration(minutes: 29));
      final endTime = dateTime.add(const Duration(minutes: 29));

      final query = await _appointmentsCollection
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: startTime.millisecondsSinceEpoch)
          .where('date', isLessThanOrEqualTo: endTime.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }

  // Get available time slots for a barber on a specific date
  Future<List<DateTime>> getAvailableTimeSlots(String barberId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get existing appointments for the day
      final appointments = await _appointmentsCollection
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('date', isLessThan: endOfDay.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

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

  // Get appointments by status for barber
  Stream<List<AppointmentModel>> getBarberAppointmentsByStatus(String barberId, String status) {
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
  Stream<List<AppointmentModel>> getClientAppointmentsByStatus(String clientId, String status) {
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
  Stream<List<AppointmentModel>> getCompletedAppointments(String barberId, {DateTime? startDate, DateTime? endDate}) {
    var query = _appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'completed');

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = FirestoreHelper.safeExtractQueryData(doc);
        return AppointmentModel.fromMap(data);
      }).toList();
    });
  }
}