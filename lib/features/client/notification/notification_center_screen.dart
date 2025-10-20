// lib/features/shared/notification/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});
  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  final _repo = NotificationRepository();
  final _user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final _types = ['all', 'appointment', 'earning', 'promotion', 'feedback'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<AppNotification>> _streamForIndex(int index) {
    final uid = _user?.uid ?? '';
    if (index == 0) {
      return _repo.streamForUser(uid);
    } else {
      return _repo.streamForUserAndType(uid, _types[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Center'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Activity'),
            Tab(text: 'Appointment'),
            Tab(text: 'Earnings'),
            Tab(text: 'Promotions'),
            Tab(text: 'Feedback'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () async {
              if (_user != null) await _repo.markAllReadForUser(_user.uid);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_types.length, (i) {
          return StreamBuilder<List<AppNotification>>(
            stream: _streamForIndex(i),
            builder: (context, snap) {
              if (snap.hasError)
                return const Center(child: Text('Failed to load'));
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty)
                return const Center(child: Text('No notifications'));

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (context, state) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final n = list[idx];
                  return Dismissible(
                    key: Key(n.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (dir) async => await _repo.delete(n.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      tileColor: n.read ? Colors.white : Colors.grey.shade100,
                      leading: _buildLeadingIcon(n.type),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.read
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(n.body),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(n.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              n.read
                                  ? Icons.mark_email_read
                                  : Icons.mark_email_unread,
                            ),
                            onPressed: () => _repo.markRead(n.id),
                          ),
                        ],
                      ),
                      onTap: () => _onTapNotification(n, context),
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildLeadingIcon(String type) {
    switch (type) {
      case 'appointment':
        return const CircleAvatar(child: Icon(Icons.calendar_today, size: 18));
      case 'earning':
        return const CircleAvatar(child: Icon(Icons.monetization_on, size: 18));
      case 'promotion':
        return const CircleAvatar(child: Icon(Icons.campaign, size: 18));
      case 'feedback':
        return const CircleAvatar(child: Icon(Icons.feedback, size: 18));
      default:
        return const CircleAvatar(child: Icon(Icons.notifications, size: 18));
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${t.month}/${t.day}/${t.year}';
  }

  void _onTapNotification(AppNotification n, BuildContext context) {
    // Example action: open appointment
    if (n.meta != null && n.meta!['appointmentId'] != null) {
      final id = n.meta!['appointmentId'] as String;
      // navigate to appointment details screen
      context.push('/appointment/$id'); // ensure route exists
    } else {
      // just mark read and show details dialog
      _repo.markRead(n.id);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(n.title),
          content: Text(n.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
