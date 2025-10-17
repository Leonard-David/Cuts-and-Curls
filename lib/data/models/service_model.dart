// lib/data/models/service_model.dart
// Model representing a barber's offered service.
// Maps to /services/{serviceId}

class ServiceModel {
  final String id;
  final String barberId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes; // length of service
  final bool available;
  final int createdAtEpoch; // unix seconds

  ServiceModel({
    required this.id,
    required this.barberId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.available = true,
    required this.createdAtEpoch,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      barberId: map['barberId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] as String?,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      durationMinutes: map['durationMinutes'] ?? 30,
      available: map['available'] ?? true,
      createdAtEpoch: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toMap() => {
        'barberId': barberId,
        'name': name,
        'description': description,
        'price': price,
        'durationMinutes': durationMinutes,
        'available': available,
        'createdAt': createdAtEpoch,
      }..removeWhere((k, v) => v == null);
}
