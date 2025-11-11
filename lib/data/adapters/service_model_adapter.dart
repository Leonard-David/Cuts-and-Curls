// ServiceModel Adapter
import 'package:hive/hive.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/models/service_model.dart';

class ServiceModelAdapter extends TypeAdapter<ServiceModel> {
  @override
  final int typeId = 2;

  @override
  ServiceModel read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{};

      for (var i = 0; i < numOfFields; i++) {
        final key = reader.readByte();
        final value = reader.read();
        fields[key] = value;
      }

      return ServiceModel(
        id: fields[0] as String? ?? '',
        barberId: fields[1] as String? ?? '',
        name: fields[2] as String? ?? '',
        description: fields[3] as String? ?? '',
        price: (fields[4] as num?)?.toDouble() ?? 0.0,
        duration: fields[5] as int? ?? 30,
        isActive: fields[6] as bool? ?? true,
        createdAt: fields[7] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int)
            : DateTime.now(),
        category: fields[8] as String?,
      );
    } catch (e) {
      print('Error reading ServiceModel: $e');
      return ServiceModel(
        id: 'default_id',
        barberId: 'default_barber',
        name: 'Default Service',
        description: 'Service description',
        price: 0.0,
        duration: 30,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  void write(BinaryWriter writer, ServiceModel obj) {
    try {
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
    } catch (e) {
      print('Error writing ServiceModel: $e');
    }
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

class ChatRoomAdapter extends TypeAdapter<ChatRoom> {
  @override
  final int typeId = 3;

  @override
  ChatRoom read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{};

      for (var i = 0; i < numOfFields; i++) {
        final key = reader.readByte();
        final value = reader.read();
        fields[key] = value;
      }

      // Handle lastMessage separately to prevent recursion
      Map<String, dynamic>? lastMessageMap;
      try {
        final lastMessageData = fields[7];
        if (lastMessageData != null && lastMessageData is Map) {
          lastMessageMap = Map<String, dynamic>.from(lastMessageData);
        }
      } catch (e) {
        print('Error parsing lastMessage: $e');
      }

      return ChatRoom(
        id: fields[0] as String? ?? '',
        clientId: fields[1] as String? ?? '',
        clientName: fields[2] as String? ?? '',
        barberId: fields[3] as String? ?? '',
        barberName: fields[4] as String? ?? '',
        createdAt: fields[5] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int)
            : DateTime.now(),
        updatedAt: fields[6] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[6] as int)
            : DateTime.now(),
        lastMessage:
            lastMessageMap != null ? ChatMessage.fromMap(lastMessageMap) : null,
        unreadCount: fields[8] as int? ?? 0,
        isActive: fields[9] as bool? ?? true,
        // Removed lastAppointmentId since it's not in the model
      );
    } catch (e) {
      print('Error reading ChatRoom: $e');
      return ChatRoom(
        id: 'default_chat',
        clientId: 'default_client',
        clientName: 'Client',
        barberId: 'default_barber',
        barberName: 'Barber',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        unreadCount: 0,
        isActive: true,
      );
    }
  }

  @override
  void write(BinaryWriter writer, ChatRoom obj) {
    try {
      // Convert lastMessage to simple map without recursion
      Map<String, dynamic>? lastMessageMap;
      if (obj.lastMessage != null) {
        lastMessageMap = {
          'id': obj.lastMessage!.id,
          'chatId': obj.lastMessage!.chatId,
          'senderId': obj.lastMessage!.senderId,
          'senderName': obj.lastMessage!.senderName,
          'senderType': obj.lastMessage!.senderType,
          'message': obj.lastMessage!.message,
          'type': obj.lastMessage!.type.name,
          'timestamp': obj.lastMessage!.timestamp.millisecondsSinceEpoch,
          'isRead': obj.lastMessage!.isRead,
          'readAt': obj.lastMessage!.readAt?.millisecondsSinceEpoch,
          'attachmentUrl': obj.lastMessage!.attachmentUrl,
          'attachmentType': obj.lastMessage!.attachmentType,
        };
      }

      // Write only 10 fields (removed lastAppointmentId)
      writer
        ..writeByte(10) // Changed from 11 to 10
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
        ..write(lastMessageMap)
        ..writeByte(8)
        ..write(obj.unreadCount)
        ..writeByte(9)
        ..write(obj.isActive);
      // Removed field 10 (lastAppointmentId)
    } catch (e) {
      print('Error writing ChatRoom: $e');
    }
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
  ChatMessage read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{};

      for (var i = 0; i < numOfFields; i++) {
        final key = reader.readByte();
        final value = reader.read();
        fields[key] = value;
      }

      return ChatMessage(
        id: fields[0] as String? ?? '',
        chatId: fields[1] as String? ?? '',
        senderId: fields[2] as String? ?? '',
        senderName: fields[3] as String? ?? '',
        senderType: fields[4] as String? ?? 'client',
        message: fields[5] as String? ?? '',
        type: _parseMessageType(fields[6] as String?),
        timestamp: fields[7] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int)
            : DateTime.now(),
        isRead: fields[8] as bool? ?? false,
        readAt: fields[9] != null
            ? DateTime.fromMillisecondsSinceEpoch(fields[9] as int)
            : null,
        attachmentUrl: fields[10] as String?,
        attachmentType: fields[11] as String?,
        data: {},
      );
    } catch (e) {
      print('Error reading ChatMessage: $e');
      return ChatMessage(
        id: 'default_msg',
        chatId: 'default_chat',
        senderId: 'default_sender',
        senderName: 'Sender',
        senderType: 'client',
        message: 'Default message',
        timestamp: DateTime.now(),
        isRead: false,
        data: {},
      );
    }
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    try {
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
    } catch (e) {
      print('Error writing ChatMessage: $e');
    }
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
    try {
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
    } catch (e) {
      print('Error reading MessageType: $e');
      return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    try {
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
    } catch (e) {
      print('Error writing MessageType: $e');
      writer.writeByte(0); // Default to text
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
