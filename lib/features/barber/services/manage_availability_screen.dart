import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/auth/controllers/auth_provider.dart';
import 'package:sheersync/core/constants/colors.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final Map<String, List<TimeSlot>> _weeklyAvailability = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Days of the week
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final authProvider = context.read<AuthProvider>();
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('barber_availability')
          .doc(barberId)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _weeklyAvailability.clear();
        
        // Parse availability data from Firestore
        for (final day in _days) {
          if (data.containsKey(day.toLowerCase())) {
            final slotsData = data[day.toLowerCase()] as List<dynamic>? ?? [];
            _weeklyAvailability[day] = slotsData.map((slot) {
              return TimeSlot.fromMap(Map<String, dynamic>.from(slot));
            }).toList();
          } else {
            _weeklyAvailability[day] = []; // Default empty slots
          }
        }
      } else {
        // Initialize with empty slots for all days
        for (final day in _days) {
          _weeklyAvailability[day] = [];
        }
      }
    } catch (e) {
      print('Error loading availability: $e');
      // Initialize with empty slots as fallback
      for (final day in _days) {
        _weeklyAvailability[day] = [];
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveAvailability() async {
    final authProvider = context.read<AuthProvider>();
    final barberId = authProvider.user?.id;

    if (barberId == null) return;

    setState(() => _isSaving = true);

    try {
      // FIX: Convert availability to Firestore format with proper typing
      final Map<String, dynamic> availabilityData = {}; // FIX: Specify type explicitly
      for (final day in _days) {
        availabilityData[day.toLowerCase()] = _weeklyAvailability[day]!
            .map((slot) => slot.toMap())
            .toList();
      }

      await FirebaseFirestore.instance
          .collection('barber_availability')
          .doc(barberId)
          .set(availabilityData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Availability saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save availability: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isSaving = false);
  }

  void _addTimeSlot(String day) {
    setState(() {
      _weeklyAvailability[day]!.add(TimeSlot(
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
      ));
    });
  }

  void _removeTimeSlot(String day, int index) {
    setState(() {
      _weeklyAvailability[day]!.removeAt(index);
    });
  }

  Future<void> _editTimeSlot(String day, int index) async {
    final slot = _weeklyAvailability[day]![index];
    
    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: slot.startTime,
    );

    if (newStartTime == null) return;

    final TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: slot.endTime,
    );

    if (newEndTime == null) return;

    setState(() {
      _weeklyAvailability[day]![index] = TimeSlot(
        startTime: newStartTime,
        endTime: newEndTime,
      );
    });
  }

  void _toggleDayAvailability(String day, bool isAvailable) {
    setState(() {
      if (isAvailable && _weeklyAvailability[day]!.isEmpty) {
        // Add default time slot when enabling a day
        _weeklyAvailability[day]!.add(TimeSlot(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
        ));
      } else if (!isAvailable) {
        // Clear all slots when disabling a day
        _weeklyAvailability[day]!.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 1,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isSaving
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveAvailability,
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final slots = _weeklyAvailability[day]!;
                final isDayAvailable = slots.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day header with toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: isDayAvailable,
                              onChanged: (value) => _toggleDayAvailability(day, value),
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                        
                        if (isDayAvailable) ...[
                          const SizedBox(height: 12),
                          // Time slots list
                          ...slots.asMap().entries.map((entry) {
                            final slotIndex = entry.key;
                            final slot = entry.value;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_formatTimeOfDay(slot.startTime)} - ${_formatTimeOfDay(slot.endTime)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editTimeSlot(day, slotIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _removeTimeSlot(day, slotIndex),
                                    color: AppColors.error,
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 8),
                          
                          // Add time slot button
                          ElevatedButton(
                            onPressed: () => _addTimeSlot(day),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                            child: const Text('Add Time Slot'),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            'Not available',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// TimeSlot model for availability
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
    };
  }

  // Create from Firestore data
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: TimeOfDay(
        hour: map['startHour'] ?? 9,
        minute: map['startMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endHour'] ?? 17,
        minute: map['endMinute'] ?? 0,
      ),
    );
  }
}