import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepo = ChatRepository();
  final TextEditingController _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to use chat')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          // 🔹 Message List
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatRepo.getChatMessages(user!.uid, widget.peerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.senderId == user!.uid;

                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 250),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.primary.withOpacity(0.9)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg.message,
                          style: TextStyle(
                            color: isMine ? Colors.white : AppColors.text,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _chatRepo.sendMessage(user!.uid, widget.peerId, text);
    _messageController.clear();
  }
}
