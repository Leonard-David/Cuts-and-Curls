import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';

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
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 16),
              // Days List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAvailability,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final slots = _weeklyAvailability[day]!;
                      final isDayAvailable = slots.isNotEmpty;
                      return _buildDayCard(day, slots, isDayAvailable);
                    },
                  ),
                ),
              ),
              // Save Button
              if (!_isLoading) _buildSaveButton(),
            ],
          );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your available hours for each day of the week',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, List<TimeSlot> slots, bool isDayAvailable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header with toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isDayAvailable,
                  onChanged: (value) => _toggleDayAvailability(day, value),
                  activeColor: AppColors.success,
                  inactiveTrackColor: AppColors.error.withOpacity(0.5),
                ),
              ],
            ),
            
            if (isDayAvailable) ...[
              const SizedBox(height: 16),
              // Time slots header
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Available Time Slots',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${slots.length} slot${slots.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Time slots list
              ...slots.asMap().entries.map((entry) {
                final slotIndex = entry.key;
                final slot = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_formatTimeOfDay(slot.startTime)} - ${_formatTimeOfDay(slot.endTime)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                        onPressed: () => _editTimeSlot(day, slotIndex),
                        tooltip: 'Edit Time Slot',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () => _removeTimeSlot(day, slotIndex),
                        tooltip: 'Remove Time Slot',
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 12),
              
              // Add time slot button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _addTimeSlot(day),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Add Time Slot'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.do_not_disturb_rounded, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Not available for bookings',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAvailability,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Save Availability',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

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
            _weeklyAvailability[day] = [];
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
      final Map<String, dynamic> availabilityData = {};
      for (final day in _days) {
        availabilityData[day.toLowerCase()] = _weeklyAvailability[day]!
            .map((slot) => slot.toMap())
            .toList();
      }

      await FirebaseFirestore.instance
          .collection('barber_availability')
          .doc(barberId)
          .set(availabilityData, SetOptions(merge: true));

      showCustomSnackBar(
        context,
        'Availability saved successfully!',
        type: SnackBarType.success,
      );
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to save availability: $e',
        type: SnackBarType.error,
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
        _weeklyAvailability[day]!.add(TimeSlot(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
        ));
      } else if (!isAvailable) {
        _weeklyAvailability[day]!.clear();
      }
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
    };
  }

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