// lib/features/barber/barber_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheersync/features/barber/dashboard/dashboard_screen.dart';
import 'package:sheersync/features/client/notification/notification_center_screen.dart';
import 'package:sheersync/features/shared/widgets/bottom_nav.dart';

class BarberShell extends ConsumerStatefulWidget {
  const BarberShell({super.key});

  @override
  ConsumerState<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends ConsumerState<BarberShell> {
  int _index = 0;

  // Build pages for barber (Dashboard, Promotions, Add, Schedule, Chat/Notifications)
  List<Widget> _pages() => const [
    BarberDashboardPage(),
    // Promotion placeholder (can be implemented later)
    Center(child: Text('Promotions')),
    // Add new service placeholder
   // BarberServicesPage(),
    //BarberAppointmentsPage(),
    NotificationCenterScreen(), // chat could be separate; using notifications for now
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages();

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
