class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String userType; // 'client', 'barber', or 'hairstylist'
  final DateTime createdAt;
  final bool isOnline;
  final bool isEmailVerified;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final double? rating;
  final int? totalRatings;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    required this.createdAt,
    required this.isOnline,
    required this.isEmailVerified,
    this.phone,
    this.profileImage,
    this.bio,
    this.rating,
    this.totalRatings,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'userType': userType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'isEmailVerified': isEmailVerified,
      'phone': phone,
      'profileImage': profileImage,
      'bio': bio,
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  // Create model from Firestore data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      fullName: map['fullName'],
      userType: map['userType'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isOnline: map['isOnline'] ?? false,
      isEmailVerified: map['isEmailVerified'] ?? false,
      phone: map['phone'],
      profileImage: map['profileImage'],
      bio: map['bio'],
      rating: map['rating']?.toDouble(),
      totalRatings: map['totalRatings'],
    );
  }

  // Create copy with method for updates
  UserModel copyWith({
    String? fullName,
    bool? isOnline,
    bool? isEmailVerified,
    String? phone,
    String? profileImage,
    String? bio,
    double? rating,
    int? totalRatings,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      userType: userType,
      createdAt: createdAt,
      isOnline: isOnline ?? this.isOnline,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }

  // Helper method to check if user is a service provider (barber or hairstylist)
  bool get isServiceProvider {
    return userType == 'barber' || userType == 'hairstylist';
  }

  // Helper method to get display name for user type
  String get userTypeDisplayName {
    switch (userType) {
      case 'barber':
        return 'Barber';
      case 'hairstylist':
        return 'Hairstylist';
      case 'client':
        return 'Client';
      default:
        return 'User';
    }
  }
}