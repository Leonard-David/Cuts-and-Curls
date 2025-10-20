// lib/data/providers/appointments_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final barberAppointmentsStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, barberId) {
      // Stream all appointments for a barber
      final col = FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .orderBy('scheduledAt', descending: true);
      return col.snapshots();
    });

// Simple aggregated stats provider for a barber (counts & earnings)
final barberStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, barberId) async {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .get();

      final total = snap.docs.length;
      final completed = snap.docs
          .where((d) => d['status'] == 'completed')
          .length;
      final pending = snap.docs.where((d) => d['status'] == 'pending').length;
      final earnings = snap.docs
          .where((d) => d['status'] == 'completed')
          .fold<double>(
            0.0,
            (sum, d) => sum + ((d.data()['price'] ?? 0) as num).toDouble(),
          );

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'earnings': earnings,
      };
    });
