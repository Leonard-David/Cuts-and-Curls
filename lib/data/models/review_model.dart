// lib/data/models/review_model.dart
// Model for reviews/ratings left by clients.
// Maps to /reviews/{reviewId}

class ReviewModel {
  final String id;
  final String appointmentId;
  final String clientId;
  final String barberId;
  final int rating; // 1..5
  final String? comment;
  final int createdAtEpoch;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.barberId,
    required this.rating,
    this.comment,
    required this.createdAtEpoch,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      clientId: map['clientId'] ?? '',
      barberId: map['barberId'] ?? '',
      rating: (map['rating'] is int) ? map['rating'] as int : (map['rating'] is num ? (map['rating'] as num).toInt() : 0),
      comment: map['comment'] as String?,
      createdAtEpoch: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toMap() => {
        'appointmentId': appointmentId,
        'clientId': clientId,
        'barberId': barberId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAtEpoch,
      }..removeWhere((k, v) => v == null);
}
