// lib/core/widgets/loading_overlay.dart
//
// A simple global loading overlay utility using OverlayEntry.
// Use LoadingOverlay.show(context) and LoadingOverlay.hide().
// Multiple calls to show() are reference counted so hiding only removes when balanced.

import 'package:flutter/material.dart';

class LoadingOverlay {
  static final LoadingOverlay _singleton = LoadingOverlay._internal();

  factory LoadingOverlay() => _singleton;

  LoadingOverlay._internal();

  OverlayEntry? _entry;
  int _counter = 0;

  void show(BuildContext context, {String? message}) {
    _counter++;
    if (_entry != null) return; // already showing

    _entry = OverlayEntry(builder: (ctx) {
      return Material(
        color: Colors.black,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  message ?? 'Please wait...',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
      );
    });

    Overlay.of(context).insert(_entry!);
  }

  void hide() {
    _counter = (_counter - 1).clamp(0, 999);
    if (_counter > 0) return; // still references active
    try {
      _entry?.remove();
    } catch (_) {}
    _entry = null;
  }
}
