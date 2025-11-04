import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/booking_repository.dart';

class AppointmentsProvider with ChangeNotifier {
  final BookingRepository _bookingRepository = BookingRepository();
  
  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _appointmentRequests = [];
  List<AppointmentModel> _todaysAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  
  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'all';

  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get appointmentRequests => _appointmentRequests;
  List<AppointmentModel> get todaysAppointments => _todaysAppointments;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  // Load all appointments with real-time updates
  void loadAppointments(String barberId, {String? filter}) {
    _isLoading = true;
    _error = null;
    _currentFilter = filter ?? 'all';
    notifyListeners();

    _bookingRepository.getBarberAppointments(barberId).listen(
      (appointments) {
        _appointments = appointments;
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

  // Load appointment requests (pending appointments)
  void loadAppointmentRequests(String barberId) {
    _bookingRepository.getAppointmentRequests(barberId).listen(
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
    _bookingRepository.getTodaysAppointments(barberId).listen(
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
    _bookingRepository.getUpcomingAppointments(barberId).listen(
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
    loadAppointments(barberId, filter: _currentFilter);
    loadAppointmentRequests(barberId);
    loadTodaysAppointments(barberId);
    loadUpcomingAppointments(barberId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}