class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'client' or 'barber'
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final String? attachmentUrl;
  final String? attachmentType; // image, document, etc.

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.attachmentUrl,
    this.attachmentType,
    required Map<String, String> data,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
    };
  }

  // Create model from Firestore data
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderType: map['senderType'] ?? '',
      message: map['message'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
      data: {},
    );
  }

  static MessageType _parseMessageType(String? typeString) {
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

  // Create copy with method for updates
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? message,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      data: {},
    );
  }
}

enum MessageType {
  text,
  image,
  document,
  system,
}
