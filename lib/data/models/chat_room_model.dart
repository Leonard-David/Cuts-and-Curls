import 'chat_message_model.dart';

class ChatRoom {
  final String id;
  final String clientId;
  final String clientName;
  final String barberId;
  final String barberName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isActive;
  final ChatMessage? lastMessage;

  const ChatRoom({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.barberId,
    required this.barberName,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCount,
    required this.isActive,
    this.lastMessage,
  });

  // Generate consistent chat ID
  static String generateChatId(String clientId, String barberId) {
    final ids = [clientId, barberId]..sort();
    return 'chat_${ids.join('_')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'barberId': barberId,
      'barberName': barberName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'lastMessage': lastMessage?.toMap(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      barberId: map['barberId'] ?? '',
      barberName: map['barberName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      lastMessage: map['lastMessage'] != null 
          ? ChatMessage.fromMap(Map<String, dynamic>.from(map['lastMessage']))
          : null,
    );
  }

  ChatRoom copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? barberId,
    String? barberName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isActive,
    ChatMessage? lastMessage,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, clientName: $clientName, barberName: $barberName, unreadCount: $unreadCount)';
  }
}