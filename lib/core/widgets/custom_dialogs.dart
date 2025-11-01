// lib/core/widgets/custom_dialogs.dart
//
// Reusable dialogs: confirm dialog, input dialog, time-slot add/edit dialog.
// Uses showDialog and returns results to caller.
//
// Usage examples:
//  final confirmed = await CustomDialogs.showConfirm(context, "Delete slot?");
//  if (confirmed == true) { ... }
//
//  final result = await CustomDialogs.showAddSlotDialog(context);
//  if (result != null) { // result contains {'start': TimeOfDay, 'end': TimeOfDay} }
//

import 'package:flutter/material.dart';

class CustomDialogs {
  /// Simple confirm dialog (Yes/No).
  static Future<bool?> showConfirm(BuildContext context, String title, {String? body}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: body != null ? Text(body) : null,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Yes")),
        ],
      ),
    );
  }

  /// Simple info dialog with single "OK".
  static Future<void> showInfo(BuildContext context, String title, {String? body}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: body != null ? Text(body) : null,
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK")),
        ],
      ),
    );
  }

  /// Show a dialog to add/edit a timeslot for a day.
  ///
  /// Returns a Map: { 'start': TimeOfDay, 'end': TimeOfDay } or null if cancelled.
  static Future<Map<String, TimeOfDay>?> showAddSlotDialog(
      BuildContext context, {
      TimeOfDay? initialStart,
      TimeOfDay? initialEnd,
      String title = "Add time slot",
    }) {
    final startController = ValueNotifier<TimeOfDay?>(initialStart);
    final endController = ValueNotifier<TimeOfDay?>(initialEnd);

    return showDialog<Map<String, TimeOfDay>?>(
      context: context,
      builder: (ctx) {
        Future<void> pickStart() async {
          final now = TimeOfDay.now();
          final picked = await showTimePicker(context: ctx, initialTime: startController.value ?? now);
          if (picked != null) startController.value = picked;
        }

        Future<void> pickEnd() async {
          final now = TimeOfDay.now();
          final picked = await showTimePicker(context: ctx, initialTime: endController.value ?? now);
          if (picked != null) endController.value = picked;
        }

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<TimeOfDay?>(
                valueListenable: startController,
                builder: (_, v, __) {
                  return ListTile(
                    title: Text(v != null ? v.format(ctx) : 'Select start time'),
                    leading: const Icon(Icons.play_arrow),
                    onTap: pickStart,
                  );
                },
              ),
              ValueListenableBuilder<TimeOfDay?>(
                valueListenable: endController,
                builder: (_, v, __) {
                  return ListTile(
                    title: Text(v != null ? v.format(ctx) : 'Select end time'),
                    leading: const Icon(Icons.stop),
                    onTap: pickEnd,
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final start = startController.value;
                final end = endController.value;
                if (start == null || end == null) {
                  // Simple validation: both required
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Please select both start and end")));
                  return;
                }
                Navigator.of(ctx).pop({'start': start, 'end': end});
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// Input dialog for simple text (e.g., override label). Returns string or null.
  static Future<String?> showTextInput(BuildContext context, {required String title, String? hint}) {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text("OK")),
        ],
      ),
    );
  }
}
