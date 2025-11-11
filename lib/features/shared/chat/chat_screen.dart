import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  Timer? _typingTimer;
  bool _isTyping = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _startConnectivityListener();
  }

  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();

      // Load messages for this chat
      chatProvider.loadMessages(widget.chatRoom.id);

      // Mark messages as read
      if (authProvider.user != null) {
        chatProvider.markMessagesAsRead(
            widget.chatRoom.id, authProvider.user!.id);
      }
    });
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasConnected = _isConnected;
      // Check if any of the results indicate we have connectivity
      _isConnected = results.any((result) => result != ConnectivityResult.none);

      if (!wasConnected && _isConnected) {
        // Connection restored - sync offline messages
        _syncOfflineMessages();
      } else if (wasConnected && !_isConnected) {
        // Connection lost
        _isOfflineMode = true;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleTyping() {
    context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user == null) return;

    if (!_isTyping) {
      _isTyping = true;
      // We'll implement typing indicators in the provider later
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
    });
  }

  Future<void> _syncOfflineMessages() async {
    context.read<ChatProvider>();
    // This will be implemented when we add offline message queuing
    _isOfflineMode = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(chatProvider),
      body: Column(
        children: [
          // Connection Status Banner
          if (!_isConnected || _isOfflineMode) _buildConnectionBanner(),

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

  Widget _buildConnectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _isConnected ? Colors.orange : AppColors.error,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected
                ? 'Slow connection - messages may be delayed'
                : 'You are offline - messages will send when connected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatProvider chatProvider) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 16,
              color: AppColors.accent,
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
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

  Widget _buildMessagesList(
      ChatProvider chatProvider, AuthProvider authProvider) {
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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: AppColors.accent,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: isMe ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : AppColors.primary,
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
                          color:
                              isMe ? Colors.white70 : AppColors.textSecondary,
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
            border: Border.all(color: AppColors.border),
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

  Widget _buildMessageInput(
      ChatProvider chatProvider, AuthProvider authProvider) {
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
            icon: Icon(Icons.attach_file, color: AppColors.primary),
            onPressed: _attachFile,
            tooltip: 'Attach File',
          ),
          // Message Input
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              onChanged: (value) => _handleTyping(),
              decoration: InputDecoration(
                hintText: _isOfflineMode
                    ? 'Message will send when online...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _isOfflineMode
                    ? Icon(Icons.cloud_off, size: 20, color: AppColors.error)
                    : null,
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (value) => _sendMessage(chatProvider, authProvider),
            ),
          ),
          // Send Button
          IconButton(
            icon: _isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: _isOfflineMode
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
            onPressed: _isSending ||
                    (_isOfflineMode && _messageController.text.isEmpty)
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
          CircularProgressIndicator(color: AppColors.primary),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryLoadingMessages,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation by sending a message!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
        currentMessage.timestamp
                .difference(previousMessage.timestamp)
                .inMinutes >
            5;
  }

  bool _shouldShowTime(List<ChatMessage> messages, int index) {
    if (index == 0) return true;

    final previousMessage = messages[index - 1];
    final currentMessage = messages[index];

    // Show time if more than 5 minutes between messages
    return currentMessage.timestamp
            .difference(previousMessage.timestamp)
            .inMinutes >
        5;
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

  Future<void> _sendMessage(
      ChatProvider chatProvider, AuthProvider authProvider) async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    if (authProvider.user == null) {
      showCustomSnackBar(context, 'Please login to send messages',
          type: SnackBarType.error);
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

      // Show success message for offline mode
      if (_isOfflineMode) {
        showCustomSnackBar(
          context,
          'Message queued - will send when online',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to send message: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _attachFile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: AppColors.primary),
              title: Text('Photo Library',
                  style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title:
                  Text('Take Photo', style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file, color: AppColors.primary),
              title: Text('Document', style: TextStyle(color: AppColors.text)),
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
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block Professional',
          style: TextStyle(color: AppColors.text),
        ),
        content: Text(
            'Are you sure you want to block ${widget.chatRoom.barberName}? You will no longer receive messages from them.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmBlockProfessional();
            },
            child: Text(
              'Block',
              style: TextStyle(color: AppColors.error),
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
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report Professional',
          style: TextStyle(color: AppColors.text),
        ),
        content: Text(
            'Please describe the issue with this professional. Our team will review your report within 24 hours.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReport();
            },
            child: Text(
              'Submit Report',
              style: TextStyle(color: AppColors.primary),
            ),
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
    _typingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
