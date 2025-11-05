import 'dart:async';

import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/booking_repository.dart';

class AppointmentsProvider with ChangeNotifier {
  final BookingRepository _bookingRepository = BookingRepository();
  
  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _appointmentRequests = [];
  List<AppointmentModel> _todaysAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  
  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'all';

  // Getters
  List<AppointmentModel> get allAppointments => _allAppointments;
  List<AppointmentModel> get appointmentRequests => _appointmentRequests;
  List<AppointmentModel> get todaysAppointments => _todaysAppointments;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  // Real-time stream subscriptions
  StreamSubscription<List<AppointmentModel>>? _appointmentsSubscription;
  StreamSubscription<List<AppointmentModel>>? _requestsSubscription;
  StreamSubscription<List<AppointmentModel>>? _todaySubscription;
  StreamSubscription<List<AppointmentModel>>? _upcomingSubscription;

  // Load all appointments with real-time updates
  void loadAllAppointments(String barberId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cancel existing subscription
    _appointmentsSubscription?.cancel();
    
    _appointmentsSubscription = _bookingRepository.getBarberAppointments(barberId).listen(
      (appointments) {
        _allAppointments = appointments;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load appointments: $error';
        notifyListeners();
      },
    );
  }

  // Load appointment requests (pending appointments from clients only)
  void loadAppointmentRequests(String barberId) {
    _requestsSubscription?.cancel();
    
    _requestsSubscription = _bookingRepository.getAppointmentRequests(barberId).listen(
      (requests) {
        _appointmentRequests = requests;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load appointment requests: $error';
        notifyListeners();
      },
    );
  }

  // Load today's appointments
  void loadTodaysAppointments(String barberId) {
    _todaySubscription?.cancel();
    
    _todaySubscription = _bookingRepository.getTodaysAppointments(barberId).listen(
      (appointments) {
        _todaysAppointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load today\'s appointments: $error';
        notifyListeners();
      },
    );
  }

  // Load upcoming appointments
  void loadUpcomingAppointments(String barberId) {
    _upcomingSubscription?.cancel();
    
    _upcomingSubscription = _bookingRepository.getUpcomingAppointments(barberId).listen(
      (appointments) {
        _upcomingAppointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load upcoming appointments: $error';
        notifyListeners();
      },
    );
  }

  // Refresh all data
  void refreshAll(String barberId) {
    loadAllAppointments(barberId);
    loadAppointmentRequests(barberId);
    loadTodaysAppointments(barberId);
    loadUpcomingAppointments(barberId);
  }

  // Add new appointment to local state (for real-time updates)
  void addAppointment(AppointmentModel appointment) {
    _allAppointments.insert(0, appointment);
    
    // Update filtered lists
    _updateFilteredLists();
    notifyListeners();
  }

  // Update appointment in local state
  void updateAppointment(AppointmentModel updatedAppointment) {
    final index = _allAppointments.indexWhere((a) => a.id == updatedAppointment.id);
    if (index != -1) {
      _allAppointments[index] = updatedAppointment;
      _updateFilteredLists();
      notifyListeners();
    }
  }

  // Remove appointment from local state
  void removeAppointment(String appointmentId) {
    _allAppointments.removeWhere((a) => a.id == appointmentId);
    _updateFilteredLists();
    notifyListeners();
  }

  // Update filtered lists based on current data
  void _updateFilteredLists() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    today.add(const Duration(days: 1));
    
    // Update today's appointments
    _todaysAppointments = _allAppointments.where((appointment) {
      final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
      return appointmentDate == today && appointment.status != 'cancelled';
    }).toList();
    
    // Update upcoming appointments
    _upcomingAppointments = _allAppointments.where((appointment) {
      final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
      return appointmentDate.isAfter(today) && appointment.status != 'cancelled';
    }).toList();
    
    // Update appointment requests
    _appointmentRequests = _allAppointments.where((appointment) {
      return appointment.status == 'pending' && !appointment.clientId.startsWith('manual_');
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose all subscriptions
  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _todaySubscription?.cancel();
    _upcomingSubscription?.cancel();
    super.dispose();
  }
}
