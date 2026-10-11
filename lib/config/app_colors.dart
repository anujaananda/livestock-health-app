import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY COLORS
  static const Color primary = Color(0xFF20B769);
  static const Color primaryLight = Color(0xFF6DCE96);
  static const Color primaryDark = Color(0xFF176B43);
  static const Color primaryBg = Color(0xFFF8FCF9);
  static const Color primarySurface = Color(0xFFE5F7EA);

  // TEXT COLORS
  static const Color textPrimary = Color(0xFF1E3027);
  static const Color textSecondary = Color(0xFF697A71);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFF7D8B83);

  // STATUS COLORS
  static const Color success = Color(0xFF20B769);
  static const Color successBg = Color(0xFFE5F7EA);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFF4E5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFFE5E5);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFE5F0FA);

  // EMERGENCY
  static const Color emergency = Color(0xFFD32F2F);
  static const Color emergencyDark = Color(0xFFB71C1C);
  static const Color emergencyBg = Color(0xFFFFE5E5);

  // NEUTRAL
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFF3F4F6);
  static const Color greyBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5F0E9);

  // ============================================================
  // ✅ DARK MODE COLORS
  // ============================================================
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF2C2C2C);

  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextHint = Color(0xFF6B6B6B);

  static const Color darkPrimary = Color(0xFF2ED87A);
  static const Color darkPrimarySurface = Color(0xFF1B3A2A);

  // GRADIENTS
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF42B97A), Color(0xFF20B769), Color(0xFF176B43)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF42B97A), Color(0xFF6DCE96), Color(0xFF91DDB0)],
  );
}
