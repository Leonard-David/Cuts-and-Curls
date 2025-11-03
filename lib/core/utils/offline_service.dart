import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/repositories/payment_repository.dart';
import 'package:sheersync/data/repositories/service_repository.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const String _appointmentsBox = 'appointments';
  static const String _paymentsBox = 'payments';
  static const String _servicesBox = 'services';
  static const String _syncQueueBox = 'sync_queue';

  late Box<AppointmentModel> _appointments;
  late Box<PaymentModel> _payments;
  late Box<ServiceModel> _services;
  late Box<Map<dynamic, dynamic>> _syncQueue;

  final BookingRepository _bookingRepository = BookingRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();

  // Initialize Hive and open boxes
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppointmentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PaymentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ServiceModelAdapter());
    }
    
    _appointments = await Hive.openBox<AppointmentModel>(_appointmentsBox);
    _payments = await Hive.openBox<PaymentModel>(_paymentsBox);
    _services = await Hive.openBox<ServiceModel>(_servicesBox);
    _syncQueue = await Hive.openBox<Map<dynamic, dynamic>>(_syncQueueBox);
  }

  // Check connectivity
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Save appointment locally
  Future<void> saveAppointmentLocally(AppointmentModel appointment) async {
    try {
      await _appointments.put(appointment.id, appointment);
      
      // Add to sync queue if created offline
      if (!(await isConnected())) {
        await addToSyncQueue('appointments', 'create', appointment.toMap());
      }
    } catch (e) {
      print('Error saving appointment locally: $e');
      throw Exception('Failed to save appointment locally: $e');
    }
  }

  // Get local appointments
  List<AppointmentModel> getLocalAppointments() {
    return _appointments.values.toList();
  }

  // Get appointment by ID
  AppointmentModel? getAppointmentById(String id) {
    return _appointments.get(id);
  }

  // Save payment locally
  Future<void> savePaymentLocally(PaymentModel payment) async {
    try {
      await _payments.put(payment.id, payment);
      
      if (!(await isConnected())) {
        await addToSyncQueue('payments', 'create', payment.toMap());
      }
    } catch (e) {
      print('Error saving payment locally: $e');
      throw Exception('Failed to save payment locally: $e');
    }
  }

  // Get local payments
  List<PaymentModel> getLocalPayments() {
    return _payments.values.toList();
  }

  // Save services locally (for barbers)
  Future<void> saveServicesLocally(List<ServiceModel> services) async {
    try {
      await _services.clear();
      for (final service in services) {
        await _services.put(service.id, service);
      }
    } catch (e) {
      print('Error saving services locally: $e');
      throw Exception('Failed to save services locally: $e');
    }
  }

  // Get local services
  List<ServiceModel> getLocalServices() {
    return _services.values.toList();
  }

  // Get service by ID
  ServiceModel? getServiceById(String id) {
    return _services.get(id);
  }

  // Add operation to sync queue
  Future<void> addToSyncQueue(String collection, String operation, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': 'sync_${DateTime.now().millisecondsSinceEpoch}',
        'collection': collection,
        'operation': operation,
        'data': data,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
      };
      
      await _syncQueue.put(syncItem['id'], syncItem);
    } catch (e) {
      print('Error adding to sync queue: $e');
      throw Exception('Failed to add to sync queue: $e');
    }
  }

  // Sync pending operations when online
  Future<void> syncPendingOperations() async {
    if (!(await isConnected())) {
      print('No internet connection, skipping sync');
      return;
    }

    final syncItems = _syncQueue.values.toList();
    
    if (syncItems.isEmpty) {
      print('No pending operations to sync');
      return;
    }

    print('Syncing ${syncItems.length} pending operations...');

    for (final syncItem in syncItems) {
      try {
        await _processSyncItem(syncItem);
        
        // Remove from queue if successful
        await _syncQueue.delete(syncItem['id']);
        print('Successfully synced operation: ${syncItem['id']}');
      } catch (e) {
        print('Error syncing operation ${syncItem['id']}: $e');
        
        // Increment attempts and keep in queue
        final attempts = (syncItem['attempts'] ?? 0) + 1;
        syncItem['attempts'] = attempts;
        syncItem['lastError'] = e.toString();
        syncItem['lastAttempt'] = DateTime.now().millisecondsSinceEpoch;
        
        await _syncQueue.put(syncItem['id'], syncItem);
        
        // If too many attempts, remove from queue and log error
        if (attempts >= 3) {
          await _syncQueue.delete(syncItem['id']);
          print('Removed operation ${syncItem['id']} after 3 failed attempts');
        }
      }
    }
  }

  Future<void> _processSyncItem(Map<dynamic, dynamic> syncItem) async {
    final String collection = syncItem['collection'];
    final String operation = syncItem['operation'];
    final Map<String, dynamic> data = Map<String, dynamic>.from(syncItem['data']);

    switch (collection) {
      case 'appointments':
        if (operation == 'create') {
          // Convert map back to AppointmentModel
          final appointment = AppointmentModel.fromMap(data);
          await _bookingRepository.createAppointment(appointment);
        }
        break;
      case 'payments':
        if (operation == 'create') {
          // Convert map back to PaymentModel
          final payment = PaymentModel.fromMap(data);
          await _paymentRepository.createPayment(payment);
        }
        break;
      case 'services':
        if (operation == 'create') {
          // Convert map back to ServiceModel
          final service = ServiceModel.fromMap(data);
          await _serviceRepository.createService(service);
        }
        break;
      default:
        throw Exception('Unknown collection type: $collection');
    }
  }

  // Update local appointment
  Future<void> updateAppointmentLocally(AppointmentModel appointment) async {
    try {
      await _appointments.put(appointment.id, appointment);
    } catch (e) {
      print('Error updating appointment locally: $e');
      throw Exception('Failed to update appointment locally: $e');
    }
  }

  // Update local payment
  Future<void> updatePaymentLocally(PaymentModel payment) async {
    try {
      await _payments.put(payment.id, payment);
    } catch (e) {
      print('Error updating payment locally: $e');
      throw Exception('Failed to update payment locally: $e');
    }
  }

  // Delete appointment locally
  Future<void> deleteAppointmentLocally(String appointmentId) async {
    try {
      await _appointments.delete(appointmentId);
    } catch (e) {
      print('Error deleting appointment locally: $e');
      throw Exception('Failed to delete appointment locally: $e');
    }
  }

  // Delete payment locally
  Future<void> deletePaymentLocally(String paymentId) async {
    try {
      await _payments.delete(paymentId);
    } catch (e) {
      print('Error deleting payment locally: $e');
      throw Exception('Failed to delete payment locally: $e');
    }
  }

  // Clear all local data (for logout)
  Future<void> clearAllLocalData() async {
    try {
      await _appointments.clear();
      await _payments.clear();
      await _services.clear();
      await _syncQueue.clear();
      print('All local data cleared successfully');
    } catch (e) {
      print('Error clearing local data: $e');
      throw Exception('Failed to clear local data: $e');
    }
  }

  // Get sync queue size
  int getPendingSyncCount() {
    return _syncQueue.length;
  }

  // Check if there are pending sync operations
  bool hasPendingSync() {
    return _syncQueue.isNotEmpty;
  }

  // Get sync queue items (for debugging)
  List<Map<dynamic, dynamic>> getSyncQueueItems() {
    return _syncQueue.values.toList();
  }

  // Initialize sync timer (call this when app starts)
  void startSyncTimer() {
    // Check for pending sync operations every 30 seconds when online
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (await isConnected() && hasPendingSync()) {
        await syncPendingOperations();
      }
    });
  }

  // Dispose Hive boxes
  Future<void> dispose() async {
    try {
      await _appointments.close();
      await _payments.close();
      await _services.close();
      await _syncQueue.close();
      print('Offline service disposed successfully');
    } catch (e) {
      print('Error disposing offline service: $e');
    }
  }
}