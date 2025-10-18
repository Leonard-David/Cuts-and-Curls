import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String barberId;
  final String name;
  final double price;
  final int duration; // minutes
  final String description;

  ServiceModel({
    required this.id,
    required this.barberId,
    required this.name,
    required this.price,
    required this.duration,
    required this.description,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> data, String docId) {
    return ServiceModel(
      id: docId,
      barberId: data['barberId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      duration: data['duration'] ?? 0,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barberId': barberId,
      'name': name,
      'price': price,
      'duration': duration,
      'description': description,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
