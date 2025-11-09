import 'package:hive/hive.dart';

part 'service_model.g.dart'; // Add this line for Hive code generation

@HiveType(typeId: 2)
class ServiceModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String barberId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final double price;
  
  @HiveField(5)
  final int duration;
  
  @HiveField(6)
  final bool isActive;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final String? category;

  ServiceModel({
    required this.id,
    required this.barberId,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.isActive = true,
    required this.createdAt,
    this.category,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barberId': barberId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'category': category,
    };
  }

  // Create model from Firestore data
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      barberId: map['barberId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is int ? (map['price'] as int).toDouble() : map['price']) ?? 0.0,
      duration: map['duration'] ?? 30,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      category: map['category'],
    );
  }

  // Create model from Hive data (Map)
  factory ServiceModel.fromHiveMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      barberId: map['barberId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      duration: map['duration'] ?? 30,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      category: map['category'],
    );
  }

  // Convert to Hive-compatible map
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'barberId': barberId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'category': category,
    };
  }

  // Create copy with method for updates
  ServiceModel copyWith({
    String? id,
    String? barberId,
    String? name,
    String? description,
    double? price,
    int? duration,
    bool? isActive,
    DateTime? createdAt,
    String? category,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      barberId: barberId ?? this.barberId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}