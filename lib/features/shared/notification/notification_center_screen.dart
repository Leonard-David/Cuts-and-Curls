// lib/features/shared/notification/notification_center_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../core/constants/colors.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: AppColors.primary),
      body: notifAsync.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No notifications'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final n = list[i];
              final created = (n['createdAt'] as Timestamp?)?.toDate();
              return ListTile(
                leading: Icon(_iconForType(n['type'])),
                title: Text(n['title'] ?? ''),
                subtitle: Text(n['body'] ?? ''),
                trailing: created != null ? Text(DateFormat.Hm().format(created)) : null,
                onTap: () {
                  // mark read or navigate to related screen
                  FirebaseFirestore.instance.collection('notifications').doc(n['id']).update({'read': true});
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _iconForType(String? t) {
    switch (t) {
      case 'appointment':
        return Icons.calendar_today;
      case 'status':
        return Icons.info;
      case 'promotion':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}
