// lib/features/client/client_shell.dart
import 'package:flutter/material.dart';
import 'package:sheersync/features/shared/widgets/bottom_nav.dart';
import 'home/home_screen.dart';
import '../../features/shared/notification/notification_center_screen.dart';
import '../client/bookings/my_bookings_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  List<Widget> _pages() => const [
        ClientHomeScreen(),
        Center(child: Text('Promotions')),
        Center(child: Text('Explore')), // add barber browsing
        MyBookingsScreen(),
        NotificationCenterScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}
