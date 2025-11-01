import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/repositories/chat_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import '../../data/models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _scrollToBottom();
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
    if (message.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user!;

    try {
      await _chatRepository.sendTextMessage(
        chatId: widget.chatRoom.id,
        senderId: user.id,
        senderName: user.fullName,
        senderType: user.userType,
        message: message,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendImage() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user!;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        await _chatRepository.sendImageMessage(
          chatId: widget.chatRoom.id,
          senderId: user.id,
          senderName: user.fullName,
          senderType: user.userType,
          imageFile: image,
        );

        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image: $e'),
          backgroundColor: Colors.red,
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getOtherUserName()),
            Text(
              _getOtherUserType() == 'barber' ? 'Barber' : 'Client',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showChatInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatRepository.getMessagesStream(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyChat();
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

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
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Start a Conversation',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${_getOtherUserName()}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String currentUserId) {
    final isMe = message.senderId == currentUserId;
    final showAvatar = !isMe;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.blue.shade600,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue.shade500 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _buildMessageContent(message),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
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
              child: message.isRead
                  ? Icon(Icons.done_all, size: 14, color: Colors.blue.shade600)
                  : Icon(Icons.done, size: 14, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    final isMe = message.senderId == context.read<AuthProvider>().user!.id;
    final textColor = isMe ? Colors.white : Colors.black;

    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📷 Image',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                          return const Icon(Icons.broken_image);
                        },
                      ),
                    )
                  : const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          ],
        );
      case MessageType.system:
        return Text(
          message.message,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        );
      default:
        return Text(
          message.message,
          style: TextStyle(color: textColor),
        );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            icon: const Icon(Icons.photo_library),
            onPressed: _sendImage,
            color: Colors.blue,
          ),
          // Message Input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          // Send Button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chat Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoItem('Client', widget.chatRoom.clientName),
              _buildInfoItem('Barber', widget.chatRoom.barberName),
              _buildInfoItem('Chat Created', 
                  DateFormat('MMM d, yyyy').format(widget.chatRoom.createdAt)),
              const SizedBox(height: 16),
              if (widget.chatRoom.lastAppointmentId != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to appointment details
                  },
                  child: const Text('View Related Appointment'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}