import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentRepository _paymentRepository = PaymentRepository();
  
  List<PaymentModel> _clientPayments = [];
  List<PaymentModel> _barberPayments = [];
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _paymentMethods = {};

  // Getters
  List<PaymentModel> get clientPayments => _clientPayments;
  List<PaymentModel> get barberPayments => _barberPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get paymentMethods => _paymentMethods;

  // Load client payments with real-time updates
  void loadClientPayments(String clientId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _paymentRepository.getClientPayments(clientId).listen(
      (payments) {
        _clientPayments = payments;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load payments: $error';
        notifyListeners();
      },
    );
  }

  // Load payment by appointment stream
  Stream<PaymentModel?> getPaymentByAppointmentStream(String appointmentId) {
    return _paymentRepository.getPaymentByAppointmentStream(appointmentId);
  }

  // Load barber payments with real-time updates
  void loadBarberPayments(String barberId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _paymentRepository.getBarberPayments(barberId).listen(
      (payments) {
        _barberPayments = payments;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load payments: $error';
        notifyListeners();
      },
    );
  }

  // Create payment
  Future<void> createPayment(PaymentModel payment) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _paymentRepository.createPayment(payment);
      
      // Add to local state for immediate UI update
      _clientPayments.insert(0, payment);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String paymentId, String status, String? transactionId) async {
    try {
      await _paymentRepository.updatePaymentStatus(paymentId, status, transactionId);
      
      // Update local state
      _updatePaymentInLists(paymentId, status, transactionId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update payment status: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Process Stripe payment
  Future<Map<String, dynamic>> processStripePayment({
    required String paymentId,
    required double amount,
    required String barberStripeAccountId,
    required String clientEmail,
    required String currency,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _paymentRepository.processStripePayment(
        paymentId: paymentId,
        amount: amount,
        barberStripeAccountId: barberStripeAccountId,
        clientEmail: clientEmail,
        currency: currency,
      );
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to process payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Confirm Stripe payment
  Future<Map<String, dynamic>> confirmStripePayment({
    required String paymentIntentId,
    required String clientSecret,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _paymentRepository.confirmStripePayment(
        paymentIntentId: paymentIntentId,
        clientSecret: clientSecret,
      );
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to confirm payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Process mobile money payment
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required String paymentId,
    required double amount,
    required String phoneNumber,
    required String provider,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _paymentRepository.processMobileMoneyPayment(
        paymentId: paymentId,
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
      );
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to process mobile money payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get payment by appointment
  Future<PaymentModel?> getPaymentByAppointment(String appointmentId) async {
    try {
      return await _paymentRepository.getPaymentByAppointment(appointmentId);
    } catch (e) {
      _error = 'Failed to get payment: $e';
      notifyListeners();
      return null;
    }
  }

  // Get barber's Stripe status
  Future<Map<String, dynamic>> getBarberStripeStatus(String barberId) async {
    try {
      return await _paymentRepository.getBarberStripeStatus(barberId);
    } catch (e) {
      _error = 'Failed to get Stripe status: $e';
      notifyListeners();
      return {
        'connected': false,
        'verified': false,
        'error': e.toString(),
      };
    }
  }

  // Add payment method
  Future<void> addPaymentMethod(Map<String, dynamic> paymentMethod) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Simulate API call to save payment method
      await Future.delayed(const Duration(seconds: 2));
      
      final methodId = 'pm_${DateTime.now().millisecondsSinceEpoch}';
      _paymentMethods[methodId] = {
        ...paymentMethod,
        'id': methodId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isDefault': _paymentMethods.isEmpty, // First method becomes default
      };
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to add payment method: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Remove payment method
  Future<void> removePaymentMethod(String methodId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Simulate API call to remove payment method
      await Future.delayed(const Duration(seconds: 1));
      
      _paymentMethods.remove(methodId);
      
      // If we removed the default method, set a new default
      if (_paymentMethods.isNotEmpty) {
        final firstMethod = _paymentMethods.values.first;
        firstMethod['isDefault'] = true;
      }
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to remove payment method: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(String methodId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Remove default from all methods
      for (final method in _paymentMethods.values) {
        method['isDefault'] = false;
      }
      
      // Set new default
      if (_paymentMethods.containsKey(methodId)) {
        _paymentMethods[methodId]!['isDefault'] = true;
      }
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to set default payment method: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get default payment method
  Map<String, dynamic>? getDefaultPaymentMethod() {
    return _paymentMethods.values.firstWhere(
      (method) => method['isDefault'] == true,
      orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods.values.first : null,
    );
  }

  // Helper method to update payment in lists
  void _updatePaymentInLists(String paymentId, String status, String? transactionId) {
    final updateList = (List<PaymentModel> list) {
      final index = list.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        final updatedPayment = list[index].copyWith(
          status: status,
          transactionId: transactionId,
          completedAt: status == 'completed' ? DateTime.now() : null,
        );
        list[index] = updatedPayment;
      }
    };

    updateList(_clientPayments);
    updateList(_barberPayments);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh client payments
  void refreshClientPayments(String clientId) {
    _clientPayments.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    loadClientPayments(clientId);
  }

  // Refresh barber payments
  void refreshBarberPayments(String barberId) {
    _barberPayments.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    loadBarberPayments(barberId);
  }

  // Get payment statistics
  Map<String, dynamic> getPaymentStatistics() {
    final completedPayments = _clientPayments.where((p) => p.status == 'completed').toList();
    final totalSpent = completedPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    final averagePayment = completedPayments.isNotEmpty ? totalSpent / completedPayments.length : 0.0;
    
    return {
      'totalSpent': totalSpent,
      'totalTransactions': completedPayments.length,
      'averagePayment': averagePayment,
      'pendingPayments': _clientPayments.where((p) => p.status == 'pending').length,
      'failedPayments': _clientPayments.where((p) => p.status == 'failed').length,
    };
  }

  // Get recent payments (last 30 days)
  List<PaymentModel> getRecentPayments() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _clientPayments.where((payment) => 
      payment.createdAt.isAfter(thirtyDaysAgo)
    ).toList();
  }

  // Check if payment exists for appointment
  bool hasPaymentForAppointment(String appointmentId) {
    return _clientPayments.any((payment) => payment.appointmentId == appointmentId);
  }

  // Get payment by ID
  PaymentModel? getPaymentById(String paymentId) {
    try {
      return _clientPayments.firstWhere((payment) => payment.id == paymentId);
    } catch (e) {
      return null;
    }
  }
}