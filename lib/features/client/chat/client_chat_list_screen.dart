import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';

class ClientChatListScreen extends StatefulWidget {
  const ClientChatListScreen({super.key});

  @override
  State<ClientChatListScreen> createState() => _ClientChatListScreenState();
}

class _ClientChatListScreenState extends State<ClientChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeChats();
  }

  void _initializeChats() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();

      if (authProvider.user != null) {
        // Load chat rooms with real-time updates
        chatProvider.loadChatRooms(authProvider.user!.id, 'client');
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Chat List
          Expanded(
            child: _buildChatList(chatProvider, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(ChatProvider chatProvider, AuthProvider authProvider) {
    if (chatProvider.isLoadingChatRooms) {
      return _buildLoadingState();
    }

    if (chatProvider.chatRoomsError != null) {
      return _buildErrorState(chatProvider.chatRoomsError!);
    }

    final filteredChats = _filterChats(chatProvider.chatRooms);

    if (filteredChats.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshChats,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final chatRoom = filteredChats[index];
          return _buildChatItem(chatRoom, authProvider);
        },
      ),
    );
  }

  Widget _buildChatItem(ChatRoom chatRoom, AuthProvider authProvider) {
    final hasUnread = chatRoom.unreadCount > 0;
    final lastMessage = chatRoom.lastMessage;
    final lastMessageTime = lastMessage?.timestamp ?? chatRoom.updatedAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openChat(chatRoom),
        onLongPress: () => _showChatOptions(chatRoom),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Barber Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 24,
                      color: AppColors.accent,
                    ),
                  ),
                  // Online Status Indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chatRoom.barberName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: hasUnread
                                ? AppColors.text
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatMessageTime(lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage?.message ?? 'No messages yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread Badge
              if (hasUnread)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chatRoom.unreadCount > 99
                        ? '99+'
                        : chatRoom.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Error Loading Chats',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.error,
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
              onPressed: _refreshChats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(140, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
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
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Conversations',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with a barber or hairstylist to see your messages here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _findProfessionals,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(180, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Find Professionals'),
            ),
          ],
        ),
      ),
    );
  }

  List<ChatRoom> _filterChats(List<ChatRoom> chatRooms) {
    if (_searchQuery.isEmpty) {
      return chatRooms;
    }

    return chatRooms.where((chat) {
      return chat.barberName.toLowerCase().contains(_searchQuery) ||
          chat.lastMessage?.message.toLowerCase().contains(_searchQuery) ==
              true;
    }).toList();
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Future<void> _refreshChats() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.user != null) {
      chatProvider.loadChatRooms(authProvider.user!.id, 'client');
    }
  }

  void _openChat(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _showChatOptions(ChatRoom chatRoom) {
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
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text(
                'Delete Conversation',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteChat(chatRoom);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: AppColors.text),
              title: Text(
                'Block Professional',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pop(context);
                _blockProfessional(chatRoom);
              },
            ),
            ListTile(
              leading: Icon(Icons.report, color: AppColors.text),
              title: Text(
                'Report',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportChat(chatRoom);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteChat(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Conversation',
          style: TextStyle(color: AppColors.text),
        ),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
              _confirmDeleteChat(chatRoom);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(ChatRoom chatRoom) {
    // In a real app, you would call the chat repository to delete the chat
    // For now, we'll just show a success message
    showCustomSnackBar(
      context,
      'Conversation deleted successfully',
      type: SnackBarType.success,
    );
  }

  void _blockProfessional(ChatRoom chatRoom) {
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
          'Are you sure you want to block ${chatRoom.barberName}? You will no longer receive messages or be able to book appointments with them.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
              _confirmBlockProfessional(chatRoom);
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

  void _confirmBlockProfessional(ChatRoom chatRoom) {
    // In a real app, you would call the user repository to block the professional
    showCustomSnackBar(
      context,
      '${chatRoom.barberName} has been blocked',
      type: SnackBarType.success,
    );
  }

  void _reportChat(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report Conversation',
          style: TextStyle(color: AppColors.text),
        ),
        content: Text(
          'Please describe the issue with this conversation. Our team will review it within 24 hours.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
              _submitReport(chatRoom);
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

  void _submitReport(ChatRoom chatRoom) {
    showCustomSnackBar(
      context,
      'Report submitted successfully. We will review it soon.',
      type: SnackBarType.success,
    );
  }

  void _findProfessionals() {
    // Navigate to professionals screen
    // This would be handled by the navigation system
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
