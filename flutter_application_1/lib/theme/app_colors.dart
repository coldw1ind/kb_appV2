import 'package:flutter/material.dart';

class AppColors {
  static const coral = Color(0xFFFF6B6B);
  static const teal = Color(0xFF0D9488);
  static const background = Color(0xFFF8FAFC);
  static const backgroundWarm = Color(0xFFFFF8F5);
  static const surface = Colors.white;
  static const text = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);
  static const iconMuted = Color(0xFFCBD5E1);
  static const line = Color(0xFFE2E8F0);
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 16.0;
}

class AppShadows {
  static final card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
