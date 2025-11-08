import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/chat_message_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Load messages for this chat
      chatProvider.loadMessages(widget.chatRoom.id);
      
      // Mark messages as read
      if (authProvider.user != null) {
        chatProvider.markMessagesAsRead(widget.chatRoom.id, authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _buildMessagesList(chatProvider, authProvider),
          ),
          // Message Input
          _buildMessageInput(chatProvider, authProvider),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: Icon(
              Icons.person,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.barberName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online', // This would come from barber's online status
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: _callProfessional,
          tooltip: 'Call',
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: _videoCallProfessional,
          tooltip: 'Video Call',
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('View Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'book_appointment',
              child: Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 8),
                  Text('Book Appointment'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block),
                  SizedBox(width: 8),
                  Text('Block Professional'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider, AuthProvider authProvider) {
    if (chatProvider.isLoadingMessages) {
      return _buildLoadingState();
    }

    if (chatProvider.messagesError != null) {
      return _buildErrorState(chatProvider.messagesError!);
    }

    final messages = chatProvider.currentMessages;

    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      reverse: false,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == authProvider.user?.id;
        final showAvatar = _shouldShowAvatar(messages, index, isMe);
        final showTime = _shouldShowTime(messages, index);

        return Column(
          children: [
            if (showTime) _buildTimeSeparator(message.timestamp),
            _buildMessageBubble(message, isMe, showAvatar),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[200],
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSeparator(DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatTimeSeparator(time),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _attachFile,
            tooltip: 'Attach File',
          ),
          // Message Input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (value) => _sendMessage(chatProvider, authProvider),
            ),
          ),
          // Send Button
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isSending
                ? null
                : () => _sendMessage(chatProvider, authProvider),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Messages',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryLoadingMessages,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowAvatar(List<ChatMessage> messages, int index, bool isMe) {
    if (isMe) return false;
    if (index == 0) return true;
    
    final previousMessage = messages[index - 1];
    final currentMessage = messages[index];
    
    // Show avatar if previous message was from different sender or more than 5 minutes ago
    return previousMessage.senderId != currentMessage.senderId ||
        currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes > 5;
  }

  bool _shouldShowTime(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    
    final previousMessage = messages[index - 1];
    final currentMessage = messages[index];
    
    // Show time if more than 5 minutes between messages
    return currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes > 5;
  }

  String _formatTimeSeparator(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return 'Today, ${DateFormat('HH:mm').format(time)}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(time);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(ChatProvider chatProvider, AuthProvider authProvider) async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    if (authProvider.user == null) {
      showCustomSnackBar(context, 'Please login to send messages', type: SnackBarType.error);
      return;
    }

    setState(() => _isSending = true);

    try {
      await chatProvider.sendMessage(
        chatId: widget.chatRoom.id,
        senderId: authProvider.user!.id,
        senderName: authProvider.user!.fullName,
        senderType: 'client',
        message: message,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to send message: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _attachFile() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    showCustomSnackBar(
      context,
      'Image picker will be implemented',
      type: SnackBarType.info,
    );
  }

  void _takePhoto() {
    showCustomSnackBar(
      context,
      'Camera will be implemented',
      type: SnackBarType.info,
    );
  }

  void _pickDocument() {
    showCustomSnackBar(
      context,
      'Document picker will be implemented',
      type: SnackBarType.info,
    );
  }

  void _callProfessional() {
    showCustomSnackBar(
      context,
      'Call functionality will be implemented',
      type: SnackBarType.info,
    );
  }

  void _videoCallProfessional() {
    showCustomSnackBar(
      context,
      'Video call functionality will be implemented',
      type: SnackBarType.info,
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'view_profile':
        _viewProfessionalProfile();
        break;
      case 'book_appointment':
        _bookAppointment();
        break;
      case 'block':
        _blockProfessional();
        break;
      case 'report':
        _reportProfessional();
        break;
    }
  }

  void _viewProfessionalProfile() {
    showCustomSnackBar(
      context,
      'Profile view will be implemented',
      type: SnackBarType.info,
    );
  }

  void _bookAppointment() {
    showCustomSnackBar(
      context,
      'Booking will be implemented',
      type: SnackBarType.info,
    );
  }

  void _blockProfessional() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Professional'),
        content: Text('Are you sure you want to block ${widget.chatRoom.barberName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmBlockProfessional();
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBlockProfessional() {
    showCustomSnackBar(
      context,
      '${widget.chatRoom.barberName} has been blocked',
      type: SnackBarType.success,
    );
  }

  void _reportProfessional() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Professional'),
        content: const Text('Please describe the issue with this professional.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReport();
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _submitReport() {
    showCustomSnackBar(
      context,
      'Report submitted successfully',
      type: SnackBarType.success,
    );
  }

  void _retryLoadingMessages() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.loadMessages(widget.chatRoom.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}