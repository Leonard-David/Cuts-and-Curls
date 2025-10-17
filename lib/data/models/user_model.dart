// lib/data/models/user_model.dart
// Model representing a user (client, barber, admin).
// This maps to /users/{userId} in Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for user roles. Keeps role values consistent.
enum UserRole { client, barber, admin }

/// User model
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? photoUrl;
  final String? bio;
  final GeoPoint? location; // Firestore GeoPoint (optional)
  final double rating; // average rating
  final int createdAtEpoch; // unix seconds - helpful for queries

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.photoUrl,
    this.bio,
    this.location,
    this.rating = 0.0,
    required this.createdAtEpoch,
  });

  /// Convert Firestore document data to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    // parse role string into enum
    UserRole role = UserRole.client;
    final r = map['role'] as String?;
    if (r == 'barber') {
      role = UserRole.barber;
    } else if (r == 'admin') {
      role = UserRole.admin;
    }

    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] as String?,
      role: role,
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      location: map['location'] as GeoPoint?,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      createdAtEpoch: map['createdAt'] != null
          ? (map['createdAt'] as int)
          : DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Convert model to Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role
          .toString()
          .split('.')
          .last, // store as 'client'|'barber'|'admin'
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'rating': rating,
      'createdAt': createdAtEpoch,
    }..removeWhere((key, value) => value == null); // remove nulls
  }
}
