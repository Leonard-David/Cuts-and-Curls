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
      id: map['id'],
      chatId: map['chatId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderType: map['senderType'],
      message: map['message'],
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
    );
  }

  // Create copy with method for updates
  ChatMessage copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );
  }
}

enum MessageType {
  text,
  image,
  document,
  system,
}