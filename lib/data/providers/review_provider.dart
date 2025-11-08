import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewRepository _reviewRepository = ReviewRepository();
  
  List<ReviewModel> _barberReviews = [];
  List<ReviewModel> _clientReviews = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ReviewModel> get barberReviews => _barberReviews;
  List<ReviewModel> get clientReviews => _clientReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load reviews for a barber with real-time updates
  void loadBarberReviews(String barberId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _reviewRepository.getBarberReviews(barberId).listen(
      (reviews) {
        _barberReviews = reviews;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load reviews: $error';
        notifyListeners();
      },
    );
  }

  // Load reviews by a client with real-time updates
  void loadClientReviews(String clientId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _reviewRepository.getClientReviews(clientId).listen(
      (reviews) {
        _clientReviews = reviews;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load reviews: $error';
        notifyListeners();
      },
    );
  }

  // Create a new review
  Future<void> createReview(ReviewModel review) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _reviewRepository.createReview(review);
      
      // Add to local state for immediate UI update
      _clientReviews.insert(0, review);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create review: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update a review
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _reviewRepository.updateReview(review);
      
      // Update local state
      _updateReviewInLists(review);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update review: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _reviewRepository.deleteReview(reviewId);
      
      // Remove from local state
      _removeReviewFromLists(reviewId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete review: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get review by appointment
  Future<ReviewModel?> getReviewByAppointment(String appointmentId) async {
    try {
      return await _reviewRepository.getReviewByAppointment(appointmentId);
    } catch (e) {
      _error = 'Failed to get review: $e';
      notifyListeners();
      return null;
    }
  }

  // Get barber's average rating stream
  Stream<double> getBarberAverageRating(String barberId) {
    return _reviewRepository.getBarberAverageRating(barberId);
  }

  // Get barber's review count stream
  Stream<int> getBarberReviewCount(String barberId) {
    return _reviewRepository.getBarberReviewCount(barberId);
  }

  // Get review distribution stream
  Stream<Map<int, int>> getBarberReviewDistribution(String barberId) {
    return _reviewRepository.getBarberReviewDistribution(barberId);
  }

  // Helper method to update review in lists
  void _updateReviewInLists(ReviewModel updatedReview) {
    final updateList = (List<ReviewModel> list) {
      final index = list.indexWhere((r) => r.id == updatedReview.id);
      if (index != -1) {
        list[index] = updatedReview;
      }
    };

    updateList(_barberReviews);
    updateList(_clientReviews);
  }

  // Helper method to remove review from lists
  void _removeReviewFromLists(String reviewId) {
    final removeFromList = (List<ReviewModel> list) {
      list.removeWhere((r) => r.id == reviewId);
    };

    removeFromList(_barberReviews);
    removeFromList(_clientReviews);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh barber reviews
  void refreshBarberReviews(String barberId) {
    _barberReviews.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    loadBarberReviews(barberId);
  }

  // Refresh client reviews
  void refreshClientReviews(String clientId) {
    _clientReviews.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    loadClientReviews(clientId);
  }

  // Check if client has reviewed an appointment
  bool hasClientReviewedAppointment(String appointmentId) {
    return _clientReviews.any((review) => review.appointmentId == appointmentId);
  }

  // Get client's review for an appointment
  ReviewModel? getClientReviewForAppointment(String appointmentId) {
    try {
      return _clientReviews.firstWhere(
        (review) => review.appointmentId == appointmentId,
      );
    } catch (e) {
      return null;
    }
  }
}