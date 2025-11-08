import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/firestore_helper.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new review
  Future<void> createReview(ReviewModel review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .set(review.toMap());
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a barber (real-time)
  Stream<List<ReviewModel>> getBarberReviews(String barberId) {
    return _firestore
        .collection('reviews')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = FirestoreHelper.safeExtractQueryData(doc);
              return ReviewModel.fromMap(data);
            })
            .toList());
  }

  // Get reviews by a client (real-time)
  Stream<List<ReviewModel>> getClientReviews(String clientId) {
    return _firestore
        .collection('reviews')
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = FirestoreHelper.safeExtractQueryData(doc);
              return ReviewModel.fromMap(data);
            })
            .toList());
  }

  // Get review by appointment ID
  Future<ReviewModel?> getReviewByAppointment(String appointmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ReviewModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }

  // Update a review
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .update(review.toMap());
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review (soft delete)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update({
            'isActive': false,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get barber's average rating
  Stream<double> getBarberAverageRating(String barberId) {
    return _firestore
        .collection('reviews')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 0.0;
          
          final totalRating = snapshot.docs.fold(0, (sum, doc) {
            final data = doc.data();
            return sum + (data['rating'] as int);
          });
          
          return totalRating / snapshot.docs.length;
        });
  }

  // Get barber's review count
  Stream<int> getBarberReviewCount(String barberId) {
    return _firestore
        .collection('reviews')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get review distribution (number of reviews per rating)
  Stream<Map<int, int>> getBarberReviewDistribution(String barberId) {
    return _firestore
        .collection('reviews')
        .where('barberId', isEqualTo: barberId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rating = data['rating'] as int;
            distribution[rating] = (distribution[rating] ?? 0) + 1;
          }
          
          return distribution;
        });
  }
}