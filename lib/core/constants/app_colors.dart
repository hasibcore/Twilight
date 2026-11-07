import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Twilight Dark Theme Palette (Matching AI Studio Slate-950 & Indigo-600 UI)
  static const Color backgroundDark = Color(0xFF020617); // slate-950
  static const Color surfaceDark = Color(0xFF0F172A); // slate-900
  static const Color surfaceVariantDark = Color(0xFF1E293B); // slate-800
  static const Color cardDark = Color(0xFF0F172A); // slate-900
  
  // Light Theme Palette
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Brand Accents (Indigo / Purple / Rose matching AI Studio Web UI)
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryAccent = Color(0xFF818CF8); // indigo-400
  static const Color secondaryAccent = Color(0xFFA855F7); // purple-500

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color textTertiaryDark = Color(0xFF64748B); // slate-500

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Status & Actions
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color error = Color(0xFFF43F5E); // rose-500
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF6366F1);

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
      isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

  static Color iconMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF020617)],
  );
}
