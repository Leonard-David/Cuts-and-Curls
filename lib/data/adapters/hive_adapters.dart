import 'package:hive/hive.dart';
import '../models/appointment_model.dart';
import '../models/payment_model.dart';
import '../models/service_model.dart';

// Hive Adapter for AppointmentModel
class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 0;

  @override
  AppointmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    
    return AppointmentModel(
      id: fields[0] as String,
      barberId: fields[1] as String,
      clientId: fields[2] as String,
      clientName: fields[3] as String?,
      barberName: fields[4] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      serviceName: fields[6] as String?,
      price: fields[7] as double?,
      status: fields[8] as String,
      notes: fields[9] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[10] as int),
      updatedAt: fields[11] != null ? DateTime.fromMillisecondsSinceEpoch(fields[11] as int) : null,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barberId)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.clientName)
      ..writeByte(4)
      ..write(obj.barberName)
      ..writeByte(5)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.serviceName)
      ..writeByte(7)
      ..write(obj.price)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(11)
      ..write(obj.updatedAt?.millisecondsSinceEpoch);
  }
}

// Hive Adapter for PaymentModel
class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 1;

  @override
  PaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    
    return PaymentModel(
      id: fields[0] as String,
      appointmentId: fields[1] as String,
      clientId: fields[2] as String,
      barberId: fields[3] as String,
      amount: fields[4] as double,
      status: fields[5] as String,
      paymentMethod: fields[6] as String,
      transactionId: fields[7] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
      completedAt: fields[9] != null ? DateTime.fromMillisecondsSinceEpoch(fields[9] as int) : null,
      failureReason: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.appointmentId)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.barberId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.paymentMethod)
      ..writeByte(7)
      ..write(obj.transactionId)
      ..writeByte(8)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(9)
      ..write(obj.completedAt?.millisecondsSinceEpoch)
      ..writeByte(10)
      ..write(obj.failureReason);
  }
}

// Hive Adapter for ServiceModel
class ServiceModelAdapter extends TypeAdapter<ServiceModel> {
  @override
  final int typeId = 2;

  @override
  ServiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    
    return ServiceModel(
      id: fields[0] as String,
      barberId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String,
      price: fields[4] as double,
      duration: fields[5] as int,
      isActive: fields[6] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      category: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barberId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.category);
  }
}