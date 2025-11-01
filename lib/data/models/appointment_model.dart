import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class AppointmentModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String barberId;
  
  @HiveField(2)
  final String clientId;
  
  @HiveField(3)
  final String? clientName;
  
  @HiveField(4)
  final String? barberName;
  
  @HiveField(5)
  final DateTime date;
  
  @HiveField(6)
  final String? serviceName;
  
  @HiveField(7)
  final double? price;
  
  @HiveField(8)
  final String status;
  
  @HiveField(9)
  final String? notes;
  
  @HiveField(10)
  final DateTime createdAt;
  
  @HiveField(11)
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.barberId,
    required this.clientId,
    this.clientName,
    this.barberName,
    required this.date,
    this.serviceName,
    this.price,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barberId': barberId,
      'clientId': clientId,
      'clientName': clientName,
      'barberName': barberName,
      'date': date.millisecondsSinceEpoch,
      'serviceName': serviceName,
      'price': price,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create model from Firestore data
  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      barberId: map['barberId'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      barberName: map['barberName'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      serviceName: map['serviceName'],
      price: map['price']?.toDouble(),
      status: map['status'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  // Create copy with method for updates
  AppointmentModel copyWith({
    String? barberId,
    String? clientId,
    String? clientName,
    String? barberName,
    DateTime? date,
    String? serviceName,
    double? price,
    String? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id,
      barberId: barberId ?? this.barberId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      barberName: barberName ?? this.barberName,
      date: date ?? this.date,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}