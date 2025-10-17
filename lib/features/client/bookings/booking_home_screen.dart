// lib/features/client/booking/booking_home_screen.dart
//
// Temporary placeholder for the Client Booking Home screen.
// Later this will display available barbers, booking history,
// and chat access.

import 'package:flutter/material.dart';

class BookingHomeScreen extends StatelessWidget {
  const BookingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome Client! Your booking options will appear here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
