import 'chat_message_model.dart';

class ChatRoom {
  final String id;
  final String clientId;
  final String clientName;
  final String barberId;
  final String barberName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isActive;
  final String? lastAppointmentId;

  ChatRoom({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.barberId,
    required this.barberName,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isActive = true,
    this.lastAppointmentId,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'barberId': barberId,
      'barberName': barberName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'lastAppointmentId': lastAppointmentId,
    };
  }

  // Create model from Firestore data
  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      barberId: map['barberId'] ?? '',
      barberName: map['barberName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
      lastMessage: map['lastMessage'] != null 
          ? ChatMessage.fromMap(Map<String, dynamic>.from(map['lastMessage']))
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      lastAppointmentId: map['lastAppointmentId'],
    );
  }

  // Create copy with method for updates
  ChatRoom copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? barberId,
    String? barberName,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatMessage? lastMessage,
    int? unreadCount,
    bool? isActive,
    String? lastAppointmentId,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      lastAppointmentId: lastAppointmentId ?? this.lastAppointmentId,
    );
  }

  // Generate chat ID from client and barber IDs
  static String generateChatId(String clientId, String barberId) {
    final ids = [clientId, barberId]..sort();
    return 'chat_${ids.join('_')}';
  }
}