import 'package:hive/hive.dart';
import '../models/appointment_model.dart';
import '../models/payment_model.dart';
import '../models/service_model.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';

// AppointmentModel Adapter
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
      price: (fields[7] as num?)?.toDouble(),
      status: fields[8] as String,
      notes: fields[9] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[10] as int),
      updatedAt: fields[11] != null ? DateTime.fromMillisecondsSinceEpoch(fields[11] as int) : null,
      hasReminder: fields[12] as bool? ?? false,
      reminderMinutes: fields[13] as int?,
      reminderNote: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
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
      amount: (fields[4] as num).toDouble(),
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ServiceModel Adapter
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
      price: (fields[4] as num).toDouble(),
      duration: fields[5] as int,
      isActive: fields[6] as bool? ?? true,
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ChatRoom Adapter
class ChatRoomAdapter extends TypeAdapter<ChatRoom> {
  @override
  final int typeId = 3;

  @override
  ChatRoom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    
    return ChatRoom(
      id: fields[0] as String,
      clientId: fields[1] as String,
      clientName: fields[2] as String,
      barberId: fields[3] as String,
      barberName: fields[4] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      lastMessage: fields[7] != null ? ChatMessage.fromMap(Map<String, dynamic>.from(fields[7])) : null,
      unreadCount: fields[8] as int? ?? 0,
      isActive: fields[9] as bool? ?? true,
      lastAppointmentId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatRoom obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.clientName)
      ..writeByte(3)
      ..write(obj.barberId)
      ..writeByte(4)
      ..write(obj.barberName)
      ..writeByte(5)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.lastMessage?.toMap())
      ..writeByte(8)
      ..write(obj.unreadCount)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.lastAppointmentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ChatMessage Adapter
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 4;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    
    return ChatMessage(
      id: fields[0] as String,
      chatId: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String,
      senderType: fields[4] as String,
      message: fields[5] as String,
      type: _parseMessageType(fields[6] as String?),
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      isRead: fields[8] as bool? ?? false,
      readAt: fields[9] != null ? DateTime.fromMillisecondsSinceEpoch(fields[9] as int) : null,
      attachmentUrl: fields[10] as String?,
      attachmentType: fields[11] as String?,
    );
  }

  MessageType _parseMessageType(String? typeString) {
    if (typeString == null) return MessageType.text;
    
    switch (typeString) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.senderType)
      ..writeByte(5)
      ..write(obj.message)
      ..writeByte(6)
      ..write(obj.type.name)
      ..writeByte(7)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.isRead)
      ..writeByte(9)
      ..write(obj.readAt?.millisecondsSinceEpoch)
      ..writeByte(10)
      ..write(obj.attachmentUrl)
      ..writeByte(11)
      ..write(obj.attachmentType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// MessageType Adapter
class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 5;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.image;
      case 2:
        return MessageType.document;
      case 3:
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.text:
        writer.writeByte(0);
        break;
      case MessageType.image:
        writer.writeByte(1);
        break;
      case MessageType.document:
        writer.writeByte(2);
        break;
      case MessageType.system:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}