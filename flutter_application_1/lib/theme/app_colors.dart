import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFCFBF8);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C1C1A);
  static const textMuted = Color(0xFF6B6A64);
  static const textHint = Color(0xFF9C9A93);
  static const line = Color(0xFFE7E5DF);
  static const accent = Color(0xFF0F766E);
  static const accentHover = Color(0xFF115E59);
  static const success = Color(0xFF3F7D5A);
  static const warning = Color(0xFFA16207);
  static const error = Color(0xFFB42318);

  // старые имена, чтобы экраны не сломались
  static const coral = accent;
  static const teal = accent;
  static const backgroundWarm = background;
  static const iconMuted = textHint;
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

class AppShadows {
  static final subtle = [
    BoxShadow(
      color: const Color(0xFF1C1C1A).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 1),
    ),
  ];
  static final card = [
    BoxShadow(
      color: const Color(0xFF1C1C1A).withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static final floating = [
    BoxShadow(
      color: const Color(0xFF1C1C1A).withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}