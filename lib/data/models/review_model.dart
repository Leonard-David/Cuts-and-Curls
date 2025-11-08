class ReviewModel {
  final String id;
  final String appointmentId;
  final String barberId;
  final String clientId;
  final String clientName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.barberId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      appointmentId: map['appointmentId'],
      barberId: map['barberId'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      rating: map['rating'],
      comment: map['comment'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'barberId': barberId,
      'clientId': clientId,
      'clientName': clientName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? appointmentId,
    String? barberId,
    String? clientId,
    String? clientName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      barberId: barberId ?? this.barberId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}