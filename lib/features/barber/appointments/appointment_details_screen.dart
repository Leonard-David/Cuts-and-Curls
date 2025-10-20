// lib/features/barber/appointments/appointment_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';

/// ✅ Appointment Detail Screen
/// Visually matches your Dashboard design and allows interactive actions.
class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(widget.appointmentId).get();
      if (doc.exists) {
        setState(() {
          _data = doc.data();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Appointment not found')));
      }
    } catch (e) {
      debugPrint('Error loading appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load appointment')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Marked as $newStatus')));
      }

      _loadAppointment();
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No data found'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _header(),
                      const SizedBox(height: 20),
                      Expanded(child: _detailSection()),
                      const SizedBox(height: 20),
                      _actionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _header() {
    final clientName = _data?['clientName'] ?? 'Client';
    final service = _data?['service'] ?? 'Service';
    final status = _data?['status'] ?? 'pending';
    final avatarUrl = _data?['clientPhoto'];

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;

    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.primary.withAlpha(30),
          backgroundImage: avatarUrl != null
              ? NetworkImage(avatarUrl)
              : const AssetImage('lib/assets/images/avatar_placeholder.png')
                  as ImageProvider,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(clientName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Text(service,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        Chip(
          label: Text(status.toUpperCase(),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: statusColor,
        ),
      ],
    );
  }

  Widget _detailSection() {
    final dateTime = _data?['time'] is Timestamp
        ? (_data?['time'] as Timestamp).toDate()
        : DateTime.now();
    final price = (_data?['price'] ?? 0).toDouble();
    final note = _data?['note'] ?? '';
    final duration = _data?['duration'] ?? '30 min';

    return ListView(
      children: [
        _infoCard(Icons.calendar_today, 'Date & Time',
            DateFormat('EEE, MMM d • hh:mm a').format(dateTime)),
        _infoCard(Icons.timer, 'Duration', duration),
        _infoCard(Icons.attach_money, 'Price', 'N\$${price.toStringAsFixed(2)}'),
        if (note.isNotEmpty) _infoCard(Icons.notes, 'Notes', note),
      ],
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              offset: const Offset(0, 2),
              blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
          )
        ],
      ),
    );
  }

  Widget _actionButtons() {
    final status = _data?['status'] ?? 'pending';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (status != 'completed')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(140, 45),
            ),
            onPressed: () => _updateStatus('completed'),
            icon: const Icon(Icons.check),
            label: const Text('Complete'),
          ),
        if (status != 'cancelled')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(140, 45),
            ),
            onPressed: () => _updateStatus('cancelled'),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
      ],
    );
  }
}
