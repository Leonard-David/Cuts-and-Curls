import 'package:flutter/foundation.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/repositories/chat_repository.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _repository = ChatRepository();
  final Map<String, bool> _typingUsers = {};
  Map<String, bool> get typingUsers => _typingUsers;

  // Chat rooms state
  List<ChatRoom> _chatRooms = [];
  bool _isLoadingChatRooms = false;
  String? _chatRoomsError;

  // Current chat state
  List<ChatMessage> _currentMessages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;

  // Connection state
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Offline state
  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoadingChatRooms => _isLoadingChatRooms;
  String? get chatRoomsError => _chatRoomsError;

  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;

  // Load chat rooms for user
  void loadChatRooms(String userId, String userType) {
    _isLoadingChatRooms = true;
    _chatRoomsError = null;
    notifyListeners();

    try {
      _repository.getChatRoomsForUser(userId, userType).listen((rooms) {
        _chatRooms = rooms;
        _isLoadingChatRooms = false;
        _chatRoomsError = null;
        notifyListeners();
      }, onError: (error) {
        _isLoadingChatRooms = false;
        _chatRoomsError = error.toString();
        notifyListeners();
      });
    } catch (e) {
      _isLoadingChatRooms = false;
      _chatRoomsError = e.toString();
      notifyListeners();
    }
  }

  // Load messages for chat
  void loadMessages(String chatId) {
    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();

    try {
      _repository.getMessagesStream(chatId).listen((messages) {
        _currentMessages = messages;
        _isLoadingMessages = false;
        _messagesError = null;
        notifyListeners();
      }, onError: (error) {
        _isLoadingMessages = false;
        _messagesError = error.toString();
        notifyListeners();
      });
      // Load typing indicators
      _repository.getTypingStatusStream(chatId).listen((typingStatus) {
        _typingUsers.clear();
        _typingUsers.addAll(typingStatus);
        notifyListeners();
      });
    } catch (e) {
      _isLoadingMessages = false;
      _messagesError = e.toString();
      notifyListeners();
    }
  }

  // Set typing status
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    try {
      await _repository.setTypingStatus(chatId, userId, isTyping);
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    try {
      if (!_isConnected) {
        // Queue message for offline sending
        await _repository.queueOfflineMessage({
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'senderType': senderType,
          'message': message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _isOfflineMode = true;
        notifyListeners();
        return;
      }

      await _repository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: message,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String readerId) async {
    try {
      await _repository.markMessagesAsRead(chatId, readerId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get or create chat room
  Future<ChatRoom> getOrCreateChatRoom({
    required String clientId,
    required String clientName,
    required String barberId,
    required String barberName,
  }) async {
    return await _repository.getOrCreateChatRoom(
      clientId: clientId,
      clientName: clientName,
      barberId: barberId,
      barberName: barberName,
    );
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentMessages.clear();
    _messagesError = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  // Sync offline messages when connection restored
  Future<void> syncOfflineMessages() async {
    try {
      await _repository.syncOfflineMessages();
      _isOfflineMode = false;
      notifyListeners();
    } catch (e) {
      print('Error syncing offline messages: $e');
    }
  }

  // Update connection status
  void updateConnectionStatus(bool connected) {
    _isConnected = connected;
    if (connected && _isOfflineMode) {
      syncOfflineMessages();
    }
    notifyListeners();
  }
}
