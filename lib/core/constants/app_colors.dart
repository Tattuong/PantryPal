import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1B8A5A);
  static const Color primaryLight = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF0E6B44);

  static const Color accent = Color(0xFFF39C12);
  static const Color accentAlt = Color(0xFFE67E22);

  static const Color background = Color(0xFFF4FBF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F5EE);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E2D28);
  static const Color onSurfaceVariant = Color(0xFF5C6F66);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color coin = Color(0xFFFFC107);

  static const Color darkBackground = Color(0xFF0F1613);
  static const Color darkSurface = Color(0xFF1A2420);

  static const Color expired = Color(0xFFE74C3C);
  static const Color expiringSoon = Color(0xFFF39C12);
  static const Color fresh = Color(0xFF27AE60);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E6B44), Color(0xFF1B8A5A), Color(0xFF2ECC71)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B8A5A), Color(0xFF2ECC71)],
  );

  static const List<Color> categoryPalette = [
    Color(0xFFE74C3C),
    Color(0xFF27AE60),
    Color(0xFFF39C12),
    Color(0xFF3498DB),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF34495E),
  ];
}
