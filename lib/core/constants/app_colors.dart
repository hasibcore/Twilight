import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Theme Palette (Twilight Slate & Midnight Glassmorphic)
  static const Color backgroundDark = Color(0xFF030712); // Slate 950
  static const Color surfaceDark = Color(0xFF0B0F19); // Deep Slate
  static const Color surfaceVariantDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF131C31); // Dark glass card surface
  static const Color cardBorder = Color(0x1AFFFFFF); // Subtle 10% white border

  // Light Theme Palette
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Brand Accents (Indigo & Violet from Image 1)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryAccent = Color(0xFF818CF8); // Indigo 400
  static const Color secondaryAccent = Color(0xFF8B5CF6); // Purple 500

  // Vibrant Orange Accents for "ON HEAVY REPEAT" and Action Highlights
  static const Color orangeAccent = Color(0xFFF97316); // Orange 500
  static const Color orangeLight = Color(0xFFFB923C); // Orange 400

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiaryDark = Color(0xFF64748B); // Slate 500

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Status & Actions
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);

  // Theme-aware dynamic helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? textTertiaryDark : textTertiaryLight;

  static Color background(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color surfaceVariant(BuildContext context) =>
      isDark(context) ? surfaceVariantDark : surfaceVariantLight;

  static Color card(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;

  static Color icon(BuildContext context) =>
      isDark(context) ? Colors.white70 : const Color(0xFF424242);

  static Color iconMuted(BuildContext context) =>
      isDark(context) ? Colors.white38 : const Color(0xFF757575);

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F172A), Color(0xFF0B0F19), Color(0xFF030712)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );
}
