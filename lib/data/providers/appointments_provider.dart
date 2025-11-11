import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import '../repositories/booking_repository.dart';

class AppointmentsProvider with ChangeNotifier {
  final BookingRepository _bookingRepository = BookingRepository();

  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _appointmentRequests = [];
  List<AppointmentModel> _todaysAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _clientAppointments = [];
  List<AppointmentModel> _clientTodaysAppointments = [];
  List<AppointmentModel> _clientUpcomingAppointments = [];

  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'all';

  // Getters
  List<AppointmentModel> get allAppointments => _allAppointments;
  List<AppointmentModel> get appointmentRequests => _appointmentRequests;
  List<AppointmentModel> get todaysAppointments => _todaysAppointments;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentModel> get clientAppointments => _clientAppointments;
  List<AppointmentModel> get clientTodaysAppointments => _clientTodaysAppointments;
  List<AppointmentModel> get clientUpcomingAppointments => _clientUpcomingAppointments;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  // Real-time stream subscriptions
  StreamSubscription<List<AppointmentModel>>? _appointmentsSubscription;
  StreamSubscription<List<AppointmentModel>>? _requestsSubscription;
  StreamSubscription<List<AppointmentModel>>? _todaySubscription;
  StreamSubscription<List<AppointmentModel>>? _upcomingSubscription;
  StreamSubscription<List<AppointmentModel>>? _clientAppointmentsSubscription;
  StreamSubscription<List<AppointmentModel>>? _clientTodaySubscription;
  StreamSubscription<List<AppointmentModel>>? _clientUpcomingSubscription;

  // Load all appointments for barber with real-time updates
  void loadBarberAppointments(String barberId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cancel existing subscription
    _appointmentsSubscription?.cancel();

    _appointmentsSubscription =
        _bookingRepository.getBarberAppointments(barberId).listen(
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

  // Load all appointments for client with real-time updates
  void loadClientAppointments(String clientId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cancel existing subscription
    _clientAppointmentsSubscription?.cancel();

    _clientAppointmentsSubscription =
        _bookingRepository.getClientAppointments(clientId).listen(
      (appointments) {
        _clientAppointments = appointments;
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

  // Load appointment requests (pending appointments from clients for barber)
  void loadAppointmentRequests(String barberId) {
    _requestsSubscription?.cancel();

    _requestsSubscription =
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

  // Load today's appointments for barber
  void loadTodaysAppointments(String barberId) {
    _todaySubscription?.cancel();

    _todaySubscription =
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

  // Load today's appointments for client
  void loadClientTodaysAppointments(String clientId) {
    _clientTodaySubscription?.cancel();

    _clientTodaySubscription =
        _bookingRepository.getClientTodaysAppointments(clientId).listen(
      (appointments) {
        _clientTodaysAppointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load today\'s appointments: $error';
        notifyListeners();
      },
    );
  }

  // Load upcoming appointments for barber (excluding today)
  void loadUpcomingAppointments(String barberId) {
    _upcomingSubscription?.cancel();

    _upcomingSubscription =
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

  // Load upcoming appointments for client (excluding today)
  void loadClientUpcomingAppointments(String clientId) {
    _clientUpcomingSubscription?.cancel();

    _clientUpcomingSubscription =
        _bookingRepository.getClientUpcomingAppointments(clientId).listen(
      (appointments) {
        _clientUpcomingAppointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load upcoming appointments: $error';
        notifyListeners();
      },
    );
  }

  // Get appointments by status for barber
  void loadBarberAppointmentsByStatus(String barberId, String status) {
    _appointmentsSubscription?.cancel();

    _appointmentsSubscription = _bookingRepository
        .getBarberAppointmentsByStatus(barberId, status)
        .listen(
      (appointments) {
        _allAppointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load appointments: $error';
        notifyListeners();
      },
    );
  }

  // Get appointments by status for client
  void loadClientAppointmentsByStatus(String clientId, String status) {
    _clientAppointmentsSubscription?.cancel();

    _clientAppointmentsSubscription = _bookingRepository
        .getClientAppointmentsByStatus(clientId, status)
        .listen(
      (appointments) {
        _clientAppointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load appointments: $error';
        notifyListeners();
      },
    );
  }

  // Get completed appointments for barber (for earnings)
  Stream<List<AppointmentModel>> getCompletedAppointmentsStream(String barberId,
      {DateTime? startDate, DateTime? endDate}) {
    return _bookingRepository.getCompletedAppointments(barberId,
        startDate: startDate, endDate: endDate);
  }

  // Create new appointment
  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookingRepository.createAppointment(appointment);

      // Add to local state for immediate UI update
      _clientAppointments.insert(0, appointment);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update appointment status with current user ID for notification routing
  Future<void> updateAppointmentStatus(
    String appointmentId, 
    String status, {
    String? reason,
    required String currentUserId,
  }) async {
    try {
      await _bookingRepository.updateAppointmentStatus(
        appointmentId, 
        status,
        reason: reason,
        currentUserId: currentUserId,
      );

      // Update local state
      _updateAppointmentInLists(
        appointmentId, 
        (appointment) => appointment.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        )
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update appointment status: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Cancel appointment with current user ID for notification routing
  Future<void> cancelAppointment(
    String appointmentId, {
    required String currentUserId,
    String? reason,
  }) async {
    try {
      await _bookingRepository.updateAppointmentStatus(
        appointmentId, 
        'cancelled',
        reason: reason,
        currentUserId: currentUserId,
      );

      // Update local state
      _updateAppointmentInLists(
        appointmentId,
        (appointment) => appointment.copyWith(
          status: 'cancelled',
          updatedAt: DateTime.now(),
        )
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to cancel appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Reschedule appointment with current user ID for notification routing
  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDate, {
    required String currentUserId,
  }) async {
    try {
      await _bookingRepository.rescheduleAppointment(
        appointmentId, 
        newDate, 
        currentUserId,
      );

      // Update local state
      _updateAppointmentInLists(
        appointmentId,
        (appointment) => appointment.copyWith(
          date: newDate,
          status: 'rescheduled',
          updatedAt: DateTime.now(),
        )
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reschedule appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _bookingRepository.deleteAppointment(appointmentId);

      // Remove from local state
      _removeAppointmentFromLists(appointmentId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      return await _bookingRepository.getAppointmentById(appointmentId);
    } catch (e) {
      _error = 'Failed to get appointment: $e';
      notifyListeners();
      return null;
    }
  }

  // Check barber availability
  Future<bool> checkBarberAvailability(
      String barberId, DateTime dateTime) async {
    try {
      return await _bookingRepository.checkBarberAvailability(
          barberId, dateTime);
    } catch (e) {
      _error = 'Failed to check availability: $e';
      notifyListeners();
      return false;
    }
  }

  // Get available time slots for a barber
  Future<List<DateTime>> getAvailableTimeSlots(
      String barberId, DateTime date) async {
    try {
      return await _bookingRepository.getAvailableTimeSlots(barberId, date);
    } catch (e) {
      _error = 'Failed to get available slots: $e';
      notifyListeners();
      return [];
    }
  }

  // Helper method to update appointment in all lists
  void _updateAppointmentInLists(
    String appointmentId,
    AppointmentModel Function(AppointmentModel) updateFn,
  ) {
    final updateList = (List<AppointmentModel> list) {
      final index = list.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        list[index] = updateFn(list[index]);
      }
    };

    updateList(_allAppointments);
    updateList(_appointmentRequests);
    updateList(_todaysAppointments);
    updateList(_upcomingAppointments);
    updateList(_clientAppointments);
    updateList(_clientTodaysAppointments);
    updateList(_clientUpcomingAppointments);
  }

  // Helper method to remove appointment from all lists
  void _removeAppointmentFromLists(String appointmentId) {
    final removeFromList = (List<AppointmentModel> list) {
      list.removeWhere((a) => a.id == appointmentId);
    };

    removeFromList(_allAppointments);
    removeFromList(_appointmentRequests);
    removeFromList(_todaysAppointments);
    removeFromList(_upcomingAppointments);
    removeFromList(_clientAppointments);
    removeFromList(_clientTodaysAppointments);
    removeFromList(_clientUpcomingAppointments);
  }

  // Add new appointment to local state (for real-time updates)
  void addAppointment(AppointmentModel appointment) {
    _clientAppointments.insert(0, appointment);
    _updateFilteredLists();
    notifyListeners();
  }

  // Update appointment in local state
  void updateAppointment(AppointmentModel updatedAppointment) {
    final index =
        _clientAppointments.indexWhere((a) => a.id == updatedAppointment.id);
    if (index != -1) {
      _clientAppointments[index] = updatedAppointment;
      _updateFilteredLists();
      notifyListeners();
    }
  }

  // Remove appointment from local state
  void removeAppointment(String appointmentId) {
    _clientAppointments.removeWhere((a) => a.id == appointmentId);
    _updateFilteredLists();
    notifyListeners();
  }

  // Update filtered lists based on current data
  void _updateFilteredLists() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    today.add(const Duration(days: 1));

    // Update today's appointments for client
    _clientTodaysAppointments = _clientAppointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.date.year, 
        appointment.date.month, 
        appointment.date.day
      );
      return appointmentDate == today &&
          appointment.status != 'cancelled' &&
          appointment.status != 'completed';
    }).toList();

    // Update upcoming appointments for client
    _clientUpcomingAppointments = _clientAppointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.date.year, 
        appointment.date.month, 
        appointment.date.day
      );
      return appointmentDate.isAfter(today) &&
          appointment.status != 'cancelled' &&
          appointment.status != 'completed';
    }).toList();

    // Update appointment requests for barber
    _appointmentRequests = _allAppointments.where((appointment) {
      return appointment.status == 'pending' &&
          !appointment.clientId.startsWith('manual_');
    }).toList();

    // Update today's appointments for barber
    _todaysAppointments = _allAppointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.date.year, 
        appointment.date.month, 
        appointment.date.day
      );
      return appointmentDate == today &&
          appointment.status != 'cancelled' &&
          appointment.status != 'completed';
    }).toList();

    // Update upcoming appointments for barber
    _upcomingAppointments = _allAppointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.date.year, 
        appointment.date.month, 
        appointment.date.day
      );
      return appointmentDate.isAfter(today) &&
          appointment.status != 'cancelled' &&
          appointment.status != 'completed';
    }).toList();
  }

  // Get appointments for specific date
  List<AppointmentModel> getAppointmentsForDate(DateTime date) {
    return _clientAppointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return appointmentDate == targetDate;
    }).toList();
  }

  // Get appointments count by status
  Map<String, int> getAppointmentCounts() {
    final counts = <String, int>{
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (final appointment in _clientAppointments) {
      counts[appointment.status] = (counts[appointment.status] ?? 0) + 1;
    }

    return counts;
  }

  // Get upcoming appointments count (next 7 days)
  int getUpcomingAppointmentsCount() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _clientAppointments.where((appointment) {
      return appointment.date.isAfter(now) &&
          appointment.date.isBefore(nextWeek) &&
          appointment.status != 'cancelled' &&
          appointment.status != 'completed';
    }).length;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data for client
  void refreshClientData(String clientId) {
    _clientAppointments.clear();
    _clientTodaysAppointments.clear();
    _clientUpcomingAppointments.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();

    loadClientAppointments(clientId);
    loadClientTodaysAppointments(clientId);
    loadClientUpcomingAppointments(clientId);
  }

  // Refresh all data for barber
  void refreshBarberData(String barberId) {
    _allAppointments.clear();
    _appointmentRequests.clear();
    _todaysAppointments.clear();
    _upcomingAppointments.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();

    loadBarberAppointments(barberId);
    loadAppointmentRequests(barberId);
    loadTodaysAppointments(barberId);
    loadUpcomingAppointments(barberId);
  }

  // Set current filter
  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Get filtered appointments based on current filter
  List<AppointmentModel> get filteredAppointments {
    switch (_currentFilter) {
      case 'today':
        return _clientTodaysAppointments;
      case 'upcoming':
        return _clientUpcomingAppointments;
      case 'pending':
        return _clientAppointments.where((a) => a.status == 'pending').toList();
      case 'completed':
        return _clientAppointments
            .where((a) => a.status == 'completed')
            .toList();
      case 'cancelled':
        return _clientAppointments
            .where((a) => a.status == 'cancelled')
            .toList();
      default:
        return _clientAppointments;
    }
  }

  // Search appointments
  List<AppointmentModel> searchAppointments(String query) {
    if (query.isEmpty) return _clientAppointments;

    final lowercaseQuery = query.toLowerCase();
    return _clientAppointments.where((appointment) {
      return appointment.barberName?.toLowerCase().contains(lowercaseQuery) ==
              true ||
          appointment.serviceName?.toLowerCase().contains(lowercaseQuery) ==
              true ||
          appointment.notes?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  // Dispose all subscriptions
  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _todaySubscription?.cancel();
    _upcomingSubscription?.cancel();
    _clientAppointmentsSubscription?.cancel();
    _clientTodaySubscription?.cancel();
    _clientUpcomingSubscription?.cancel();
    super.dispose();
  }
}