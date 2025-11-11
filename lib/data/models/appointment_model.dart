import 'package:hive/hive.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import '../models/payment_model.dart';

// AppointmentModel Adapter
class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 0;

  @override
  AppointmentModel read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{};

      for (var i = 0; i < numOfFields; i++) {
        final key = reader.readByte();
        final value = reader.read();
        fields[key] = value;
      }

      return AppointmentModel(
        id: fields[0] as String? ?? '',
        barberId: fields[1] as String? ?? '',
        clientId: fields[2] as String? ?? '',
        clientName: fields[3] as String?,
        barberName: fields[4] as String?,
        date: fields[5] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int)
            : DateTime.now(),
        serviceName: fields[6] as String?,
        price: (fields[7] as num?)?.toDouble(),
        status: fields[8] as String? ?? 'pending',
        notes: fields[9] as String?,
        createdAt: fields[10] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[10] as int)
            : DateTime.now(),
        updatedAt: fields[11] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[11] as int)
            : null,
        hasReminder: fields[12] as bool? ?? false,
        reminderMinutes: fields[13] as int?,
        reminderNote: fields[14] as String?,
      );
    } catch (e) {
      print('Error reading AppointmentModel: $e');
      return AppointmentModel(
        id: 'default_id',
        barberId: 'default_barber',
        clientId: 'default_client',
        date: DateTime.now(),
        status: 'pending',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    try {
      writer
        ..writeByte(15)
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
        ..write(obj.updatedAt?.millisecondsSinceEpoch)
        ..writeByte(12)
        ..write(obj.hasReminder)
        ..writeByte(13)
        ..write(obj.reminderMinutes)
        ..writeByte(14)
        ..write(obj.reminderNote);
    } catch (e) {
      print('Error writing AppointmentModel: $e');
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// PaymentModel Adapter
class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 1;

  @override
  PaymentModel read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{};

      for (var i = 0; i < numOfFields; i++) {
        final key = reader.readByte();
        final value = reader.read();
        fields[key] = value;
      }

      return PaymentModel(
        id: fields[0] as String? ?? '',
        appointmentId: fields[1] as String? ?? '',
        clientId: fields[2] as String? ?? '',
        barberId: fields[3] as String? ?? '',
        amount: (fields[4] as num?)?.toDouble() ?? 0.0,
        status: fields[5] as String? ?? 'pending',
        paymentMethod: fields[6] as String? ?? 'card',
        transactionId: fields[7] as String?,
        createdAt: fields[8] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[8] as int)
            : DateTime.now(),
        completedAt: fields[9] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[9] as int)
            : null,
        failureReason: fields[10] as String?,
      );
    } catch (e) {
      print('Error reading PaymentModel: $e');
      return PaymentModel(
        id: 'default_id',
        appointmentId: 'default_appointment',
        clientId: 'default_client',
        barberId: 'default_barber',
        amount: 0.0,
        status: 'pending',
        paymentMethod: 'card',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    try {
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
    } catch (e) {
      print('Error writing PaymentModel: $e');
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
