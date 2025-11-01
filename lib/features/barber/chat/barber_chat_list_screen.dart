import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/repositories/chat_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/shared/chat/chat_screen.dart';

class BarberChatListScreen extends StatefulWidget {
  const BarberChatListScreen({super.key});

  @override
  State<BarberChatListScreen> createState() => _BarberChatListScreenState();
}

class _BarberChatListScreenState extends State<BarberChatListScreen> {
  final ChatRepository _chatRepository = ChatRepository();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      return const Center(child: Text('Please login again'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatRepository.getChatRoomsForUser(barberId, 'barber'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final chatRooms = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatRoomItem(chatRoom);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Messages',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your messages with clients will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom chatRoom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: Colors.blue.shade600,
          ),
        ),
        title: Text(
          chatRoom.clientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chatRoom.lastMessage != null)
              Text(
                chatRoom.lastMessage!.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(chatRoom.updatedAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: chatRoom.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chatRoom.unreadCount > 9 ? '9+' : chatRoom.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: chatRoom),
            ),
          );
        },
      ),
    );
  }
}