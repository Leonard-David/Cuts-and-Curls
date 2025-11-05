import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/utils/offline_service.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/repositories/chat_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final OfflineService _offlineService = OfflineService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isSending = false;
  bool _isOnline = true;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _markMessagesAsRead();
    _scrollToBottom();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    // Check connectivity every 10 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) {
        _checkConnectivity();
      }
      return mounted;
    });
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _offlineService.isConnected();
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  void _markMessagesAsRead() {
    final authProvider = context.read<AuthProvider>();
    _chatRepository.markMessagesAsRead(
      widget.chatRoom.id,
      authProvider.user!.id,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user!;

    setState(() {
      _isSending = true;
    });

    try {
      if (_isOnline) {
        await _chatRepository.sendTextMessage(
          chatId: widget.chatRoom.id,
          senderId: user.id,
          senderName: user.fullName,
          senderType: user.userType,
          message: message,
        );
      } else {
        // Save message locally for offline sync
        final tempMessage = ChatMessage(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          chatId: widget.chatRoom.id,
          senderId: user.id,
          senderName: user.fullName,
          senderType: user.userType,
          message: message,
          timestamp: DateTime.now(),
          isRead: false,
        );
        
        // Add to local storage for sync later
        await _offlineService.addOfflineMessage(tempMessage);
        
        // Add to UI immediately
        setState(() {
          _messages.add(tempMessage);
        });
        _scrollToBottom();
        
        showCustomSnackBar(
          context,
          'Message saved offline. Will send when connected.',
          type: SnackBarType.info,
        );
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to send message: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendImage() async {
    if (_isSending) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user!;

    setState(() {
      _isSending = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        if (_isOnline) {
          await _chatRepository.sendImageMessage(
            chatId: widget.chatRoom.id,
            senderId: user.id,
            senderName: user.fullName,
            senderType: user.userType,
            imageFile: image,
          );
        } else {
          showCustomSnackBar(
            context,
            'Image sharing requires internet connection',
            type: SnackBarType.error,
          );
        }
        _scrollToBottom();
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to send image: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatRepository.deleteMessage(widget.chatRoom.id, message.id);
        showCustomSnackBar(
          context,
          'Message deleted',
          type: SnackBarType.success,
        );
      } catch (e) {
        showCustomSnackBar(
          context,
          'Failed to delete message: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _onMessageChanged(String text) {
    // Implement typing indicator
    if (text.isNotEmpty && _isOnline) {
      _chatRepository.sendTypingIndicator(
        widget.chatRoom.id,
        context.read<AuthProvider>().user!.id,
        true,
      );
    }
  }

  String _getOtherUserName() {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user!.id;
    
    return currentUserId == widget.chatRoom.clientId
        ? widget.chatRoom.barberName
        : widget.chatRoom.clientName;
  }

  String _getOtherUserType() {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user!.id;
    
    return currentUserId == widget.chatRoom.clientId ? 'barber' : 'client';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user!;

    return Column(
      children: [
        // Connection Status Banner
        if (!_isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.accent.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'You are offline. Messages will be sent when connected.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        // Messages List
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatRepository.getMessagesStream(widget.chatRoom.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final messages = snapshot.data ?? [];
              _messages = messages;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              if (messages.isEmpty) {
                return _buildEmptyChat();
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message, currentUser.id);
                },
              );
            },
          ),
        ),
        // Message Input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Start a Conversation',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${_getOtherUserName()}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String currentUserId) {
    final isMe = message.senderId == currentUserId;
    final showAvatar = !isMe;
    final isOffline = message.id.startsWith('offline_');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (showAvatar)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getOtherUserType() == 'barber' ? Icons.cut : Icons.person,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _deleteMessage(message),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: isOffline 
                          ? Border.all(color: AppColors.accent.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessageContent(message, isMe),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? AppColors.onPrimary.withOpacity(0.7) : AppColors.textSecondary,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              if (isOffline)
                                Icon(Icons.cloud_upload, size: 12, color: AppColors.accent),
                              if (!isOffline && message.isRead)
                                Icon(Icons.done_all, size: 12, color: AppColors.success),
                              if (!isOffline && !message.isRead)
                                Icon(Icons.done, size: 12, color: AppColors.onPrimary.withOpacity(0.5)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(left: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isMe) {
    final textColor = isMe ? AppColors.onPrimary : AppColors.text;

    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📷 Image',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade300,
              ),
              child: message.attachmentUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.attachmentUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary);
                        },
                      ),
                    )
                  : Icon(Icons.image, size: 40, color: AppColors.textSecondary),
            ),
          ],
        );
      case MessageType.system:
        return Text(
          message.message,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        );
      default:
        return Text(
          message.message,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
          ),
        );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Button
          IconButton(
            icon: Icon(
              Icons.photo_library,
              color: _isOnline ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: _isOnline ? _sendImage : null,
            tooltip: 'Send Image',
          ),
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: _onMessageChanged,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _isSending
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isSending,
              ),
            ),
          ),
          // Send Button
          IconButton(
            icon: Icon(
              Icons.send,
              color: _isSending ? AppColors.textSecondary : AppColors.primary,
            ),
            onPressed: _isSending ? null : _sendMessage,
            tooltip: 'Send Message',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}