import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF8F4EF);
  static const surface = Color(0xFFFFFCF9);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const text = Color(0xFF2C2420);
  static const textMuted = Color(0xFF7A716A);
  static const textHint = Color(0xFFA89F97);
  static const line = Color(0xFFEDE6DF);
  static const accent = Color(0xFFE07A6A);
  static const accentHover = Color(0xFFC96A5C);
  static const success = Color(0xFF5C8A6E);
  static const warning = Color(0xFFC4A35A);
  static const error = Color(0xFFC45C4A);

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